import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:paperclip2/models/game_state.dart';

GameSnapshot _snapshot() => GameSnapshot(
      metadata: {
        'snapshotSchemaVersion': 1,
        'lastActiveAt': DateTime.now().toIso8601String(),
      },
      core: {'paperclips': 0, 'money': 0.0},
      market: const {},
      production: const {},
      stats: const {},
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GamePersistenceOrchestrator.instance.resetForTesting();
    SaveManagerAdapter.resetForTesting();
  });

  test('coalescing: multiple autosave requests compress to a single persisted save', () async {
    final state = GameState();
    state.initializeNewGame('Coalesce Test');
    final pid = state.partieId!;

    // Seed initial snapshot so that a save is meaningful
    await const LocalGamePersistenceService().saveSnapshot(_snapshot(), slotId: pid);

    // Enqueue several autosave requests quickly
    await GamePersistenceOrchestrator.instance.requestAutoSave(state, reason: 'tick1');
    await GamePersistenceOrchestrator.instance.requestAutoSave(state, reason: 'tick2');
    await GamePersistenceOrchestrator.instance.requestAutoSave(state, reason: 'tick3');

    // Let the background pump run
    await Future<void>.delayed(const Duration(milliseconds: 80));

    // There should be exactly one regular save for this id
    final saves = await GamePersistenceOrchestrator.instance.listSaves();
    final regular = saves.where((s) => s.id == pid && !s.isBackup).toList();
    expect(regular.length, 1);
  });

  test('backup cooldown: lifecycle triggers one backup, second within cooldown skipped', () async {
    final state = GameState();
    state.initializeNewGame('Backup Cooldown Test');
    final pid = state.partieId!;

    // Seed snapshot
    await const LocalGamePersistenceService().saveSnapshot(_snapshot(), slotId: pid);

    // First lifecycle -> should create a backup
    await GamePersistenceOrchestrator.instance.requestLifecycleSave(state, reason: 'first');
    await Future<void>.delayed(const Duration(milliseconds: 60));

    final backupsAfterFirst = await SaveManagerAdapter.listBackupsForPartie(pid);
    expect(backupsAfterFirst.length, 1);

    // Second lifecycle soon after -> still within internal cooldown -> no new backup
    await GamePersistenceOrchestrator.instance.requestLifecycleSave(state, reason: 'second');
    await Future<void>.delayed(const Duration(milliseconds: 60));

    final backupsAfterSecond = await SaveManagerAdapter.listBackupsForPartie(pid);
    expect(backupsAfterSecond.length, 1);
  });
}
