import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'game_config.dart';
import 'event_system.dart';
import 'resource_manager.dart';
import '../dialogs/metal_crisis_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_state.dart';
import '../widgets/notification_widgets.dart';

class MarketDynamics {
  double volatility;
  double trend;
  double competitorPressure;
  DateTime lastUpdate;

  MarketDynamics({
    this.volatility = GameConstants.MARKET_VOLATILITY,
    this.trend = 0.0,
    this.competitorPressure = 0.0,
  }) : lastUpdate = DateTime.now();

  Map<String, dynamic> toJson() => {
    'volatility': volatility,
    'trend': trend,
    'competitorPressure': competitorPressure,
    'lastUpdate': lastUpdate.toIso8601String(),
  };

  factory MarketDynamics.fromJson(Map<String, dynamic> json) {
    return MarketDynamics(
      volatility: (json['volatility'] as num?)?.toDouble() ?? GameConstants.MARKET_VOLATILITY,
      trend: (json['trend'] as num?)?.toDouble() ?? 0.0,
      competitorPressure: (json['competitorPressure'] as num?)?.toDouble() ?? 0.0,
    )..lastUpdate = DateTime.parse(json['lastUpdate'] as String);
  }

  void updateMarketConditions() {
    volatility = 0.8 + (Random().nextDouble() * 0.4);
    trend = -0.2 + (Random().nextDouble() * 0.4);
    competitorPressure = 0.9 + (Random().nextDouble() * 0.2);
  }

  double getMarketConditionMultiplier() {
    return volatility * (1 + trend) * competitorPressure;
  }
}

class SaleRecord {
  final DateTime timestamp;
  final int quantity;
  final double price;
  final double revenue;

  SaleRecord({
    required this.timestamp,
    required this.quantity,
    required this.price,
  }) : revenue = quantity * price;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'quantity': quantity,
    'price': price,
    'revenue': revenue,
  };

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    return SaleRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }
}

class MarketSegment {
  final String name;
  final double elasticity;
  final double maxPrice;
  final double marketShare;
  final double qualityThreshold;

  MarketSegment({
    required this.name,
    required this.elasticity,
    required this.maxPrice,
    required this.marketShare,
    required this.qualityThreshold,
  });

  double calculateDemand(double price, double quality) {
    if (quality < qualityThreshold) return 0;
    final priceRatio = price / maxPrice;
    return marketShare * (1 - pow(priceRatio, elasticity));
  }
}

class CachedValue<T> {
  T value;
  DateTime lastUpdate;
  Duration validityDuration;

  CachedValue(this.value, this.validityDuration) : lastUpdate = DateTime.now();

  bool get isValid => DateTime.now().difference(lastUpdate) < validityDuration;

  void update(T newValue) {
    value = newValue;
    lastUpdate = DateTime.now();
  }
}

class MarketManager extends ChangeNotifier {
  final MarketDynamics _dynamics;
  double _marketMetalStock;
  double _currentMetalPrice;
  double _reputation;
  final List<SaleRecord> _salesHistory;
  int _marketingLevel;
  final Random _random;
  final List<MarketSegment> _segments;

  // Cache pour les calculs coûteux
  late CachedValue<double> _cachedDemand;
  late CachedValue<double> _cachedMarketSaturation;

  MarketManager(this._dynamics)
      : _marketMetalStock = GameConstants.INITIAL_MARKET_STOCK,
        _currentMetalPrice = GameConstants.BASE_METAL_PRICE,
        _reputation = 1.0,
        _salesHistory = [],
        _marketingLevel = 0,
        _random = Random(),
        _segments = [
          MarketSegment(
            name: 'Budget',
            elasticity: 2.0,
            maxPrice: 0.3,
            marketShare: 0.4,
            qualityThreshold: 0.5,
          ),
          MarketSegment(
            name: 'Standard',
            elasticity: 1.5,
            maxPrice: 0.6,
            marketShare: 0.4,
            qualityThreshold: 0.7,
          ),
          MarketSegment(
            name: 'Premium',
            elasticity: 1.0,
            maxPrice: 1.0,
            marketShare: 0.2,
            qualityThreshold: 0.9,
          ),
        ] {
    _initializeCachedValues();
  }

  void _initializeCachedValues() {
    _cachedDemand = CachedValue(0.0, const Duration(seconds: 5));
    _cachedMarketSaturation = CachedValue(1.0, const Duration(minutes: 1));
  }

  // Getters
  double get marketMetalStock => _marketMetalStock;
  double get currentMetalPrice => _currentMetalPrice;
  double get reputation => _reputation;
  List<SaleRecord> get salesHistory => List.unmodifiable(_salesHistory);
  int get marketingLevel => _marketingLevel;
  MarketDynamics get dynamics => _dynamics;

  void updateMarket() {
    final now = DateTime.now();
    final timeDelta = now.difference(_dynamics.lastUpdate).inSeconds / 3600;

    // Mise à jour des dynamiques de marché
    _updateMarketDynamics(timeDelta);

    // Mise à jour du stock et du prix
    _updateStockAndPrice();

    // Mise à jour de la réputation
    _updateReputation();

    _dynamics.lastUpdate = now;
    notifyListeners();
  }

  void _updateMarketDynamics(double timeDelta) {
    // Mise à jour de la tendance
    _dynamics.trend += _random.nextDouble() * 2 - 1;
    _dynamics.trend *= 0.95; // Amortissement

    // Mise à jour de la pression concurrentielle
    _dynamics.competitorPressure = sin(DateTime.now().millisecondsSinceEpoch / 1000000) * 0.5;

    // Mise à jour de la volatilité
    _dynamics.volatility = max(
      GameConstants.MARKET_VOLATILITY * 0.5,
      min(
        GameConstants.MARKET_VOLATILITY * 2,
        _dynamics.volatility + (_random.nextDouble() * 0.1 - 0.05),
      ),
    );
  }

  void _updateStockAndPrice() {
    // Calculer les variations de stock
    final stockVariation = _calculateStockVariation();
    _marketMetalStock = max(
      GameConstants.MIN_MARKET_STOCK,
      min(
        GameConstants.MAX_MARKET_STOCK,
        _marketMetalStock + stockVariation,
      ),
    );

    // Calculer le nouveau prix
    final priceVariation = _calculatePriceVariation();
    final newPrice = _currentMetalPrice * (1 + priceVariation);
    _currentMetalPrice = max(
      GameConstants.MIN_METAL_PRICE,
      min(GameConstants.MAX_METAL_PRICE, newPrice),
    );

    // Vérifier les conditions de crise
    _checkMarketConditions();
  }

  double _calculateStockVariation() {
    final baseVariation = _random.nextDouble() * 100 - 50;
    final trendEffect = _dynamics.trend * 20;
    final competitorEffect = _dynamics.competitorPressure * 30;
    return baseVariation + trendEffect + competitorEffect;
  }

  double _calculatePriceVariation() {
    final stockEffect = (_marketMetalStock - GameConstants.INITIAL_MARKET_STOCK) / GameConstants.INITIAL_MARKET_STOCK;
    final volatilityEffect = (_random.nextDouble() * 2 - 1) * _dynamics.volatility;
    final trendEffect = _dynamics.trend * 0.1;
    return stockEffect * -0.1 + volatilityEffect + trendEffect;
  }

  void _checkMarketConditions() {
    // Vérifier les conditions de prix
    if (_currentMetalPrice > GameConstants.MAX_METAL_PRICE * 0.9) {
      EventManager.instance.addMarketEvent(
        MarketEventType.PRICE_SPIKE,
        _currentMetalPrice,
        'Les prix du métal atteignent des sommets !',
      );
    } else if (_currentMetalPrice < GameConstants.MIN_METAL_PRICE * 1.2) {
      EventManager.instance.addMarketEvent(
        MarketEventType.PRICE_CRASH,
        _currentMetalPrice,
        'Les prix du métal s\'effondrent !',
      );
    }

    // Vérifier les conditions de stock
    if (_marketMetalStock < GameConstants.MIN_MARKET_STOCK * 1.2) {
      EventManager.instance.addMarketEvent(
        MarketEventType.STOCK_SHORTAGE,
        _marketMetalStock,
        'Pénurie de métal sur le marché !',
      );
    }
  }

  void _updateReputation() {
    // Décroissance naturelle de la réputation
    _reputation *= GameConstants.REPUTATION_DECAY;

    // Limites de réputation
    _reputation = max(
      GameConstants.MIN_REPUTATION,
      min(GameConstants.MAX_REPUTATION, _reputation),
    );
  }

  void addSaleRecord(int quantity, double price) {
    final record = SaleRecord(
      timestamp: DateTime.now(),
      quantity: quantity,
      price: price,
    );
    _salesHistory.add(record);

    // Limiter l'historique à 1000 ventes
    if (_salesHistory.length > 1000) {
      _salesHistory.removeAt(0);
    }

    // Mettre à jour la réputation en fonction du prix
    final optimalPrice = (GameConstants.OPTIMAL_PRICE_LOW + GameConstants.OPTIMAL_PRICE_HIGH) / 2;
    final priceDifference = (price - optimalPrice).abs() / optimalPrice;
    if (priceDifference < 0.1) {
      _reputation *= 1.01; // Bonus pour un prix proche de l'optimal
    } else if (priceDifference > 0.3) {
      _reputation *= 0.99; // Pénalité pour un prix trop éloigné
    }

    notifyListeners();
  }

  void updateMarketStock(double amount) {
    _marketMetalStock = max(
      GameConstants.MIN_MARKET_STOCK,
      min(GameConstants.MAX_MARKET_STOCK, _marketMetalStock + amount),
    );
    notifyListeners();
  }

  void updateMarketingBonus(int level) {
    _marketingLevel = level;
    notifyListeners();
  }

  double calculateDemand(double price, double quality) {
    if (!_cachedDemand.isValid) {
      double totalDemand = 0;
      for (var segment in _segments) {
        totalDemand += segment.calculateDemand(price, quality);
      }
      _cachedDemand.update(totalDemand * (1 + _marketingLevel * 0.1));
    }
    return _cachedDemand.value;
  }

  double getMarketSaturation() {
    if (!_cachedMarketSaturation.isValid) {
      final saturation = _marketMetalStock / GameConstants.INITIAL_MARKET_STOCK;
      _cachedMarketSaturation.update(saturation);
    }
    return _cachedMarketSaturation.value;
  }

  List<SaleRecord> getRecentSales({int limit = 10}) {
    return _salesHistory.reversed.take(limit).toList();
  }

  double getAveragePrice({Duration? period}) {
    if (_salesHistory.isEmpty) return 0;

    final now = DateTime.now();
    var relevantSales = _salesHistory;

    if (period != null) {
      final cutoff = now.subtract(period);
      relevantSales = _salesHistory.where((sale) => sale.timestamp.isAfter(cutoff)).toList();
    }

    if (relevantSales.isEmpty) return 0;

    final totalRevenue = relevantSales.fold(0.0, (sum, sale) => sum + sale.revenue);
    final totalQuantity = relevantSales.fold(0, (sum, sale) => sum + sale.quantity);

    return totalQuantity > 0 ? totalRevenue / totalQuantity : 0;
  }

  Map<String, dynamic> toJson() => {
    'dynamics': _dynamics.toJson(),
    'marketMetalStock': _marketMetalStock,
    'currentMetalPrice': _currentMetalPrice,
    'reputation': _reputation,
    'marketingLevel': _marketingLevel,
    'salesHistory': _salesHistory.map((sale) => sale.toJson()).toList(),
  };

  void fromJson(Map<String, dynamic> json) {
    _dynamics.volatility = (json['dynamics']['volatility'] as num?)?.toDouble() ?? GameConstants.MARKET_VOLATILITY;
    _dynamics.trend = (json['dynamics']['trend'] as num?)?.toDouble() ?? 0.0;
    _dynamics.competitorPressure = (json['dynamics']['competitorPressure'] as num?)?.toDouble() ?? 0.0;
    _dynamics.lastUpdate = DateTime.parse(json['dynamics']['lastUpdate'] as String);

    _marketMetalStock = (json['marketMetalStock'] as num?)?.toDouble() ?? GameConstants.INITIAL_MARKET_STOCK;
    _currentMetalPrice = (json['currentMetalPrice'] as num?)?.toDouble() ?? GameConstants.BASE_METAL_PRICE;
    _reputation = (json['reputation'] as num?)?.toDouble() ?? 1.0;
    _marketingLevel = (json['marketingLevel'] as num?)?.toInt() ?? 0;

    _salesHistory.clear();
    if (json['salesHistory'] != null) {
      final salesData = json['salesHistory'] as List;
      _salesHistory.addAll(
        salesData.map((sale) => SaleRecord.fromJson(sale as Map<String, dynamic>)),
      );
    }

    notifyListeners();
  }
} 