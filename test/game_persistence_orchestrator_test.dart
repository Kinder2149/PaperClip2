import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GamePersistenceOrchestrator.instance.resetForTesting();
    // Reset adapter to re-init internal manager on demand
    SaveManagerAdapter.resetForTesting();
  });

  GameSnapshot _makeValidSnapshot() {
    return GameSnapshot(
      metadata: {
        'snapshotSchemaVersion': 1,
        'lastActiveAt': DateTime.now().toIso8601String(),
      },
      core: {
        'paperclips': 10,
        'money': 5.0,
      },
      market: const {},
      production: const {},
      stats: const {},
    );
  }

  test('validateForListing returns valid for save containing a readable snapshot', () async {
    final pid = 'partie-validate-valid';

    final snapshot = _makeValidSnapshot();
    await const LocalGamePersistenceService().saveSnapshot(snapshot, slotId: pid);

    final status = await GamePersistenceOrchestrator.instance.validateForListing(pid);
    expect(status, GamePersistenceOrchestrator.integrityValid);
  });

  test('validateForListing returns migratable when snapshot key is missing', () async {
    final pid = 'partie-validate-migratable';

    final sg = SaveGame(
      id: pid,
      name: pid,
      lastSaveTime: DateTime.now(),
      // No snapshot key inside gameData
      gameData: <String, dynamic>{'legacyPayload': {'some': 'data'}},
      version: '1.0.0',
      gameMode: GameMode.INFINITE,
    );
    await SaveManagerAdapter.saveGame(sg);

    final status = await GamePersistenceOrchestrator.instance.validateForListing(pid);
    expect(status, GamePersistenceOrchestrator.integrityMigratable);
  });

  test('validateForListing returns corrupt for unreadable snapshot value', () async {
    final pid = 'partie-validate-corrupt';

    final bad = SaveGame(
      id: pid,
      name: pid,
      lastSaveTime: DateTime.now(),
      // snapshot present but invalid (unexpected type)
      gameData: <String, dynamic>{LocalGamePersistenceService.snapshotKey: 12345},
      version: '1.0.0',
      gameMode: GameMode.INFINITE,
    );
    await SaveManagerAdapter.saveGame(bad);

    final status = await GamePersistenceOrchestrator.instance.validateForListing(pid);
    expect(status, GamePersistenceOrchestrator.integrityCorrupt);
  });

  test('checkAndRestoreLastSaveFromBackupIfNeeded restores from latest backup when last save is invalid', () async {
    // Create a good backup and a corrupt latest regular save; validate that restoration occurs
    final baseId = 'partie-restore';

    // First, create a valid backup entry
    final backupName = baseId + '|' + DateTime.now().millisecondsSinceEpoch.toString();
    final backup = SaveGame(
      name: backupName,
      lastSaveTime: DateTime.now(),
      gameData: <String, dynamic>{
        LocalGamePersistenceService.snapshotKey: _makeValidSnapshot().toJson(),
      },
      version: '1.0.0',
      gameMode: GameMode.INFINITE,
    );
    await SaveManagerAdapter.saveGame(backup);

    // Then, create a regular save which is considered the "last" but with corrupt snapshot
    final last = SaveGame(
      id: baseId,
      name: baseId,
      lastSaveTime: DateTime.now(),
      gameData: <String, dynamic>{LocalGamePersistenceService.snapshotKey: '%%%not-json%%%'},
      version: '1.0.0',
      gameMode: GameMode.INFINITE,
    );
    await SaveManagerAdapter.saveGame(last);

    // Ensure adapter returns our last save as most recent
    // Now run the restoration check
    await GamePersistenceOrchestrator.instance.checkAndRestoreLastSaveFromBackupIfNeeded();

    // After restoration, the regular save should contain a valid snapshot
    final reloaded = await SaveManagerAdapter.loadGameById(baseId);
    expect(reloaded, isNotNull);
    final gd = reloaded!.gameData;
    expect(gd.containsKey(LocalGamePersistenceService.snapshotKey), isTrue);
    // Snapshot must be parseable back to Map
    final raw = gd[LocalGamePersistenceService.snapshotKey];
    expect(raw, isA<Map>());
  });
}
