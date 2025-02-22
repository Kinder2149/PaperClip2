// lib/models/market.dart
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
import 'package:paperclip2/widgets/notification_widgets.dart';



class MarketDynamics {
  double marketVolatility = 1.0;
  double marketTrend = 0.0;
  double competitorPressure = 1.0;

  Map<String, dynamic> toJson() => {
    'marketVolatility': marketVolatility,
    'marketTrend': marketTrend,
    'competitorPressure': competitorPressure,
  };

  void fromJson(Map<String, dynamic> json) {
    marketVolatility = (json['marketVolatility'] as num?)?.toDouble() ?? 1.0;
    marketTrend = (json['marketTrend'] as num?)?.toDouble() ?? 0.0;
    competitorPressure = (json['competitorPressure'] as num?)?.toDouble() ?? 1.0;
  }



  void updateMarketConditions() {
    marketVolatility = 0.8 + (Random().nextDouble() * 0.4);
    marketTrend = -0.2 + (Random().nextDouble() * 0.4);
    competitorPressure = 0.9 + (Random().nextDouble() * 0.2);
  }

  double getMarketConditionMultiplier() {
    return marketVolatility * (1 + marketTrend) * competitorPressure;
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
    required this.revenue,
  });
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'quantity': quantity,
    'price': price,
    'revenue': revenue,
  };


  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    return SaleRecord(
      timestamp: DateTime.parse(json['timestamp']),
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      revenue: json['revenue'].toDouble(),
    );
  }
}

class MarketSegment {
  final String name;
  final double elasticity;
  final double maxPrice;
  final double marketShare;

  const MarketSegment(
      this.name,
      this.elasticity,
      this.maxPrice,
      this.marketShare
      );
}


class CachedValue {
  final dynamic value;
  final DateTime expiryTime;
  static const Duration CACHE_DURATION = Duration(milliseconds: 500);

  CachedValue(this.value) : expiryTime = DateTime.now().add(CACHE_DURATION);

  bool get isValid => DateTime.now().isBefore(expiryTime);
}

class MarketManager extends ChangeNotifier {
  final MarketDynamics dynamics;
  final Random _random = Random();
  final Map<String, CachedValue> _cache = {};
  double _marketingBonus = 1.0;
  final Set<String> _sentNotifications = {};
  bool _hasTriggeredDepletion = false;
  BuildContext? _context;
  final Set<String> _sentCrisisNotifications = {};  // Ajoutez cette ligne
  final Set<String> _sentDepletionNotifications = {};
  double _lastNotifiedPercentage = 100.0;
  static const double MARKET_25_PERCENT = GameConstants.INITIAL_MARKET_METAL *
      0.25;

  void setContext(BuildContext context) {
    _context = context;
  }


  List<SaleRecord> salesHistory = [];
  double reputation = 1.0;
  double marketMetalStock = GameConstants.INITIAL_MARKET_METAL;
  int _gameStartDay = DateTime
      .now()
      .millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
  double _difficultyMultiplier = GameConstants.BASE_DIFFICULTY;
  double _currentMetalPrice = GameConstants.MIN_METAL_PRICE;
  double _currentPrice = 1.0;
  double _competitionPrice = GameConstants.INITIAL_PRICE;
  double _marketSaturation = 100.0;

  double get currentMetalPrice => _currentMetalPrice;
  bool _isPaused = false;

  double get currentPrice => _currentPrice;

  double get competitionPrice => _competitionPrice;

  double get marketSaturation => _marketSaturation;


  static const double MARKET_DEPLETION_THRESHOLD = 750.0;
  static const double MIN_PRICE = GameConstants.MIN_PRICE;
  static const double MAX_PRICE = GameConstants.MAX_PRICE;

  Map<String, MarketSegment> _segments = {
    'budget': MarketSegment('Budget', -2.0, 0.25, 0.4),
    'standard': MarketSegment('Standard', -1.5, 0.50, 0.4),
    'premium': MarketSegment('Premium', -1.0, 1.00, 0.2),
  };

  MarketManager(this.dynamics);

  Map<String, dynamic> toJson() =>
      {
        'marketMetalStock': marketMetalStock,
        'reputation': reputation,
        'currentMetalPrice': _currentMetalPrice,
        'competitionPrice': _competitionPrice,
        'marketSaturation': _marketSaturation,
        'sentDepletionNotifications': List<String>.from(
            _sentDepletionNotifications),
        'lastNotifiedPercentage': _lastNotifiedPercentage,
        'dynamics': {
          'marketVolatility': dynamics.marketVolatility,
          'marketTrend': dynamics.marketTrend,
          'competitorPressure': dynamics.competitorPressure,
        },
        'salesHistory': salesHistory.map((sale) => sale.toJson()).toList(),
      };

  void fromJson(Map<String, dynamic> json) {
    marketMetalStock = (json['marketMetalStock'] as num?)?.toDouble() ??
        GameConstants.INITIAL_MARKET_METAL;
    reputation = (json['reputation'] as num?)?.toDouble() ?? 1.0;
    _currentMetalPrice = (json['currentMetalPrice'] as num?)?.toDouble() ??
        GameConstants.MIN_METAL_PRICE;
    _competitionPrice = (json['competitionPrice'] as num?)?.toDouble() ??
        GameConstants.INITIAL_PRICE;
    _marketSaturation = (json['marketSaturation'] as num?)?.toDouble() ?? 100.0;

    if (json['dynamics'] != null) {
      final dynamicsData = json['dynamics'] as Map<String, dynamic>;
      dynamics.marketVolatility =
          (dynamicsData['marketVolatility'] as num?)?.toDouble() ?? 1.0;
      dynamics.marketTrend =
          (dynamicsData['marketTrend'] as num?)?.toDouble() ?? 0.0;
      dynamics.competitorPressure =
          (dynamicsData['competitorPressure'] as num?)?.toDouble() ?? 1.0;
    }

    if (json['salesHistory'] != null) {
      salesHistory = (json['salesHistory'] as List)
          .map((saleJson) =>
          SaleRecord.fromJson(saleJson as Map<String, dynamic>))
          .toList();
      _sentDepletionNotifications.clear();
      _sentDepletionNotifications.addAll(
          (json['sentDepletionNotifications'] as List<dynamic>?)?.cast<
              String>() ?? []
      );
      _lastNotifiedPercentage =
          (json['lastNotifiedPercentage'] as num?)?.toDouble() ?? 100.0;
    }
  }

  void updateMarketStock(double amount) {
    double previousStock = marketMetalStock;
    marketMetalStock = (marketMetalStock + amount)
        .clamp(0.0, GameConstants.INITIAL_MARKET_METAL);

    // Vérifier le déclenchement de la crise
    if (marketMetalStock <= 0 && previousStock > 0 && !_hasTriggeredDepletion) {
      _hasTriggeredDepletion = true;
      print('Déclenchement mode crise - Stock épuisé');
      _sendCrisisNotification('0');
    }

    notifyListeners();
  }
  

  void updateMarketingBonus(int marketingLevel) {
    _marketingBonus =
        1.0 + (marketingLevel * GameConstants.MARKETING_UPGRADE_BASE);
    notifyListeners();
  }

  double getSaleMultiplier() {
    return _marketingBonus;
  }


  double updateMetalPrice() {
    dynamics.updateMarketConditions();
    double variation = (Random().nextDouble() * 4) - 2;
    _currentMetalPrice = (_currentMetalPrice + variation)
        .clamp(GameConstants.MIN_METAL_PRICE, GameConstants.MAX_METAL_PRICE);
    return _currentMetalPrice;
  }


  bool isPriceExcessive(double price) {
    return price > _currentMetalPrice * 2;
  }

  String getPriceRecommendation() {
    return "Prix recommandé : ${(_currentMetalPrice * 1.5).toStringAsFixed(2)}";
  }

  bool canSellMetal(double quantity, int maxMetalStorage,
      double currentPlayerMetal) {
    return marketMetalStock >= quantity &&
        (currentPlayerMetal + quantity) <= maxMetalStorage;
  }

  bool sellMetal(double quantity, int maxMetalStorage, {
    required double currentPlayerMetal,
    required double currentMetalPrice,
    required Function(double) addMetal,
    required Function(double) subtractMoney
  }) {
    // Vérifie si le marché a assez de métal
    if (marketMetalStock < quantity) {
      return false;  // Pas assez de métal dans le marché
    }

    // Vérifie si le joueur peut stocker le métal
    if ((currentPlayerMetal + quantity) > maxMetalStorage) {
      return false;  // Capacité de stockage dépassée
    }

    marketMetalStock -= quantity;
    addMetal(quantity);
    subtractMoney(quantity * currentMetalPrice);
    _checkMarketDepletion();
    notifyListeners();
    return true;
  }

  void _checkMarketDepletion() {
    print('Vérification des seuils de crise'); // Debug
    print('Stock actuel: $marketMetalStock'); // Debug
    print('Notifications déjà envoyées: $_sentCrisisNotifications'); // Debug

    if (!_sentCrisisNotifications.contains('0') &&
        marketMetalStock <= GameConstants.METAL_CRISIS_THRESHOLD_0) {
      print('Déclenchement notification crise - 0%'); // Debug
      _sendCrisisNotification('0');
    }
  }

  void _sendCrisisNotification(String level) {
    if (_sentCrisisNotifications.contains(level)) return;
    _sentCrisisNotifications.add(level);

    EventManager.instance.addEvent(
        EventType.RESOURCE_DEPLETION,
        "Stock Mondial Épuisé",
        description: "Les réserves mondiales de métal sont épuisées.\nActivez la production de métal !",
        importance: EventImportance.CRITICAL,
        additionalData: {'crisisLevel': '0'}
    );
  }


  void resetCrisisNotifications() {
    _sentCrisisNotifications.clear();
  }



  void resetDepletionNotifications() {
    _sentDepletionNotifications.clear();
    _lastNotifiedPercentage = 100.0;
  }
  void resetNotifications() {
    _sentNotifications.clear();
  }

  bool isMarketDepletedForNextPhase() {
    return marketMetalStock <= MARKET_DEPLETION_THRESHOLD;
  }

  void triggerNextPhaseTransition() {
    if (isMarketDepletedForNextPhase()) {
      print("Les réserves de métal du marché s'épuisent. Nouvelle stratégie requise !");
    }
  }
  void reset() {
    marketMetalStock = GameConstants.INITIAL_MARKET_METAL;
    resetDepletionNotifications();
    reputation = 1.0;
    _currentMetalPrice = GameConstants.MIN_METAL_PRICE;
    _currentPrice = 1.0;
    _competitionPrice = GameConstants.INITIAL_PRICE;
    _marketSaturation = 100.0;
    salesHistory.clear();
    dynamics.marketVolatility = 1.0;
    dynamics.marketTrend = 0.0;
    dynamics.competitorPressure = 1.0;
    notifyListeners();
  }



  double _calculatePriceElasticity(double price) {
    if (price <= 0.25) return -1.0;
    if (price <= 0.50) return -2.0;
    return -3.0;
  }

  double _calculateBaseDemand(double price) {
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

    return _marketSaturation * exp(elasticity * (price / GameConstants.OPTIMAL_PRICE_LOW));
  }

  double _calculateReputationFactor(double price) {
    return max(0.1, 1.0 - (price - 0.25) * 0.5) * reputation;
  }

  double _calculateCompetitionFactor(double price) {
    return max(0.1, 1.0 - (price / _competitionPrice - 1.0));
  }

  double calculateDemand(double price, int marketingLevel) {
    // Cache pour optimiser les calculs fréquents
    final cacheKey = 'demand_${price}_$marketingLevel';
    final cached = _cache[cacheKey];

    if (cached != null && cached.isValid) {
      return cached.value as double;
    }

    double baseDemand = _calculateBaseDemand(price);
    double marketingBonus = 1.0 + (marketingLevel * 0.30); // +30% par niveau
    double reputationFactor = _calculateReputationImpact(price);
    double finalDemand = baseDemand * marketingBonus * reputationFactor;

    // Mise en cache du résultat
    _cache[cacheKey] = CachedValue(finalDemand);

    return finalDemand;
  }

// Ajouter une méthode de nettoyage du cache
  void _cleanCache() {
    _cache.removeWhere((_, value) => !value.isValid);
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

  double _calculateDifficultyFactor() {
    return 1.0 / _difficultyMultiplier;
  }

  void _updateDifficultyMultiplier() {
    int currentDay = DateTime.now().millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
    int monthsPassed = (currentDay - _gameStartDay) ~/ 30;
    _difficultyMultiplier = GameConstants.BASE_DIFFICULTY +
        (monthsPassed * GameConstants.DIFFICULTY_INCREASE_PER_MONTH);
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
    double priceImpact = price <= 0.35 ? 0.02 : -0.01;
    double customerSatisfactionImpact = satisfiedCustomers * 0.001;
    reputation = (reputation + priceImpact + customerSatisfactionImpact).clamp(0.0, 2.0);
  }

  void updateMarket() {
    if (_isPaused) return;

    dynamics.updateMarketConditions();
    updateMetalPrice();  // Changer _updateMetalPrice en updateMetalPrice
    _checkMarketDepletion();

    if (marketMetalStock <= GameConstants.WARNING_THRESHOLD) {  // Utiliser marketMetalStock au lieu de _marketMetalStock
      EventManager.instance.addEvent(
          EventType.RESOURCE_DEPLETION,
          'Rupture Imminente des Stocks de Métal',
          description: 'Les réserves de métal du marché sont presque épuisées.',
          importance: EventImportance.CRITICAL
      );
    }
  }
  void _checkResourceLevels() {
    if (marketMetalStock <= GameConstants.WARNING_THRESHOLD) {
      EventManager.instance.addEvent(
          EventType.RESOURCE_DEPLETION,
          "Ressources en diminution",
          description: "Les réserves mondiales de métal s'amenuisent",
          importance: EventImportance.HIGH
      );
    }
  }

  void updateMarketConditions() {
    _competitionPrice = GameConstants.INITIAL_PRICE *
        (0.8 + Random().nextDouble() * 0.4);

    _marketSaturation = max(50, _marketSaturation +
        (Random().nextDouble() - 0.5) * 10);

    _checkForMarketEvent();
  }

  void _checkForMarketEvent() {
    if (Random().nextDouble() < 0.05) {
      final event = MarketEvent.values[
      Random().nextInt(MarketEvent.values.length)
      ];
      _handleMarketEvent(event);
    }
  }

  // Dans la classe MarketManager, modifier _handleMarketEvent
  void _handleMarketEvent(MarketEvent event) {
    switch (event) {
      case MarketEvent.PRICE_WAR:
        _competitionPrice *= 0.8;
        break;
      case MarketEvent.DEMAND_SPIKE:
        _marketSaturation *= 1.5;
        break;
      case MarketEvent.MARKET_CRASH:
        _competitionPrice *= 0.6;
        _marketSaturation *= 0.7;
        break;
      case MarketEvent.QUALITY_CONCERNS:
        reputation *= 0.9;
        break;
    }

    // Ajouter la notification de crise
    EventManager.instance.addCrisisNotification(event);

    notifyListeners();
  }


  String _getEventTitle(MarketEvent event) {
    switch (event) {
      case MarketEvent.PRICE_WAR:
        return "Guerre des Prix!";
      case MarketEvent.DEMAND_SPIKE:
        return "Pic de Demande!";
      case MarketEvent.MARKET_CRASH:
        return "Krach du Marché!";
      case MarketEvent.QUALITY_CONCERNS:
        return "Problèmes de Qualité";
    }
  }

  String _getEventDescription(MarketEvent event) {
    switch (event) {
      case MarketEvent.PRICE_WAR:
        return "Les concurrents baissent leurs prix agressivement";
      case MarketEvent.DEMAND_SPIKE:
        return "La demande en trombones explose!";
      case MarketEvent.MARKET_CRASH:
        return "Le marché s'effondre, les prix chutent";
      case MarketEvent.QUALITY_CONCERNS:
        return "Des inquiétudes sur la qualité affectent la réputation";
    }
  }

  double _calculateSeasonalityFactor() {
    DateTime now = DateTime.now();
    switch (now.month) {
      case 12:
      case 1:
        return 1.2;
      case 7:
      case 8:
        return 0.8;
      default:
        return 1.0;
    }
  }

  double _calculateCompetitivePressure() {
    return _random.nextDouble() * 0.2;
  }

  double _calculateHistoricalElasticityModifier() {
    if (salesHistory.isEmpty) return 0;
    int recentSales = salesHistory.length;
    return log(recentSales + 1) * 0.1;
  }

  double recommendPricing(double currentPrice, double demand) {
    double adjustmentFactor = 1 + ((demand - 50) / 100);
    return currentPrice * adjustmentFactor;
  }
}
