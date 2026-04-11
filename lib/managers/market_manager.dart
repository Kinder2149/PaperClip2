// lib/managers/market_manager.dart
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../constants/game_config.dart';
import '../models/json_loadable.dart';
import '../models/statistics_manager.dart';
import 'player_manager.dart';
import 'research_manager.dart';
import '../services/upgrades/upgrade_effects_calculator.dart';
import '../services/units/value_objects.dart';
import 'package:paperclip2/services/runtime/clock.dart';
import 'package:paperclip2/utils/logger.dart';

// ---------------------------------------------------------------------------
// Modèles de données
// ---------------------------------------------------------------------------

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
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
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

class CachedValue {
  final dynamic value;
  final DateTime expiryTime;
  static const Duration CACHE_DURATION = Duration(milliseconds: 500);

  CachedValue(this.value) : expiryTime = DateTime.now().add(CACHE_DURATION);

  bool get isValid => DateTime.now().isBefore(expiryTime);
}

class MarketSegment {
  final String name;
  final double elasticity;
  final double maxPrice;
  final double marketShare;

  const MarketSegment(this.name, this.elasticity, this.maxPrice, this.marketShare);
}

// ---------------------------------------------------------------------------
// MarketManager — Marché mondial simulé
// ---------------------------------------------------------------------------

class MarketManager extends ChangeNotifier implements JsonLoadable {
  final Logger _logger = Logger.forComponent('market');
  final Clock _clock;
  final bool Function()? _pauseReader;
  final void Function(bool)? _pauseRequest;

  PlayerManager? _playerManager;
  ResearchManager? _researchManager;
  late StatisticsManager _statisticsManager;
  dynamic _levelSystem;

  final Random _random = Random();
  final Map<String, CachedValue> _cache = {};

  // --- Variables marché mondial ---
  double _worldDemand = GameConstants.WORLD_BASE_DEMAND;
  double _competitorPrice = GameConstants.COMPETITOR_BASE_PRICE;
  double _playerMarketShare = GameConstants.MARKET_SHARE_NEUTRAL;
  double _totalGameTime = 0.0; // secondes cumulées depuis début/reset (pour cycles)
  double _tickNoise = 0.0;     // bruit calculé UNE FOIS par tick

  // --- Variables marché existantes conservées ---
  double _marketMetalStock = GameConstants.INITIAL_MARKET_METAL;
  double _currentPrice = GameConstants.INITIAL_PRICE;
  DateTime? _lastMetalPriceUpdateTime;
  double _marketMetalPrice = GameConstants.MIN_METAL_PRICE;
  bool _autoSellEnabled = true;
  double _salesRemainder = 0.0;
  double reputation = 1.0;

  // Réputation dynamique
  DateTime _lastReputationUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  int _lowSalesStreak = 0;
  static const Duration _reputationCooldown = Duration(seconds: 10);
  static const Duration _reputationWindow = Duration(seconds: 60);
  static const int _salesPerMinThreshold = 10;
  static const int _lowSalesStreakThreshold = 5;

  // Historique et agrégats
  final List<SaleRecord> salesHistory = [];
  double _totalSales = 0;
  int _totalSalesCount = 0;
  double _averageSalePrice = 0;
  double _highestSalePrice = 0.0;

  // Ventes du dernier tick (pour l'UI temps réel)
  double _lastTickSalesPerSecond = 0.0;

  // Marché actif
  List<dynamic> _activeEvents = [];
  final MarketDynamics dynamics = MarketDynamics();
  MarketDynamics _marketDynamics = MarketDynamics();

  // ---------------------------------------------------------------------------
  // Constructeur
  // ---------------------------------------------------------------------------

  MarketManager({
    Clock? clock,
    bool Function()? pauseReader,
    void Function(bool)? pauseRequest,
  })  : _clock = (clock ?? SystemClock()),
        _pauseReader = pauseReader,
        _pauseRequest = pauseRequest;

  void setManagers(
    PlayerManager playerManager,
    StatisticsManager statisticsManager,
    ResearchManager researchManager, {
    dynamic levelSystem,
  }) {
    _playerManager = playerManager;
    _statisticsManager = statisticsManager;
    _researchManager = researchManager;
    _levelSystem = levelSystem;
  }

  // ---------------------------------------------------------------------------
  // Getters publics
  // ---------------------------------------------------------------------------

  bool get autoSellEnabled => _autoSellEnabled;
  bool get isPaused => _pauseReader != null ? _pauseReader!.call() : false;
  bool get isActive => !isPaused;

  double get currentPrice => _currentPrice;
  double get marketMetalPrice => _marketMetalPrice;
  double get marketMetalStock => _marketMetalStock;
  DateTime? get lastMetalPriceUpdateTime => _lastMetalPriceUpdateTime;

  /// Prix concurrent simulé (affiché dans MarketPanel)
  double get competitorPrice => _competitorPrice;

  /// Demande mondiale courante (affiché dans MarketPanel)
  double get worldDemand => _worldDemand;

  /// Part de marché du joueur (0.02 à 0.70)
  double get playerMarketShare => _playerMarketShare;

  /// Ventes réalisées lors du dernier tick (trombones/s affiché dans UI)
  double get lastTickSalesPerSecond => _lastTickSalesPerSecond;

  double get totalSalesRevenue => _totalSales;
  int get totalSalesCount => _totalSalesCount;
  double get averageSalePrice => _averageSalePrice;
  double get highestSalePrice => _highestSalePrice;

  set autoSellEnabled(bool value) {
    if (_autoSellEnabled == value) return;
    _autoSellEnabled = value;
    notifyListeners();
  }

  set lastMetalPriceUpdateTime(DateTime? value) {
    _lastMetalPriceUpdateTime = value;
    notifyListeners();
  }

  set marketMetalPrice(double price) {
    _marketMetalPrice = price;
    dynamics.updateMarketConditions();
    notifyListeners();
  }

  void togglePause() {
    if (_pauseRequest != null) {
      _pauseRequest!.call(!isPaused);
    }
  }

  // ---------------------------------------------------------------------------
  // Cycle marché mondial — calculé à chaque tick
  // ---------------------------------------------------------------------------

  /// Met à jour les 3 variables mondiales : _worldDemand, _competitorPrice, _playerMarketShare
  void _updateWorldMarket(double elapsedSeconds, double playerSellPrice) {
    _totalGameTime += elapsedSeconds;

    // Équation A — Demande Mondiale
    final ecoSine = sin(2 * pi * _totalGameTime / GameConstants.WORLD_DEMAND_CYCLE_SECONDS);
    _worldDemand = GameConstants.WORLD_BASE_DEMAND *
        (GameConstants.WORLD_DEMAND_MIN_FACTOR +
            (1.0 - GameConstants.WORLD_DEMAND_MIN_FACTOR) * (ecoSine + 1) / 2);
    // → varie entre WORLD_BASE_DEMAND × 0.7 et WORLD_BASE_DEMAND × 1.0

    // Équation B — Prix Concurrent (calculé UNE FOIS par tick, bruit fixé)
    _tickNoise = (_random.nextDouble() * 2 - 1) * GameConstants.COMPETITOR_PRICE_NOISE;
    final priceSine = sin(2 * pi * _totalGameTime / GameConstants.COMPETITOR_PRICE_CYCLE_SECONDS);
    _competitorPrice = (GameConstants.COMPETITOR_BASE_PRICE *
            (1.0 + GameConstants.COMPETITOR_PRICE_AMPLITUDE * priceSine) +
        _tickNoise)
        .clamp(0.12, 0.50);

    // Équation C — Part de Marché Joueur
    final effectivePlayerPrice = playerSellPrice.clamp(GameConstants.MIN_PRICE, GameConstants.MAX_PRICE);
    if (_competitorPrice > 0) {
      final delta = (_competitorPrice - effectivePlayerPrice) / _competitorPrice;
      if (delta >= 0) {
        // Joueur moins cher ou au même prix → attractif
        _playerMarketShare =
            (GameConstants.MARKET_SHARE_NEUTRAL + 0.50 * delta)
                .clamp(GameConstants.MARKET_SHARE_NEUTRAL, GameConstants.MARKET_SHARE_MAX);
      } else {
        // Joueur plus cher → perd des parts de marché
        final factor = (1.0 + delta) * (1.0 + delta); // (1+delta)²
        _playerMarketShare =
            (GameConstants.MARKET_SHARE_NEUTRAL * factor)
                .clamp(GameConstants.MARKET_SHARE_MIN, GameConstants.MARKET_SHARE_NEUTRAL);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Calcul de la demande
  // ---------------------------------------------------------------------------

  /// Retourne la demande par seconde pour un prix donné.
  /// Utilisé par processSales et par l'agent MarketAnalyst.
  double calculateDemand(double playerPrice, int marketingLevel) {
    // Bonus marketing (upgrades + recherche)
    final extraMarketing = _researchManager?.getResearchBonus('marketDemand') ?? 0.0;
    final marketingMultiplier = (1.0 + marketingLevel * GameConstants.MARKETING_BOOST_PER_LEVEL) *
        (1.0 + extraMarketing);

    // Bonus réputation + recherche
    final reputationExtra = _researchManager?.getResearchBonus('reputationBonus') ?? 0.0;
    final reputationFactor = reputation.clamp(0.5, 1.5) * (1.0 + reputationExtra);

    return _worldDemand * _playerMarketShare * marketingMultiplier * reputationFactor;
  }

  UnitsPerSecond calculateDemandPerSecond({
    required double price,
    required int marketingLevel,
  }) {
    return UnitsPerSecond(calculateDemand(price, marketingLevel));
  }

  // ---------------------------------------------------------------------------
  // Traitement des ventes
  // ---------------------------------------------------------------------------

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
    if (isPaused) return MarketSaleResult.none;
    if (requireAutoSellEnabled && !_autoSellEnabled) return MarketSaleResult.none;

    final elapsed = (elapsedSeconds.isFinite && elapsedSeconds > 0) ? elapsedSeconds : 1.0;

    // Mise à jour du marché mondial (inclut worldDemand, competitorPrice, marketShare)
    if (updateMarketState) {
      _updateWorldMarket(elapsed, sellPrice);
      _updateMetalPrice();
    }

    // Calcul de la demande avec le nouveau système
    final demandPerSecond = calculateDemand(sellPrice, marketingLevel);

    // Bonus qualité via recherche
    final qualityBonus = 1.0 + (_researchManager?.getResearchBonus('salePrice') ?? 0.0);
    final maxPriceBonus = _researchManager?.getResearchBonus('maxSalePrice') ?? 0.0;
    final effectiveMaxPrice = GameConstants.MAX_PRICE_THRESHOLD * (1.0 + maxPriceBonus);
    final effectiveSellPrice = (sellPrice * qualityBonus).clamp(0.0, effectiveMaxPrice);

    // Accumulation fractionnaire pour éviter la perte d'unités
    final desiredDouble = (demandPerSecond * elapsed) + _salesRemainder;
    final int demandUnits = max(0, desiredDouble.floor());
    _salesRemainder = desiredDouble - demandUnits;

    // Ventes réelles limitées par le stock
    _lastTickSalesPerSecond = 0.0;
    if (playerPaperclips > 0 && demandUnits > 0) {
      final int sold = min(demandUnits, playerPaperclips.floor());
      if (sold > 0) {
        final revenue = sold * effectiveSellPrice;

        updatePaperclips(-sold.toDouble());
        updateMoney(revenue);
        recordSale(sold, effectiveSellPrice);
        _statisticsManager.updateEconomics(moneyEarned: revenue);

        if (_levelSystem != null) {
          _levelSystem.addSale(sold, effectiveSellPrice);
        }

        _lastTickSalesPerSecond = sold / elapsed;
        _maybeUpdateReputation(sellPrice: sellPrice, elapsedSeconds: elapsed);

        if (kDebugMode && verboseLogs) {
          _logger.debug('[Market] Vendu: $sold × ${effectiveSellPrice.toStringAsFixed(3)}€'
              ' = ${revenue.toStringAsFixed(2)}€'
              ' | Concurrent: ${_competitorPrice.toStringAsFixed(3)}€'
              ' | Part: ${(_playerMarketShare * 100).toStringAsFixed(1)}%'
              ' | Demande: ${demandPerSecond.toStringAsFixed(1)}/s');
        }

        return MarketSaleResult(
          quantity: sold,
          unitPrice: effectiveSellPrice,
          revenue: revenue,
        );
      }
    }

    return MarketSaleResult.none;
  }

  // ---------------------------------------------------------------------------
  // Mise à jour état marché (appelée depuis game_engine via tick)
  // ---------------------------------------------------------------------------

  void updateMarketState() {
    if (isPaused) return;
    // La mise à jour mondiale se fait dans processSales (avec elapsedSeconds réel).
    // Cette méthode met seulement à jour le prix du métal si processSales n'est pas appelé.
    _updateMetalPrice();
    notifyListeners();
  }

  void startMarketUpdates() {
    dynamics.updateMarketConditions();
  }

  void stopMarketUpdates() {}

  // ---------------------------------------------------------------------------
  // Prix du métal
  // ---------------------------------------------------------------------------

  void _updateMetalPrice() {
    final stockRatio = _marketMetalStock / GameConstants.INITIAL_MARKET_METAL;
    final priceRange = GameConstants.MAX_METAL_PRICE - GameConstants.MIN_METAL_PRICE;
    _marketMetalPrice = (GameConstants.MAX_METAL_PRICE - (stockRatio * priceRange))
        .clamp(GameConstants.MIN_METAL_PRICE, GameConstants.MAX_METAL_PRICE);
    _lastMetalPriceUpdateTime = _clock.now();
  }

  void updateMetalPrice() => _updateMetalPrice();

  void updateMarketStock(double newStock) {
    _marketMetalStock = newStock;
    _updateMetalPrice();
    notifyListeners();
  }

  void updateSellPrice(double price) {
    _currentPrice = price;
    notifyListeners();
  }

  bool isPriceExcessive(double price) => price > GameConstants.MAX_PRICE * 1.5;

  String getPriceRecommendation() {
    return "Prix optimal : ${GameConstants.OPTIMAL_PRICE_LOW}€ – ${GameConstants.OPTIMAL_PRICE_HIGH}€. "
        "Prix concurrent actuel : ${_competitorPrice.toStringAsFixed(2)}€.";
  }

  bool isInCrisisMode() => _marketMetalStock <= GameConstants.METAL_CRISIS_THRESHOLD_25;

  MarketEvent getCurrentMarketEvent() {
    if (_marketMetalStock <= GameConstants.METAL_CRISIS_THRESHOLD_0) return MarketEvent.MARKET_CRASH;
    if (_marketMetalStock <= GameConstants.METAL_CRISIS_THRESHOLD_25) return MarketEvent.PRICE_WAR;
    if (_marketMetalStock <= GameConstants.METAL_CRISIS_THRESHOLD_50) return MarketEvent.QUALITY_CONCERNS;
    return MarketEvent.DEMAND_SPIKE;
  }

  // ---------------------------------------------------------------------------
  // Réputation
  // ---------------------------------------------------------------------------

  double _computeRecentSalesPerMin() {
    if (salesHistory.isEmpty) return 0.0;
    final cutoff = _clock.now().subtract(_reputationWindow);
    int qty = 0;
    for (int i = salesHistory.length - 1; i >= 0; i--) {
      if (salesHistory[i].timestamp.isBefore(cutoff)) break;
      qty += salesHistory[i].quantity;
    }
    return qty / _reputationWindow.inSeconds * 60.0;
  }

  void _maybeUpdateReputation({
    required double sellPrice,
    required double elapsedSeconds,
    bool noSale = false,
  }) {
    final now = _clock.now();
    if (now.difference(_lastReputationUpdate) < _reputationCooldown) return;

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
      _lowSalesStreak += 1;
      if (_lowSalesStreak >= _lowSalesStreakThreshold) {
        reputation = (reputation - 0.01).clamp(0.5, 1.5);
        _lowSalesStreak = 0;
        adjusted = true;
      }
    } else {
      _lowSalesStreak = 0;
    }

    if (adjusted) {
      _lastReputationUpdate = now;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Historique ventes
  // ---------------------------------------------------------------------------

  void recordSale(int amount, double price) {
    if (amount <= 0) return;
    final revenue = amount * price;
    salesHistory.add(SaleRecord(
      timestamp: _clock.now(),
      quantity: amount,
      price: price,
      revenue: revenue,
    ));
    if (salesHistory.length > GameConstants.MAX_SALES_HISTORY) {
      salesHistory.removeAt(0);
    }
    _totalSales += revenue;
    _totalSalesCount += amount;
    _averageSalePrice = _totalSalesCount > 0 ? _totalSales / _totalSalesCount : 0.0;
    if (price > _highestSalePrice) _highestSalePrice = price;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  void reset() {
    _marketMetalStock = GameConstants.INITIAL_MARKET_METAL;
    _currentPrice = GameConstants.INITIAL_PRICE;
    _marketMetalPrice = GameConstants.MIN_METAL_PRICE;
    _lastMetalPriceUpdateTime = _clock.now();
    _activeEvents.clear();
    _salesRemainder = 0.0;
    _totalGameTime = 0.0;
    _worldDemand = GameConstants.WORLD_BASE_DEMAND;
    _competitorPrice = GameConstants.COMPETITOR_BASE_PRICE;
    _playerMarketShare = GameConstants.MARKET_SHARE_NEUTRAL;
    _lastTickSalesPerSecond = 0.0;
    notifyListeners();
  }

  void resetForProgression() {
    reset();
    reputation = 1.0;
    _totalSales = 0.0;
    _totalSalesCount = 0;
    _averageSalePrice = 0.0;
    _highestSalePrice = 0.0;
    salesHistory.clear();
    notifyListeners();
  }

  void resetMarketSaturation() {
    // Conservé pour compatibilité — sans effet dans le nouveau système
  }

  // ---------------------------------------------------------------------------
  // Sérialisation JSON
  // ---------------------------------------------------------------------------

  @override
  Map<String, dynamic> toJson() => {
    'marketMetalStock': _marketMetalStock,
    'currentPrice': _currentPrice,
    'marketMetalPrice': _marketMetalPrice,
    'lastMetalPriceUpdateTime': _lastMetalPriceUpdateTime?.toIso8601String(),
    'totalSales': _totalSales,
    'totalSalesCount': _totalSalesCount,
    'averageSalePrice': _averageSalePrice,
    'reputation': reputation,
    'totalGameTime': _totalGameTime,
    'worldDemand': _worldDemand,
    'competitorPrice': _competitorPrice,
    'playerMarketShare': _playerMarketShare,
    'marketDynamics': _marketDynamics.toJson(),
    // Champs legacy conservés pour ne pas casser d'anciennes sauvegardes
    'currentMarketSaturation': 1.0,
  };

  @override
  void fromJson(Map<String, dynamic> json) {
    _marketMetalStock =
        (json['marketMetalStock'] as num?)?.toDouble() ?? GameConstants.INITIAL_MARKET_METAL;
    _currentPrice =
        (json['currentPrice'] as num?)?.toDouble() ?? GameConstants.INITIAL_PRICE;
    _marketMetalPrice =
        (json['marketMetalPrice'] as num?)?.toDouble() ?? GameConstants.MIN_METAL_PRICE;
    _totalSales = (json['totalSales'] as num?)?.toDouble() ?? 0.0;
    _totalSalesCount = (json['totalSalesCount'] as num?)?.toInt() ?? 0;
    _averageSalePrice = (json['averageSalePrice'] as num?)?.toDouble() ?? 0.0;
    reputation = (json['reputation'] as num?)?.toDouble() ?? 1.0;
    _totalGameTime = (json['totalGameTime'] as num?)?.toDouble() ?? 0.0;
    _worldDemand = (json['worldDemand'] as num?)?.toDouble() ?? GameConstants.WORLD_BASE_DEMAND;
    _competitorPrice =
        (json['competitorPrice'] as num?)?.toDouble() ?? GameConstants.COMPETITOR_BASE_PRICE;
    _playerMarketShare =
        (json['playerMarketShare'] as num?)?.toDouble() ?? GameConstants.MARKET_SHARE_NEUTRAL;

    if (json['lastMetalPriceUpdateTime'] != null) {
      try {
        _lastMetalPriceUpdateTime =
            DateTime.parse(json['lastMetalPriceUpdateTime'].toString());
      } catch (_) {
        _lastMetalPriceUpdateTime = _clock.now();
      }
    }
    if (json['marketDynamics'] != null) {
      _marketDynamics.fromJson(json['marketDynamics'] as Map<String, dynamic>);
    }
  }
}
