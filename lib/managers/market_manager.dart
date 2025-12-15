// lib/managers/market_manager.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import '../constants/game_config.dart'; // Mis à jour pour utiliser le dossier constants
import '../models/json_loadable.dart';
import '../models/statistics_manager.dart';
import 'player_manager.dart'; // Import de PlayerManager
import '../services/upgrades/upgrade_effects_calculator.dart';

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
    this.marketShare,
  );
}

class CachedValue {
  final dynamic value;
  final DateTime expiryTime;
  static const Duration CACHE_DURATION = Duration(milliseconds: 500);

  CachedValue(this.value) : expiryTime = DateTime.now().add(CACHE_DURATION);

  bool get isValid => DateTime.now().isBefore(expiryTime);
}

class MarketSaleResult {
  final int quantity;
  final double unitPrice;
  final double revenue;

  const MarketSaleResult({
    required this.quantity,
    required this.unitPrice,
    required this.revenue,
  });

  static const MarketSaleResult none = MarketSaleResult(
    quantity: 0,
    unitPrice: 0.0,
    revenue: 0.0,
  );
}

class MarketManager extends ChangeNotifier implements JsonLoadable {
  // Références aux autres managers
  PlayerManager? _playerManager;
  late StatisticsManager _statisticsManager; // Utilisation de 'late' pour déclarer une variable non-nullable qui sera initialisée plus tard
  
  // Méthode pour initialiser les références aux autres managers
  void setManagers(PlayerManager playerManager, StatisticsManager statisticsManager) {
    _playerManager = playerManager;
    _statisticsManager = statisticsManager;
  }

  final MarketDynamics dynamics = MarketDynamics();
  final Random _random = Random();
  final Map<String, CachedValue> _cache = {};
  double _marketingBonus = 1.0;
  final Set<String> _sentNotifications = {};
  bool _hasTriggeredDepletion = false;
  final Set<String> _sentCrisisNotifications = {};
  final Set<String> _sentDepletionNotifications = {};
  double _lastNotifiedPercentage = 100.0;
  static const double MARKET_25_PERCENT = GameConstants.INITIAL_MARKET_METAL * 0.25;
  bool _isPaused = false;
  
  double _marketMetalStock = GameConstants.INITIAL_MARKET_METAL;
  double _currentPrice = GameConstants.INITIAL_PRICE;  // Prix par défaut
  DateTime? _lastMetalPriceUpdateTime;
  List<MarketEvent> _activeEvents = [];

  List<SaleRecord> salesHistory = [];
  double reputation = 1.0;
  double _currentMarketSaturation = GameConstants.DEFAULT_MARKET_SATURATION;
  double _difficultyMultiplier = GameConstants.BASE_DIFFICULTY;
  double _marketReputation = 1.0;
  double _competitivePressure = 0.0;
  double _marketMetalPrice = GameConstants.MIN_METAL_PRICE;
  double _metalTrend = 0;
  List<double> _salesHistory = [];
  List<double> _priceHistory = [];
  bool _autoSellEnabled = true;

  bool get autoSellEnabled => _autoSellEnabled;

  set autoSellEnabled(bool value) {
    if (_autoSellEnabled == value) return;
    _autoSellEnabled = value;
    if (kDebugMode) {
      print('[MarketManager] autoSellEnabled mis à jour: $_autoSellEnabled');
    }
    notifyListeners();
  }
  List<double> _demandHistory = [];
  DateTime _lastUpdate = DateTime.now();
  // Nous n'utilisons plus de timer périodique
  MarketDynamics _marketDynamics = MarketDynamics();
  double _totalSales = 0;
  int _totalSalesCount = 0;
  double _averageSalePrice = 0;
  double _highestSalePrice = 0.0;

  double get totalSalesRevenue => _totalSales;
  int get totalSalesCount => _totalSalesCount;
  double get averageSalePrice => _averageSalePrice;
  double get highestSalePrice => _highestSalePrice;

  double get currentMetalPrice => _marketMetalPrice;

  void togglePause() {
    _isPaused = !_isPaused;
  }

  void startMarketUpdates() {
    // Nous ne créons pas de timer périodique car les ventes seront désormais
    // déclenchées directement par les changements dans les conditions du marché
    
    // Appel initial pour configurer le marché
    dynamics.updateMarketConditions();
    
    if (kDebugMode) {
      print('[MarketManager] Le système de mise à jour du marché est initialisé (mode basé sur événements)');
    }
  }
  
  void stopMarketUpdates() {
    // Rien à arrêter car nous n'utilisons plus de timer
    if (kDebugMode) {
      print('[MarketManager] stopMarketUpdates appelé (pas de timer à arrêter)');
    }
  }

  void updateMarketStock(double newStock) {
    _marketMetalStock = newStock;
    updateMetalPrice();
    notifyListeners();
  }

  void updateSellPrice(double price) {
    _currentPrice = price;
    // Un changement du prix de vente peut déclencher des changements dans les conditions du marché
    dynamics.updateMarketConditions();
    notifyListeners();
  }
  
  // Setter pour le marketMetalPrice (pour les événements spéciaux)
  set marketMetalPrice(double price) {
    // Après un changement manuel du prix, mettons à jour les conditions du marché
    bool hasChanged = _marketMetalPrice != price;
    
    _marketMetalPrice = price;
    if (hasChanged) {
      // Un changement significatif du prix peut déclencher des changements dans les conditions du marché
      dynamics.updateMarketConditions();
    }
    notifyListeners();
  }

  void updateMetalPrice() {
    double stockRatio = _marketMetalStock / GameConstants.INITIAL_MARKET_METAL;
    double priceRange = GameConstants.MAX_METAL_PRICE - GameConstants.MIN_METAL_PRICE;

    _marketMetalPrice = GameConstants.MAX_METAL_PRICE - (stockRatio * priceRange);

    if (_marketMetalPrice < GameConstants.MIN_METAL_PRICE) {
      _marketMetalPrice = GameConstants.MIN_METAL_PRICE;
    } else if (_marketMetalPrice > GameConstants.MAX_METAL_PRICE) {
      _marketMetalPrice = GameConstants.MAX_METAL_PRICE;
    }

    _lastMetalPriceUpdateTime = DateTime.now();
    notifyListeners();
  }

  bool isPriceExcessive(double price) {
    return price > GameConstants.MAX_PRICE * 1.5;
  }

  String getPriceRecommendation() {
    double optimalLow = GameConstants.OPTIMAL_PRICE_LOW;
    double optimalHigh = GameConstants.OPTIMAL_PRICE_HIGH;

    return "Le prix optimal se situe entre $optimalLow€ et $optimalHigh€ par trombone.";
  }

  bool isInCrisisMode() {
    return _marketMetalStock <= GameConstants.METAL_CRISIS_THRESHOLD_25;
  }

  MarketEvent getCurrentMarketEvent() {
    if (_marketMetalStock <= GameConstants.METAL_CRISIS_THRESHOLD_0) {
      return MarketEvent.MARKET_CRASH;
    } else if (_marketMetalStock <= GameConstants.METAL_CRISIS_THRESHOLD_25) {
      return MarketEvent.PRICE_WAR;
    } else if (_marketMetalStock <= GameConstants.METAL_CRISIS_THRESHOLD_50) {
      return MarketEvent.QUALITY_CONCERNS;
    } else {
      return MarketEvent.DEMAND_SPIKE;
    }
  }

  MarketSaleResult processSales({
    required double playerPaperclips,
    required double sellPrice,
    required int marketingLevel,
    required int qualityLevel,
    required void Function(double paperclipsDelta) updatePaperclips,
    required void Function(double moneyDelta) updateMoney,
    bool updateMarketState = true,
    bool requireAutoSellEnabled = true,
    bool verboseLogs = false,
  }) {
    if (_isPaused) {
      if (kDebugMode) print('[MarketManager] processSales: Ignoré - Le marché est en pause');
      return MarketSaleResult.none;
    }

    if (requireAutoSellEnabled && !_autoSellEnabled) {
      if (kDebugMode) {
        print('[MarketManager] processSales: Ignoré - Vente automatique désactivée');
      }
      return MarketSaleResult.none;
    }

    // Logs détaillés sur les conditions initiales
    if (kDebugMode && verboseLogs) {
      print('===== PROCESSUS DE VENTE =====');
      print('[MarketManager] État initial: ${playerPaperclips.toStringAsFixed(1)} trombones, prix de vente: ${sellPrice.toStringAsFixed(2)}, niveau marketing: $marketingLevel');
      print('[MarketManager] État marché: saturation: ${_currentMarketSaturation.toStringAsFixed(2)}, prix métal: ${_marketMetalPrice.toStringAsFixed(2)}');
    }

    if (updateMarketState) {
      _updateMarketState();
    }

    double demand = calculateDemand(sellPrice, marketingLevel);

    // Log de la demande calculée
    if (kDebugMode && verboseLogs) {
      print('[MarketManager] Demande calculée: ${demand.toStringAsFixed(1)} unités');
    }

    if (playerPaperclips > 0) {
      final int demandUnits = max(0, demand.floor());
      int potentialSales = min(demandUnits, playerPaperclips.floor());

      if (kDebugMode && verboseLogs) {
        print('[MarketManager] Ventes potentielles: $potentialSales unités');
      }

      if (potentialSales > 0) {
        final qualityBonus = UpgradeEffectsCalculator.qualityMultiplier(level: qualityLevel);
        final salePrice = sellPrice * qualityBonus;
        final revenue = potentialSales * salePrice;

        // Logs détaillés de la transaction
        if (kDebugMode && verboseLogs) {
          print('[MarketManager] Bonus qualité: x${qualityBonus.toStringAsFixed(2)}');
          print('[MarketManager] Prix de vente effectif: ${salePrice.toStringAsFixed(2)}');
          print('[MarketManager] Transaction: -$potentialSales trombones, +${revenue.toStringAsFixed(2)} argent');
        }

        updatePaperclips(-potentialSales.toDouble());
        updateMoney(revenue);
        recordSale(potentialSales, salePrice);

        _statisticsManager.updateEconomics(
          moneyEarned: revenue,
          // Retrait des paramètres sales et price non supportés
        );
        
        if (kDebugMode && verboseLogs) {
          print('[MarketManager] Statistiques mises à jour: ${_totalSalesCount} ventes totales, ${_totalSales.toStringAsFixed(2)} revenus cumulés');
          print('===== FIN PROCESSUS DE VENTE =====');
        }

        return MarketSaleResult(
          quantity: potentialSales,
          unitPrice: salePrice,
          revenue: revenue,
        );
      } else {
        if (kDebugMode) print('[MarketManager] Aucune vente possible - demande insuffisante');
      }
    } else {
      if (kDebugMode) print('[MarketManager] Aucune vente possible - pas de stock de trombones');
    }

    return MarketSaleResult.none;
  }

  @Deprecated('Utiliser processSales(...) comme chemin officiel de vente (Option B2).')
  double sellPaperclips({
    required double amount,
    required double sellPrice,
    required Function(double) updatePaperclips,
    required Function(double) updateMoney,
  }) {
    if (amount <= 0) return 0.0;

    double qualityBonus = 1.0 + (sellPrice * 0.10);
    double salePrice = sellPrice * qualityBonus;
    double revenue = amount * salePrice;

    updatePaperclips(-amount);
    updateMoney(revenue);
    recordSale(amount.floor(), salePrice);

    try {
      // Essayer d'appeler updateEconomics avec les paramètres spécifiés
      _statisticsManager.updateEconomics(
        moneyEarned: revenue,
        // Retrait des paramètres non supportés
      );
    } catch (e) {
      // En cas d'erreur, essayer un appel alternatif ou simplement logger l'erreur
      if (kDebugMode) {
        print('[MarketManager] Erreur lors de la mise à jour des statistiques: $e');
        print('[MarketManager] La vente a quand même été enregistrée avec succès');
      }
      // Tenter d'utiliser une signature alternative si disponible
      try {
        _statisticsManager.updateEconomics(moneyEarned: revenue);
      } catch (e2) {
        // Si ça échoue aussi, on ignore simplement
      }
    }
    
    return revenue;
  }

  void _updateMarketState() {
    // Mise à jour des tendances du marché
    final now = DateTime.now();
    _lastMetalPriceUpdateTime = now;
    _lastUpdate = now;

    // Mise à jour des dynamiques du marché
    dynamics.updateMarketConditions();

    // Mise à jour de la saturation du marché
    if (_currentMarketSaturation < GameConstants.DEFAULT_MARKET_SATURATION) {
      _currentMarketSaturation += GameConstants.SATURATION_DECAY_RATE;
      if (_currentMarketSaturation > GameConstants.DEFAULT_MARKET_SATURATION) {
        _currentMarketSaturation = GameConstants.DEFAULT_MARKET_SATURATION;
      }
    }

    if (_currentMarketSaturation < GameConstants.MIN_MARKET_SATURATION) {
      _currentMarketSaturation = GameConstants.MIN_MARKET_SATURATION;
    }

    // Mise à jour du prix du métal en fonction du stock
    updateMetalPrice();
  }

  /// Met à jour l'état du marché (tendances, saturation, prix métal), sans exécuter de vente.
  void updateMarketState() {
    if (_isPaused) {
      if (kDebugMode) {
        print('[MarketManager] updateMarketState: Le marché est en pause, pas de mise à jour');
      }
      return;
    }

    if (kDebugMode) {
      print('[MarketManager] Début updateMarketState() - ${DateTime.now()}');
    }

    _updateMarketState();
    notifyListeners();

    if (kDebugMode) {
      print('[MarketManager] Fin updateMarketState()');
    }
  }

  @Deprecated('Utiliser updateMarketState() + processSales(...) (Option B2).')
  void updateMarket() {
    updateMarketState();
  }

  double calculateDemand(double price, int marketingLevel) {
    // Calcul de la demande basé sur le prix de vente, la saturation du marché
    // et le niveau de marketing
    double baselineDemand = GameConstants.BASE_DEMAND;
    
    // Réduction de la demande si le prix est trop élevé
    double priceMultiplier = max(0.1, 1.0 - (price / GameConstants.MAX_PRICE_THRESHOLD));
    
    // Bonus de marketing (chaque niveau augmente la demande de 10%)
    double marketingMultiplier = 1.0 + (marketingLevel * GameConstants.MARKETING_BOOST_PER_LEVEL);
    
    // Facteur de saturation du marché
    double saturationFactor = _currentMarketSaturation / GameConstants.DEFAULT_MARKET_SATURATION;
    
    // La demande est fonction de tous ces facteurs
    final reputationFactor = max(0.0, reputation);
    double demand = baselineDemand *
        priceMultiplier *
        marketingMultiplier *
        saturationFactor *
        reputationFactor;
    
    // Utilise la dynamique du marché pour les fluctuations
    double marketConditionEffect = _marketDynamics.getMarketConditionMultiplier();
    
    return demand * marketConditionEffect;
  }

  void recordSale(int amount, double price) {
    if (amount <= 0) return;
    
    // Créer un enregistrement de vente avec l'horodatage actuel
    SaleRecord record = SaleRecord(
      timestamp: DateTime.now(),
      quantity: amount,
      price: price,
      revenue: amount * price,
    );
    
    // Ajouter à l'historique des ventes
    salesHistory.add(record);
    
    // Limiter la taille de l'historique pour éviter une utilisation excessive de mémoire
    if (salesHistory.length > GameConstants.MAX_SALES_HISTORY) {
      salesHistory.removeAt(0);  // Supprimer l'entrée la plus ancienne
    }
    
    // Mise à jour des statistiques de vente
    _totalSales += amount * price;
    _totalSalesCount += amount;
    _averageSalePrice = _totalSalesCount > 0 ? _totalSales / _totalSalesCount : 0.0;
    
    // Mettre à jour le prix de vente le plus élevé si nécessaire
    if (price > _highestSalePrice) {
      _highestSalePrice = price;
    }
    
    // Ajuster la saturation du marché après une vente
    _currentMarketSaturation -= (amount * GameConstants.SATURATION_IMPACT_PER_SALE);
    if (_currentMarketSaturation < GameConstants.MIN_MARKET_SATURATION) {
      _currentMarketSaturation = GameConstants.MIN_MARKET_SATURATION;
    }
    
    // Notifier les écouteurs des changements
    notifyListeners();
  }

  // Getters manquants
  double get currentPrice => _currentPrice;
  bool get isActive => !_isPaused;
  DateTime? get lastMetalPriceUpdateTime => _lastMetalPriceUpdateTime;
  set lastMetalPriceUpdateTime(DateTime? value) {
    _lastMetalPriceUpdateTime = value;
    notifyListeners();
  }
  double get marketMetalPrice => _marketMetalPrice;
  double get marketMetalStock => _marketMetalStock;
  
  // Alias pour reset (utilisé dans GameState)
  void reset() {
    // Réinitialisation de toutes les propriétés
    _marketMetalStock = GameConstants.INITIAL_MARKET_METAL;
    _currentPrice = GameConstants.INITIAL_PRICE;
    _marketMetalPrice = GameConstants.MIN_METAL_PRICE;
    _currentMarketSaturation = GameConstants.DEFAULT_MARKET_SATURATION;
    _lastMetalPriceUpdateTime = DateTime.now();
    _activeEvents.clear();
    notifyListeners();
  }
  
  /// Réinitialise la saturation du marché à sa valeur par défaut pour garantir la demande
  void resetMarketSaturation() {
    _currentMarketSaturation = GameConstants.DEFAULT_MARKET_SATURATION;
    if (kDebugMode) {
      print('[MarketManager] Saturation du marché réinitialisée à ${_currentMarketSaturation.toStringAsFixed(2)}');
    }
  }
  
  Map<String, dynamic> toJson() => {
    'marketMetalStock': _marketMetalStock,
    'currentPrice': _currentPrice,
    'marketMetalPrice': _marketMetalPrice,
    'lastMetalPriceUpdateTime': _lastMetalPriceUpdateTime?.toIso8601String(),
    'isPaused': _isPaused,
    'currentMarketSaturation': _currentMarketSaturation,
    'totalSales': _totalSales,
    'totalSalesCount': _totalSalesCount,
    'averageSalePrice': _averageSalePrice,
    'reputation': reputation,
    'marketDynamics': _marketDynamics.toJson(),
  };

  void fromJson(Map<String, dynamic> json) {
    _marketMetalStock = (json['marketMetalStock'] as num?)?.toDouble() ?? GameConstants.INITIAL_MARKET_METAL;
    _currentPrice = (json['currentPrice'] as num?)?.toDouble() ?? GameConstants.INITIAL_PRICE;
    _marketMetalPrice = (json['marketMetalPrice'] as num?)?.toDouble() ?? GameConstants.MIN_METAL_PRICE;
    
    // Charger les dynamiques de marché si présentes
    if (json['marketDynamics'] != null) {
      _marketDynamics.fromJson(json['marketDynamics']);
    }
    
    if (json['lastMetalPriceUpdateTime'] != null) {
      try {
        _lastMetalPriceUpdateTime = DateTime.parse(json['lastMetalPriceUpdateTime'].toString());
      } catch (e) {
        print('Erreur lors du parsing de lastMetalPriceUpdateTime dans MarketManager: $e');
        _lastMetalPriceUpdateTime = DateTime.now();
      }
    }
    _isPaused = json['isPaused'] as bool? ?? false;
    _currentMarketSaturation = (json['currentMarketSaturation'] as num?)?.toDouble() ?? GameConstants.DEFAULT_MARKET_SATURATION;
    _totalSales = (json['totalSales'] as num?)?.toDouble() ?? 0.0;
    _totalSalesCount = (json['totalSalesCount'] as num?)?.toInt() ?? 0;
    _averageSalePrice = (json['averageSalePrice'] as num?)?.toDouble() ?? 0.0;
    // Ajout de l'initialisation du champ reputation manquant dans les anciennes sauvegardes
    reputation = (json['reputation'] as num?)?.toDouble() ?? 1.0;
  }
}
