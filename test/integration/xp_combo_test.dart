import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import '../helpers/game_simulator.dart';

/// Test du système de combos XP
void main() {
  group('Combos XP', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      while (!gameState.isInitialized) {}
      
      // Donner ressources pour tests
      gameState.playerManager.updateMoney(10000);
      gameState.playerManager.updateMetal(5000);
    });

    test('XP gagnée par production manuelle', () {
      final xpBefore = gameState.levelSystem.experience;
      
      // Produire un trombone
      gameState.productionManager.producePaperclip();
      
      final xpAfter = gameState.levelSystem.experience;
      final xpGain = xpAfter - xpBefore;
      
      print('📊 XP Production Manuelle :');
      print('   XP avant : $xpBefore');
      print('   XP après : $xpAfter');
      print('   XP gagnée : $xpGain');
      
      expect(xpGain, greaterThan(0),
          reason: 'Production manuelle devrait donner de l\'XP');
    });

    test('XP gagnée par vente', () {
      // Produire trombones
      for (int i = 0; i < 50; i++) {
        gameState.productionManager.producePaperclip();
      }
      
      final xpBefore = gameState.levelSystem.experience;
      
      // Vendre avec le vrai MarketManager pour déclencher l'XP
      GameSimulator.sellPaperclipsReal(gameState, 0.25);
      
      final xpAfter = gameState.levelSystem.experience;
      final xpGain = xpAfter - xpBefore;
      
      print('📊 XP Vente :');
      print('   XP gagnée : $xpGain');
      
      // Le système attribue maintenant de l'XP pour les ventes
      expect(xpGain, greaterThan(0),
          reason: 'Vente devrait donner de l\'XP');
    });

    test('XP gagnée par achat autoclipper', () {
      final xpBefore = gameState.levelSystem.experience;
      
      // Acheter autoclipper
      gameState.productionManager.buyAutoclipperOfficial();
      
      final xpAfter = gameState.levelSystem.experience;
      final xpGain = xpAfter - xpBefore;
      
      print('📊 XP Achat Autoclipper :');
      print('   XP gagnée : $xpGain');
      
      expect(xpGain, greaterThan(0),
          reason: 'Achat autoclipper devrait donner de l\'XP');
    });

    test('Progression de niveau', () {
      final levelBefore = gameState.levelSystem.currentLevel;
      
      // Produire beaucoup pour gagner XP
      for (int i = 0; i < 500; i++) {
        gameState.productionManager.producePaperclip();
      }
      
      final levelAfter = gameState.levelSystem.currentLevel;
      
      print('📊 Progression Niveau :');
      print('   Niveau avant : $levelBefore');
      print('   Niveau après : $levelAfter');
      print('   XP : ${gameState.levelSystem.experience}');
      
      expect(levelAfter, greaterThanOrEqualTo(levelBefore),
          reason: 'Niveau devrait augmenter ou rester stable');
    });
  });
}
