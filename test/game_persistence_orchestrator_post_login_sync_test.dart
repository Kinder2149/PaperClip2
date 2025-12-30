import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';

class _PortCapture implements CloudPersistencePort {
  final List<CloudIndexEntry> index;
  final Map<String, Map<String, dynamic>> pulls;
  final List<Map<String, dynamic>> pushes = [];
  _PortCapture({required this.index, required this.pulls});

  @override
  Future<void> deleteById({required String partieId}) async {}

  @override
  Future<List<CloudIndexEntry>> listParties() async => index;

  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async => pulls[partieId];

  @override
  Future<void> pushById({required String partieId, required Map<String, dynamic> snapshot, required Map<String, dynamic> metadata}) async {
    pushes.add({'id': partieId, 'snapshot': snapshot, 'metadata': metadata});
  }

  @override
  Future<CloudStatus> statusById({required String partieId}) async => CloudStatus(partieId: partieId, syncState: 'unknown');
}

GameSnapshot _snapWith({double money = 1}) => GameSnapshot(
      metadata: {
        'snapshotSchemaVersion': 1,
        'lastActiveAt': DateTime.now().toIso8601String(),
      },
      core: {'money': money},
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

  test('postLoginSync: local-only → push auto to cloud', () async {
    final id = 'pls-local-only';
    // Create local save
    await const LocalGamePersistenceService().saveSnapshot(_snapWith(money: 5), slotId: id);

    final port = _PortCapture(index: [], pulls: {});
    GamePersistenceOrchestrator.instance.setCloudPort(port);
    GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async => 'player-x');

    await GamePersistenceOrchestrator.instance.postLoginSync(playerId: 'player-x');

    expect(port.pushes.any((p) => p['id'] == id), isTrue);
  });

  test('postLoginSync: cloud-only → materialize locally', () async {
    final id = 'pls-cloud-only';
    final savedAt = DateTime.now().toUtc().toIso8601String();

    final port = _PortCapture(
      index: [CloudIndexEntry(partieId: id, name: 'remote-name', gameVersion: 'rv1', remoteVersion: 1)],
      pulls: {
        id: {
          'snapshot': _snapWith(money: 7).toJson(),
          'metadata': {
            'name': 'remote-name',
            'gameVersion': 'rv1',
            'gameMode': 'INFINITE',
            'savedAt': savedAt,
          }
        }
      },
    );
    GamePersistenceOrchestrator.instance.setCloudPort(port);

    await GamePersistenceOrchestrator.instance.postLoginSync(playerId: 'player-x');

    final meta = await SaveManagerAdapter.getSaveMetadataById(id);
    expect(meta, isNotNull);
    expect(meta!.name, 'remote-name');
    final saved = await SaveManagerAdapter.loadGameById(id);
    expect(saved, isNotNull);
    expect((saved!.gameData[LocalGamePersistenceService.snapshotKey] as Map)['core']['money'], 7);
  });

  test('postLoginSync: local ∧ cloud → import cloud when cloud is fresher', () async {
    final id = 'pls-both-import-cloud';
    // Local older timestamp
    await const LocalGamePersistenceService().saveSnapshot(_snapWith(money: 1), slotId: id);
    // Simulate older local by waiting a bit before setting newer cloud savedAt
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final savedAtCloud = DateTime.now().toUtc().toIso8601String();

    final port = _PortCapture(
      index: [CloudIndexEntry(partieId: id, name: 'cloud-name', gameVersion: 'rv2', remoteVersion: 2)],
      pulls: {
        id: {
          'snapshot': _snapWith(money: 99).toJson(),
          'metadata': {
            'name': 'cloud-name',
            'gameVersion': 'rv2',
            'gameMode': 'INFINITE',
            'savedAt': savedAtCloud,
          }
        }
      },
    );
    GamePersistenceOrchestrator.instance.setCloudPort(port);

    await GamePersistenceOrchestrator.instance.postLoginSync(playerId: 'player-x');

    final saved = await SaveManagerAdapter.loadGameById(id);
    expect(saved, isNotNull);
    final snap = saved!.gameData[LocalGamePersistenceService.snapshotKey] as Map;
    expect(snap['core']['money'], 99);
  });
}
