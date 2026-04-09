import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/cloud/models/cloud_status.dart';
import 'package:paperclip2/services/cloud/models/cloud_index_entry.dart';
import 'package:paperclip2/services/cloud/models/cloud_world_detail.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';

class _FakeCloudPort implements CloudPersistencePort {
  Map<String, Map<String, dynamic>> storage = {};
  Map<String, Map<String, dynamic>> lastMetadata = {};
  Map<String, CloudStatus> status = {};
  List<CloudIndexEntry> index = [];

  @override
  Future<void> pushById({required String enterpriseId, required Map<String, dynamic> snapshot, required Map<String, dynamic> metadata}) async {
    storage[enterpriseId] = {
      'snapshot': snapshot,
      'metadata': metadata,
    };
    lastMetadata[enterpriseId] = metadata;
    status[enterpriseId] = CloudStatus(exists: true, lastSavedAt: DateTime.now(), name: metadata['name']?.toString());
    final entry = CloudIndexEntry(enterpriseId: enterpriseId, name: metadata['name']?.toString(), gameVersion: metadata['gameVersion']?.toString());
    index.removeWhere((e) => e.enterpriseId == enterpriseId);
    index.add(entry);
  }

  @override
  Future<CloudWorldDetail?> pullById({required String enterpriseId}) async {
    final data = storage[enterpriseId];
    if (data == null) return null;
    return CloudWorldDetail(
      enterpriseId: enterpriseId,
      version: 1,
      snapshot: data['snapshot'] as Map<String, dynamic>,
      updatedAt: DateTime.now().toIso8601String(),
      name: (data['metadata'] as Map<String, dynamic>?)?['name']?.toString(),
      gameVersion: (data['metadata'] as Map<String, dynamic>?)?['gameVersion']?.toString(),
    );
  }

  @override
  Future<CloudStatus> statusById({required String enterpriseId}) async {
    return status[enterpriseId] ?? CloudStatus(exists: false);
  }

  @override
  Future<List<CloudIndexEntry>> listParties() async {
    return index;
  }

  @override
  Future<void> deleteById({required String enterpriseId}) async {
    storage.remove(enterpriseId);
    status[enterpriseId] = CloudStatus(exists: false);
    index.removeWhere((e) => e.enterpriseId == enterpriseId);
  }

  @override
  Future<List<int>> listVersions({required String enterpriseId}) async => <int>[];

  @override
  Future<Map<String, dynamic>?> getVersionSnapshot({required String enterpriseId, required int version}) async => null;

  @override
  Future<bool> restoreVersion({required String enterpriseId, required int version}) async => false;
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
      final enterpriseId = 'pid-1';
      port.storage[enterpriseId] = {
        'snapshot': {
          'metadata': {
            'enterpriseId': enterpriseId,
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

      final ok = await GamePersistenceOrchestrator.instance.materializeFromCloud(enterpriseId: enterpriseId);
      expect(ok, isTrue);

      final mgr = await LocalSaveGameManager.getInstance();
      final local = await mgr.loadSave(enterpriseId);
      expect(local, isNotNull);
      expect(local!.gameData.containsKey(LocalGamePersistenceService.snapshotKey), isTrue);
    });

    test('pushCloudFromSaveId sends snapshot + metadata', () async {
      final mgr = await LocalSaveGameManager.getInstance();
      final enterpriseId = 'pid-2';

      // Create a local save with a snapshot
      final save = SaveGame(
        id: enterpriseId,
        name: 'Local World',
        lastSaveTime: DateTime.now(),
        gameData: <String, dynamic>{
          LocalGamePersistenceService.snapshotKey: {
            'metadata': {
              'enterpriseId': enterpriseId,
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

      await GamePersistenceOrchestrator.instance.pushCloudFromSaveId(enterpriseId: enterpriseId, playerId: 'player-1');

      // Assert cloud side
      expect(port.storage.containsKey(enterpriseId), isTrue);
      final obj = port.storage[enterpriseId]!;
      expect(obj['snapshot'], isA<Map<String, dynamic>>());
      expect(obj['metadata'], isA<Map<String, dynamic>>());
      final meta = obj['metadata'] as Map<String, dynamic>;
      expect(meta['enterpriseId'], equals(enterpriseId));
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
