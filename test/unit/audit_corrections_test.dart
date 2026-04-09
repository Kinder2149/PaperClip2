// test/unit/audit_corrections_test.dart
// Tests de validation des corrections appliquées suite à l'audit post-CHANTIER-01 à 06

import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/managers/rare_resources_manager.dart';

void main() {
  group('AUDIT - Corrections Critiques (C1-C3)', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
    });

    // ========================================================================
    // C1-C2 : Persistence RareResourcesManager et ResearchManager
    // ========================================================================

    test('C1-C2: RareResourcesManager est persisté dans toSnapshot()', () {
      // Arrange : Ajouter des ressources rares
      gameState.rareResources.addQuantum(50);
      gameState.rareResources.addPointsInnovation(30);
      gameState.rareResources.recordReset(
        quantumGained: 50,
        innovationPointsGained: 30,
        levelReached: 20,
        paperclipsProduced: 500000,
        moneyEarned: 25000,
        autoclippersOwned: 5,
        playTimeHours: 3.0,
      );

      // Act : Créer snapshot
      final snapshot = gameState.toSnapshot();

      // Assert : Vérifier que rareResourcesManager est dans le snapshot
      expect(snapshot.core.containsKey('rareResourcesManager'), isTrue,
          reason: 'rareResourcesManager doit être sérialisé dans le snapshot');

      final rareResourcesData = snapshot.core['rareResourcesManager'] as Map<String, dynamic>;
      expect(rareResourcesData['quantum'], equals(50));
      expect(rareResourcesData['pointsInnovation'], equals(30));
      expect(rareResourcesData['totalResets'], equals(1));
    });

    test('C1-C2: ResearchManager est persisté dans toSnapshot()', () {
      // Arrange : Rechercher des nœuds
      gameState.rareResources.addPointsInnovation(100);
      gameState.research.research('prod_efficiency_1');
      gameState.research.research('prod_speed_1');

      // Act : Créer snapshot
      final snapshot = gameState.toSnapshot();

      // Assert : Vérifier que researchManager est dans le snapshot
      expect(snapshot.core.containsKey('researchManager'), isTrue,
          reason: 'researchManager doit être sérialisé dans le snapshot');

      final researchData = snapshot.core['researchManager'] as Map<String, dynamic>;
      expect(researchData.containsKey('researchedIds'), isTrue,
          reason: 'researchedIds doit être présent');
      expect(researchData.containsKey('nodes'), isTrue,
          reason: 'nodes doit être présent');
      
      final researchedIds = researchData['researchedIds'] as List;
      expect(researchedIds.length, greaterThanOrEqualTo(3),
          reason: 'Au moins root + 2 nœuds recherchés'); // root + 2 nœuds
    });

    test('C1-C2: RareResourcesManager est restauré depuis applySnapshot()', () {
      // Arrange : Créer un état avec ressources rares
      gameState.rareResources.addQuantum(75);
      gameState.rareResources.addPointsInnovation(45);
      final snapshot = gameState.toSnapshot();

      // Act : Créer nouveau GameState et appliquer snapshot
      final newGameState = GameState();
      newGameState.applySnapshot(snapshot);

      // Assert : Vérifier que les ressources rares sont restaurées
      expect(newGameState.rareResources.quantum, equals(75),
          reason: 'Quantum doit être restauré depuis le snapshot');
      expect(newGameState.rareResources.pointsInnovation, equals(45),
          reason: 'Points Innovation doivent être restaurés depuis le snapshot');
    });

    test('C1-C2: ResearchManager est restauré depuis applySnapshot()', () {
      // Arrange : Créer un état avec recherches
      gameState.rareResources.addPointsInnovation(100);
      gameState.research.research('prod_efficiency_1');
      gameState.research.research('prod_speed_1');
      final completedCount = gameState.research.completedResearchCount;
      final snapshot = gameState.toSnapshot();

      // Act : Créer nouveau GameState et appliquer snapshot
      final newGameState = GameState();
      newGameState.applySnapshot(snapshot);

      // Assert : Vérifier que les recherches sont restaurées
      expect(newGameState.research.completedResearchCount, equals(completedCount),
          reason: 'Les recherches complétées doivent être restaurées');
      
      final node1 = newGameState.research.allNodes.firstWhere((n) => n.id == 'prod_efficiency_1');
      expect(node1.isResearched, isTrue,
          reason: 'Le nœud prod_efficiency_1 doit être marqué comme recherché');
    });

    test('C1-C2: Cycle complet toSnapshot() -> applySnapshot() préserve tout', () {
      // Arrange : Créer un état complet
      gameState.rareResources.addQuantum(100);
      gameState.rareResources.addPointsInnovation(60);
      
      // Dépenser manuellement (sans recherche)
      gameState.rareResources.spendQuantum(25);
      
      // Sauvegarder les valeurs avant reset
      final quantumBeforeReset = gameState.rareResources.quantum;
      final piBeforeReset = gameState.rareResources.pointsInnovation;
      final quantumLifetimeBefore = gameState.rareResources.quantumLifetime;
      final piLifetimeBefore = gameState.rareResources.innovationPointsLifetime;
      final quantumSpentBefore = gameState.rareResources.quantumSpent;
      
      gameState.rareResources.recordReset(
        quantumGained: 75,
        innovationPointsGained: 45,
        levelReached: 25,
        paperclipsProduced: 1000000,
        moneyEarned: 50000,
        autoclippersOwned: 10,
        playTimeHours: 5.0,
      );

      final snapshot = gameState.toSnapshot();

      // Act : Restaurer dans nouveau GameState
      final newGameState = GameState();
      newGameState.applySnapshot(snapshot);

      // Assert : Vérifier toutes les données
      expect(newGameState.rareResources.quantum, equals(quantumBeforeReset));
      expect(newGameState.rareResources.pointsInnovation, equals(piBeforeReset));
      expect(newGameState.rareResources.quantumLifetime, equals(quantumLifetimeBefore));
      expect(newGameState.rareResources.innovationPointsLifetime, equals(piLifetimeBefore));
      expect(newGameState.rareResources.quantumSpent, equals(quantumSpentBefore));
      expect(newGameState.rareResources.totalResets, equals(1));
      
      expect(newGameState.research.completedResearchCount, 
          equals(gameState.research.completedResearchCount));
    });

    // ========================================================================
    // C3 : Valeurs lifetime initialisées à 0
    // ========================================================================

    test('C3: RareResourcesManager lifetime initialisé à 0', () {
      // Arrange & Act : Créer nouveau manager
      final manager = RareResourcesManager();

      // Assert : Vérifier valeurs initiales
      expect(manager.quantumLifetime, equals(0),
          reason: 'quantumLifetime doit être initialisé à 0, pas 1000');
      expect(manager.innovationPointsLifetime, equals(0),
          reason: 'innovationPointsLifetime doit être initialisé à 0, pas 5000');
      expect(manager.quantum, equals(0));
      expect(manager.pointsInnovation, equals(0));
      expect(manager.quantumSpent, equals(0));
      expect(manager.innovationPointsSpent, equals(0));
    });

    test('C3: Lifetime augmente correctement après ajout', () {
      // Arrange
      final manager = RareResourcesManager();

      // Act : Ajouter ressources
      manager.addQuantum(50);
      manager.addPointsInnovation(30);

      // Assert : Lifetime doit refléter les ajouts
      expect(manager.quantumLifetime, equals(50));
      expect(manager.innovationPointsLifetime, equals(30));
    });
  });

  group('AUDIT - Corrections Importantes (I3)', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
    });

    // ========================================================================
    // I3 : AgentManager.syncWithResearch() sécurisé
    // ========================================================================

    test('I3: syncWithResearch() ne crash pas si nœuds recherche absents', () {
      // Arrange : Créer un GameState et vider les nœuds de recherche
      final testGameState = GameState();
      
      // Supprimer les nœuds agent_slot_3 et agent_slot_4 pour simuler état invalide
      testGameState.research.allNodes.removeWhere((n) => 
          n.id == 'agent_slot_3' || n.id == 'agent_slot_4');

      // Act & Assert : Ne doit pas crasher
      expect(() => testGameState.agents.syncWithResearch(), returnsNormally,
          reason: 'syncWithResearch() doit gérer l\'absence de nœuds sans crasher');
      
      // Vérifier que maxSlots reste à la valeur par défaut
      expect(testGameState.agents.maxSlots, equals(2),
          reason: 'maxSlots doit rester à 2 si nœuds non trouvés');
    });

    test('I3: syncWithResearch() fonctionne normalement avec nœuds présents', () {
      // Arrange : Rechercher agent_slot_3
      gameState.rareResources.addPointsInnovation(100);
      gameState.research.research('agent_slot_2');
      gameState.research.research('agent_slot_3');

      // Act : Synchroniser
      gameState.agents.syncWithResearch();

      // Assert : maxSlots doit être mis à jour
      expect(gameState.agents.maxSlots, equals(3),
          reason: 'maxSlots doit être 3 après recherche de agent_slot_3');
    });

    test('I3: syncWithResearch() gère correctement 4 slots', () {
      // Arrange : Rechercher jusqu'à agent_slot_4
      gameState.rareResources.addPointsInnovation(200);
      gameState.research.research('agent_slot_2');
      gameState.research.research('agent_slot_3');
      gameState.research.research('agent_slot_4');

      // Act : Synchroniser
      gameState.agents.syncWithResearch();

      // Assert
      expect(gameState.agents.maxSlots, equals(4),
          reason: 'maxSlots doit être 4 après recherche de agent_slot_4');
    });

    test('I3: syncWithResearch() débloque agents correctement', () {
      // Arrange : Rechercher unlock agent
      gameState.rareResources.addPointsInnovation(200);
      
      // Rechercher prérequis pour production optimizer
      gameState.research.research('prod_efficiency_1');
      gameState.research.research('prod_speed_1');
      gameState.research.research('prod_efficiency_2');
      gameState.research.research('prod_speed_2');
      gameState.research.research('prod_mass');
      gameState.research.research('unlock_agent_production');

      // Act : Synchroniser
      gameState.agents.syncWithResearch();

      // Assert : Agent doit être débloqué
      final agent = gameState.agents.getAgent('production_optimizer');
      expect(agent, isNotNull);
      expect(agent!.status.toString(), equals('AgentStatus.UNLOCKED'),
          reason: 'Agent production_optimizer doit être débloqué');
    });
  });

  group('AUDIT - Intégration Complète', () {
    test('INTÉGRATION: Scénario complet reset progression', () {
      // Arrange : Créer partie complète
      final gameState = GameState();
      
      // 1. Jouer et progresser
      gameState.rareResources.addQuantum(100);
      gameState.rareResources.addPointsInnovation(80);
      
      // 2. Rechercher des nœuds
      gameState.research.research('prod_efficiency_1'); // 5 PI
      gameState.research.research('prod_speed_1'); // 5 PI
      gameState.research.research('agent_slot_2'); // 15 PI
      
      // Sauvegarder état avant reset
      final quantumBefore = gameState.rareResources.quantum;
      final piBefore = gameState.rareResources.pointsInnovation;
      final researchCountBefore = gameState.research.completedResearchCount;
      
      // 3. Enregistrer reset
      gameState.rareResources.recordReset(
        quantumGained: 100,
        innovationPointsGained: 80,
        levelReached: 30,
        paperclipsProduced: 2000000,
        moneyEarned: 100000,
        autoclippersOwned: 15,
        playTimeHours: 8.0,
      );

      // Act : Sauvegarder et recharger
      final snapshot = gameState.toSnapshot();
      final newGameState = GameState();
      newGameState.applySnapshot(snapshot);

      // Assert : Tout doit être préservé
      expect(newGameState.rareResources.quantum, equals(quantumBefore),
          reason: 'Quantum doit être préservé');
      expect(newGameState.rareResources.pointsInnovation, equals(piBefore),
          reason: 'PI doivent être préservés');
      expect(newGameState.rareResources.totalResets, equals(1),
          reason: 'Nombre de resets doit être préservé');
      
      expect(newGameState.research.completedResearchCount, equals(researchCountBefore),
          reason: 'Recherches complétées doivent être préservées');
      
      // Vérifier que les nœuds recherchés sont bien restaurés
      final node1 = newGameState.research.allNodes.firstWhere((n) => n.id == 'prod_efficiency_1');
      expect(node1.isResearched, isTrue);
      
      final node2 = newGameState.research.allNodes.firstWhere((n) => n.id == 'agent_slot_2');
      expect(node2.isResearched, isTrue);
    });

    test('INTÉGRATION: Méta-progression préservée après multiple resets', () {
      // Arrange
      final gameState = GameState();
      
      // Reset 1
      gameState.rareResources.addQuantum(50);
      gameState.rareResources.addPointsInnovation(30);
      gameState.rareResources.recordReset(
        quantumGained: 50,
        innovationPointsGained: 30,
        levelReached: 20,
        paperclipsProduced: 500000,
        moneyEarned: 25000,
        autoclippersOwned: 5,
        playTimeHours: 3.0,
      );
      
      // Reset 2
      gameState.rareResources.addQuantum(75);
      gameState.rareResources.addPointsInnovation(45);
      gameState.rareResources.recordReset(
        quantumGained: 75,
        innovationPointsGained: 45,
        levelReached: 25,
        paperclipsProduced: 1000000,
        moneyEarned: 50000,
        autoclippersOwned: 10,
        playTimeHours: 5.0,
      );

      // Act : Sauvegarder et recharger
      final snapshot = gameState.toSnapshot();
      final newGameState = GameState();
      newGameState.applySnapshot(snapshot);

      // Assert : Historique complet préservé
      expect(newGameState.rareResources.totalResets, equals(2));
      expect(newGameState.rareResources.quantum, equals(125)); // 50 + 75
      expect(newGameState.rareResources.pointsInnovation, equals(75)); // 30 + 45
      expect(newGameState.rareResources.quantumLifetime, equals(125));
      expect(newGameState.rareResources.innovationPointsLifetime, equals(75));
    });
  });
}
