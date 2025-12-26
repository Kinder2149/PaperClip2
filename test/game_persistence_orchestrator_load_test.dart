import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/constants/game_config.dart';

GameSnapshot _validSnap() => GameSnapshot(
      metadata: {
        'snapshotSchemaVersion': 1,
        'lastActiveAt': DateTime.now().toIso8601String(),
      },
      core: {'paperclips': 1, 'money': 0.0},
      market: const {},
      production: const {},
      stats: const {},
    );

Map<String, dynamic> _corruptSnapshotJson() => {
      // Force a newer schema version to trigger FormatException in migrateSnapshot()
      'metadata': {
        'snapshotSchemaVersion': 999,
        'lastActiveAt': DateTime.now().toIso8601String(),
      },
      'core': {'paperclips': 0},
      'market': {},
      'production': {},
      'stats': {},
    };

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GamePersistenceOrchestrator.instance.resetForTesting();
    SaveManagerAdapter.resetForTesting();
  });

  test('validateForListing returns integrityMissing when id does not exist', () async {
    final status = await GamePersistenceOrchestrator.instance.validateForListing('does-not-exist');
    expect(status, GamePersistenceOrchestrator.integrityMissing);
  });

  test('loadGameById with allowRestore=false rethrows on corrupt snapshot', () async {
    final state = GameState();
    final pid = 'allow-restore-false';

    // Save a corrupt snapshot under this id
    final bad = SaveGame(
      id: pid,
      name: pid,
      lastSaveTime: DateTime.now(),
      gameData: <String, dynamic>{LocalGamePersistenceService.snapshotKey: _corruptSnapshotJson()},
      version: '1.0.0',
      gameMode: GameMode.INFINITE,
    );
    await SaveManagerAdapter.saveGame(bad);

    // Expect an error (FormatException path) and not restored because allowRestore=false
    expect(
      () => GamePersistenceOrchestrator.instance.loadGameById(state, pid, allowRestore: false),
      throwsA(isA<Exception>()),
    );
  });

  test('loadGameById with allowRestore=true restores from latest backup on corrupt snapshot', () async {
    final state = GameState();
    final pid = 'allow-restore-true';

    // Create a valid backup entry for this partieId
    final backupName = '$pid${GameConstants.BACKUP_DELIMITER}${DateTime.now().millisecondsSinceEpoch}';
    final backup = SaveGame(
      name: backupName,
      lastSaveTime: DateTime.now(),
      gameData: <String, dynamic>{LocalGamePersistenceService.snapshotKey: _validSnap().toJson()},
      version: '1.0.0',
      gameMode: GameMode.INFINITE,
    );
    await SaveManagerAdapter.saveGame(backup);

    // Create a corrupt regular save for this id (ensures target metadata exists)
    final bad = SaveGame(
      id: pid,
      name: pid,
      lastSaveTime: DateTime.now(),
      gameData: <String, dynamic>{LocalGamePersistenceService.snapshotKey: _corruptSnapshotJson()},
      version: '1.0.0',
      gameMode: GameMode.INFINITE,
    );
    await SaveManagerAdapter.saveGame(bad);

    // Should not throw thanks to fallback restoration from backup
    await GamePersistenceOrchestrator.instance.loadGameById(state, pid, allowRestore: true);

    // After load, regular save should contain a valid snapshot (restored)
    final reloaded = await SaveManagerAdapter.loadGameById(pid);
    expect(reloaded, isNotNull);
    final raw = reloaded!.gameData[LocalGamePersistenceService.snapshotKey];
    expect(raw, isA<Map>());
  });
}
