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

class _MockCloudPort implements CloudPersistencePort {
  final Map<String, Map<String, dynamic>> storage = {};
  final Map<String, CloudStatus> statuses = {};
  final List<CloudIndexEntry> parties = [];

  @override
  Future<void> pushById({required String enterpriseId, required Map<String, dynamic> snapshot, required Map<String, dynamic> metadata}) async {
    storage[enterpriseId] = {'snapshot': snapshot, 'metadata': metadata};
    statuses[enterpriseId] = CloudStatus(exists: true, lastSavedAt: DateTime.now(), name: metadata['name']?.toString());
    parties.removeWhere((e) => e.enterpriseId == enterpriseId);
    parties.add(CloudIndexEntry(enterpriseId: enterpriseId, name: metadata['name']?.toString(), gameVersion: metadata['gameVersion']?.toString()));
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
  Future<CloudStatus> statusById({required String enterpriseId}) async => statuses[enterpriseId] ?? CloudStatus(exists: false);

  @override
  Future<List<CloudIndexEntry>> listParties() async => parties;

  @override
  Future<void> deleteById({required String enterpriseId}) async {
    storage.remove(enterpriseId);
    statuses[enterpriseId] = CloudStatus(exists: false);
    parties.removeWhere((e) => e.enterpriseId == enterpriseId);
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

  group('Orchestrator sync arbitrage and retry (no GameState)', () {
    late _MockCloudPort port;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      port = _MockCloudPort();
      GamePersistenceOrchestrator.instance.resetForTesting();
      GamePersistenceOrchestrator.instance.setCloudPort(port);
      GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async => 'player-42');
    });

    test('postLoginSync pushes when local more recent than cloud', () async {
      final mgr = await LocalSaveGameManager.getInstance();
      final id = 'p-sync-1';
      // Local save with recent timestamp
      final now = DateTime.now();
      await mgr.saveGame(SaveGame(
        id: id,
        name: 'Local-Newer',
        lastSaveTime: now,
        gameData: {
          LocalGamePersistenceService.snapshotKey: {
            'metadata': {'enterpriseId': id, 'createdAt': now.toIso8601String(), 'version': 2},
            'core': <String, dynamic>{'paperclips': 1},
            'market': const <String, dynamic>{},
            'production': const <String, dynamic>{},
            'stats': const <String, dynamic>{},
          },
        },
        version: GameConstants.VERSION,
        gameMode: GameMode.INFINITE,
      ));
      // Cloud has older status and entry listed
      port.statuses[id] = CloudStatus(exists: true, lastSavedAt: now.subtract(const Duration(days: 1)), name: 'Cloud-Old');
      port.parties.add(CloudIndexEntry(enterpriseId: id, name: 'Cloud-Old', gameVersion: GameConstants.VERSION));

      await GamePersistenceOrchestrator.instance.postLoginSync(playerId: 'player-42');

      expect(port.storage.containsKey(id), isTrue, reason: 'Local newer should push to cloud');
    });

    test('postLoginSync imports when cloud more recent than local', () async {
      final mgr = await LocalSaveGameManager.getInstance();
      final id = 'p-sync-2';
      final old = DateTime.now().subtract(const Duration(days: 2));
      await mgr.saveGame(SaveGame(
        id: id,
        name: 'Local-Old',
        lastSaveTime: old,
        gameData: {
          LocalGamePersistenceService.snapshotKey: {
            'metadata': {'enterpriseId': id, 'createdAt': old.toIso8601String(), 'version': 2},
            'core': <String, dynamic>{'paperclips': 1},
            'market': const <String, dynamic>{},
            'production': const <String, dynamic>{},
            'stats': const <String, dynamic>{},
          },
        },
        version: GameConstants.VERSION,
        gameMode: GameMode.INFINITE,
      ));

      // Cloud entry newer
      final cloudSnap = {
        'snapshot': {
          'metadata': {
            'enterpriseId': id,
            'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'version': 2,
          },
          'core': <String, dynamic>{'paperclips': 99},
          'market': const <String, dynamic>{},
          'production': const <String, dynamic>{},
          'stats': const <String, dynamic>{},
        },
        'metadata': {
          'name': 'Cloud-Newer',
          'gameVersion': GameConstants.VERSION,
        },
      };
      port.storage[id] = cloudSnap;
      port.statuses[id] = CloudStatus(exists: true, lastSavedAt: DateTime.now(), name: 'Cloud-Newer');
      port.parties.add(CloudIndexEntry(enterpriseId: id, name: 'Cloud-Newer', gameVersion: GameConstants.VERSION));

      await GamePersistenceOrchestrator.instance.postLoginSync(playerId: 'player-42');

      final updated = await mgr.loadSave(id);
      expect(updated, isNotNull);
      final data = updated!.gameData[LocalGamePersistenceService.snapshotKey] as Map<String, dynamic>;
      final core = Map<String, dynamic>.from(data['core'] as Map);
      expect(core['paperclips'], 99, reason: 'Cloud newer should import to local');
    });

    test('retryPendingCloudPushes sends pending entries', () async {
      final mgr = await LocalSaveGameManager.getInstance();
      final id = 'p-retry-1';
      final now = DateTime.now();
      await mgr.saveGame(SaveGame(
        id: id,
        name: 'ToPush',
        lastSaveTime: now,
        gameData: {
          LocalGamePersistenceService.snapshotKey: {
            'metadata': {'enterpriseId': id, 'createdAt': now.toIso8601String(), 'version': 2},
            'core': <String, dynamic>{'paperclips': 12},
            'market': const <String, dynamic>{},
            'production': const <String, dynamic>{},
            'stats': const <String, dynamic>{},
          },
        },
        version: GameConstants.VERSION,
        gameMode: GameMode.INFINITE,
      ));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pending_cloud_push_'+id, true);

      await GamePersistenceOrchestrator.instance.retryPendingCloudPushes();

      expect(port.storage.containsKey(id), isTrue, reason: 'Pending push should have been sent');
      expect(prefs.getBool('pending_cloud_push_'+id) ?? false, isFalse, reason: 'Flag should be cleared');
    });
  });
}
