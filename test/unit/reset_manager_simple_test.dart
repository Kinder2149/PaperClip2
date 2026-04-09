import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';

/// Tests simples pour ResetManager refactoré
/// 
/// Valide que le refactoring fonctionne correctement
void main() {
  group('ResetManager - Architecture Refactorée', () {
    late GameState gameState;
    
    setUp(() {
      gameState = GameState();
      // Attendre initialisation
      while (!gameState.isInitialized) {}
    });
    
    test('ResetManager est créé automatiquement dans GameState', () {
      expect(gameState.resetManager, isNotNull);
    });
    
    test('canReset retourne false au démarrage', () {
      // Niveau 1, 0 trombones produits
      expect(gameState.resetManager.canReset(), isFalse);
    });
    
    test('calculatePotentialRewards retourne des récompenses valides', () {
      final rewards = gameState.resetManager.calculatePotentialRewards();
      
      // Même sans progression, devrait retourner des valeurs >= 0
      expect(rewards.quantum, greaterThanOrEqualTo(0));
      expect(rewards.innovationPoints, greaterThanOrEqualTo(0));
    });
    
    test('getResetRecommendation retourne un message', () {
      final rewards = gameState.resetManager.calculatePotentialRewards();
      final recommendation = gameState.resetManager.getResetRecommendation(
        gameState.levelSystem.currentLevel,
        rewards,
      );
      
      expect(recommendation, isNotEmpty);
      expect(recommendation, contains('Niveau'));
    });
    
    test('performReset échoue si conditions non remplies', () async {
      final result = await gameState.resetManager.performReset();
      
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
      expect(result.error, contains('Conditions non remplies'));
    });
    
    test('resetHistory est vide au démarrage', () {
      expect(gameState.resetHistory, isEmpty);
      expect(gameState.resetCount, equals(0));
    });
  });
}
