// lib/managers/mock/market_manager_mock.dart
import 'package:flutter/foundation.dart';
import '../market_manager.dart';

/// Mock implementation of MarketManager to avoid NoSuchMethodError
class MarketManagerMock extends ChangeNotifier {
  double _marketMetalPrice = 10.0;
  
  double get currentMetalPrice => _marketMetalPrice;
  
  // Autres propriétés ou méthodes nécessaires
  void updateMetalPrice(double newPrice) {
    _marketMetalPrice = newPrice;
    notifyListeners();
  }
  
  void simulate() {
    // Simulation vide
  }

  void updateMarketState() {
    // Pas de logique de marché dans le mock
  }

  MarketSaleResult processSales({
    required double playerPaperclips,
    required double sellPrice,
    required int marketingLevel,
    required void Function(double paperclipsDelta) updatePaperclips,
    required void Function(double moneyDelta) updateMoney,
    bool updateMarketState = true,
    bool requireAutoSellEnabled = true,
  }) {
    // Mock simplifié: vend 1 unité si possible
    if (playerPaperclips <= 0) {
      return MarketSaleResult.none;
    }

    const quantity = 1;
    final revenue = sellPrice;
    updatePaperclips(-quantity.toDouble());
    updateMoney(revenue);
    return MarketSaleResult(quantity: quantity, unitPrice: sellPrice, revenue: revenue);
  }

  @Deprecated('Utiliser processSales(...) (Option B2).')
  double sellPaperclips({
    required double amount,
    required double sellPrice,
    required Function(double) updatePaperclips,
    required Function(double) updateMoney,
    required dynamic statistics,
  }) {
    if (amount <= 0) return 0.0;
    updatePaperclips(-amount);
    updateMoney(amount * sellPrice);
    return amount * sellPrice;
  }
}
