// test/transition_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state_transition.dart';

void main() {
  group('GameStateTransition Tests', () {
    late GameStateTransition gameState;

    setUp(() {
      gameState = GameStateTransition();
    });

    test('Initialisation des composants', () {
      // Vérifier que les composants sont initialisés
      expect(gameState.paperclipManager, isNotNull);
      expect(gameState.metalManager, isNotNull);
      expect(gameState.upgradeSystem, isNotNull);
      expect(gameState.marketSystem, isNotNull);
      expect(gameState.progressionSystem, isNotNull);
    });

    test('Production de trombones', () {
      // État initial
      int initialPaperclips = gameState.paperclipManager.totalPaperclipsProduced;
      
      // Produire un trombone
      gameState.producePaperclip();
      
      // Vérifier que le nombre de trombones a augmenté dans les deux systèmes
      expect(gameState.paperclipManager.totalPaperclipsProduced, equals(initialPaperclips + 1));
      expect(gameState.progressionSystem.playerStats['paperclips_produced'], equals(initialPaperclips + 1));
    });

    test('Achat de metal', () {
      // État initial
      double initialMetal = gameState.metalManager.playerMetal;
      
      // Ajouter de l'argent pour pouvoir acheter du métal
      gameState.playerManager.money = 1000;
      
      // Acheter du métal
      gameState.buyMetal(10);
      
      // Vérifier que la quantité de métal a augmenté
      expect(gameState.metalManager.playerMetal, greaterThan(initialMetal));
    });

    test('Achat d\'amelioration', () {
      // Ajouter de l'argent pour pouvoir acheter une amélioration
      gameState.playerManager.money = 1000;
      
      // Acheter une amélioration
      bool success = gameState.purchaseUpgrade('efficiency');
      
      // Vérifier que l'achat a réussi
      expect(success, isTrue);
      
      // Vérifier que le niveau d'amélioration a augmenté
      expect(gameState.upgradeSystem.getUpgradeLevel('efficiency'), equals(1));
    });

    test('Serialisation et deserialisation', () {
      // Modifier l'état du jeu
      gameState.playerManager.money = 1000;
      gameState.producePaperclip();
      gameState.buyMetal(10);
      gameState.purchaseUpgrade('efficiency');
      
      // Sérialiser
      Map<String, dynamic> json = gameState.toJson();
      
      // Créer un nouvel état de jeu
      GameStateTransition newGameState = GameStateTransition();
      
      // Désérialiser
      newGameState.fromJson(json);
      
      // Vérifier que les données ont été correctement chargées
      expect(newGameState.paperclipManager.totalPaperclipsProduced, equals(gameState.paperclipManager.totalPaperclipsProduced));
      expect(newGameState.metalManager.playerMetal, equals(gameState.metalManager.playerMetal));
      expect(newGameState.upgradeSystem.getUpgradeLevel('efficiency'), equals(gameState.upgradeSystem.getUpgradeLevel('efficiency')));
    });
  });
} 