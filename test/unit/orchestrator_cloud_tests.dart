import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';

class _FakeCloudPort implements CloudPersistencePort {
  Map<String, Map<String, dynamic>> storage = {};
  Map<String, Map<String, dynamic>> lastMetadata = {};
  Map<String, CloudStatus> status = {};
  List<CloudIndexEntry> index = [];

  @override
  Future<void> pushById({required String partieId, required Map<String, dynamic> snapshot, required Map<String, dynamic> metadata}) async {
    storage[partieId] = {
      'snapshot': snapshot,
      'metadata': metadata,
    };
    lastMetadata[partieId] = metadata;
    status[partieId] = CloudStatus(exists: true, lastSavedAt: DateTime.now(), name: metadata['name']?.toString());
    final entry = CloudIndexEntry(partieId: partieId, name: metadata['name']?.toString(), gameVersion: metadata['gameVersion']?.toString());
    index.removeWhere((e) => e.partieId == partieId);
    index.add(entry);
  }

  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async {
    return storage[partieId];
  }

  @override
  Future<CloudStatus> statusById({required String partieId}) async {
    return status[partieId] ?? CloudStatus(exists: false);
  }

  @override
  Future<List<CloudIndexEntry>> listParties() async {
    return index;
  }

  @override
  Future<void> deleteById({required String partieId}) async {
    storage.remove(partieId);
    status[partieId] = CloudStatus(exists: false);
    index.removeWhere((e) => e.partieId == partieId);
  }

  @override
  Future<List<int>> listVersions({required String partieId}) async => <int>[];

  @override
  Future<Map<String, dynamic>?> getVersionSnapshot({required String partieId, required int version}) async => null;

  @override
  Future<bool> restoreVersion({required String partieId, required int version}) async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GamePersistenceOrchestrator — cloud interactions (mocked)', () {
    late _FakeCloudPort port;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object?>{});
      port = _FakeCloudPort();
      GamePersistenceOrchestrator.instance.resetForTesting();
      GamePersistenceOrchestrator.instance.setCloudPort(port);
    });

    test('materializeFromCloud writes a local save with snapshot', () async {
      // Arrange: prepare cloud object
      final partieId = 'pid-1';
      port.storage[partieId] = {
        'snapshot': {
          'metadata': {
            'worldId': partieId,
            'createdAt': DateTime.now().toIso8601String(),
            'version': 2,
          },
          'core': <String, dynamic>{'paperclips': 5},
          'market': const <String, dynamic>{},
          'production': const <String, dynamic>{},
          'stats': const <String, dynamic>{},
        },
        'metadata': {
          'name': 'Cloud World',
          'gameVersion': GameConstants.VERSION,
        },
      };

      final ok = await GamePersistenceOrchestrator.instance.materializeFromCloud(partieId: partieId);
      expect(ok, isTrue);

      final mgr = await LocalSaveGameManager.getInstance();
      final local = await mgr.loadSave(partieId);
      expect(local, isNotNull);
      expect(local!.gameData.containsKey(LocalGamePersistenceService.snapshotKey), isTrue);
    });

    test('pushCloudFromSaveId sends snapshot + metadata', () async {
      final mgr = await LocalSaveGameManager.getInstance();
      final partieId = 'pid-2';

      // Create a local save with a snapshot
      final save = SaveGame(
        id: partieId,
        name: 'Local World',
        lastSaveTime: DateTime.now(),
        gameData: <String, dynamic>{
          LocalGamePersistenceService.snapshotKey: {
            'metadata': {
              'worldId': partieId,
              'createdAt': DateTime.now().toIso8601String(),
              'version': 2,
            },
            'core': <String, dynamic>{'paperclips': 7},
            'market': const <String, dynamic>{},
            'production': const <String, dynamic>{},
            'stats': const <String, dynamic>{},
          },
        },
        version: GameConstants.VERSION,
        gameMode: GameMode.INFINITE,
      );
      final okSave = await mgr.saveGame(save);
      expect(okSave, isTrue);

      await GamePersistenceOrchestrator.instance.pushCloudFromSaveId(partieId: partieId, playerId: 'player-1');

      // Assert cloud side
      expect(port.storage.containsKey(partieId), isTrue);
      final obj = port.storage[partieId]!;
      expect(obj['snapshot'], isA<Map<String, dynamic>>());
      expect(obj['metadata'], isA<Map<String, dynamic>>());
      final meta = obj['metadata'] as Map<String, dynamic>;
      expect(meta['partieId'], equals(partieId));
      expect(meta['playerId'], equals('player-1'));
    });

    test('validateForListing returns migratable when snapshot missing', () async {
      final mgr = await LocalSaveGameManager.getInstance();
      final id = 'pid-3';
      // Save without snapshot key
      final save = SaveGame(
        id: id,
        name: 'NoSnap',
        lastSaveTime: DateTime.now(),
        gameData: <String, dynamic>{},
        version: GameConstants.VERSION,
        gameMode: GameMode.INFINITE,
      );
      expect(await mgr.saveGame(save), isTrue);

      final status = await GamePersistenceOrchestrator.instance.validateForListing(id);
      expect(status, equals(GamePersistenceOrchestrator.integrityMigratable));
    });
  });
}
