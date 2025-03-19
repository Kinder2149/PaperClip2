// test/metal_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/managers/metal_manager.dart';
import 'package:paperclip2/models/game_config.dart';

void main() {
  group('MetalManager', () {
    late MetalManager metalManager;

    setUp(() {
      metalManager = MetalManager();
    });

    test('Initialisation correcte', () {
      expect(metalManager.metal, GameConstants.INITIAL_METAL);
      expect(metalManager.marketMetalStock, GameConstants.INITIAL_MARKET_METAL);
    });

    test('Mise à jour du métal', () {
      metalManager.updateMetal(50.0);
      expect(metalManager.metal, 50.0);
    });

    test('Limite de stockage respectée', () {
      metalManager.updateMetal(GameConstants.INITIAL_STORAGE_CAPACITY * 2);
      expect(metalManager.metal, metalManager.maxMetalStorage);
    });

    test('Achat de métal valide', () {
      bool result = metalManager.buyMetal(
          price: 10.0,
          playerMoney: 100.0,
          updatePlayerMoney: (newAmount) {},
          amount: 50.0
      );
      expect(result, isTrue);
    });

    test('Achat de métal invalide', () {
      bool result = metalManager.buyMetal(
          price: 10.0,
          playerMoney: 5.0,
          updatePlayerMoney: (newAmount) {},
          amount: 50.0
      );
      expect(result, isFalse);
    });

    test('Notification de stock bas', () {
      metalManager.updateMetal(10.0);
      // Vérifier qu'une notification a été générée
      // Cette vérification dépend de votre implémentation d'EventManager
    });

    test('Validation des exceptions', () {
      expect(() => MetalManager(initialMetal: -10), throwsA(isA<MetalManagerException>()));
      expect(() => MetalManager(initialMarketStock: -10), throwsA(isA<MetalManagerException>()));
    });
  });
}