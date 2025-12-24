import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import '../../../helpers/in_memory_save_manager.dart';

class _FakeCloudPort implements CloudPersistencePort {
  final Map<String, Map<String, dynamic>> _store = {};
  final Map<String, CloudStatus> _status = {};

  @override
  Future<void> pushById({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    _store[partieId] = {
      'snapshot': snapshot,
      'metadata': metadata,
    };
    _status[partieId] = CloudStatus(
      partieId: partieId,
      syncState: 'in_sync',
      remoteVersion: (metadata['version'] as int?) ?? 0,
      lastPushAt: DateTime.now(),
      lastPullAt: null,
    );
  }

  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async {
    final d = _store[partieId];
    return d;
  }

  @override
  Future<CloudStatus> statusById({required String partieId}) async {
    return _status[partieId] ?? CloudStatus(partieId: partieId, syncState: 'unknown');
  }

  @override
  Future<List<CloudIndexEntry>> listParties() async {
    // Non utilisé dans ces tests
    return <CloudIndexEntry>[];
  }

  @override
  Future<void> deleteById({required String partieId}) async {
    _store.remove(partieId);
    _status.remove(partieId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cloud sync by partieId', () {
    late InMemorySaveGameManager mem;

    setUp(() {
      mem = InMemorySaveGameManager();
      SaveManagerAdapter.setSaveManagerForTesting(mem);
      GamePersistenceOrchestrator.instance.resetForTesting();
      // Fournir un playerId pour permettre les pushes cloud
      GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async => 'player-test');
    });

    tearDown(() {
      SaveManagerAdapter.resetForTesting();
      GamePersistenceOrchestrator.instance.resetForTesting();
    });

    test('pushCloudFromSaveId envoie le snapshot au port cloud', () async {
      final state = GameState();
      state.initialize();
      await state.startNewGame('cloud-push');
      // Enrichir un peu l'état
      state.playerManager.updateMoney(50);

      // Sauvegarde locale ID-first
      await GamePersistenceOrchestrator.instance.saveGameById(state);

      final fake = _FakeCloudPort();
      GamePersistenceOrchestrator.instance.setCloudPort(fake);

      final id = state.partieId!;
      await GamePersistenceOrchestrator.instance.pushCloudFromSaveId(partieId: id, playerId: 'player-test');

      final pulled = await fake.pullById(partieId: id);
      expect(pulled, isNotNull);
      final snap = pulled!['snapshot'] as Map<String, dynamic>;
      // Doit contenir la clé snapshot
      expect(snap, isNotEmpty);

      state.dispose();
    });

    test('pullCloudById récupère le snapshot précédemment poussé', () async {
      final state = GameState();
      state.initialize();
      await state.startNewGame('cloud-pull');
      await GamePersistenceOrchestrator.instance.saveGameById(state);

      final fake = _FakeCloudPort();
      GamePersistenceOrchestrator.instance.setCloudPort(fake);

      final id = state.partieId!;
      // Simuler push
      final snapKey = LocalGamePersistenceService.snapshotKey;
      final local = await SaveManagerAdapter.loadGameById(id);
      final snapshot = Map<String, dynamic>.from(local!.gameData[snapKey] as Map);
      await fake.pushById(partieId: id, snapshot: snapshot, metadata: {'version': 1});

      final cloudData = await GamePersistenceOrchestrator.instance.pullCloudById(partieId: id);
      expect(cloudData, isNotNull);
      expect(cloudData!['snapshot'], isNotNull);

      state.dispose();
    });
  });
}
