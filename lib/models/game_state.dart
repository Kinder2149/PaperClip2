import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../utils/update_manager.dart';
import 'constants.dart';
import 'upgrade.dart';
import 'market/market_manager.dart';
import 'interfaces/game_state_market.dart';
import 'interfaces/game_state_production.dart';
import '../models/level_system.dart';
import '../services/save_manager.dart';
import 'package:paperclip2/widgets/xp_status_display.dart';
import 'package:paperclip2/models/resource_manager.dart';
import 'package:paperclip2/models/progression_bonus.dart';
import 'package:paperclip2/models/event_manager.dart'; // Garder uniquement celui-ci
import 'package:paperclip2/models/notification_manager.dart';
import 'package:paperclip2/models/game_event.dart';
import 'game_enums.dart';
import 'notification_event.dart';
import 'notification_manager.dart';
import 'package:paperclip2/main.dart';
import 'package:paperclip2/main.dart' show navigatorKey;
import 'market/market_dynamics.dart';


class GameState extends ChangeNotifier with GameStateMarket, GameStateProduction {
  // Timers
  Timer? marketTimer;
  Timer? productionTimer;
  Timer? _metalPriceTimer;
  Timer? _playTimeTimer;
  Timer? _autoSaveTimer;
  double _maintenanceCosts = 0.0;
  Timer? _maintenanceTimer;

  // Private properties
  String? _gameName;
  double _paperclips = 0;
  double _metal = GameConstants.INITIAL_METAL;
  double _money = GameConstants.INITIAL_MONEY;
  double _sellPrice = GameConstants.INITIAL_PRICE;
  int _autoclippers = 0;
  double _currentMetalPrice = GameConstants.MIN_METAL_PRICE;
  int _totalPaperclipsProduced = 0;
  int _totalTimePlayedInSeconds = 0;
  DateTime? _lastSaveTime;
  BuildContext? _context;
  LevelSystem _levelSystem = LevelSystem();
  final MarketDynamics marketDynamics = MarketDynamics();
  final MarketManager marketManager;
  String? _currentGameName;
  String? get currentGameName => _currentGameName;

  // Public getters
  String? get gameName => _gameName;
  LevelSystem get levelSystem => _levelSystem;
  double get paperclips => _paperclips;
  double get metal => _metal;
  double get money => _money;
  double get sellPrice => _sellPrice;
  int get autoclippers => _autoclippers;
  double get currentMetalPrice => _currentMetalPrice;
  int get totalTimePlayed => _totalTimePlayedInSeconds;
  int get totalPaperclipsProduced => _totalPaperclipsProduced;
  DateTime? get lastSaveTime => _lastSaveTime;
  final ResourceManager resourceManager = ResourceManager();
  bool _isGameInitialized = false;
  bool get isGameInitialized => _isGameInitialized;

  set money(double value) {
    if (value >= 0) { // Vérifie que l'argent ne devient pas négatif
      _money = value;
      notifyListeners(); // Notifie les listeners des changements
    }
  }


  double get autocliperCost {
    double baseCost = GameConstants.BASE_AUTOCLIPPER_COST * (1.15 * _autoclippers);
    double automationDiscount = 1.0 - ((upgrades['automation']?.level ?? 0) * 0.10);
    return baseCost * automationDiscount;
  }


  int get maxMetalStorage => (1000 * (1 + (upgrades['storage']?.level ?? 0) * 0.50)).toInt();
  @override
  set sellPrice(double value) {
    if (value >= GameConstants.MIN_PRICE && value <= GameConstants.MAX_PRICE) {
      _sellPrice = value;
      notifyListeners();
    }
  }
  int getCriticalEventsCount() {
    return EventManager.getEvents()
        .where((event) => event.importance == EventImportance.CRITICAL)
        .length;
  }


  @override
  set metal(double value) {
    _metal = value;
    notifyListeners();
  }

  @override
  set paperclips(double value) {
    _paperclips = value;
    notifyListeners();
  }


  // Upgrades
  @override
  Map<String, Upgrade> get upgrades => _upgrades;
  final Map<String, Upgrade> _upgrades = {
    'efficiency': Upgrade(
      name: 'Metal Efficiency',
      description: 'Réduit la consommation de métal de 15 %',
      baseCost: 45.0,
      level: 0,
      maxLevel: 10,
    ),
    'marketing': Upgrade(
      name: 'Marketing',
      description: 'Augmente la demande du marché de 30 %',
      baseCost: 75.0,
      level: 0,
      maxLevel: 8,
    ),
    'bulk': Upgrade(
      name: 'Bulk Production',
      description: 'Les autoclippeuses produisent 35 % plus vite',
      baseCost: 150.0,
      level: 0,
      maxLevel: 8,
    ),
    'speed': Upgrade(
      name: 'Speed Boost',
      description: 'Augmente la vitesse de production de 20 %',
      baseCost: 100.0,
      level: 0,
      maxLevel: 5,
    ),
    'storage': Upgrade(
      name: 'Storage Upgrade',
      description: 'Augmente la capacité de stockage de métal de 50 %',
      baseCost: 60.0,
      level: 0,
      maxLevel: 5,
    ),
    'automation': Upgrade(
      name: 'Automation',
      description: 'Réduit le coût des autoclippeuses de 10 % par niveau',
      baseCost: 200.0,
      level: 0,
      maxLevel: 5,
    ),
    'quality': Upgrade(
      name: 'Quality Control',
      description: 'Augmente le prix de vente des trombones de 10 % par niveau',
      baseCost: 80.0,
      level: 0,
      maxLevel: 10,
    ),
  };

  // Constructor
  GameState() : marketManager = MarketManager(MarketDynamics()) {
    _levelSystem.onLevelUp = _handleLevelUp;
    _loadSavedGame();
    _initializeGame();
  }
  Future<void> _loadSavedGame() async {
    final lastSave = await SaveManager.getLastSave();
    if (lastSave != null) {
      await loadGame(lastSave.name);
    }
    _isGameInitialized = true;
    notifyListeners();
  }
  @override
  void dispose() {
    productionTimer?.cancel();
    super.dispose();
  }

  void startProductionTimer() {
    productionTimer?.cancel();
    productionTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        processProduction();
        processMarket();
      },
    );
  }

  void processProduction() {
    if (_autoclippers > 0) {
      double bulkBonus = 1.0 + (upgrades['bulk']?.level ?? 0) * 0.35;
      double efficiencyBonus = 1.0 - ((upgrades['efficiency']?.level ?? 0) * 0.15);
      double speedBonus = 1.0 + (upgrades['speed']?.level ?? 0) * 0.20;

      double metalNeeded = _autoclippers * GameConstants.METAL_PER_PAPERCLIP * efficiencyBonus;

      if (_metal >= metalNeeded) {
        _metal -= metalNeeded;
        double production = _autoclippers * bulkBonus * speedBonus;
        _paperclips += production;
        _totalPaperclipsProduced += production.floor();
        notifyListeners();
      }
    }
  }








  void _initializeGame() async {
    initializeMarket();
    final lastSave = await SaveManager.getLastSave();
    if (lastSave != null) {
      await loadGame(lastSave.name);
    }
    _startGameSystems();
  }

  void _startGameSystems() {
    startProductionTimer();  // S'assurer que ceci est appelé
    _startMetalPriceVariation();
    _startPlayTimeTracking();
  }


  void _handleLevelUp(int newLevel, List<UnlockableFeature> newFeatures) {
    // Logique de gestion des level up
    print('Niveau atteint : $newLevel');
    print('Fonctionnalités débloquées : $newFeatures');

    // Exemple de notification ou d'action lors du déblocage
    newFeatures.forEach((feature) {
      switch (feature) {
        case UnlockableFeature.MANUAL_PRODUCTION:
          _showUnlockNotification('Production manuelle débloquée !');
          break;
        case UnlockableFeature.MARKET_SALES:
          _showUnlockNotification('Ventes débloquées !');
          break;
        case UnlockableFeature.AUTOCLIPPERS:
          _showUnlockNotification('Autoclippeuses disponibles !');
          break;
        case UnlockableFeature.METAL_PURCHASE:
          _showUnlockNotification('Achat de métal débloqué !');
          break;
        case UnlockableFeature.MARKET_SCREEN:
          _showUnlockNotification('Écran de marché débloqué !');
          break;
        case UnlockableFeature.UPGRADES:
          _showUnlockNotification('Améliorations disponibles !');
          break;
      }
    });

    notifyListeners();
  }
  void _showUnlockNotification(String message) {
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(_context!).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } else {
      print(message); // Fallback if context is not available
    }
  }
  Map<String, bool> getVisibleScreenElements() {
    return _levelSystem.featureUnlocker.getVisibleScreenElements(_levelSystem.level);
  }

  void _startMetalPriceVariation() {
    _metalPriceTimer?.cancel();
    _metalPriceTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _currentMetalPrice = marketManager.updateMetalPrice();
      notifyListeners();
    });
  }

  // Méthode de suivi du temps de jeu
  void _startPlayTimeTracking() {
    _playTimeTimer?.cancel();
    _playTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _totalTimePlayedInSeconds++;
    });
  }

  // Game Actions
  void buyMetal() {
    if (_money >= _currentMetalPrice) {
      double amount = GameConstants.METAL_PACK_AMOUNT;

      // Vérification de la capacité de stockage
      if (_metal + amount <= maxMetalStorage) {
        _metal += amount;
        _money -= _currentMetalPrice;
        notifyListeners();
      } else {
        // Notification de stockage plein
        EventManager.addEvent(
            EventType.RESOURCE_DEPLETION,
            "Stockage plein",
            description: "Impossible d'acheter plus de métal. Améliorez votre stockage!",
            importance: EventImportance.HIGH
        );
      }
    }
  }
  void _startMaintenanceTimer() {
    _maintenanceTimer?.cancel();
    _maintenanceTimer = Timer.periodic(
        const Duration(minutes: 1),
            (_) => _applyMaintenanceCosts()
    );
  }
  void _applyMaintenanceCosts() {
    _maintenanceCosts = resourceManager.calculateMaintenanceCost();
    if (_money >= _maintenanceCosts) {
      _money -= _maintenanceCosts;
      notifyListeners();
    }
  }

  void setSellPrice(double newPrice) {
    if (marketManager.isPriceExcessive(newPrice)) {
      final notification = NotificationEvent(
        title: "Prix Excessif!",
        description: "Ce prix pourrait affecter vos ventes",
        detailedDescription: """
Impact du prix élevé sur votre entreprise:

• Réputation: Diminution possible
• Ventes: Réduction probable
• Concurrence: Avantage pour vos concurrents

${marketManager.getPriceRecommendation()}

Conseils:
1. Analysez le marché actuel
2. Ajustez progressivement vos prix
3. Surveillez l'impact sur vos ventes
      """,
        icon: Icons.price_change,
        priority: NotificationPriority.HIGH,
        additionalData: {
          "Prix actuel": newPrice.toStringAsFixed(2),
          "Prix recommandé": marketManager.getPriceRecommendation(),
          "Impact sur la réputation": "Négatif",
        },
        canBeSuppressed: true,
        suppressionDuration: const Duration(minutes: 10),
      );

      if (navigatorKey.currentContext != null) {
        NotificationManager.showGameNotification(
          navigatorKey.currentContext!,
          event: notification,
        );
      }
    }
    _sellPrice = newPrice;
    notifyListeners();
  }
  void checkMetalStorage() {
    double stockPercentage = metal / maxMetalStorage;

    if (stockPercentage >= 0.9) {  // 90% de remplissage
      final notification = NotificationEvent(
        title: "Stockage Critique",
        description: "Stockage à ${(stockPercentage * 100).toInt()}%",
        detailedDescription: """
Votre stockage de métal atteint ses limites !

État actuel :
• Capacité totale: $maxMetalStorage
• Métal stocké: ${metal.toInt()}
• Taux d'occupation: ${(stockPercentage * 100).toInt()}%

Actions recommandées :
1. Augmentez votre capacité de stockage
2. Accélérez la production
3. Vendez l'excès de métal
      """,
        icon: Icons.warehouse,
        priority: NotificationPriority.HIGH,
        additionalData: {
          'Capacité maximale': maxMetalStorage,
          'Stock actuel': metal.toInt(),
          'Espace restant': (maxMetalStorage - metal).toInt(),
          'Taux remplissage': '${(stockPercentage * 100).toInt()}%',
        },
        canBeSuppressed: true,
        suppressionDuration: const Duration(minutes: 5),
      );

      if (navigatorKey.currentContext != null) {
        NotificationManager.showGameNotification(
          navigatorKey.currentContext!,
          event: notification,
        );
      }
    }
  }

  void buyAutoclipper() {
    if (_money >= autocliperCost) {
      _money -= autocliperCost;
      _autoclippers++;
      _levelSystem.addAutoclipperPurchase();
      notifyListeners();
    }
  }

  void purchaseUpgrade(String id) {
    final upgrade = upgrades[id];
    if (upgrade != null && _money >= upgrade.currentCost && upgrade.level < upgrade.maxLevel) {
      _money -= upgrade.currentCost;
      upgrade.level++;
      _levelSystem.addUpgradePurchase(upgrade.level);
      notifyListeners();

      // Debug log pour vérifier
      print('Upgrade $id purchased. New level: ${upgrade.level}');
      print('Current bonuses:');
      print('Bulk: ${1.0 + (upgrades['bulk']?.level ?? 0) * 0.35}');
      print('Efficiency: ${1.0 - ((upgrades['efficiency']?.level ?? 0) * 0.15)}');
      print('Speed: ${1.0 + (upgrades['speed']?.level ?? 0) * 0.20}');
    }
  }

  void producePaperclip() {
    if (_metal >= GameConstants.METAL_PER_PAPERCLIP) {
      _paperclips++;
      _totalPaperclipsProduced++;
      _metal -= GameConstants.METAL_PER_PAPERCLIP;
      _levelSystem.addManualProduction();
      resourceManager.checkMetalStatus(levelSystem.level, maxMetalStorage, _metal);
      notifyListeners();
    }
  }

  @override
  void processMarket() {
    double calculatedDemand = marketManager.calculateDemand(_sellPrice, getMarketingLevel());
    int potentialSales = calculatedDemand.floor();

    // Limiter les ventes au stock disponible
    potentialSales = min(potentialSales, _paperclips.floor());

    if (potentialSales > 0) {  // Vérification modifiée
      double qualityBonus = 1.0 + (upgrades['quality']?.level ?? 0) * 0.10;
      double salePrice = _sellPrice * qualityBonus;

      // Ajout d'une limite sur les ventes en fonction de la réputation
      int actualSales = (potentialSales * marketManager.reputation).floor();

      // Double vérification pour éviter les nombres négatifs
      actualSales = min(actualSales, _paperclips.floor());

      _paperclips -= actualSales;
      _money += actualSales * salePrice;
      marketManager.recordSale(actualSales, salePrice);
      _levelSystem.addSale(actualSales, salePrice);
      notifyListeners();
    }
  }
  Future<void> startNewGame([String? name]) async {
    // Réinitialiser toutes les valeurs
    resetGame();
    if (name != null) {
      _gameName = name;
    }
    _isGameInitialized = true;
    startProductionTimer(); // S'assurer que la production démarre
    notifyListeners();
  }



  int getMarketingLevel() {
    return upgrades['marketing']?.level ?? 0;
  }

  // Save/Load integration

  void resetGame() {
    _paperclips = 0;
    _metal = GameConstants.INITIAL_METAL;
    _money = GameConstants.INITIAL_MONEY;
    _autoclippers = 0;
    // Réinitialiser les autres valeurs...
    _isGameInitialized = false;
    productionTimer?.cancel();
  }


  Future<void> loadGame(String name) async {
    final saveGame = await SaveManager.loadGame(name);
    if (saveGame != null) {
      _loadGameData(saveGame.gameData);
      _gameName = name;
      _startGameSystems(); // Redémarrage des systèmes après chargement
      notifyListeners();
    }
  }

  Map<String, dynamic> prepareGameData() {
    return {
      'paperclips': _paperclips,
      'metal': _metal,
      'money': _money,
      'sellPrice': _sellPrice,
      'autoclippers': _autoclippers,
      'currentMetalPrice': _currentMetalPrice,
      'totalPaperclipsProduced': _totalPaperclipsProduced,
      'totalTimePlayedInSeconds': _totalTimePlayedInSeconds,
      'upgrades': upgrades.map((key, value) => MapEntry(key, value.toJson())),
      'marketReputation': marketManager.reputation,
      'marketMetalStock': _metal,  // Utiliser _metal au lieu de resourceManager.marketMetalStock
      'levelSystem': _levelSystem.toJson(),
    };
  }

  void _loadGameData(Map<String, dynamic> data) {
    // Conversion sûre avec cast de type
    _paperclips = (data['paperclips'] as num?)?.toDouble() ?? 0.0;
    _metal = (data['metal'] as num?)?.toDouble() ?? GameConstants.INITIAL_METAL;
    _money = (data['money'] as num?)?.toDouble() ?? GameConstants.INITIAL_MONEY;
    _sellPrice = (data['sellPrice'] as num?)?.toDouble() ?? GameConstants.INITIAL_PRICE;
    _autoclippers = (data['autoclippers'] as num?)?.toInt() ?? 0;
    _currentMetalPrice = (data['currentMetalPrice'] as num?)?.toDouble() ?? GameConstants.MIN_METAL_PRICE;
    _totalPaperclipsProduced = (data['totalPaperclipsProduced'] as num?)?.toInt() ?? 0;
    _totalTimePlayedInSeconds = (data['totalTimePlayedInSeconds'] as num?)?.toInt() ?? 0;

    if (data['upgrades'] != null) {
      final savedUpgrades = data['upgrades'] as Map<String, dynamic>;
      savedUpgrades.forEach((key, value) {
        if (upgrades.containsKey(key)) {
          try {
            final upgradeData = value as Map<String, dynamic>;
            final upgrade = upgrades[key];
            if (upgrade != null) {
              upgrade.level = (upgradeData['level'] as num?)?.toInt() ?? 0;
            }
          } catch (e) {
            print('Erreur lors du chargement de l\'upgrade $key: $e');
          }
        }

      });
    }
    if (data['marketMetalStock'] != null) {
      resourceManager.loadFromJson({
        'marketMetalStock': data['marketMetalStock']
      });
    }

    if (data['levelSystem'] != null) {
      try {
        final levelData = data['levelSystem'] as Map<String, dynamic>;
        _levelSystem.loadFromJson(levelData);  // Utiliser une méthode d'instance à la place
      } catch (e) {
        print('Erreur lors du chargement du niveau: $e');
        _levelSystem = LevelSystem();  // Réinitialiser en cas d'erreur
      }
    }

    marketManager.reputation = (data['marketReputation'] as num?)?.toDouble() ?? 1.0;
  }

  void _resetGameState() {
    _paperclips = 0;
    _metal = GameConstants.INITIAL_METAL;
    _money = GameConstants.INITIAL_MONEY;
    _sellPrice = GameConstants.INITIAL_PRICE;
    _autoclippers = 0;
    _currentMetalPrice = GameConstants.MIN_METAL_PRICE;
    _totalPaperclipsProduced = 0;
    _totalTimePlayedInSeconds = 0;
    upgrades.forEach((key, value) => value.reset());
    _levelSystem = LevelSystem();
    _startGameSystems();
  }

  void setContext(BuildContext context) {
    _context = context;
    _startAutoSave();
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (_gameName != null) {
        await SaveManager.saveGame(this, _gameName!);
      }
    });
  }


  void activateXPBoost() {
    levelSystem.applyXPBoost(2.0, const Duration(minutes: 5));
    EventManager.triggerNotificationPopup(
      title: 'Bonus XP activé !',
      description: 'x2 XP pendant 5 minutes',
      icon: Icons.stars,
    );
  }
  void checkMilestones() {
    if (_levelSystem.level % 5 == 0) {
      activateXPBoost();
    }
  }

  void activateTemporaryBoost(double multiplier, Duration duration) {
    _levelSystem.applyXPBoost(multiplier, duration);
  }

  void checkResourceCrisis() {
    if (resourceManager.marketMetalStock <= ResourceManager.WARNING_THRESHOLD) {  // Utiliser ResourceManager.WARNING_THRESHOLD
      EventManager.addEvent(
          EventType.RESOURCE_DEPLETION,
          "Ressources en diminution",
          description: "Les réserves mondiales de métal s'amenuisent",
          importance: EventImportance.HIGH
      );
    }
  }
}