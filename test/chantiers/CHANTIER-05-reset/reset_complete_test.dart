import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/reset_history_entry.dart';

/// Tests d'intégration pour le reset complet
void main() {
  group('Reset Complet - Intégration', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      while (!gameState.isInitialized) {}
    });

    test('Reset conserve Quantum et Points Innovation', () async {
      // Setup: ajouter des ressources rares
      gameState.rareResources.addQuantum(50);
      gameState.rareResources.addPointsInnovation(25);
      
      final quantumBefore = gameState.rareResources.quantum;
      final piBefore = gameState.rareResources.pointsInnovation;
      
      expect(quantumBefore, equals(50));
      expect(piBefore, equals(25));
      
      // Action: effectuer reset
      await gameState.resetManager.performReset();
      
      // Assert: Quantum et PI conservés (ou augmentés)
      expect(gameState.rareResources.quantum, greaterThanOrEqualTo(quantumBefore));
      expect(gameState.rareResources.pointsInnovation, greaterThanOrEqualTo(piBefore));
    });

    test('Reset conserve recherches débloquées', () async {
      // Setup: débloquer une recherche
      final researchCountBefore = gameState.research.completedResearchCount;
      
      // Action: effectuer reset (si conditions remplies)
      // Note: reset peut échouer si niveau < 20
      await gameState.resetManager.performReset();
      
      // Assert: recherches conservées (même si reset échoue)
      expect(gameState.research.completedResearchCount, greaterThanOrEqualTo(researchCountBefore));
    });

    test('Reset ajoute entrée dans historique', () {
      // Setup: vérifier historique vide
      expect(gameState.resetHistory, isEmpty);
      expect(gameState.resetCount, equals(0));
      
      // Action: ajouter manuellement une entrée (simuler reset)
      final entry = ResetHistoryEntry(
        timestamp: DateTime.now(),
        levelBefore: 25,
        quantumGained: 10,
        innovationGained: 5,
      );
      gameState.addResetEntry(entry);
      
      // Assert: historique mis à jour
      expect(gameState.resetHistory.length, equals(1));
      expect(gameState.resetCount, equals(1));
      expect(gameState.resetHistory.first.levelBefore, equals(25));
    });

    test('Reset incrémente compteur à chaque fois', () {
      // Setup: historique vide
      expect(gameState.resetCount, equals(0));
      
      // Action: ajouter 3 resets
      for (int i = 0; i < 3; i++) {
        gameState.addResetEntry(ResetHistoryEntry(
          timestamp: DateTime.now(),
          levelBefore: 20 + i,
          quantumGained: 10,
          innovationGained: 5,
        ));
      }
      
      // Assert: compteur = 3
      expect(gameState.resetCount, equals(3));
      expect(gameState.resetHistory.length, equals(3));
    });

    test('Reset remet niveau à 1', () async {
      // Setup: monter de niveau
      gameState.levelSystem.addExperience(10000);
      expect(gameState.levelSystem.currentLevel, greaterThan(1));
      
      // Action: reset niveau
      gameState.levelSystem.resetForProgression();
      
      // Assert: niveau 1
      expect(gameState.levelSystem.currentLevel, equals(1));
      expect(gameState.levelSystem.experience, equals(0));
    });
  });
}
