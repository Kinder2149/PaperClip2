// lib/domain/entities/market_entity.dart
import 'dart:math';
import '../../core/constants/game_constants.dart';
import 'sale_record_entity.dart';

class MarketDynamicsEntity {
  final double marketVolatility;
  final double marketTrend;
  final double competitorPressure;

  MarketDynamicsEntity({
    this.marketVolatility = 1.0,
    this.marketTrend = 0.0,
    this.competitorPressure = 1.0,
  });

  void updateMarketConditions() {
    marketVolatility = 0.8 + (Random().nextDouble() * 0.4);
    marketTrend = -0.2 + (Random().nextDouble() * 0.4);
    competitorPressure = 0.9 + (Random().nextDouble() * 0.2);
  }

  double getMarketConditionMultiplier() {
    return marketVolatility * (1 + marketTrend) * competitorPressure;
  }

  MarketDynamicsEntity copyWith({
    double? marketVolatility,
    double? marketTrend,
    double? competitorPressure,
  }) {
    return MarketDynamicsEntity(
      marketVolatility: marketVolatility ?? this.marketVolatility,
      marketTrend: marketTrend ?? this.marketTrend,
      competitorPressure: competitorPressure ?? this.competitorPressure,
    );
  }
}

class MarketEntity {
  final double reputation;
  final double marketMetalStock;
  final List<SaleRecordEntity> salesHistory;
  final double currentMetalPrice;
  final double marketSaturation;
  final MarketDynamicsEntity dynamics;

  MarketEntity({
    required this.reputation,
    required this.marketMetalStock,
    required this.salesHistory,
    required this.currentMetalPrice,
    required this.marketSaturation,
    required this.dynamics,
  });

  double calculateDemand(double price, int marketingLevel) {
    double elasticity;

    if (price <= GameConstants.OPTIMAL_PRICE_LOW) {
      elasticity = -1.0;
    } else if (price <= GameConstants.OPTIMAL_PRICE_HIGH) {
      elasticity = -1.5;
    } else if (price <= GameConstants.MAX_PRICE) {
      elasticity = -2.0;
    } else {
      elasticity = -3.0;
    }

    double baseDemand = marketSaturation * pow(
        e,
        elasticity * (price / GameConstants.OPTIMAL_PRICE_LOW)
    );
    double marketingBonus = 1.0 + (marketingLevel * 0.30);
    double reputationFactor = _calculateReputationImpact(price);

    return baseDemand * marketingBonus * reputationFactor;
  }

  double _calculateReputationImpact(double price) {
    if (price > GameConstants.MAX_PRICE) {
      reputation *= GameConstants.REPUTATION_PENALTY_RATE;
    } else if (price <= GameConstants.OPTIMAL_PRICE_HIGH) {
      reputation = min(
          GameConstants.MAX_REPUTATION,
          reputation * GameConstants.REPUTATION_BONUS_RATE
      );
    }

    return max(GameConstants.MIN_REPUTATION, reputation);
  }

  void updateMarketStock(double amount) {
    marketMetalStock = (marketMetalStock + amount)
        .clamp(0.0, GameConstants.INITIAL_MARKET_METAL);
  }

  void recordSale(int quantity, double price) {
    final sale = SaleRecordEntity(
      timestamp: DateTime.now(),
      quantity: quantity,
      price: price,
      revenue: quantity * price,
    );

    salesHistory.add(sale);

    if (salesHistory.length > GameConstants.MAX_SALES_HISTORY) {
      salesHistory.removeAt(0);
    }

    updateReputation(price, quantity);
  }

  void updateReputation(double price, int satisfiedCustomers) {
    double priceImpact = price <= 0.35 ? 0.02 : -0.01;
    double customerSatisfactionImpact = satisfiedCustomers * 0.001;
    reputation = (reputation + priceImpact + customerSatisfactionImpact)
        .clamp(0.0, 2.0);
  }

  MarketEntity copyWith({
    double? reputation,
    double? marketMetalStock,
    List<SaleRecordEntity>? salesHistory,
    double? currentMetalPrice,
    double? marketSaturation,
    MarketDynamicsEntity? dynamics,
  }) {
    return MarketEntity(
      reputation: reputation ?? this.reputation,
      marketMetalStock: marketMetalStock ?? this.marketMetalStock,
      salesHistory: salesHistory ?? this.salesHistory,
      currentMetalPrice: currentMetalPrice ?? this.currentMetalPrice,
      marketSaturation: marketSaturation ?? this.marketSaturation,
      dynamics: dynamics ?? this.dynamics,
    );
  }
}