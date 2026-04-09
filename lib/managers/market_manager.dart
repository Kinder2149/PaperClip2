// lib/managers/market_manager.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import '../constants/game_config.dart'; // Mis à jour pour utiliser le dossier constants
import '../models/json_loadable.dart';
import '../models/statistics_manager.dart';
import 'player_manager.dart'; // Import de PlayerManager
import 'research_manager.dart'; // Import de ResearchManager
import '../services/upgrades/upgrade_effects_calculator.dart';
import '../services/units/value_objects.dart';
import 'package:paperclip2/services/runtime/clock.dart';
import 'package:paperclip2/utils/logger.dart';

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

// (constructeur de MarketManager défini plus bas)

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
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      revenue: (json['revenue'] as num).toDouble(),
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
  final Logger _logger = Logger.forComponent('market');
  final Clock _clock;
  // Ponts vers le runtime maître (lecture/commande de pause)
  final bool Function()? _pauseReader;
  final void Function(bool)? _pauseRequest;
  // Références aux autres managers
  PlayerManager? _playerManager;
  ResearchManager? _researchManager;
  late StatisticsManager _statisticsManager; // Utilisation de 'late' pour déclarer une variable non-nullable qui sera initialisée plus tard
  dynamic _levelSystem; // LevelSystem pour l'attribution d'XP
  
  // Méthode pour initialiser les références aux autres managers
  void setManagers(PlayerManager playerManager, StatisticsManager statisticsManager, ResearchManager researchManager, {dynamic levelSystem}) {
    _playerManager = playerManager;
    _statisticsManager = statisticsManager;
    _researchManager = researchManager;
    _levelSystem = levelSystem;
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
  
  double _marketMetalStock = GameConstants.INITIAL_MARKET_METAL;
  double _currentPrice = GameConstants.INITIAL_PRICE;  // Prix par défaut
  DateTime? _lastMetalPriceUpdateTime;
  List<MarketEvent> _activeEvents = [];

  // Historique léger: buffer borné pour éviter la consommation mémoire
  final List<SaleRecord> salesHistory = [];
  double reputation = 1.0;
  double _currentMarketSaturation = GameConstants.DEFAULT_MARKET_SATURATION;
  double _difficultyMultiplier = GameConstants.BASE_DIFFICULTY;
  double _marketReputation = 1.0;
  double _competitivePressure = 0.0;
  double _marketMetalPrice = GameConstants.MIN_METAL_PRICE;
  double _metalTrend = 0;
  bool _autoSellEnabled = true;

  double _salesRemainder = 0.0;

  bool get autoSellEnabled => _autoSellEnabled;

  set autoSellEnabled(bool value) {
    if (_autoSellEnabled == value) return;
    _autoSellEnabled = value;
    if (kDebugMode) {
      _logger.debug('[MarketManager] autoSellEnabled mis à jour: $_autoSellEnabled');
    }
    notifyListeners();
  }
  List<double> _demandHistory = [];
  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  // Nous n'utilisons plus de timer périodique
  MarketDynamics _marketDynamics = MarketDynamics();
  double _totalSales = 0;
  int _totalSalesCount = 0;
  double _averageSalePrice = 0;
  double _highestSalePrice = 0.0;
  // --- Réputation dynamique (Option B) ---
  DateTime _lastReputationUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  int _lowSalesStreak = 0;
  static const Duration _reputationWindow = Duration(seconds: 60);
  static const Duration _reputationCooldown = Duration(seconds: 10);
  static const int _salesPerMinThreshold = 10; // seuil indicatif
  static const int _lowSalesStreakThreshold = 5; // N ticks consécutifs avant pénalité

  // Agrégats d'historique minimalistes (utilisés par l'écran Historique)
  double get totalSalesRevenue => _totalSales;
  int get totalSalesCount => _totalSalesCount;
  double get averageSalePrice => _averageSalePrice;
  double get highestSalePrice => _highestSalePrice;

  double get currentMetalPrice => _marketMetalPrice;
  // Expose pause via runtime maître si branché (lecture UI/services)
  bool get isPaused => _pauseReader != null ? (_pauseReader!.call()) : false;

  void togglePause() {
    if (_pauseRequest != null) {
      _pauseRequest!.call(!isPaused);
    }
  }

  // Constructeur avec Clock optionnelle (SystemClock par défaut) et ponts de pause runtime
  MarketManager({Clock? clock, bool Function()? pauseReader, void Function(bool)? pauseRequest})
      : _clock = (clock ?? SystemClock()),
        _pauseReader = pauseReader,
        _pauseRequest = pauseRequest;

  void startMarketUpdates() {
    // Nous ne créons pas de timer périodique car les ventes seront désormais
    // déclenchées directement par les changements dans les conditions du marché
    
    // Appel initial pour configurer le marché
    dynamics.updateMarketConditions();
    
    if (kDebugMode) {
      _logger.debug('[MarketManager] Le système de mise à jour du marché est initialisé (mode basé sur événements)');
    }
  }
  
  void stopMarketUpdates() {
    // Rien à arrêter car nous n'utilisons plus de timer
    if (kDebugMode) {
      _logger.debug('[MarketManager] stopMarketUpdates appelé (pas de timer à arrêter)');
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

    _lastMetalPriceUpdateTime = _clock.now();
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
    double elapsedSeconds = 1.0,
    bool updateMarketState = true,
    bool requireAutoSellEnabled = true,
    bool verboseLogs = false,
  }) {
    if (isPaused) {
      if (kDebugMode) _logger.debug('[MarketManager] processSales: Ignoré - Le marché est en pause');
      return MarketSaleResult.none;
    }

    if (requireAutoSellEnabled && !_autoSellEnabled) {
      if (kDebugMode) {
        _logger.debug('[MarketManager] processSales: Ignoré - Vente automatique désactivée');
      }
      return MarketSaleResult.none;
    }

    // Logs détaillés sur les conditions initiales
    if (kDebugMode && verboseLogs) {
      _logger.debug('===== PROCESSUS DE VENTE =====');
      _logger.debug('[MarketManager] État initial: ${playerPaperclips.toStringAsFixed(1)} trombones, prix de vente: ${sellPrice.toStringAsFixed(2)}, niveau marketing: $marketingLevel');
      _logger.debug('[MarketManager] État marché: saturation: ${_currentMarketSaturation.toStringAsFixed(2)}, prix métal: ${_marketMetalPrice.toStringAsFixed(2)}');
    }

    if (updateMarketState) {
      _updateMarketState();
    }

    final elapsed = elapsedSeconds.isFinite && elapsedSeconds > 0
        ? elapsedSeconds
        : 1.0;

    final demandPerSecond = calculateDemandPerSecond(
      price: sellPrice,
      marketingLevel: marketingLevel,
    ).value;
    final desiredUnitsDouble = (demandPerSecond * elapsed) + _salesRemainder;
    final int demandUnits = max(0, desiredUnitsDouble.floor());
    _salesRemainder = desiredUnitsDouble - demandUnits;

    final demand = demandUnits.toDouble();

    // Log de la demande calculée
    if (kDebugMode && verboseLogs) {
      _logger.debug('[MarketManager] Demande calculée: ${demand.toStringAsFixed(1)} unités');
    }

    if (playerPaperclips > 0) {
      int potentialSales = min(demandUnits, playerPaperclips.floor());

      if (kDebugMode && verboseLogs) {
        _logger.debug('[MarketManager] Ventes potentielles: $potentialSales unités');
      }

      if (potentialSales > 0) {
        // CHANTIER-03 : Utiliser bonus recherche pour qualité
        final qualityBonus = 1.0 + (_researchManager?.getResearchBonus('salePrice') ?? 0.0);
        
        // CHANTIER-03 : Appliquer plafond de prix avec bonus recherche (M6 Marché de Niche)
        final maxPriceBonus = _researchManager?.getResearchBonus('maxSalePrice') ?? 0.0;
        final effectiveMaxPrice = GameConstants.MAX_PRICE_THRESHOLD * (1.0 + maxPriceBonus);
        
        final baseSalePrice = sellPrice * qualityBonus;
        final salePrice = min(baseSalePrice, effectiveMaxPrice);
        final revenue = potentialSales * salePrice;

        // Logs détaillés de la transaction
        if (kDebugMode && verboseLogs) {
          _logger.debug('[MarketManager] Bonus qualité: x${qualityBonus.toStringAsFixed(2)}');
          _logger.debug('[MarketManager] Prix de vente effectif: ${salePrice.toStringAsFixed(2)}');
          _logger.debug('[MarketManager] Transaction: -$potentialSales trombones, +${revenue.toStringAsFixed(2)} argent');
        }

        updatePaperclips(-potentialSales.toDouble());
        updateMoney(revenue);
        // Enregistre une ligne dans un buffer borné et met à jour les agrégats
        recordSale(potentialSales, salePrice);
        _statisticsManager.updateEconomics(
          moneyEarned: revenue,
          // Retrait des paramètres sales et price non supportés
        );
        
        // Attribution d'XP pour la vente
        if (_levelSystem != null) {
          _levelSystem.addSale(potentialSales, salePrice);
        }

        // Réputation dynamique (Option B): mise à jour lissée et bornée
        _maybeUpdateReputation(
          sellPrice: sellPrice,
          elapsedSeconds: elapsed,
        );
        
        if (kDebugMode && verboseLogs) {
          _logger.debug('[MarketManager] Statistiques mises à jour: ${_totalSalesCount} ventes totales, ${_totalSales.toStringAsFixed(2)} revenus cumulés');
          _logger.debug('===== FIN PROCESSUS DE VENTE =====');
        }

        return MarketSaleResult(
          quantity: potentialSales,
          unitPrice: salePrice,
          revenue: revenue,
        );
      } else {
        if (kDebugMode) _logger.debug('[MarketManager] Aucune vente possible - demande insuffisante');
        // Pas de vente: possibilité d'augmenter la série de faibles ventes si le prix est excessif
        _maybeUpdateReputation(
          sellPrice: sellPrice,
          elapsedSeconds: elapsed,
          noSale: true,
        );
      }
    } else {
      if (kDebugMode) _logger.debug('[MarketManager] Aucune vente possible - pas de stock de trombones');
    }

    return MarketSaleResult.none;
  }

  double _computeRecentSalesPerMin({Duration window = _reputationWindow}) {
    if (salesHistory.isEmpty) return 0.0;
    final cutoff = _clock.now().subtract(window);
    int qty = 0;
    for (int i = salesHistory.length - 1; i >= 0; i--) {
      final rec = salesHistory[i];
      if (rec.timestamp.isBefore(cutoff)) break;
      qty += rec.quantity;
    }
    if (window.inSeconds <= 0) return 0.0;
    final perSec = qty / window.inSeconds;
    return perSec * 60.0;
  }

  void _maybeUpdateReputation({
    required double sellPrice,
    required double elapsedSeconds,
    bool noSale = false,
  }) {
    final now = _clock.now();
    if (now.difference(_lastReputationUpdate) < _reputationCooldown) {
      return;
    }

    final recentPerMin = _computeRecentSalesPerMin();
    final inOptimalRange =
        sellPrice >= GameConstants.OPTIMAL_PRICE_LOW && sellPrice <= GameConstants.OPTIMAL_PRICE_HIGH;
    final priceExcessive = sellPrice > GameConstants.MAX_PRICE_THRESHOLD;

    bool adjusted = false;
    if (inOptimalRange && recentPerMin >= _salesPerMinThreshold) {
      reputation = (reputation + 0.01).clamp(0.5, 1.5);
      _lowSalesStreak = 0;
      adjusted = true;
    } else if (priceExcessive) {
      if (noSale || recentPerMin < _salesPerMinThreshold) {
        _lowSalesStreak += 1;
        if (_lowSalesStreak >= _lowSalesStreakThreshold) {
          reputation = (reputation - 0.01).clamp(0.5, 1.5);
          _lowSalesStreak = 0;
          adjusted = true;
        }
      } else {
        _lowSalesStreak = 0;
      }
    } else {
      _lowSalesStreak = 0;
    }

    if (adjusted) {
      notifyListeners();
    }
  }

  void _updateMarketState() {
    // Mise à jour des tendances du marché
    final now = _clock.now();
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
    if (isPaused) {
      if (kDebugMode) {
        _logger.debug('[MarketManager] updateMarketState: Le marché est en pause, pas de mise à jour');
      }
      return;
    }

    if (kDebugMode) {
      _logger.debug('[MarketManager] Début updateMarketState() - ${_clock.now()}');
    }

    _updateMarketState();
    notifyListeners();

    if (kDebugMode) {
      _logger.debug('[MarketManager] Fin updateMarketState()');
    }
  }


  double calculateDemand(double price, int marketingLevel) {
    // Calcul de la demande basé sur le prix de vente, la saturation du marché
    // et le niveau de marketing
    double baselineDemand = GameConstants.BASE_DEMAND;
    
    // Réduction de la demande si le prix est trop élevé
    double priceMultiplier = max(0.1, 1.0 - (price / GameConstants.MAX_PRICE_THRESHOLD));

    // CHANTIER-03 : Utiliser bonus recherche pour marketing
    double marketingMultiplier = 1.0;
    final extraMarketing = _researchManager?.getResearchBonus('marketDemand') ?? 0.0;
    marketingMultiplier *= (1.0 + extraMarketing);
    
    // Facteur de saturation du marché
    // CHANTIER-03 : Appliquer bonus recherche marketSaturation (M5 Domination Marché)
    final saturationBonus = _researchManager?.getResearchBonus('marketSaturation') ?? 0.0;
    double saturationFactor = (_currentMarketSaturation + saturationBonus) / GameConstants.DEFAULT_MARKET_SATURATION;
    
    // CHANTIER-03 : Intègre la réputation et le bonus recherche
    final reputationExtra = _researchManager?.getResearchBonus('reputationBonus') ?? 0.0;
    final reputationFactor = max(0.0, reputation) * (1.0 + reputationExtra);
    double demand = baselineDemand *
        priceMultiplier *
        marketingMultiplier *
        saturationFactor *
        reputationFactor;
    
    // Utilise la dynamique du marché pour les fluctuations
    double marketConditionEffect = _marketDynamics.getMarketConditionMultiplier();
    // CHANTIER-03 : Réduction de volatilité via recherche
    final volReduction = _researchManager?.getResearchBonus('volatilityReduction') ?? 0.0;
    marketConditionEffect *= (1.0 - volReduction);
    
    return demand * marketConditionEffect;
  }

  UnitsPerSecond calculateDemandPerSecond({
    required double price,
    required int marketingLevel,
  }) {
    return UnitsPerSecond(calculateDemand(price, marketingLevel));
  }

  void recordSale(int amount, double price) {
    if (amount <= 0) return;

    final revenue = amount * price;
    salesHistory.add(SaleRecord(
      timestamp: _clock.now(),
      quantity: amount,
      price: price,
      revenue: revenue,
    ));

    // Buffer borné
    if (salesHistory.length > GameConstants.MAX_SALES_HISTORY) {
      salesHistory.removeAt(0);
    }

    // Agrégats minimaux
    _totalSales += revenue;
    _totalSalesCount += amount;
    _averageSalePrice = _totalSalesCount > 0 ? _totalSales / _totalSalesCount : 0.0;
    if (price > _highestSalePrice) {
      _highestSalePrice = price;
    }

    // Ajuster légèrement la saturation après une vente
    _currentMarketSaturation -= (amount * GameConstants.SATURATION_IMPACT_PER_SALE);
    if (_currentMarketSaturation < GameConstants.MIN_MARKET_SATURATION) {
      _currentMarketSaturation = GameConstants.MIN_MARKET_SATURATION;
    }

    notifyListeners();
  }

  // Getters manquants
  double get currentPrice => _currentPrice;
  bool get isActive => !isPaused;
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
    _lastMetalPriceUpdateTime = _clock.now();
    _activeEvents.clear();
    _salesRemainder = 0.0;
    notifyListeners();
  }
  
  /// Reset pour progression (prestige)
  /// 
  /// Réinitialise le marché mais conserve les recherches
  void resetForProgression() {
    _marketMetalStock = GameConstants.INITIAL_MARKET_METAL;
    _currentPrice = GameConstants.INITIAL_PRICE;
    _marketMetalPrice = GameConstants.MIN_METAL_PRICE;
    _currentMarketSaturation = GameConstants.DEFAULT_MARKET_SATURATION;
    _lastMetalPriceUpdateTime = _clock.now();
    _activeEvents.clear();
    _salesRemainder = 0.0;
    reputation = 1.0;
    _totalSales = 0.0;
    _totalSalesCount = 0;
    _averageSalePrice = 0.0;
    notifyListeners();
  }
  
  /// Réinitialise la saturation du marché à sa valeur par défaut pour garantir la demande
  void resetMarketSaturation() {
    _currentMarketSaturation = GameConstants.DEFAULT_MARKET_SATURATION;
    if (kDebugMode) {
      _logger.debug('[MarketManager] Saturation du marché réinitialisée à ${_currentMarketSaturation.toStringAsFixed(2)}');
    }
  }
  
  Map<String, dynamic> toJson() => {
    'marketMetalStock': _marketMetalStock,
    'currentPrice': _currentPrice,
    'marketMetalPrice': _marketMetalPrice,
    'lastMetalPriceUpdateTime': _lastMetalPriceUpdateTime?.toIso8601String(),
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
        _lastMetalPriceUpdateTime = _clock.now();
      }
    }
    _currentMarketSaturation = (json['currentMarketSaturation'] as num?)?.toDouble() ?? GameConstants.DEFAULT_MARKET_SATURATION;
    _totalSales = (json['totalSales'] as num?)?.toDouble() ?? 0.0;
    _totalSalesCount = (json['totalSalesCount'] as num?)?.toInt() ?? 0;
    _averageSalePrice = (json['averageSalePrice'] as num?)?.toDouble() ?? 0.0;
    // Ajout de l'initialisation du champ reputation manquant dans les anciennes sauvegardes
    reputation = (json['reputation'] as num?)?.toDouble() ?? 1.0;
  }
}
