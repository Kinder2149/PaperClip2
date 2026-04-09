// test/unit/agents/agent_manager_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/managers/agent_manager.dart';
import 'package:paperclip2/managers/rare_resources_manager.dart';
import 'package:paperclip2/managers/research_manager.dart';
import 'package:paperclip2/models/agent.dart';

// Note: Tests complets avec GameState seront créés au Jour 3
// Ces tests basiques valident la logique core de AgentManager

void main() {
  group('AgentManager - Tests basiques', () {
    late AgentManager agentManager;
    late RareResourcesManager rareResourcesManager;
    late ResearchManager researchManager;

    setUp(() {
      rareResourcesManager = RareResourcesManager();
      researchManager = ResearchManager(rareResourcesManager);
      
      // Créer AgentManager avec mocks minimaux (null pour managers non utilisés dans ces tests)
      agentManager = AgentManager(
        rareResourcesManager,
        researchManager,
        null as dynamic, // PlayerManager - sera testé au Jour 3
        null as dynamic, // MarketManager - sera testé au Jour 3
        null as dynamic, // ResourceManager - sera testé au Jour 3
      );
    });

    test('Initialise 4 agents', () {
      expect(agentManager.allAgents.length, 4);
    });

    test('Agents initialement verrouillés', () {
      for (var agent in agentManager.allAgents) {
        expect(agent.status, AgentStatus.LOCKED);
      }
    });

    test('maxSlots initial est 2', () {
      expect(agentManager.maxSlots, 2);
    });

    test('availableSlots initial est 2', () {
      expect(agentManager.availableSlots, 2);
    });

    test('activeCount initial est 0', () {
      expect(agentManager.activeCount, 0);
    });

    test('getProductionSpeedBonus retourne 0 si agent inactif', () {
      expect(agentManager.getProductionSpeedBonus(), 0.0);
    });

    test('hasActiveAgent retourne false si agent inactif', () {
      expect(agentManager.hasActiveAgent('production_optimizer'), false);
    });

    test('activateAgent échoue si Quantum insuffisant', () {
      // Débloquer agent manuellement pour test
      final agent = agentManager.getAgent('production_optimizer')!;
      agent.status = AgentStatus.UNLOCKED;
      
      // Quantum = 0, coût = 5
      final success = agentManager.activateAgent('production_optimizer');
      expect(success, false);
      expect(agent.status, AgentStatus.UNLOCKED);
    });

    test('activateAgent réussit avec Quantum suffisant', () {
      // Débloquer agent
      final agent = agentManager.getAgent('production_optimizer')!;
      agent.status = AgentStatus.UNLOCKED;
      
      // Ajouter Quantum
      rareResourcesManager.addQuantum(10, source: 'test');
      
      final success = agentManager.activateAgent('production_optimizer');
      expect(success, true);
      expect(agent.status, AgentStatus.ACTIVE);
      expect(agent.isActive, true);
      expect(rareResourcesManager.quantum, 5); // 10 - 5
    });

    test('activateAgent échoue si slots pleins', () {
      // Débloquer 3 agents
      final agent1 = agentManager.getAgent('production_optimizer')!;
      final agent2 = agentManager.getAgent('market_analyst')!;
      final agent3 = agentManager.getAgent('metal_buyer')!;
      
      agent1.status = AgentStatus.UNLOCKED;
      agent2.status = AgentStatus.UNLOCKED;
      agent3.status = AgentStatus.UNLOCKED;
      
      // Ajouter Quantum pour 3 activations
      rareResourcesManager.addQuantum(20, source: 'test');
      
      // Activer 2 agents (max slots = 2)
      agentManager.activateAgent('production_optimizer');
      agentManager.activateAgent('market_analyst');
      
      // Tentative 3ème activation
      final success = agentManager.activateAgent('metal_buyer');
      expect(success, false);
      expect(agentManager.activeCount, 2);
    });

    test('deactivateAgent désactive agent actif', () {
      // Activer agent
      final agent = agentManager.getAgent('production_optimizer')!;
      agent.status = AgentStatus.UNLOCKED;
      rareResourcesManager.addQuantum(10, source: 'test');
      agentManager.activateAgent('production_optimizer');
      
      expect(agent.isActive, true);
      
      // Désactiver
      agentManager.deactivateAgent('production_optimizer');
      expect(agent.status, AgentStatus.UNLOCKED);
      expect(agent.isActive, false);
    });

    test('getProductionSpeedBonus retourne 0.25 si agent actif', () {
      final agent = agentManager.getAgent('production_optimizer')!;
      agent.status = AgentStatus.UNLOCKED;
      rareResourcesManager.addQuantum(10, source: 'test');
      agentManager.activateAgent('production_optimizer');
      
      expect(agentManager.getProductionSpeedBonus(), 0.25);
    });

    test('hasActiveAgent retourne true si agent actif', () {
      final agent = agentManager.getAgent('production_optimizer')!;
      agent.status = AgentStatus.UNLOCKED;
      rareResourcesManager.addQuantum(10, source: 'test');
      agentManager.activateAgent('production_optimizer');
      
      expect(agentManager.hasActiveAgent('production_optimizer'), true);
    });

    test('toJson/fromJson préserve état agents', () {
      // Activer un agent
      final agent = agentManager.getAgent('market_analyst')!;
      agent.status = AgentStatus.UNLOCKED;
      rareResourcesManager.addQuantum(10, source: 'test');
      agentManager.activateAgent('market_analyst');
      
      // Sérialiser
      final json = agentManager.toJson();
      
      // Créer nouveau manager et restaurer
      final newManager = AgentManager(
        rareResourcesManager,
        researchManager,
        null as dynamic,
        null as dynamic,
        null as dynamic,
      );
      newManager.fromJson(json);
      
      // Vérifier état restauré
      final restoredAgent = newManager.getAgent('market_analyst')!;
      expect(restoredAgent.status, AgentStatus.ACTIVE);
      expect(restoredAgent.isActive, true);
    });
    
    // Note: Tests complets d'intégration avec GameState seront créés au Jour 3
    // après l'intégration dans GameState et GameEngine
  });
}
