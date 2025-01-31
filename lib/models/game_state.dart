// lib/models/game_state.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
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
import '../dialogs/metal_crisis_dialog.dart';
import '../services/auto_save_service.dart';

class GameState extends ChangeNotifier {
  late final PlayerManager _playerManager;
  late final MarketManager _marketManager;
  late final ResourceManager _resourceManager;
  late final LevelSystem _levelSystem;
  late final MissionSystem _missionSystem;
  bool _isInCrisisMode = false;
  bool _crisisTransitionComplete = false;
  DateTime? _crisisStartTime;
  late final StatisticsManager _statistics;
  StatisticsManager get statistics => _statistics;
  Timer? _playTimeTimer;
  Timer? marketTimer;
  late final AutoSaveService _autoSaveService;
  bool get isInCrisisMode => _isInCrisisMode;
  bool get crisisTransitionComplete => _crisisTransitionComplete;



  bool _isInitialized = false;
  String? _gameName;
  BuildContext? _context;

  bool get isInitialized => _isInitialized;
  String? get gameName => _gameName;
  PlayerManager get playerManager => _playerManager;
  MarketManager get marketManager => _marketManager;
  ResourceManager get resourceManager => _resourceManager;
  LevelSystem get levelSystem => _levelSystem;
  MissionSystem get missionSystem => _missionSystem;
  GameState() {
    _initializeManagers();
  }
  void _initializeManagers() {
    if (!_isInitialized) {
      // Étape 1 : Création des managers
      _createManagers();

      // Étape 2 : Configuration et démarrage
      _configureAndStart();

      _isInitialized = true;
    }
  }

  void _createManagers() {
    try {
      _statistics = StatisticsManager();
      _resourceManager = ResourceManager();
      _marketManager = MarketManager(MarketDynamics());
      _levelSystem = LevelSystem();
      _missionSystem = MissionSystem();
      _autoSaveService = AutoSaveService(this);

      _playerManager = PlayerManager(
        levelSystem: _levelSystem,
        resourceManager: _resourceManager,
        marketManager: _marketManager,
      );
    } catch (e) {
      print('Erreur lors de la création des managers: $e');
      rethrow;
    }
  }

  void _configureAndStart() {
    try {
      _levelSystem.onLevelUp = _handleLevelUp;
      _missionSystem.initialize();
      _autoSaveService.initialize();
      _setupLifecycleListeners();  // Ajouter cette ligne
      _startTimers();
    } catch (e) {
      print('Erreur lors de la configuration: $e');
      rethrow;
    }
  }
  Future<void> saveOnImportantEvent() async {
    if (!_isInitialized || _gameName == null) return;

    try {
      await SaveManager.saveGame(this, _gameName!);
      _lastSaveTime = DateTime.now();
    } catch (e) {
      print('Erreur lors de la sauvegarde événementielle: $e');
    }
  }

  DateTime _lastUpdateTime = DateTime.now();
  DateTime? _lastSaveTime;
  bool _isPaused = false;
  // État privé
  int _totalTimePlayedInSeconds = 0;
  int _totalPaperclipsProduced = 0;
  double _maintenanceCosts = 0.0;
  // Constructeur privé


  // Gestionnaire de timers centralisé
  final Map<String, Timer> _timers = {};
  DateTime? get lastSaveTime => _lastSaveTime;

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



  String get formattedPlayTime {
    int hours = _totalTimePlayedInSeconds ~/ 3600;
    int minutes = (_totalTimePlayedInSeconds % 3600) ~/ 60;
    int seconds = _totalTimePlayedInSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
  void enterCrisisMode() {
    if (_isInCrisisMode) return;

    print("Début de la transition vers le mode crise");

    // Afficher d'abord le dialogue si on a un contexte
    if (_context != null) {
      showDialog(
        context: _context!,
        barrierDismissible: false,
        builder: (context) => MetalCrisisDialog(
          onTransitionComplete: () {
            // Activer le mode crise après la fermeture du dialogue
            _isInCrisisMode = true;
            _crisisStartTime = DateTime.now();

            // Notifier le changement de mode
            EventManager.instance.addEvent(
                EventType.CRISIS_MODE,
                "Mode Crise Activé",
                description: "Adaptation nécessaire : plus de métal disponible !",
                importance: EventImportance.CRITICAL,
                additionalData: {
                  'timestamp': _crisisStartTime!.toIso8601String(),
                  'marketMetalStock': marketManager.marketMetalStock,
                }
            );

            // Activer les nouvelles fonctionnalités
            _unlockCrisisFeatures();

            saveOnImportantEvent(); // Sauvegarder l'état après la transition
            notifyListeners();
          },
        ),
      );
    } else {
      // Si pas de contexte, activer directement le mode crise
      _isInCrisisMode = true;
      _crisisStartTime = DateTime.now();

      EventManager.instance.addEvent(
          EventType.CRISIS_MODE,
          "Mode Crise Activé",
          description: "Adaptation nécessaire : plus de métal disponible !",
          importance: EventImportance.CRITICAL,
          additionalData: {
            'timestamp': _crisisStartTime!.toIso8601String(),
            'marketMetalStock': marketManager.marketMetalStock,
          }
      );

      _unlockCrisisFeatures();
      saveOnImportantEvent();
      notifyListeners();
    }
  }
  void _unlockCrisisFeatures() {
    // Supprimer les références au recyclage
    _crisisTransitionComplete = true;

    // Notifier le changement de mode
    EventManager.instance.addEvent(
        EventType.CRISIS_MODE,
        "Mode Production Activé",
        description: "Vous pouvez maintenant produire votre propre métal !",
        importance: EventImportance.CRITICAL
    );

    notifyListeners();
  }






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









  void reset() {
    _stopAllTimers();

    // Ne pas réinitialiser les managers, juste leurs états
    _playerManager.resetResources();
    _levelSystem.reset();
    _marketManager.reset();

    _startTimers();
    notifyListeners();
  }

  void resetMarket() {
    _marketManager = MarketManager(MarketDynamics());
    market.updateMarket();
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

    // Production toutes les secondes
    _gameLoopTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      processProduction();
    });

    // Timer du marché - Ajout de cette partie
    marketTimer = Timer.periodic(
        const Duration(seconds: 1),
            (timer) => _processMarket()  // Utilisez _processMarket au lieu de processMarket
    );

    // Timer du temps de jeu
    _playTimeTimer?.cancel();
    _playTimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _totalTimePlayedInSeconds++;
      _statistics.updateProgression(
          playTime: const Duration(seconds: 1)
      );
      notifyListeners();
    });
  }





  void _stopAllTimers() {
    _gameLoopTimer?.cancel();
    _gameLoopTimer = null;
    marketTimer?.cancel();
    marketTimer = null;
    _playTimeTimer?.cancel();
    _playTimeTimer = null;
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
      'statistics': _statistics.toJson(),
      'totalTimePlayedInSeconds': _totalTimePlayedInSeconds,
      'totalPaperclipsProduced': _totalPaperclipsProduced,
      // Données de crise complètes
      'crisisMode': {
        'isInCrisisMode': _isInCrisisMode,
        'crisisStartTime': _crisisStartTime?.toIso8601String(),
        'crisisTransitionComplete': _crisisTransitionComplete,
      },
    };

    // Ajout des données des managers
    try {
      baseData['playerManager'] = playerManager.toJson();
      baseData['marketManager'] = marketManager.toJson();
      baseData['levelSystem'] = levelSystem.toJson();
      baseData['missionSystem'] = missionSystem?.toJson();

      // Debug logs
      print('PrepareGameData - Sauvegarde des données:');
      print('Mode crise actif: ${_isInCrisisMode}');
      print('Début de la crise: ${_crisisStartTime?.toIso8601String()}');
      print('Transition complète: $_crisisTransitionComplete');
      print('Données joueur: ${baseData['playerManager']}');
      print('Données marché: ${baseData['marketManager']}');

      return baseData;
    } catch (e) {
      print('Erreur dans prepareGameData: $e');
      rethrow;
    }
  }












  void processProduction() {
    // Calcul des bonus
    double speedBonus = 1.0 + ((playerManager.upgrades['speed']?.level ?? 0) * 0.20);
    double bulkBonus = 1.0 + ((playerManager.upgrades['bulk']?.level ?? 0) * 0.35);
    double efficiencyBonus = 1.0 - ((playerManager.upgrades['efficiency']?.level ?? 0) * 0.15);

    // Nombre total d'autoclippers avec les bonus
    double totalProduction = playerManager.autoclippers * speedBonus * bulkBonus;

    // Métal nécessaire par trombone
    double metalPerClip = GameConstants.METAL_PER_PAPERCLIP * efficiencyBonus;

    // Nombre maximum de trombones possibles avec le métal disponible
    int maxPossibleClips = (playerManager.metal / metalPerClip).floor();

    // Production effective (limitée par le métal disponible)
    int actualProduction = min(totalProduction.floor(), maxPossibleClips);

    if (actualProduction > 0) {
      // Mise à jour des ressources
      double metalUsed = actualProduction * metalPerClip;
      playerManager.updateMetal(playerManager.metal - metalUsed);
      playerManager.updatePaperclips(playerManager.paperclips + actualProduction);
      _totalPaperclipsProduced += actualProduction;

      // Mise à jour des statistiques
      _statistics.updateProduction(
        isManual: false,
        amount: actualProduction,
        metalUsed: metalUsed,
      );

      // Expérience pour la production automatique
      levelSystem.addAutomaticProduction(actualProduction);
    }

    notifyListeners();
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

    if (playerManager.paperclips > 0) {
      int potentialSales = min(demand.floor(), playerManager.paperclips.floor());
      if (potentialSales > 0) {
        double qualityBonus = 1.0 + (playerManager.upgrades['quality']?.level ?? 0) * 0.10;
        double salePrice = playerManager.sellPrice * qualityBonus;
        double revenue = potentialSales * salePrice;

        playerManager.updatePaperclips(playerManager.paperclips - potentialSales);
        playerManager.updateMoney(playerManager.money + revenue);
        marketManager.recordSale(potentialSales, salePrice);

        // Ajout statistiques
        _statistics.updateEconomics(
          moneyEarned: revenue,
          sales: potentialSales,
          price: salePrice,
        );
      }
    }
  }





  void checkResourceCrisis() {
    if (marketManager.marketMetalStock <= 0 && !_isInCrisisMode) {
      print("Déclenchement de la crise - Stock épuisé");

      EventManager.instance.addEvent(
          EventType.RESOURCE_DEPLETION,
          "Stock Mondial Épuisé",
          description: "Les réserves mondiales de métal sont épuisées.\nDe nouveaux moyens de production doivent être trouvés !",
          importance: EventImportance.CRITICAL,
          additionalData: {'crisisLevel': '0'}
      );

      if (_context != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: _context!,
            barrierDismissible: false,
            builder: (context) => const MetalCrisisDialog(),
          );
          saveOnImportantEvent();
        });
      }
    }
  }
  bool validateCrisisTransition() {
    if (!_isInCrisisMode) {
      print("Erreur: Mode crise non activé");
      return false;
    }

    if (!_crisisTransitionComplete) {
      print("Erreur: Transition non terminée");
      return false;
    }
    saveOnImportantEvent();

    return true;
  }


  // Actions du jeu
  void buyMetal() {
    print('Tentative d\'achat de métal'); // Debug
    print('Stock disponible: ${marketManager.marketMetalStock}'); // Debug

    if (!_canBuyMetal()) {
      print('Achat impossible - conditions non remplies'); // Debug
      return;
    }

    double metalPrice = marketManager.currentMetalPrice;
    double amount = GameConstants.METAL_PACK_AMOUNT;

    print('Prix: $metalPrice, Quantité: $amount'); // Debug

    // Le joueur peut payer et stocker le métal
    playerManager.updateMoney(playerManager.money - metalPrice);
    playerManager.updateMetal(playerManager.metal + amount);
    marketManager.updateMarketStock(-amount);  // Important: le signe négatif

    print('Achat effectué - Nouveau stock marché: ${marketManager.marketMetalStock}'); // Debug

    if (marketManager.marketMetalStock <= 0) {
      print('Stock épuisé - Déclenchement mode crise'); // Debug
      enterCrisisMode();
    }
    _statistics.updateEconomics(
      moneySpent: metalPrice,
      metalBought: amount,
    );

    if (marketManager.marketMetalStock <= 0) {
      enterCrisisMode();
    }

    notifyListeners();
  }

  bool _canBuyMetal() {
    double metalPrice = marketManager.currentMetalPrice;
    double currentMetal = playerManager.metal;
    double maxStorage = playerManager.maxMetalStorage;

    return playerManager.money >= metalPrice &&
        currentMetal + GameConstants.METAL_PACK_AMOUNT <= maxStorage &&
        marketManager.marketMetalStock >= GameConstants.METAL_PACK_AMOUNT;  // Ajout de cette vérification
  }

  void buyAutoclipper() {
    double cost = autocliperCost;
    if (player.money >= cost) {
      player.updateMoney(player.money - cost);
      player.updateAutoclippers(player.autoclippers + 1);
      level.addAutoclipperPurchase();

      // Ajout statistiques
      _statistics.updateProgression(autoclippersBought: 1);  // Cette ligne est correcte
      _statistics.updateEconomics(moneySpent: cost);
      saveOnImportantEvent();

      notifyListeners();
    }
  }

  void producePaperclip() {
    if (player.consumeMetal(GameConstants.METAL_PER_PAPERCLIP)) {
      player.updatePaperclips(player.paperclips + 1);
      _totalPaperclipsProduced++;
      level.addManualProduction();
      // Ajout statistiques
      _statistics.updateProduction(
        isManual: true,
        amount: 1,
        metalUsed: GameConstants.METAL_PER_PAPERCLIP,  // Cette valeur est bien passée
      );
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
    saveOnImportantEvent();
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

      // Réinitialiser l'état si déjà initialisé
      if (_isInitialized) {
        reset();
      }

      // Initialiser les managers
      _initializeManagers();

      // Sauvegarder l'état initial
      await SaveManager.saveGame(this, name);
      saveOnImportantEvent();
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
      _playerManager.fromJson(gameData['playerManager'] ?? {});
      _marketManager.fromJson(gameData['marketManager'] ?? {});

      // Appliquer les effets des améliorations
      _applyUpgradeEffects();

      // Charger les statistiques
      if (gameData['statistics'] != null) {
        _statistics.fromJson(gameData['statistics']);
      }

      // Charger les statistiques globales
      _totalTimePlayedInSeconds = gameData['totalTimePlayedInSeconds'] ?? 0;
      _totalPaperclipsProduced = gameData['totalPaperclipsProduced'] ?? 0;

      // Restaurer l'état du mode crise
      if (gameData['crisisMode'] != null) {
        final crisisData = gameData['crisisMode'];
        _isInCrisisMode = crisisData['isInCrisisMode'] ?? false;
        if (_isInCrisisMode) {
          _crisisTransitionComplete = crisisData['crisisTransitionComplete'] ?? true;
          if (crisisData['crisisStartTime'] != null) {
            _crisisStartTime = DateTime.parse(crisisData['crisisStartTime']);
          } else {
            _crisisStartTime = DateTime.now();
          }
        }
      }

      _gameName = name;
      _lastSaveTime = saveGame.lastSaveTime;

      _startTimers();
      notifyListeners();
    } catch (e) {
      print('Error loading game: $e');
      rethrow;
    }
  }
  void _applyUpgradeEffects() {
    if (_playerManager.upgrades['storage'] != null) {
      int storageLevel = _playerManager.upgrades['storage']!.level;
      double newCapacity = GameConstants.INITIAL_STORAGE_CAPACITY *
          (1 + (storageLevel * GameConstants.STORAGE_UPGRADE_MULTIPLIER));
      _playerManager.updateMaxMetalStorage(newCapacity);
      _resourceManager.upgradeStorageCapacity(storageLevel);
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
    if (gameData['statistics'] != null) {
      _statistics.fromJson(gameData['statistics']);
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

    final upgrade = playerManager.upgrades[upgradeId];
    if (upgrade == null) return false;

    double cost = upgrade.getCost();
    bool success = playerManager.purchaseUpgrade(upgradeId);

    if (success) {
      levelSystem.addUpgradePurchase(upgrade.level);

      // Ajout statistiques
      _statistics.updateProgression(upgradesBought: 1);
      _statistics.updateEconomics(moneySpent: cost);
      saveOnImportantEvent();
    }

    return success;
  }

  Future<void> checkAndRestoreFromBackup() async {
    if (!_isInitialized || _gameName == null) return;

    try {
      final saves = await SaveManager.listSaves();
      final backups = saves.where((save) =>
          save.name.startsWith('${_gameName!}_backup_'))
          .toList();

      if (backups.isEmpty) return;

      // Tenter de charger le dernier backup valide
      backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      for (var backup in backups) {
        try {
          await loadGame(backup.name);
          print('Restauration réussie depuis le backup: ${backup.name}');
          return;
        } catch (e) {
          print('Échec de la restauration depuis ${backup.name}: $e');
          continue;
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification des backups: $e');
    }
  }
  void _setupLifecycleListeners() {
    SystemChannels.lifecycle.setMessageHandler((String? state) async {
      if (state == 'paused' || state == 'inactive') {
        await saveOnImportantEvent();
        await _autoSaveService.createBackup();
      }
      return null;
    });
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
    _autoSaveService.dispose();
    playerManager.dispose();
    levelSystem.dispose();
    super.dispose();
  }
}