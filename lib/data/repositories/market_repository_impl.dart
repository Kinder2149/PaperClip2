// lib/data/repositories/market_repository_impl.dart

import 'dart:math';
import '../../domain/repositories/market_repository.dart';
import '../datasources/local/market_data_source.dart';
import '../../domain/entities/market_entity.dart';
import '../../domain/entities/sale_record_entity.dart';
import '../../core/constants/game_constants.dart';
import '../models/market_model.dart';
import '../models/sale_record_model.dart';

class MarketRepositoryImpl implements MarketRepository {
  final MarketDataSource _dataSource;

  MarketRepositoryImpl(this._dataSource);

  @override
  Future<MarketEntity> getMarket() async {
    final marketModel = await _dataSource.getMarketState();
    return marketModel.toEntity();
  }

  @override
  Future<void> updateMarket(MarketEntity market) async {
    final marketModel = MarketModel.fromEntity(market);
    await _dataSource.updateMarketState(marketModel);
  }

  @override
  Future<double> calculateDemand(double price, int marketingLevel) async {
    final market = await getMarket();

    // Base de calcul de la demande avec élasticité
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

    // Calcul de la demande base
    double baseDemand = market.marketSaturation *
        exp(elasticity * (price / GameConstants.OPTIMAL_PRICE_LOW));

    // Bonus marketing
    double marketingBonus = 1.0 + (marketingLevel * 0.30);

    // Impact de la réputation
    double reputationFactor = _calculateReputationImpact(market, price);

    return baseDemand * marketingBonus * reputationFactor;
  }

  double _calculateReputationImpact(MarketEntity market, double price) {
    double reputationChange;

    if (price > GameConstants.MAX_PRICE) {
      // Pénalité si prix trop élevé
      reputationChange = market.reputation * GameConstants.REPUTATION_PENALTY_RATE;
    } else if (price <= GameConstants.OPTIMAL_PRICE_HIGH) {
      // Bonus si prix attractif
      reputationChange = min(
          GameConstants.MAX_REPUTATION,
          market.reputation * GameConstants.REPUTATION_BONUS_RATE
      );
    } else {
      // Stabilité si prix dans la moyenne
      reputationChange = market.reputation;
    }

    return max(GameConstants.MIN_REPUTATION, reputationChange);
  }

  @override
  Future<void> updateMarketStock(double amount) async {
    final currentMarket = await getMarket();
    final updatedMarket = currentMarket.copyWith(
        marketMetalStock: (currentMarket.marketMetalStock + amount)
            .clamp(0.0, GameConstants.INITIAL_MARKET_METAL)
    );
    await updateMarket(updatedMarket);
  }

  @override
  Future<void> recordSale(int quantity, double price) async {
    final saleRecord = SaleRecord(
      timestamp: DateTime.now(),
      quantity: quantity,
      price: price,
      revenue: quantity * price,
    );

    await _dataSource.recordSale(SaleRecordModel.fromEntity(saleRecord));

    // Mettre à jour la réputation
    final currentMarket = await getMarket();
    final updatedMarket = currentMarket.copyWith(
        reputation: _calculateSaleReputation(currentMarket, quantity, price)
    );
    await updateMarket(updatedMarket);
  }

  double _calculateSaleReputation(MarketEntity market, int quantity, double price) {
    // Impact positif du prix bas
    double priceImpact = price <= 0.35 ? 0.02 : -0.01;

    // Impact de la satisfaction client
    double customerSatisfactionImpact = quantity * 0.001;

    return (market.reputation + priceImpact + customerSatisfactionImpact)
        .clamp(GameConstants.MIN_REPUTATION, GameConstants.MAX_REPUTATION);
  }

  @override
  Future<double> updateMetalPrice() async {
    final currentMarket = await getMarket();

    // Calcul de la volatilité du prix
    final volatility = currentMarket.dynamics.marketVolatility;
    final trend = currentMarket.dynamics.marketTrend;
    final competitorPressure = currentMarket.dynamics.competitorPressure;

    // Variation de prix
    double priceChange = (Random().nextDouble() * volatility - 0.5) *
        (1 + trend) *
        competitorPressure;

    final newPrice = max(
        GameConstants.MIN_METAL_PRICE,
        min(
            currentMarket.currentMetalPrice * (1 + priceChange),
            GameConstants.MAX_METAL_PRICE
        )
    );

    await _dataSource.updateMetalPrice(newPrice);
    return newPrice;
  }

  @override
  Future<List<SaleRecord>> getSalesHistory() async {
    final salesHistory = await _dataSource.getSalesHistory();
    return salesHistory.map((model) => model.toEntity()).toList();
  }

  @override
  Future<bool> isPriceExcessive(double price) async {
    return price > GameConstants.MAX_PRICE;
  }

  @override
  Future<void> updateMarketConditions() async {
    final currentMarket = await getMarket();
    final updatedDynamics = currentMarket.dynamics.copyWith(
      marketVolatility: 0.8 + (Random().nextDouble() * 0.4),
      marketTrend: -0.2 + (Random().nextDouble() * 0.4),
      competitorPressure: 0.9 + (Random().nextDouble() * 0.2),
    );

    final updatedMarket = currentMarket.copyWith(
        dynamics: updatedDynamics
    );

    await updateMarket(updatedMarket);
  }
}