// test/integration_test/enterprise_flow_test.dart
// CHANTIER-01: Tests intégration flux complet entreprise

import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/persistence/game_persistence_mapper.dart';

void main() {
  group('CHANTIER-01: Enterprise Flow Integration', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
    });

    test('Flux complet: Création → Sauvegarde → Chargement', () async {
      // 1. Créer entreprise
      await gameState.createNewEnterprise('Integration Test Corp');
      final originalId = gameState.enterpriseId;
      final originalName = gameState.enterpriseName;

      expect(originalId, isNotNull);
      expect(originalName, equals('Integration Test Corp'));

      // 2. Ajouter des ressources
      gameState.addQuantum(100);
      gameState.addPointsInnovation(1000);

      // 3. Sauvegarder
      await GamePersistenceOrchestrator.instance.saveEnterprise(gameState);

      // 4. Charger dans nouveau GameState
      final loadedSnapshot = await GamePersistenceOrchestrator.instance.loadEnterprise();
      expect(loadedSnapshot, isNotNull);

      final newState = GameState();
      GamePersistenceMapper.fromSnapshotV3(newState, loadedSnapshot!);

      // 5. Vérifier données restaurées
      expect(newState.enterpriseId, equals(originalId));
      expect(newState.enterpriseName, equals(originalName));
      expect(newState.quantum, equals(100));
      expect(newState.pointsInnovation, equals(1000));
    });

    test('Flux: Création → Modification → Sauvegarde → Chargement', () async {
      // Créer
      await gameState.createNewEnterprise('Original Name');
      final enterpriseId = gameState.enterpriseId;

      // Modifier
      gameState.setEnterpriseName('Modified Name');
      gameState.addQuantum(50);

      // Sauvegarder
      await GamePersistenceOrchestrator.instance.saveEnterprise(gameState);

      // Charger
      final snapshot = await GamePersistenceOrchestrator.instance.loadEnterprise();
      final loadedState = GameState();
      GamePersistenceMapper.fromSnapshotV3(loadedState, snapshot!);

      // Vérifier modifications persistées
      expect(loadedState.enterpriseId, equals(enterpriseId));
      expect(loadedState.enterpriseName, equals('Modified Name'));
      expect(loadedState.quantum, equals(50));
    });

    test('Flux: Création → Suppression → Vérification', () async {
      // Créer et sauvegarder
      await gameState.createNewEnterprise('To Delete Corp');
      await GamePersistenceOrchestrator.instance.saveEnterprise(gameState);

      // Vérifier existence
      var snapshot = await GamePersistenceOrchestrator.instance.loadEnterprise();
      expect(snapshot, isNotNull);

      // Supprimer
      await GamePersistenceOrchestrator.instance.deleteEnterprise();

      // Vérifier suppression
      snapshot = await GamePersistenceOrchestrator.instance.loadEnterprise();
      expect(snapshot, isNull);
    });

    test('Flux: Multiples sauvegardes écrasent correctement', () async {
      await gameState.createNewEnterprise('Test Corp');
      final enterpriseId = gameState.enterpriseId;

      // Première sauvegarde
      gameState.addQuantum(10);
      await GamePersistenceOrchestrator.instance.saveEnterprise(gameState);

      // Deuxième sauvegarde avec nouvelles valeurs
      gameState.addQuantum(20); // Total: 30
      await GamePersistenceOrchestrator.instance.saveEnterprise(gameState);

      // Charger et vérifier dernière valeur
      final snapshot = await GamePersistenceOrchestrator.instance.loadEnterprise();
      final loadedState = GameState();
      GamePersistenceMapper.fromSnapshotV3(loadedState, snapshot!);

      expect(loadedState.enterpriseId, equals(enterpriseId));
      expect(loadedState.quantum, equals(30));
    });

    test('Validation: Snapshot v3 structure complète', () async {
      await gameState.createNewEnterprise('Structure Test');
      gameState.addQuantum(5);
      gameState.addPointsInnovation(50);

      await GamePersistenceOrchestrator.instance.saveEnterprise(gameState);
      final snapshot = await GamePersistenceOrchestrator.instance.loadEnterprise();

      expect(snapshot, isNotNull);
      expect(snapshot!.metadata['version'], equals(3));
      expect(snapshot.metadata['enterpriseId'], isNotNull);
      expect(snapshot.metadata['enterpriseName'], isNotNull);
      expect(snapshot.metadata['quantum'], equals(5));
      expect(snapshot.metadata['pointsInnovation'], equals(50));
      expect(snapshot.core['agents'], isNotNull);
      expect(snapshot.core['research'], isNotNull);
    });

    test('Persistance: Clé unique ENTERPRISE_KEY', () async {
      // Cette clé doit être utilisée pour toutes les opérations
      await gameState.createNewEnterprise('Key Test');
      await GamePersistenceOrchestrator.instance.saveEnterprise(gameState);

      // Le chargement doit utiliser la même clé
      final snapshot = await GamePersistenceOrchestrator.instance.loadEnterprise();
      expect(snapshot, isNotNull);
      expect(snapshot!.metadata['enterpriseName'], equals('Key Test'));
    });
  });
}
