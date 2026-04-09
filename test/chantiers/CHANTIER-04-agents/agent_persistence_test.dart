// test/unit/agent_persistence_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/game_persistence_mapper.dart';

/// Test de persistance des agents IA autonomes
/// Vérifie que les agents activés sont correctement sauvegardés et restaurés
void main() {
  group('Agent Persistence Tests', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
    });

    test('Les agents sérialisent correctement leur état', () {
      // Arrange : Activer un agent
      final agentId = 'production_optimizer';
      
      // Simuler déblocage via recherche
      gameState.research.unlockNode('agent_production_optimizer');
      gameState.agents.syncWithResearch();
      
      // Ajouter du Quantum pour activation
      gameState.rareResources.addQuantum(10, source: 'test');
      
      // Activer l'agent
      final activated = gameState.agents.activateAgent(agentId);
      expect(activated, isTrue, reason: 'Agent devrait être activé');

      // Act : Sérialiser
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);
      
      // Assert : Vérifier structure
      expect(snapshot.core['agents'], isNotNull);
      expect(snapshot.core['agents'], isA<Map<String, dynamic>>());
      
      final agentsData = snapshot.core['agents'] as Map<String, dynamic>;
      expect(agentsData['agents'], isNotNull);
      expect(agentsData['agents'], isA<Map<String, dynamic>>());
      
      final agentsMap = agentsData['agents'] as Map<String, dynamic>;
      expect(agentsMap.containsKey(agentId), isTrue);
      
      final agentData = agentsMap[agentId] as Map<String, dynamic>;
      expect(agentData['status'], equals('ACTIVE'));
      expect(agentData['activatedAt'], isNotNull);
      expect(agentData['expiresAt'], isNotNull);
    });

    test('Les agents désérialisent correctement leur état', () {
      // Arrange : Créer un snapshot avec agent actif
      final agentId = 'production_optimizer';
      
      // Débloquer et activer
      gameState.research.unlockNode('agent_production_optimizer');
      gameState.agents.syncWithResearch();
      gameState.rareResources.addQuantum(10, source: 'test');
      gameState.agents.activateAgent(agentId);
      
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);
      
      // Act : Créer nouveau GameState et charger
      final newGameState = GameState();
      GamePersistenceMapper.fromSnapshotV3(newGameState, snapshot);
      
      // Assert : Vérifier que l'agent est restauré actif
      final agent = newGameState.agents.getAgent(agentId);
      expect(agent, isNotNull);
      expect(agent!.isActive, isTrue);
      expect(agent.activatedAt, isNotNull);
      expect(agent.expiresAt, isNotNull);
      expect(agent.status.toString(), equals('AgentStatus.ACTIVE'));
    });

    test('Les agents inactifs sont correctement sauvegardés', () {
      // Arrange : Agent débloqué mais non activé
      final agentId = 'market_analyst';
      
      gameState.research.unlockNode('agent_market_analyst');
      gameState.agents.syncWithResearch();
      
      // Act : Sérialiser
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);
      
      // Assert
      final agentsData = snapshot.core['agents'] as Map<String, dynamic>;
      final agentsMap = agentsData['agents'] as Map<String, dynamic>;
      final agentData = agentsMap[agentId] as Map<String, dynamic>;
      
      expect(agentData['status'], equals('UNLOCKED'));
      expect(agentData['activatedAt'], isNull);
      expect(agentData['expiresAt'], isNull);
    });

    test('Les agents verrouillés sont correctement sauvegardés', () {
      // Arrange : Agent non débloqué
      final agentId = 'metal_buyer';
      
      // Act : Sérialiser sans débloquer
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);
      
      // Assert
      final agentsData = snapshot.core['agents'] as Map<String, dynamic>;
      final agentsMap = agentsData['agents'] as Map<String, dynamic>;
      final agentData = agentsMap[agentId] as Map<String, dynamic>;
      
      expect(agentData['status'], equals('LOCKED'));
    });

    test('Le nombre de slots est persisté', () {
      // Arrange : Débloquer slot supplémentaire
      gameState.research.unlockNode('agent_slot_3');
      gameState.agents.syncWithResearch();
      
      expect(gameState.agents.maxSlots, equals(3));
      
      // Act : Sérialiser et désérialiser
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);
      final newGameState = GameState();
      GamePersistenceMapper.fromSnapshotV3(newGameState, snapshot);
      
      // Assert
      expect(newGameState.agents.maxSlots, equals(3));
    });

    test('Les statistiques lifetime des agents sont préservées', () {
      // Arrange : Activer et utiliser un agent
      final agentId = 'production_optimizer';
      
      gameState.research.unlockNode('agent_production_optimizer');
      gameState.agents.syncWithResearch();
      gameState.rareResources.addQuantum(10, source: 'test');
      gameState.agents.activateAgent(agentId);
      
      // Simuler quelques actions
      final agent = gameState.agents.getAgent(agentId)!;
      agent.totalActions = 42;
      
      // Act : Sérialiser et désérialiser
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);
      final newGameState = GameState();
      GamePersistenceMapper.fromSnapshotV3(newGameState, snapshot);
      
      // Assert
      final restoredAgent = newGameState.agents.getAgent(agentId);
      expect(restoredAgent!.totalActions, equals(42));
    });

    test('Plusieurs agents actifs sont tous persistés', () {
      // Arrange : Activer plusieurs agents
      gameState.research.unlockNode('agent_production_optimizer');
      gameState.research.unlockNode('agent_market_analyst');
      gameState.research.unlockNode('agent_slot_3');
      gameState.agents.syncWithResearch();
      
      gameState.rareResources.addQuantum(20, source: 'test');
      gameState.agents.activateAgent('production_optimizer');
      gameState.agents.activateAgent('market_analyst');
      
      // Act : Sérialiser et désérialiser
      final snapshot = GamePersistenceMapper.toSnapshotV3(gameState);
      final newGameState = GameState();
      GamePersistenceMapper.fromSnapshotV3(newGameState, snapshot);
      
      // Assert
      expect(newGameState.agents.activeCount, equals(2));
      expect(newGameState.agents.getAgent('production_optimizer')!.isActive, isTrue);
      expect(newGameState.agents.getAgent('market_analyst')!.isActive, isTrue);
    });
  });
}
