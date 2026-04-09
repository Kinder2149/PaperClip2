// test/integration_test/agents_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/agent.dart';
import 'package:paperclip2/managers/agent_manager.dart';

/// Tests d'intégration pour le système d'agents IA
void main() {
  group('Agents Integration Tests', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
    });

    test('Activation agent consomme Quantum et active agent', () {
      // Donner du Quantum
      gameState.rareResources.addQuantum(10);
      
      // Débloquer un agent via recherche
      gameState.research.unlockResearch('unlock_agent_production');
      gameState.agents.syncWithResearch();
      
      final agentManager = gameState.agents;
      final quantumBefore = gameState.rareResources.quantum;
      
      // Activer l'agent
      final success = agentManager.activateAgent('production_optimizer');
      
      expect(success, true);
      expect(gameState.rareResources.quantum, quantumBefore - 5);
      expect(agentManager.activeCount, 1);
      
      final agent = agentManager.getAgentById('production_optimizer');
      expect(agent?.isActive, true);
      expect(agent?.expiresAt, isNotNull);
    });

    test('Limite de slots respectée', () {
      gameState.rareResources.addQuantum(50);
      
      // Débloquer tous les agents
      gameState.research.unlockResearch('unlock_agent_production');
      gameState.research.unlockResearch('unlock_agent_market');
      gameState.research.unlockResearch('unlock_agent_metal');
      gameState.agents.syncWithResearch();
      
      final agentManager = gameState.agents;
      
      // Activer 2 agents (limite par défaut)
      expect(agentManager.activateAgent('production_optimizer'), true);
      expect(agentManager.activateAgent('market_analyst'), true);
      
      // Le 3ème devrait échouer
      expect(agentManager.activateAgent('metal_buyer'), false);
      expect(agentManager.activeCount, 2);
    });

    test('Débloquer slot 3 permet d\'activer 3 agents', () {
      gameState.rareResources.addQuantum(50);
      
      // Débloquer agents et slot 3
      gameState.research.unlockResearch('unlock_agent_production');
      gameState.research.unlockResearch('unlock_agent_market');
      gameState.research.unlockResearch('unlock_agent_metal');
      gameState.research.unlockResearch('agent_slot_3');
      gameState.agents.syncWithResearch();
      
      final agentManager = gameState.agents;
      
      expect(agentManager.maxSlots, 3);
      expect(agentManager.activateAgent('production_optimizer'), true);
      expect(agentManager.activateAgent('market_analyst'), true);
      expect(agentManager.activateAgent('metal_buyer'), true);
      expect(agentManager.activeCount, 3);
    });

    test('Bonus Production Optimizer appliqué', () {
      gameState.rareResources.addQuantum(10);
      gameState.research.unlockResearch('unlock_agent_production');
      gameState.agents.syncWithResearch();
      
      // Avant activation
      final bonusBefore = gameState.agents.getProductionSpeedBonus();
      expect(bonusBefore, 0.0);
      
      // Activer Production Optimizer
      gameState.agents.activateAgent('production_optimizer');
      
      // Après activation
      final bonusAfter = gameState.agents.getProductionSpeedBonus();
      expect(bonusAfter, 0.25); // +25%
    });

    test('Désactivation agent libère slot', () {
      gameState.rareResources.addQuantum(20);
      gameState.research.unlockResearch('unlock_agent_production');
      gameState.research.unlockResearch('unlock_agent_market');
      gameState.agents.syncWithResearch();
      
      final agentManager = gameState.agents;
      
      agentManager.activateAgent('production_optimizer');
      agentManager.activateAgent('market_analyst');
      expect(agentManager.availableSlots, 0);
      
      agentManager.deactivateAgent('production_optimizer');
      expect(agentManager.availableSlots, 1);
      expect(agentManager.activeCount, 1);
    });

    test('Persistance agents dans snapshot', () {
      gameState.rareResources.addQuantum(10);
      gameState.research.unlockResearch('unlock_agent_production');
      gameState.agents.syncWithResearch();
      gameState.agents.activateAgent('production_optimizer');
      
      // Créer snapshot
      final snapshot = gameState.toSnapshot();
      
      // Créer nouveau GameState et charger snapshot
      final newGameState = GameState();
      newGameState.applySnapshot(snapshot);
      
      // Vérifier que l'agent est toujours actif
      final agent = newGameState.agents.getAgentById('production_optimizer');
      expect(agent?.isActive, true);
      expect(agent?.expiresAt, isNotNull);
      expect(newGameState.agents.activeCount, 1);
    });

    test('Quantum insuffisant empêche activation', () {
      gameState.rareResources.addQuantum(3); // Moins de 5
      gameState.research.unlockResearch('unlock_agent_production');
      gameState.agents.syncWithResearch();
      
      final success = gameState.agents.activateAgent('production_optimizer');
      expect(success, false);
      expect(gameState.agents.activeCount, 0);
    });

    test('Agent verrouillé ne peut pas être activé', () {
      gameState.rareResources.addQuantum(10);
      // Ne pas débloquer via recherche
      
      final success = gameState.agents.activateAgent('production_optimizer');
      expect(success, false);
      
      final agent = gameState.agents.getAgentById('production_optimizer');
      expect(agent?.status, AgentStatus.LOCKED);
    });

    test('Synchronisation recherche débloque agents', () {
      final agentManager = gameState.agents;
      
      // Avant recherche
      var agent = agentManager.getAgentById('production_optimizer');
      expect(agent?.status, AgentStatus.LOCKED);
      
      // Débloquer via recherche
      gameState.research.unlockResearch('unlock_agent_production');
      agentManager.syncWithResearch();
      
      // Après recherche
      agent = agentManager.getAgentById('production_optimizer');
      expect(agent?.status, AgentStatus.UNLOCKED);
    });

    test('Statistiques agent mises à jour', () {
      gameState.rareResources.addQuantum(10);
      gameState.research.unlockResearch('unlock_agent_innovation');
      gameState.agents.syncWithResearch();
      
      final agentManager = gameState.agents;
      agentManager.activateAgent('innovation_researcher');
      
      final agent = agentManager.getAgentById('innovation_researcher');
      expect(agent?.totalActions, 0);
      
      // Simuler action (normalement fait par tick)
      agent?.totalActions = 1;
      agent?.lastActionAt = DateTime.now();
      
      expect(agent?.totalActions, 1);
      expect(agent?.lastActionAt, isNotNull);
    });
  });
}
