// lib/managers/mock/market_manager_mock.dart
import 'package:flutter/foundation.dart';

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
  
  // Ajout de la méthode pour vendre des trombones
  double sellPaperclips({
    required double amount,
    required double sellPrice,
    required Function(double) updatePaperclips,
    required Function(double) updateMoney,
    required dynamic statistics,
  }) {
    if (amount <= 0) return 0.0;

    double qualityBonus = 1.0 + (sellPrice * 0.10);
    double salePrice = sellPrice * qualityBonus;
    double revenue = amount * salePrice;

    updatePaperclips(-amount);
    updateMoney(revenue);
    
    // Mise à jour des statistiques
    if (statistics != null) {
      statistics.updateEconomics(
        moneyEarned: revenue,
      );
    }
    
    return revenue;
  }
}
