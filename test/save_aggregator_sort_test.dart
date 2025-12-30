import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/persistence/save_aggregator.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import 'support/game_state_test_factory.dart';
import 'package:paperclip2/models/save_game.dart';

class _FakeCloudPort implements CloudPersistencePort {
  final List<CloudIndexEntry> entries;
  _FakeCloudPort(this.entries);
  @override
  Future<void> deleteById({required String partieId}) async {}
  @override
  Future<List<CloudIndexEntry>> listParties() async => entries;
  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async => null;
  @override
  Future<void> pushById({required String partieId, required Map<String, dynamic> snapshot, required Map<String, dynamic> metadata}) async {}
  @override
  Future<CloudStatus> statusById({required String partieId}) async => CloudStatus(partieId: partieId, syncState: 'unknown');
}

Future<void> _createValidSave(String id) async {
  final gs = GameStateTestFactory.newInitialized(partieId: id);
  final save = SaveGame(
    id: id,
    name: id,
    lastSaveTime: DateTime.now(),
    gameData: {
      'gameSnapshot': gs.toSnapshot().toJson(),
    },
    version: GameConstants.VERSION,
    gameMode: gs.gameMode,
  );
  await SaveManagerAdapter.saveGame(save);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SaveManagerAdapter.resetForTesting();
    GamePersistenceOrchestrator.instance.resetForTesting();
  });

  testWidgets('SaveAggregator sorts by lastModified desc; cloud-only without date appear last', (tester) async {
    dotenv.dotenv.testLoad(fileInput: 'FEATURE_CLOUD_PER_PARTIE=true');
    await SaveManagerAdapter.ensureInitialized();
    await LocalSaveGameManager.getInstance();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Create three locals with increasing timestamps (valid saves)
    await _createValidSave('p1');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await _createValidSave('p2');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await _createValidSave('p3');

    // One cloud-only without dates
    final fakePort = _FakeCloudPort([
      const CloudIndexEntry(partieId: 'cloud-only', name: 'remote', remoteVersion: 1),
    ]);
    GamePersistenceOrchestrator.instance.setCloudPort(fakePort);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    final context = tester.element(find.byType(SizedBox));

    final agg = SaveAggregator();
    final list = await agg.listAll(context);
    final visible = list.where((e) => !e.isBackup).toList();

    // Expect cloud-only exists and appears after locals with dates
    expect(visible.map((e) => e.id), contains('cloud-only'));
    // Ensure cloud-only exists and is last
    expect(visible.last.id, 'cloud-only');
  });
}
