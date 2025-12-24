import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';

class _OkPort implements CloudPersistencePort {
  int pushes = 0;
  @override
  Future<void> pushById({required String partieId, required Map<String, dynamic> snapshot, required Map<String, dynamic> metadata}) async {
    pushes++;
  }
  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async => null;
  @override
  Future<CloudStatus> statusById({required String partieId}) async => CloudStatus(partieId: partieId, syncState: 'unknown');
  @override
  Future<List<CloudIndexEntry>> listParties() async => <CloudIndexEntry>[];
  @override
  Future<void> deleteById({required String partieId}) async {}
}

class _FailingPort implements CloudPersistencePort {
  @override
  Future<void> pushById({required String partieId, required Map<String, dynamic> snapshot, required Map<String, dynamic> metadata}) async {
    throw Exception('network');
  }
  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async => null;
  @override
  Future<CloudStatus> statusById({required String partieId}) async => CloudStatus(partieId: partieId, syncState: 'unknown');
  @override
  Future<List<CloudIndexEntry>> listParties() async => <CloudIndexEntry>[];
  @override
  Future<void> deleteById({required String partieId}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('syncState transitions and non-blocking gameplay', () {
    setUp(() {
      GamePersistenceOrchestrator.instance.resetForTesting();
    });

    test('idle → syncing → success (ready)', () async {
      final gs = GameState();
      gs.initialize();
      await gs.startNewGame('sync-ok');
      GamePersistenceOrchestrator.instance.setCloudPort(_OkPort());
      GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async => 'player-test');

      final states = <String>[];
      void listener() {
        states.add(GamePersistenceOrchestrator.instance.syncState.value);
      }
      GamePersistenceOrchestrator.instance.syncState.addListener(listener);

      await GamePersistenceOrchestrator.instance.requestAutoSave(gs, reason: 'test');
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Dernier état attendu: ready (succès)
      expect(GamePersistenceOrchestrator.instance.syncState.value, 'ready');
      // A minima, syncing a été rencontré
      expect(states.contains('syncing'), isTrue);
      GamePersistenceOrchestrator.instance.syncState.removeListener(listener);
      gs.dispose();
    });

    test('idle → syncing → error path still returns to ready and gameplay unaffected', () async {
      final gs = GameState();
      gs.initialize();
      await gs.startNewGame('sync-fail');
      GamePersistenceOrchestrator.instance.setCloudPort(_FailingPort());
      GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async => 'player-test');

      await GamePersistenceOrchestrator.instance.requestAutoSave(gs, reason: 'test');
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // L’orchestrateur ne conserve pas l’état 'error' -> revient à 'ready'
      expect(GamePersistenceOrchestrator.instance.syncState.value, 'ready');

      // Gameplay non bloqué: on peut toujours interagir avec le GameState
      final before = gs.playerManager.money;
      gs.playerManager.updateMoney(1);
      expect(gs.playerManager.money, before + 1);
      gs.dispose();
    });
  });
}
