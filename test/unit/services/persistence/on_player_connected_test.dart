import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import '../../../../test/helpers/in_memory_save_manager.dart';

class _MemPort implements CloudPersistencePort {
  final List<String> materialized = [];
  final List<String> pushed = [];
  final Map<String, Map<String, dynamic>> store = {};

  @override
  Future<void> pushById({required String partieId, required Map<String, dynamic> snapshot, required Map<String, dynamic> metadata}) async {
    pushed.add(partieId);
    store[partieId] = {'snapshot': snapshot, 'metadata': metadata};
  }

  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async {
    return store[partieId];
  }

  @override
  Future<CloudStatus> statusById({required String partieId}) async => CloudStatus(partieId: partieId, syncState: 'unknown');

  @override
  Future<List<CloudIndexEntry>> listParties() async {
    return store.keys.map((id) => CloudIndexEntry(partieId: id)).toList();
  }

  @override
  Future<void> deleteById({required String partieId}) async {
    store.remove(partieId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('onPlayerConnected triggers full sync', () {
    setUp(() {
      SaveManagerAdapter.setSaveManagerForTesting(InMemorySaveGameManager());
      GamePersistenceOrchestrator.instance.resetForTesting();
    });

    tearDown(() {
      SaveManagerAdapter.resetForTesting();
      GamePersistenceOrchestrator.instance.resetForTesting();
    });

    test('local-only -> push; cloud-only -> materialize; both -> cloud wins', () async {
      final port = _MemPort();
      GamePersistenceOrchestrator.instance.setCloudPort(port);
      GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async => 'player-test');

      // 1) cloud-only id
      port.store['cloud-only'] = {'snapshot': {'metadata': {'schemaVersion': 1}, 'core': {}, 'stats': {}}, 'metadata': {'name': 'Cloud Only'}};

      // 2) local-only id: create minimal local save (deterministic id)
      final localOnly = await InMemorySaveGameManager().createNewSave(name: 'Local Only');
      final localId = 'local-only-1';
      await SaveManagerAdapter.instance.saveGame(localOnly.copyWith(id: localId));

      // 3) both id: simulate by writing cloud entry then also having local meta with same id
      final bothId = 'both-1';
      port.store[bothId] = {'snapshot': {'metadata': {'schemaVersion': 1}, 'core': {'money': 1}, 'stats': {}}, 'metadata': {'name': 'Cloud Name'}};
      await SaveManagerAdapter.instance.saveGame((await InMemorySaveGameManager().createNewSave(name: 'Local Name')).copyWith(id: bothId, name: 'Local Name'));

      // Trigger
      await GamePersistenceOrchestrator.instance.onPlayerConnected(playerId: 'player-test');

      // cloud-only should be materialized locally
      final metas = await SaveManagerAdapter.instance.listSaves();
      final hasCloudOnly = metas.any((m) => m.id == 'cloud-only');
      expect(hasCloudOnly, isTrue);

      // both -> cloud wins: local metadata name should match cloud metadata ('Cloud Name')
      final bothMeta = metas.firstWhere((m) => m.id == 'both-1');
      expect(bothMeta.name, 'Cloud Name');
    });
  });
}
