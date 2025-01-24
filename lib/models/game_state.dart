// lib/models/game_state.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_config.dart';
import 'event_system.dart';
import 'player_manager.dart';
import 'market.dart';
import 'progression_system.dart';
import 'resource_manager.dart';
import 'game_state_interfaces.dart';
import '../services/save_manager.dart';
import 'dart:convert';
import '../utils/notification_manager.dart';

class GameState extends ChangeNotifier {


  // Timers
  Timer? _productionTimer;
  Timer? _marketTimer;
  Timer? _metalPriceTimer;
  Timer? _playTimeTimer;
  Timer? _autoSaveTimer;
  Timer? _maintenanceTimer;

  // État du jeu
  bool _isPaused = false;
  String? _gameName;
  BuildContext? _context;
  DateTime _lastUpdateTime = DateTime.now();
  int _totalTimePlayedInSeconds = 0;
  int _totalPaperclipsProduced = 0;
  DateTime? _lastSaveTime;
  double _maintenanceCosts = 0.0;


  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPaused => _isPaused;
  String? get gameName => _gameName;
  DateTime? get lastSaveTime => _lastSaveTime;
  int get totalTimePlayed => _totalTimePlayedInSeconds;
  int get totalPaperclipsProduced => _totalPaperclipsProduced;
  double get maintenanceCosts => _maintenanceCosts;
  Map<String, Upgrade> get upgrades => playerManager.upgrades;
  double get maxMetalStorage => playerManager.maxMetalStorage;
  PlayerManager get player => playerManager;
  MarketManager get market => marketManager;
  ResourceManager get resources => resourceManager;
  LevelSystem get level => levelSystem;

  bool _isInitialized = false;
  late final PlayerManager playerManager;
  late final MarketManager marketManager;
  late final LevelSystem levelSystem;
  late final MissionSystem missionSystem;
  late final ResourceManager resourceManager;

  double get autocliperCost {
    double baseCost = GameConstants.BASE_AUTOCLIPPER_COST * (1.15 * player.autoclippers);
    double automationDiscount = 1.0 - ((player.upgrades['automation']?.level ?? 0) * 0.10);
    return baseCost * automationDiscount;
  }



  // Constructeur et initialisation
  GameState() {
    _initializeGame();
  }

  void _initializeGame() {

    // Initialisation des systèmes dans le bon ordre
    levelSystem = LevelSystem()
      ..onLevelUp = _handleLevelUp;

    playerManager = PlayerManager(levelSystem);

    marketManager = MarketManager(MarketDynamics())
      ..updateMarket();

    resourceManager = ResourceManager();  // Initialisation du ResourceManager

    missionSystem = MissionSystem()
      ..initialize()
      ..onMissionCompleted = _handleMissionCompleted;

    _startTimers();
    notifyListeners();
  }


  void reset() {
    _stopTimers();
    player.resetResources();
    level.reset();
    marketManager = MarketManager(MarketDynamics());
    missionSystem = MissionSystem()..initialize();
    _startTimers();
    // Réinitialiser _isInitialized
    _isInitialized = false;
    notifyListeners();
  }

  void resetMarket() {
    marketManager = MarketManager(MarketDynamics());
    market.updateMarket();
  }

  // Gestion des timers
  void _startTimers() {
    _stopTimers();

    _productionTimer = Timer.periodic(
        const Duration(seconds: 1),
            (_) => _processProduction()
    );

    _marketTimer = Timer.periodic(
        const Duration(milliseconds: 500),
            (_) => _processMarket()
    );

    _metalPriceTimer = Timer.periodic(
        const Duration(seconds: 4),
            (_) {
          marketManager.updateMetalPrice();
          notifyListeners();
        }
    );

    _playTimeTimer = Timer.periodic(
        const Duration(seconds: 1),
            (_) {
          _totalTimePlayedInSeconds++;
          notifyListeners();
        }
    );

    _startAutoSave();

    _maintenanceTimer = Timer.periodic(
        const Duration(minutes: 1),
            (_) => _applyMaintenanceCosts()
    );
  }
  void _applyMaintenanceCosts() {
    if (player.autoclippers == 0) return;

    _maintenanceCosts = player.autoclippers * GameConstants.STORAGE_MAINTENANCE_RATE;

    if (player.money >= _maintenanceCosts) {
      player.updateMoney(player.money - _maintenanceCosts);
      notifyListeners();
    } else {
      player.updateAutoclippers((player.autoclippers * 0.9).floor());
      EventManager.instance.addEvent(
          EventType.RESOURCE_DEPLETION,
          "Maintenance impayée !",
          description: "Certaines autoclippeuses sont hors service",
          importance: EventImportance.HIGH
      );
    }
  }
  Map<String, dynamic> prepareGameData() {
    return {
      'playerManager': playerManager.toJson(),
      'marketManager': marketManager.toJson(),
      'levelSystem': levelSystem.toJson(),
      'missionSystem': missionSystem.toJson(),
      'totalTimePlayedInSeconds': _totalTimePlayedInSeconds,
      'totalPaperclipsProduced': _totalPaperclipsProduced,
      'paperclips': playerManager.paperclips,
      'money': playerManager.money,
      'metal': playerManager.metal,
      'autoclippers': playerManager.autoclippers,
    };
  }
  Future<void> loadGame(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('save_$name');

      if (savedData == null) {
        throw Exception('Sauvegarde non trouvée');
      }

      final gameData = jsonDecode(savedData);
      _gameName = name;
      _loadGameData(gameData);
      _startTimers();

      // Mettre _isInitialized à true seulement après le chargement réussi
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading game: $e');
      rethrow;
    }
  }

  void _stopTimers() {
    _productionTimer?.cancel();
    _marketTimer?.cancel();
    _metalPriceTimer?.cancel();
    _playTimeTimer?.cancel();
    _autoSaveTimer?.cancel();
    _maintenanceTimer?.cancel();
  }


  // Production et marché
  void _processProduction() {
    if (_isPaused) return;

    final now = DateTime.now();
    final elapsed = now.difference(_lastUpdateTime).inMilliseconds / 1000;
    _lastUpdateTime = now;

    double manualProduction = _calculateManualProduction(elapsed);
    double autoProduction = _calculateAutoProduction(elapsed);
    _applyProduction(manualProduction + autoProduction);

    checkMetalStorage();
    checkResourceCrisis();
    notifyListeners();
  }

  double _calculateManualProduction(double elapsed) {
    if (player.metal < GameConstants.METAL_PER_PAPERCLIP) return 0;

    double metalUsed = GameConstants.METAL_PER_PAPERCLIP;
    double efficiencyBonus = 1.0 + (player.upgrades['efficiency']?.level ?? 0) * 0.1;
    metalUsed /= efficiencyBonus;

    player.updateMetal(player.metal - metalUsed);
    return 1.0 * elapsed;
  }

  double _calculateAutoProduction(double elapsed) {
    if (player.autoclippers == 0) return 0;
    if (player.metal < GameConstants.MIN_METAL_CONSUMPTION) return 0;

    double baseProduction = player.autoclippers * elapsed;
    double efficiencyBonus = 1.0 + (player.upgrades['efficiency']?.level ?? 0) * 0.15;
    double speedBonus = 1.0 + (player.upgrades['speed']?.level ?? 0) * 0.20;
    double bulkBonus = 1.0 + (player.upgrades['bulk']?.level ?? 0) * 0.35;

    double totalProduction = baseProduction * speedBonus * bulkBonus;
    double metalNeeded = totalProduction * GameConstants.METAL_PER_PAPERCLIP / efficiencyBonus;

    if (metalNeeded > player.metal) {
      totalProduction = (player.metal * efficiencyBonus) / GameConstants.METAL_PER_PAPERCLIP;
      metalNeeded = player.metal;
    }

    player.updateMetal(player.metal - metalNeeded);
    return totalProduction;
  }
  void _applyProduction(double amount) {
    if (amount <= 0) return;

    player.updatePaperclips(player.paperclips + amount);
    _totalPaperclipsProduced += amount.floor();
    level.addAutomaticProduction(amount.floor());

    missionSystem.updateMissions(
        MissionType.PRODUCE_PAPERCLIPS,
        amount
    );
  }

  void _processMarket() {
    if (_isPaused) return;

    market.updateMarket();

    double demand = market.calculateDemand(
        player.sellPrice,
        player.upgrades['marketing']?.level ?? 0
    );

    int sales = min(demand.floor(), player.paperclips.floor());
    if (sales > 0) {
      _processSales(sales);
    }
  }

  void _processSales(int quantity) {
    double qualityBonus = 1.0 + (player.upgrades['quality']?.level ?? 0) * 0.1;
    double salePrice = player.sellPrice * qualityBonus;
    double revenue = quantity * salePrice;

    player.updatePaperclips(player.paperclips - quantity);
    player.updateMoney(player.money + revenue);

    market.recordSale(quantity, salePrice);
    level.addSale(quantity, salePrice);

    missionSystem.updateMissions(
        MissionType.SELL_PAPERCLIPS,
        quantity.toDouble()
    );
  }

  // Gestion des notifications et événements
  void checkMetalStorage() {
    double stockPercentage = player.metal / player.maxMetalStorage;
    if (stockPercentage >= 0.9) {
      final notification = NotificationEvent(
        title: "Stockage Critique",
        description: "Stockage à ${(stockPercentage * 100).toInt()}%",
        detailedDescription: """
Votre stockage de métal atteint ses limites !

État actuel :
• Capacité totale: ${player.maxMetalStorage}
• Métal stocké: ${player.metal.toInt()}
• Taux d'occupation: ${(stockPercentage * 100).toInt()}%

Actions recommandées :
1. Augmentez votre capacité de stockage
2. Accélérez la production
3. Vendez l'excès de métal
            """,
        icon: Icons.warehouse,
        priority: NotificationPriority.HIGH,
      );

      if (_context != null) {
        NotificationManager.showGameNotification(
          _context!,
          event: notification,
        );
      }
    }
  }

  void checkResourceCrisis() {
    if (marketManager.marketMetalStock <= GameConstants.WARNING_THRESHOLD) {
      EventManager.instance.addEvent(
          EventType.RESOURCE_DEPLETION,
          "Ressources en diminution",
          description: "Les réserves mondiales de métal s'amenuisent",
          importance: EventImportance.HIGH
      );
    }
  }

  // Actions du jeu
  void buyMetal() {
    double metalPrice = market.currentMetalPrice;
    if (player.money >= metalPrice) {
      double amount = GameConstants.METAL_PACK_AMOUNT;

      if (player.metal + amount <= player.maxMetalStorage) {
        player.updateMetal(player.metal + amount);
        player.updateMoney(player.money - metalPrice);
        notifyListeners();
      } else {
        EventManager.instance.addEvent(
            EventType.RESOURCE_DEPLETION,
            "Stockage plein",
            description: "Impossible d'acheter plus de métal. Améliorez votre stockage!",
            importance: EventImportance.HIGH
        );
      }
    }
  }

  void buyAutoclipper() {
    if (player.money >= autocliperCost) {
      player.updateMoney(player.money - autocliperCost);
      player.updateAutoclippers(player.autoclippers + 1);
      level.addAutoclipperPurchase();
      notifyListeners();
    }
  }

  void producePaperclip() {
    if (player.metal >= GameConstants.METAL_PER_PAPERCLIP) {
      player.updatePaperclips(player.paperclips + 1);
      _totalPaperclipsProduced++;
      player.updateMetal(player.metal - GameConstants.METAL_PER_PAPERCLIP);
      level.addManualProduction();
      notifyListeners();
    }
  }

  void setSellPrice(double newPrice) {
    if (market.isPriceExcessive(newPrice)) {
      final notification = NotificationEvent(
        title: "Prix Excessif!",
        description: "Ce prix pourrait affecter vos ventes",
        detailedDescription: market.getPriceRecommendation(),
        icon: Icons.price_change,
        priority: NotificationPriority.HIGH,
      );

      if (_context != null) {
        NotificationManager.showGameNotification(_context!, event: notification);
      }
    }
    player.updateSellPrice(newPrice);  // Utiliser updateSellPrice au lieu de l'affectation directe
    notifyListeners();
  }

  // Gestion des niveaux et missions
  void _handleLevelUp(int newLevel, List<UnlockableFeature> newFeatures) {
    for (var feature in newFeatures) {
      switch (feature) {
        case UnlockableFeature.MANUAL_PRODUCTION:
          _showUnlockNotification('Production manuelle débloquée !');
          break;
        case UnlockableFeature.MARKET_SALES:
          _showUnlockNotification('Ventes débloquées !');
          break;
        case UnlockableFeature.AUTOCLIPPERS:
          _showUnlockNotification('Autoclippeuses disponibles !');
          player.updateMoney(player.money + GameConstants.BASE_AUTOCLIPPER_COST);  // Utiliser updateMoney
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
    }

    checkMilestones();
    notifyListeners();
  }

  void _handleMissionCompleted(Mission mission) {
    levelSystem.gainExperience(mission.experienceReward);

    EventManager.instance.addEvent(
        EventType.SPECIAL_ACHIEVEMENT,
        "Mission accomplie !",
        description: "${mission.title} - ${mission.experienceReward} XP gagnés",
        importance: EventImportance.MEDIUM
    );
  }
  Future<void> startNewGame(String name) async {
    _gameName = name;
    playerManager.resetResources();
    levelSystem.reset();

    // Sauvegarder l'état initial
    await saveGame(name);

    // Mettre _isInitialized à true seulement après la création réussie
    _isInitialized = true;
    notifyListeners();
  }

  // Gestion de la sauvegarde
  Future<void> _loadSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(GameConstants.SAVE_KEY);
    if (savedData != null) {
      final gameData = jsonDecode(savedData);
      _loadGameData(gameData);
    }
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (_gameName != null) {
        await saveGame(_gameName!);
      }
    });
  }

  Future<void> saveGame(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _gameName = name;
      _lastSaveTime = DateTime.now();

      final gameData = {
        'version': GameConstants.VERSION,
        'timestamp': _lastSaveTime!.toIso8601String(),
        'playerManager': playerManager.toJson(),
        'marketManager': marketManager.toJson(),
        'levelSystem': levelSystem.toJson(),
        'missionSystem': missionSystem.toJson(),
        'totalTimePlayedInSeconds': _totalTimePlayedInSeconds,
        'totalPaperclipsProduced': _totalPaperclipsProduced,
      };

      await prefs.setString('save_$name', jsonEncode(gameData));
    } catch (e) {
      print('Error saving game: $e');
      rethrow;
    }
  }

  Map<String, bool> getVisibleScreenElements() {
    return {
      // Éléments de base
      'metalStock': true,  // Toujours visible
      'paperclipStock': true,  // Toujours visible
      'manualProductionButton': true,  // Toujours visible
      'moneyDisplay': true,  // Toujours visible

      // Éléments de marché
      'market': level.level >= GameConstants.MARKET_UNLOCK_LEVEL,
      'marketPrice': level.level >= GameConstants.MARKET_UNLOCK_LEVEL,
      'sellButton': level.level >= GameConstants.MARKET_UNLOCK_LEVEL,
      'marketStats': level.level >= GameConstants.MARKET_UNLOCK_LEVEL,
      'priceChart': level.level >= GameConstants.MARKET_UNLOCK_LEVEL,

      // Éléments de production
      'metalPurchaseButton': level.level >= 1,
      'autoclippersSection': level.level >= 3,
      'productionStats': level.level >= 2,
      'efficiencyDisplay': level.level >= 3,

      // Éléments d'amélioration
      'upgradesSection': level.level >= GameConstants.UPGRADES_UNLOCK_LEVEL,
      'upgradesScreen': level.level >= GameConstants.UPGRADES_UNLOCK_LEVEL,

      // Éléments de progression
      'levelDisplay': true,
      'experienceBar': true,
      'comboDisplay': level.level >= 2,

      // Éléments de statistiques
      'statsSection': level.level >= 4,
      'achievementsSection': level.level >= 5,

      // Éléments d'interface
      'settingsButton': true,
      'musicToggle': true,
      'notificationButton': true,
      'saveLoadButtons': true
    };
  }

  bool purchaseUpgrade(String upgradeId) {
    return playerManager.purchaseUpgrade(upgradeId);
  }


  void _loadGameData(Map<String, dynamic> data) {
    playerManager.loadFromJson(data['playerManager'] ?? {});
    marketManager.fromJson(data['marketManager'] ?? {});
    levelSystem.loadFromJson(data['levelSystem'] ?? {});
    missionSystem.fromJson(data['missionSystem'] ?? {});

    _totalTimePlayedInSeconds = (data['totalTimePlayedInSeconds'] as num?)?.toInt() ?? 0;
    _totalPaperclipsProduced = (data['totalPaperclipsProduced'] as num?)?.toInt() ?? 0;

    _lastUpdateTime = DateTime.now();
    notifyListeners();
  }

  // Utilitaires et autres
  void setContext(BuildContext context) {
    _context = context;
    _startAutoSave();
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
    }
  }

  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void checkMilestones() {
    if (levelSystem.level % 5 == 0) {
      activateXPBoost();
    }
  }

  void activateXPBoost() {
    levelSystem.applyXPBoost(2.0, const Duration(minutes: 5));
    EventManager.instance.addEvent(
        EventType.XP_BOOST,
        'Bonus XP activé !',
        description: 'x2 XP pendant 5 minutes',
        importance: EventImportance.MEDIUM
    );
  }

  @override
  void dispose() {
    _stopTimers();
    playerManager.dispose();
    levelSystem.dispose();
    missionSystem.dispose();
    super.dispose();
  }
}