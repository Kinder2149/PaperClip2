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
  static final GameState _instance = GameState._internal();
  factory GameState() => _instance;

  // Managers comme propriétés sans 'late'
  final LevelSystem levelSystem = LevelSystem();
  PlayerManager? _playerManager;
  MarketManager? _marketManager;
  ResourceManager? _resourceManager;
  MissionSystem? _missionSystem;
  // Getters sécurisés
  PlayerManager get playerManager => _playerManager!;
  MarketManager get marketManager => _marketManager!;
  ResourceManager get resourceManager => _resourceManager!;
  MissionSystem get missionSystem => _missionSystem!;
  DateTime _lastUpdateTime = DateTime.now();

  DateTime? _lastSaveTime;
  bool _isPaused = false;
  // État privé
  bool _isInitialized = false;
  String? _gameName;
  BuildContext? _context;
  int _totalTimePlayedInSeconds = 0;
  int _totalPaperclipsProduced = 0;
  double _maintenanceCosts = 0.0;
  // Constructeur privé
  GameState._internal() {
    levelSystem.onLevelUp = _handleLevelUp;
  }

  // Gestionnaire de timers centralisé
  final Map<String, Timer> _timers = {};

  // Getters
  bool get isInitialized => _isInitialized;
  String? get gameName => _gameName;
  int get totalTimePlayed => _totalTimePlayedInSeconds;
  int get totalPaperclipsProduced => _totalPaperclipsProduced;
  double get maintenanceCosts => _maintenanceCosts;


  // Timers
  // Ajouter après les propriétés existantes (vers ligne 43)
  static const Duration GAME_LOOP_INTERVAL = Duration(milliseconds: 100);
  static const Duration MARKET_UPDATE_INTERVAL = Duration(seconds: 2);
  static const Duration AUTOSAVE_INTERVAL = Duration(minutes: 5);
  static const Duration MAINTENANCE_INTERVAL = Duration(minutes: 1);

  Timer? _gameLoopTimer;
  int _ticksSinceLastMarketUpdate = 0;
  int _ticksSinceLastAutoSave = 0;
  int _ticksSinceLastMaintenance = 0;






  Map<String, Upgrade> get upgrades => playerManager.upgrades;
  double get maxMetalStorage => playerManager.maxMetalStorage;
  PlayerManager get player => playerManager;
  MarketManager get market => marketManager;
  ResourceManager get resources => resourceManager;
  LevelSystem get level => levelSystem;



  double get autocliperCost {
    double baseCost = GameConstants.BASE_AUTOCLIPPER_COST * (1.15 * player.autoclippers);
    double automationDiscount = 1.0 - ((player.upgrades['automation']?.level ?? 0) * 0.10);
    return baseCost * automationDiscount;
  }




  void _initializeManagers() {
    _stopAllTimers();

    // Créer de nouvelles instances des managers
    _playerManager = PlayerManager(levelSystem);
    _marketManager = MarketManager(MarketDynamics());
    _resourceManager = ResourceManager();
    _missionSystem = MissionSystem()..initialize();

    _startTimers();
    _isInitialized = true;
  }




  void reset() {
    _stopAllTimers();
    player.resetResources();
    level.reset();
    _marketManager = MarketManager(MarketDynamics());  // Utiliser l'affectation avec _
    _missionSystem = MissionSystem()..initialize();    // Utiliser l'affectation avec _
    _startTimers();
    _isInitialized = false;
    notifyListeners();
  }

  void resetMarket() {
    _marketManager = MarketManager(MarketDynamics());
    market.updateMarket();
  }
  void checkResourceLevels() {
    if (marketManager.marketMetalStock <= GameConstants.WARNING_THRESHOLD) {
      EventManager.instance.addEvent(
          EventType.RESOURCE_DEPLETION,
          "Ressources en diminution",
          description: "Les réserves mondiales de métal s'amenuisent",
          importance: EventImportance.HIGH
      );
    }
  }
  double _calculateManualProduction(double elapsed) {
    if (playerManager.metal < GameConstants.METAL_PER_PAPERCLIP) return 0;

    double metalUsed = GameConstants.METAL_PER_PAPERCLIP;
    double efficiencyBonus = 1.0 + (playerManager.upgrades['efficiency']?.level ?? 0) * 0.1;
    metalUsed /= efficiencyBonus;

    playerManager.updateMetal(playerManager.metal - metalUsed);
    return 1.0 * elapsed;
  }

  // Gestion des timers
  void _startTimers() {
    _stopAllTimers();
    _lastUpdateTime = DateTime.now();

    _gameLoopTimer = Timer.periodic(GameConstants.GAME_LOOP_INTERVAL, (timer) {
      if (_isPaused) return;
      _processProduction();
    });
  }


  void _stopAllTimers() {
    _gameLoopTimer?.cancel();
    _gameLoopTimer = null;
    _ticksSinceLastMarketUpdate = 0;
    _ticksSinceLastAutoSave = 0;
    _ticksSinceLastMaintenance = 0;
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
    // Préparation des données de base
    final Map<String, dynamic> baseData = {
      'version': GameConstants.VERSION,
      'timestamp': DateTime.now().toIso8601String(),
      'totalTimePlayedInSeconds': _totalTimePlayedInSeconds,
      'totalPaperclipsProduced': _totalPaperclipsProduced,
    };

    // Ajout des données des managers
    try {
      baseData['playerManager'] = playerManager.toJson();
      baseData['marketManager'] = marketManager.toJson();
      baseData['levelSystem'] = levelSystem.toJson();
      baseData['missionSystem'] = missionSystem?.toJson();

      // Debug
      print('PrepareGameData - playerManager data:');
      print(baseData['playerManager']);

      return baseData;
    } catch (e) {
      print('Erreur dans prepareGameData: $e');
      rethrow;
    }
  }





  // Production et marché
  void _processProduction() {
    if (_isPaused || playerManager.autoclippers <= 0) return;

    // Production par tick (100ms)
    _calculateAutoProduction();
  }



  double _calculateProduction(double elapsed) {
    double manualProduction = _calculateManualProduction(elapsed);
    // Supprimez cette ligne car _calculateAutoProduction est void maintenant
    // double autoProduction = _calculateAutoProduction(elapsed);
    return manualProduction;
  }
  void _calculateAutoProduction() {
    if (playerManager.autoclippers <= 0) return;

    // Production de base : 0.1 trombone par tick (donc 1 par seconde)
    double baseProduction = playerManager.autoclippers * GameConstants.BASE_PRODUCTION_PER_TICK;

    // Application des bonus
    double speedBonus = 1.0 + (playerManager.upgrades['speed']?.level ?? 0) * 0.20;
    double bulkBonus = 1.0 + (playerManager.upgrades['bulk']?.level ?? 0) * 0.35;
    double efficiencyBonus = 1.0 + (playerManager.upgrades['efficiency']?.level ?? 0) * 0.15;

    // Production totale
    double totalProduction = baseProduction * speedBonus * bulkBonus;

    // Métal nécessaire
    double metalNeeded = totalProduction * GameConstants.METAL_PER_PAPERCLIP / efficiencyBonus;

    // Vérification du métal disponible
    if (metalNeeded > playerManager.metal) {
      totalProduction = (playerManager.metal * efficiencyBonus) / GameConstants.METAL_PER_PAPERCLIP;
      metalNeeded = playerManager.metal;
    }

    if (totalProduction > 0) {
      // Application de la production
      playerManager.updateMetal(playerManager.metal - metalNeeded);
      playerManager.updatePaperclips(playerManager.paperclips + totalProduction);

      // Logs de debug
      print('AutoClipper Production:');
      print('- Nombre d\'autoclippers: ${playerManager.autoclippers}');
      print('- Production par tick: ${totalProduction.toStringAsFixed(2)} trombones');
      print('- Production par seconde: ${(totalProduction * GameConstants.TICKS_PER_SECOND).toStringAsFixed(2)} trombones/s');
      print('- Métal utilisé: ${metalNeeded.toStringAsFixed(2)}');
      print('- Métal restant: ${playerManager.metal.toStringAsFixed(2)}');
    }
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
  Future<void> _autoSave() async {
    if (!_isInitialized || _gameName == null) return;

    try {
      await saveGame(_gameName!);
      _lastSaveTime = DateTime.now();
    } catch (e) {
      print('Erreur lors de la sauvegarde automatique: $e');
      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text('Erreur de sauvegarde automatique: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _processMarket() {
    if (!_isInitialized) return;

    marketManager.updateMarket();
    double demand = marketManager.calculateDemand(
        playerManager.sellPrice,
        playerManager.getMarketingLevel()
    );

    int potentialSales = min(demand.floor(), playerManager.paperclips.floor());
    if (potentialSales > 0) {
      _processSales(potentialSales);
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
    if (!_canBuyMetal()) return;

    double metalPrice = marketManager.currentMetalPrice;
    double amount = GameConstants.METAL_PACK_AMOUNT;

    playerManager.updateMoney(playerManager.money - metalPrice);
    playerManager.updateMetal(playerManager.metal + amount);
    marketManager.updateMarketStock(-amount);

    notifyListeners();
  }

  bool _canBuyMetal() {
    double metalPrice = marketManager.currentMetalPrice;
    double currentMetal = playerManager.metal;
    double maxStorage = playerManager.maxMetalStorage;

    return playerManager.money >= metalPrice &&
        currentMetal + GameConstants.METAL_PACK_AMOUNT <= maxStorage;
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
    if (player.consumeMetal(GameConstants.METAL_PER_PAPERCLIP)) {
      player.updatePaperclips(player.paperclips + 1);
      _totalPaperclipsProduced++;
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
  // Dans GameState, ajoutez un logger pour le debug
  Future<void> startNewGame(String name) async {
    try {
      print('Starting new game with name: $name');
      _gameName = name;

      // Initialiser les managers
      _initializeManagers();

      // Réinitialiser les ressources
      _playerManager?.resetResources();
      levelSystem.reset();

      // Sauvegarder l'état initial
      await SaveManager.saveGame(this, name);

      notifyListeners();
    } catch (e) {
      print('Error starting new game: $e');
      rethrow;
    }
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
  Future<void> loadGame(String name) async {
    try {
      final saveGame = await SaveManager.loadGame(name);
      if (saveGame == null) throw SaveError('NOT_FOUND', 'Sauvegarde non trouvée');

      _stopAllTimers();

      // Initialiser de nouveaux managers
      _initializeManagers();

      // Accéder aux données via l'objet SaveGame
      final gameData = saveGame.gameData;

      // Charger les données dans les managers
      levelSystem.loadFromJson(gameData['levelSystem'] ?? {});
      _playerManager?.fromJson(gameData['playerManager'] ?? {});
      _marketManager?.fromJson(gameData['marketManager'] ?? {});

      // Charger les statistiques globales
      _totalTimePlayedInSeconds = gameData['totalTimePlayedInSeconds'] ?? 0;
      _totalPaperclipsProduced = gameData['totalPaperclipsProduced'] ?? 0;

      _gameName = name;
      _lastSaveTime = saveGame.lastSaveTime;

      _startTimers();
      notifyListeners();
    } catch (e) {
      print('Error loading game: $e');
      rethrow;
    }
  }

  void _loadGameData(Map<String, dynamic> gameData) {
    if (gameData['playerManager'] != null) {
      playerManager.loadFromJson(gameData['playerManager']);
    }
    if (gameData['marketManager'] != null) {
      marketManager.fromJson(gameData['marketManager']);
    }
    if (gameData['levelSystem'] != null) {
      levelSystem.loadFromJson(gameData['levelSystem']);
    }
    if (gameData['missionSystem'] != null) {
      missionSystem.fromJson(gameData['missionSystem']);
    }

    _totalTimePlayedInSeconds = (gameData['totalTimePlayedInSeconds'] as num?)?.toInt() ?? 0;
    _totalPaperclipsProduced = (gameData['totalPaperclipsProduced'] as num?)?.toInt() ?? 0;
  }



  Future<void> saveGame(String name) async {
    if (!_isInitialized) {
      throw SaveError('NOT_INITIALIZED', 'Le jeu n\'est pas initialisé');
    }

    try {
      await SaveManager.saveGame(this, name);
      _gameName = name;
      _lastSaveTime = DateTime.now();
      notifyListeners();
    } catch (e) {
      print('Erreur dans GameState.saveGame: $e');
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
    if (!playerManager.canAffordUpgrade(upgradeId)) return false;

    bool success = playerManager.purchaseUpgrade(upgradeId);
    if (success) {
      levelSystem.addUpgradePurchase(
          playerManager.upgrades[upgradeId]?.level ?? 0
      );
    }

    return success;
  }





  // Utilitaires et autres
  void setContext(BuildContext context) {
    _context = context;
  }

  void _showUnlockNotification(String message) {
    EventManager.instance.addNotification(
      NotificationEvent(
        title: 'Nouveau Déblocage !',
        description: message,
        icon: Icons.lock_open,
        priority: NotificationPriority.HIGH,
      ),
    );
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
    _stopAllTimers();
    _gameLoopTimer?.cancel();
    playerManager.dispose();
    levelSystem.dispose();
    super.dispose();
  }
}