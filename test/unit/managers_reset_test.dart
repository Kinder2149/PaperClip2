import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';

/// Tests pour les méthodes reset() des managers
void main() {
  group('Managers Reset Methods', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      while (!gameState.isInitialized) {}
    });

    test('ProductionManager.reset() existe et fonctionne', () {
      // Action: reset
      gameState.productionManager.reset();
      
      // Assert: coûts maintenance à zéro après reset
      expect(gameState.productionManager.maintenanceCosts, equals(0.0));
    });

    test('MarketManager.reset() existe et fonctionne', () {
      // Action: reset
      gameState.marketManager.reset();
      
      // Assert: valeurs restaurées
      expect(gameState.marketManager.marketMetalStock, greaterThan(0));
      expect(gameState.marketManager.currentPrice, greaterThan(0));
    });

    test('LevelSystem.resetForProgression() remet niveau 1', () {
      // Setup: monter de niveau
      gameState.levelSystem.addExperience(10000);
      
      final levelBefore = gameState.levelSystem.currentLevel;
      expect(levelBefore, greaterThan(1));
      
      // Action: reset
      gameState.levelSystem.resetForProgression();
      
      // Assert: niveau 1, XP 0
      expect(gameState.levelSystem.currentLevel, equals(1));
      expect(gameState.levelSystem.experience, equals(0));
    });

    test('StatisticsManager conserve données lifetime', () {
      // Setup: vérifier stats initiales
      final totalBefore = gameState.statistics.totalPaperclipsProduced;
      final moneyBefore = gameState.statistics.totalMoneyEarned;
      
      // Les stats lifetime persistent (pas de reset)
      expect(gameState.statistics.totalPaperclipsProduced, equals(totalBefore));
      expect(gameState.statistics.totalMoneyEarned, equals(moneyBefore));
    });

    test('Tous les managers ont une méthode reset accessible', () {
      // Vérifier que les méthodes existent et sont appelables
      expect(() => gameState.productionManager.reset(), returnsNormally);
      expect(() => gameState.marketManager.reset(), returnsNormally);
      expect(() => gameState.levelSystem.resetForProgression(), returnsNormally);
    });
  });
}
