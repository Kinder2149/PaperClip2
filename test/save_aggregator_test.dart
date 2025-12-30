import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/save_game.dart';
import 'support/game_state_test_factory.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/persistence/save_aggregator.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';

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

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SaveManagerAdapter.resetForTesting();
    GamePersistenceOrchestrator.instance.resetForTesting();
  });

  testWidgets('SaveAggregator lists local saves and filters backups (cloud disabled)', (tester) async {
    // Désactiver le feature flag cloud par partie pour isoler le local
    dotenv.dotenv.testLoad(fileInput: 'FEATURE_CLOUD_PER_PARTIE=false');

    // Initialiser explicitement l'adapter (évite la course _prefs non initialisé)
    await SaveManagerAdapter.ensureInitialized();
    // S'assurer que le gestionnaire local est prêt avant d'écrire
    await LocalSaveGameManager.getInstance();
    // Laisser le temps au cache de métadonnées d'être prêt
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Créer une sauvegarde locale VALIDE via SaveManagerAdapter.saveGame
    final gs0 = GameStateTestFactory.newInitialized(partieId: 'p-local-1');
    final save0 = SaveGame(
      id: 'p-local-1',
      name: 'p-local-1',
      lastSaveTime: DateTime.now(),
      gameData: {
        'gameSnapshot': gs0.toSnapshot().toJson(),
      },
      version: GameConstants.VERSION,
      gameMode: gs0.gameMode,
    );
    await SaveManagerAdapter.saveGame(save0);
    // Créer un backup pour le même ID afin de tester le filtrage
    // Utiliser un GameState de test pour créer un backup nommé correctement "<id>|<ts>"
    final gs = GameStateTestFactory.newInitialized(partieId: 'p-local-1');
    await SaveManagerAdapter.createBackup(gs);
    await Future<void>.delayed(const Duration(milliseconds: 150));

    // Construire un arbre minimal pour obtenir un BuildContext valable
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    final context = tester.element(find.byType(SizedBox));

    final agg = SaveAggregator();
    final list = await agg.listAll(context);

    // La backup locale ne doit pas être listée
    expect(list.where((e) => e.isBackup).isEmpty, isTrue);
    // L'entrée locale est présente
    final local = list.firstWhere((e) => e.id == 'p-local-1');
    expect(local.source, SaveSource.local);
  });
}
