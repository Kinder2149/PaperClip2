import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import '../../../../test/helpers/in_memory_save_manager.dart';

class _NoopPort implements CloudPersistencePort {
  @override
  Future<void> pushById({required String partieId, required Map<String, dynamic> snapshot, required Map<String, dynamic> metadata}) async {}
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

  group('playerId requis pour push cloud', () {
    setUp(() {
      SaveManagerAdapter.setSaveManagerForTesting(InMemorySaveGameManager());
      GamePersistenceOrchestrator.instance.resetForTesting();
      GamePersistenceOrchestrator.instance.setCloudPort(_NoopPort());
    });

    tearDown(() {
      SaveManagerAdapter.resetForTesting();
      GamePersistenceOrchestrator.instance.resetForTesting();
    });

    test('pushCloudFromSaveId sans playerId -> StateError et sauvegarde locale intacte', () async {
      final gs = GameState();
      gs.initialize();
      await gs.startNewGame('p1');
      await GamePersistenceOrchestrator.instance.saveGameById(gs);

      expect(
        () => GamePersistenceOrchestrator.instance.pushCloudFromSaveId(partieId: 'pid-1'),
        throwsA(isA<StateError>()),
      );

      final local = await SaveManagerAdapter.getLastSave();
      expect(local, isNotNull);
      gs.dispose();
    });

    test('pushCloudById sans playerId -> StateError et sauvegarde locale intacte', () async {
      final gs = GameState();
      gs.initialize();
      await gs.startNewGame('p2');
      await GamePersistenceOrchestrator.instance.saveGameById(gs);

      expect(
        () => GamePersistenceOrchestrator.instance.pushCloudById(partieId: 'pid-2', state: gs),
        throwsA(isA<StateError>()),
      );

      final local = await SaveManagerAdapter.getLastSave();
      expect(local, isNotNull);
      gs.dispose();
    });
  });
}
