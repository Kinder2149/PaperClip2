import '../constants.dart';
import 'market_dynamics.dart';
import 'sale_record.dart';

class MarketManager {
  final MarketDynamics dynamics;
  List<SaleRecord> salesHistory = [];
  double reputation = 1.0;

  static const double MIN_PRICE = GameConstants.MIN_PRICE;
  static const double MAX_PRICE = GameConstants.MAX_PRICE;

  MarketManager(this.dynamics);

  double calculateDemand(double price, int marketingLevel) {
    double baseDemand;
    int multiplier;

    if (price <= 0.15) {
      baseDemand = 1.0 + (0.15 - price) * 3;
      multiplier = 5;
    } else if (price <= 0.35) {
      baseDemand = 1.5 - (price - 0.15) * 2;
      multiplier = 10;
    } else if (price <= 0.50) {
      baseDemand = 0.8 - (price - 0.35);
      multiplier = 3;
    } else {
      baseDemand = 0.3;
      multiplier = 1;
    }

    double marketingMultiplier = 1.0 + (marketingLevel * 0.3);
    double reputationFactor = 0.5 + (reputation * 0.5);

    return (baseDemand * marketingMultiplier * reputationFactor * multiplier) *
        dynamics.getMarketConditionMultiplier();
  }

  void recordSale(int quantity, double price) {
    final sale = SaleRecord(
      timestamp: DateTime.now(),
      quantity: quantity,
      price: price,
      revenue: quantity * price,
    );

    salesHistory.add(sale);
    if (salesHistory.length > 100) {
      salesHistory.removeAt(0);
    }

    updateReputation(price, quantity);
  }

  void updateReputation(double price, int satisfiedCustomers) {
    double priceImpact = price <= 0.35 ? 0.01 : -0.01;
    reputation = (reputation + priceImpact * satisfiedCustomers).clamp(0.0, 2.0);
  }

  void updateMarket() {
    dynamics.updateMarketConditions();
  }
}