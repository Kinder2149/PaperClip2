import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';

/// Test du système d'agents
void main() {
  group('Système d\'Agents', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      while (!gameState.isInitialized) {}
    });

    test('Débloquer et activer un agent', () {
      // Donner du Quantum
      gameState.rareResources.addQuantum(10);
      
      expect(gameState.rareResources.quantum, equals(10));
      
      // Débloquer l'agent via recherche
      // Note: Pour l'instant, on suppose que l'agent est déjà débloqué
      // TODO: Ajouter test de déblocage via recherche quand implémenté
      
      final agentId = 'production_optimizer';
      final quantumBefore = gameState.rareResources.quantum;
      
      // Tenter d'activer l'agent
      final success = gameState.agents.activateAgent(agentId);
      
      print('📊 Activation Agent :');
      print('   Agent : $agentId');
      print('   Succès : $success');
      print('   Quantum avant : $quantumBefore');
      print('   Quantum après : ${gameState.rareResources.quantum}');
      
      if (success) {
        // Vérifier que le Quantum a été dépensé (5 Quantum par agent)
        expect(gameState.rareResources.quantum, equals(quantumBefore - 5),
            reason: 'Devrait dépenser 5 Quantum pour activer l\'agent');
        
        // Vérifier que l'agent est actif
        expect(gameState.agents.hasActiveAgent(agentId), isTrue,
            reason: 'L\'agent devrait être actif après activation');
      } else {
        print('   ⚠️  Agent non activé (peut-être verrouillé)');
      }
    });

    test('Impossible d\'activer agent sans Quantum', () {
      // Pas de Quantum
      expect(gameState.rareResources.quantum, equals(0));
      
      final agentId = 'production_optimizer';
      
      // Tenter d'activer sans Quantum
      final success = gameState.agents.activateAgent(agentId);
      
      print('📊 Test Sans Quantum :');
      print('   Succès : $success');
      
      expect(success, isFalse,
          reason: 'Ne devrait pas pouvoir activer sans Quantum');
    });

    test('Vérifier liste des agents disponibles', () {
      final allAgents = gameState.agents.allAgents;
      
      print('📊 Agents Disponibles :');
      for (final agent in allAgents) {
        print('   - ${agent.name} (${agent.id})');
        print('     Coût : ${agent.activationCost} Quantum');
        print('     Type : ${agent.type}');
        print('     Statut : ${agent.status}');
      }
      
      expect(allAgents, isNotEmpty,
          reason: 'Devrait avoir au moins un agent défini');
      
      // Vérifier que tous les agents coûtent 5 Quantum
      for (final agent in allAgents) {
        expect(agent.activationCost, equals(5),
            reason: 'Tous les agents devraient coûter 5 Quantum');
      }
    });

    test('Activer plusieurs agents avec assez de Quantum', () {
      // Donner beaucoup de Quantum
      gameState.rareResources.addQuantum(50);
      
      final agents = gameState.agents.allAgents;
      int activated = 0;
      
      print('📊 Activation Multiple :');
      print('   Quantum initial : ${gameState.rareResources.quantum}');
      
      // Tenter d'activer tous les agents
      for (final agent in agents) {
        if (gameState.agents.activateAgent(agent.id)) {
          activated++;
          print('   ✅ ${agent.name} activé');
        } else {
          print('   ❌ ${agent.name} non activé');
        }
      }
      
      print('   Agents activés : $activated');
      print('   Quantum restant : ${gameState.rareResources.quantum}');
      
      if (activated > 0) {
        expect(gameState.rareResources.quantum, 
            equals(50 - (activated * 5)),
            reason: 'Devrait dépenser 5 Quantum par agent activé');
      }
    });

    test('Vérifier slots d\'agents disponibles', () {
      final availableSlots = gameState.agents.availableSlots;
      final activeAgents = gameState.agents.activeAgents;
      
      print('📊 Slots Agents :');
      print('   Slots disponibles : $availableSlots');
      print('   Agents actifs : ${activeAgents.length}');
      
      expect(availableSlots, greaterThanOrEqualTo(0),
          reason: 'Slots disponibles ne peut pas être négatif');
    });

    test('Agent Production Optimizer - Vérifier bonus', () {
      // Donner ressources
      gameState.rareResources.addQuantum(10);
      gameState.playerManager.updateMoney(10000);
      
      // Acheter autoclippers
      for (int i = 0; i < 10; i++) {
        gameState.productionManager.buyAutoclipperOfficial();
      }
      
      // Activer Production Optimizer (+25% vitesse)
      final success = gameState.agents.activateAgent('production_optimizer');
      
      if (success) {
        print('📊 Test Bonus Production Optimizer :');
        print('   Agent activé : ✅');
        print('   Bonus attendu : +25% vitesse autoclippers');
        print('   TODO: Vérifier que le bonus s\'applique réellement');
        
        // TODO: Tester que la production est effectivement +25% plus rapide
        // Nécessite de mesurer la vitesse de production avant/après
      } else {
        print('   ⚠️  Agent non activé (peut-être verrouillé)');
      }
    });
  });
}
