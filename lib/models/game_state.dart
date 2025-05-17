// lib/models/game_state.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/competitive_result_screen.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_config.dart';
import 'event_system.dart';
import 'player_manager.dart';
import 'market.dart';
import 'progression_system.dart';
import 'dart:convert';
import '../utils/notification_manager.dart';
import '../dialogs/metal_crisis_dialog.dart';
import '../services/auto_save_service.dart';
import 'package:paperclip2/services/games_services_controller.dart';
import 'package:games_services/games_services.dart' hide SaveGame;
import '../screens/main_screen.dart';
import '../services/save/save_system.dart';
import '../services/save/save_types.dart';
import 'package:provider/provider.dart';
import '../services/user/user_manager.dart';
import '../main.dart' show navigatorKey;

import '../managers/metal_manager.dart';
import '../managers/statistics_manager.dart';
import '../managers/crisis_manager.dart';
import '../managers/production_manager.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../services/user/user_manager.dart';

class GameState extends ChangeNotifier implements SaveDataProvider {

  // Gestionnaires d'état
  PlayerManager? _playerManager;
  MarketManager? _marketManager;
  MetalManager? _metalManager;
  LevelSystem? _levelSystem;
  MissionSystem? _missionSystem;
  StatisticsManager? _statistics;
  ProductionManager? _productionManager;
  CrisisManager? _crisisManager;
  SaveSystem? _saveSystem;
  AutoSaveService? _autoSaveService;
  UserManager? _socialUserManager;

  // Timers
  Timer? _gameLoopTimer;
  Timer? marketTimer;
  Timer? _playTimeTimer;

  // État
  bool _isInitialized = false;
  String? _gameName;
  BuildContext? _context;
  GameMode _gameMode = GameMode.INFINITE;
  DateTime? _competitiveStartTime;
  bool _isPaused = false;
  int _totalTimePlayedInSeconds = 0;
  double _maintenanceCosts = 0.0;
  DateTime _lastUpdateTime = DateTime.now();
  DateTime? _lastSaveTime;

  // Getters sécurisés avec vérification d'initialisation
  bool get isInitialized => _isInitialized;
  String? get gameName => _gameName;

  // Getter pour accéder à PlayerManager via player
  PlayerManager get player {
    if (_playerManager == null) {
      throw StateError('PlayerManager n\'est pas initialisé. Appelez initialize() d\'abord.');
    }
    return _playerManager!;
  }

  // Getter pour accéder à MarketManager via market
  MarketManager get market {
    if (_marketManager == null) {
      throw StateError('MarketManager n\'est pas initialisé. Appelez initialize() d\'abord.');
    }
    return _marketManager!;
  }

  // Getter pour accéder à LevelSystem via level
  LevelSystem get level {
    if (_levelSystem == null) {
      throw StateError('LevelSystem n\'est pas initialisé. Appelez initialize() d\'abord.');
    }
    return _levelSystem!;
  }

  PlayerManager get playerManager {
    if (_playerManager == null) {
      throw StateError('PlayerManager n\'est pas initialisé. Appelez initialize() d\'abord.');
    }
    return _playerManager!;
  }

  MarketManager get marketManager {
    if (_marketManager == null) {
      throw StateError('MarketManager n\'est pas initialisé. Appelez initialize() d\'abord.');
    }
    return _marketManager!;
  }

  MetalManager get metalManager {
    if (_metalManager == null) {
      throw StateError('MetalManager n\'est pas initialisé. Appelez initialize() d\'abord.');
    }
    return _metalManager!;
  }

  LevelSystem get levelSystem {
    if (_levelSystem == null) {
      throw StateError('LevelSystem n\'est pas initialisé. Appelez initialize() d\'abord.');
    }
    return _levelSystem!;
  }

  MissionSystem get missionSystem {
    if (_missionSystem == null) {
      throw StateError('MissionSystem n\'est pas initialisé. Appelez initialize() d\'abord.');
    }
    return _missionSystem!;
  }

  StatisticsManager get statistics {
    if (_statistics == null) {
      throw StateError('StatisticsManager n\'est pas initialisé. Appelez initialize() d\'abord.');
    }
    return _statistics!;
  }
  void setSocialUserManager(UserManager userManager) {
    _socialUserManager = userManager;
  }

  ProductionManager get productionManager {
    if (_productionManager == null) {
      throw StateError('ProductionManager n\'est pas initialisé. Appelez initialize() d\'abord.');
    }
    return _productionManager!;
  }



  bool get isInCrisisMode => _crisisManager?.isInCrisisMode ?? false;
  bool get crisisTransitionComplete => _crisisManager?.crisisTransitionComplete ?? false;
  bool get showingCrisisView => _crisisManager?.showingCrisisView ?? false;
  DateTime? get crisisStartTime => _crisisManager?.crisisStartTime;

  GameMode get gameMode => _gameMode;
  DateTime? get competitiveStartTime => _competitiveStartTime;
  Duration get competitivePlayTime {
    if (_competitiveStartTime == null) return Duration.zero;
    return DateTime.now().difference(_competitiveStartTime!);
  }

  DateTime? get lastSaveTime => _saveSystem?.lastSaveTime;
  int get totalTimePlayed => _totalTimePlayedInSeconds;
  int get totalPaperclipsProduced => _productionManager?.totalPaperclipsProduced ?? 0;
  double get maintenanceCosts => _maintenanceCosts;
  Map<String, Upgrade> get upgrades => _playerManager?.upgrades ?? {};
  double get maxMetalStorage => _playerManager?.maxMetalStorage ?? GameConstants.INITIAL_STORAGE_CAPACITY;
  double get autocliperCost => _productionManager?.calculateAutoclipperCost() ?? GameConstants.BASE_AUTOCLIPPER_COST;

  // Constructeur
  GameState() {
    // Ne pas initialiser automatiquement - l'initialisation sera explicite
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('GameState: Initialisation en cours...');

      // Créer les managers indépendants en premier
      _statistics = StatisticsManager();
      _levelSystem = LevelSystem();
      _missionSystem = MissionSystem();

      debugPrint('GameState: Managers de base créés');

      // Créer des managers avec dépendances limitées
      _metalManager = MetalManager(
          onCrisisTriggered: () {
            if (_crisisManager != null) {
              _crisisManager!.enterCrisisMode();
            }
          }
      );

      _marketManager = MarketManager(MarketDynamics());

      debugPrint('GameState: Metal et Market Managers créés');

      // Le CrisisManager avec ses dépendances
      _crisisManager = CrisisManager(
        getGameMode: () => _gameMode,
        calculateCompetitiveScore: calculateCompetitiveScore,
        saveOnImportantEvent: saveOnImportantEvent,
        onCrisisTriggered: () {
          // Actions supplémentaires
        },
        onCompetitiveGameEnd: (score) {
          _handleCompetitiveGameEndWithScore(score);
        },
      );

      debugPrint('GameState: CrisisManager créé');

      // Création du ProductionManager
      _productionManager = ProductionManager(
        metalManager: _metalManager!,
        levelSystem: _levelSystem!,
        showNotification: (message) {
          EventManager.instance.addEvent(
              EventType.INFO,
              "Production",
              description: message,
              importance: EventImportance.LOW
          );
        },
        getUpgradeLevel: (upgradeId) => _playerManager?.upgrades[upgradeId]?.level ?? 0,
        updateStatistics: (quantity, metalUsed, metalSaved) {
          _statistics?.updateProduction(
            isManual: false,
            amount: quantity,
            metalUsed: metalUsed,
            metalSaved: metalSaved,
            efficiency: metalSaved / (metalUsed + metalSaved),
          );
        },
        initialPaperclips: 0.0,
        initialAutoclippers: 0,
        initialTotalProduced: 0,
      );

      debugPrint('GameState: ProductionManager créé');

      // Création du PlayerManager avec référence à this
      _playerManager = PlayerManager(
        gameState: this,
        levelSystem: _levelSystem!,
        metalManager: _metalManager!,
        marketManager: _marketManager!,
      );

      debugPrint('GameState: PlayerManager créé');

      // Configurer les callbacks et événements
      _levelSystem!.onLevelUp = _handleLevelUp;
      _missionSystem!.initialize();

      // AutoSaveService si SaveSystem est disponible
      if (_saveSystem != null) {
        _autoSaveService = AutoSaveService(_saveSystem!, this);
        await _autoSaveService?.initialize();
      }

      // Configuration des timers
      _setupTimers();

      _isInitialized = true;
      debugPrint('GameState: Initialisation terminée avec succès');
    } catch (e, stack) {
      debugPrint('GameState: Erreur lors de l\'initialisation: $e');
      debugPrint('Stack trace: $stack');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'GameState initialization error');
      rethrow;
    }
  }

  // Configurer les timers
  void _setupTimers() {
    _stopAllTimers();
    _lastUpdateTime = DateTime.now();

    // Timer de production
    _gameLoopTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      processProduction();
    });

    // Timer du marché
    marketTimer = Timer.periodic(
        const Duration(seconds: 1),
            (timer) => _processMarket()
    );

    // Ajout d'un timer spécifique pour vérifier les ressources
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isPaused) {
        checkResourceCrisis();
      }
    });

    // Timer du temps de jeu
    _playTimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _totalTimePlayedInSeconds++;
      _statistics?.updatePlayTime(const Duration(seconds: 1));
      notifyListeners();
    });
  }

  void _updateLeaderboardsOnMilestone() {
    if (totalPaperclipsProduced % 100 == 0 ||     // Tous les 100 trombones
        levelSystem.level % 5 == 0 ||               // Tous les 5 niveaux
        _totalTimePlayedInSeconds % 3600 == 0) {    // Toutes les heures
      updateLeaderboard();
    }
  }

  // Arrêter tous les timers
  void _stopAllTimers() {
    _gameLoopTimer?.cancel();
    _gameLoopTimer = null;

    marketTimer?.cancel();
    marketTimer = null;

    _playTimeTimer?.cancel();
    _playTimeTimer = null;
  }

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

  void handleCompetitiveGameEnd() {
    if (_crisisManager != null) {
      _crisisManager!.handleCompetitiveGameEnd();
    }
  }

  // Méthode pour démarrer une nouvelle partie compétitive
  void _startNewCompetitiveGame(BuildContext context) {
    final gameName = 'Compétition_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().hour}${DateTime.now().minute}';
    startNewGame(gameName, mode: GameMode.COMPETITIVE).then((_) {
      // Retourner à l'écran principal avec la nouvelle partie
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    });
  }

  // Méthode pour calculer le score compétitif
  int calculateCompetitiveScore() {
    if (_gameMode != GameMode.COMPETITIVE) return 0;

    // Base: production de trombones (50% du score)
    double productionScore = totalPaperclipsProduced * 10;

    // Argent gagné (25% du score)
    double moneyScore = (_playerManager?.money ?? 0) * 5;

    // Niveau atteint (15% du score)
    double levelScore = (_levelSystem?.level ?? 1) * 1000;

    // Bonus d'efficacité (10% du score)
    double efficiencyBonus = calculateEfficiencyRating() * 500;

    // Temps de jeu - bonus inversement proportionnel
    int minutes = competitivePlayTime.inMinutes;
    double timeMultiplier = 1.0;
    if (minutes > 0) {
      timeMultiplier = 2.0 / (1 + (minutes / 30));
    }

    // Score final
    int finalScore = ((productionScore + moneyScore + levelScore + efficiencyBonus) * timeMultiplier).toInt();

    return finalScore;
  }

  // Méthode pour calculer l'efficacité (ratio trombones/métal)
  double calculateEfficiencyRating() {
    // Obtenir la consommation totale de métal depuis les statistiques
    double totalMetalUsed = _statistics?.getTotalMetalUsed() ?? 1.0;
    if (totalMetalUsed <= 0) return 1.0;

    // Ratio trombones/métal (ajusté pour être significatif)
    return totalPaperclipsProduced / totalMetalUsed;
  }

  // Méthode pour vérifier les achievements compétitifs
  void _checkCompetitiveAchievements(int score) {
    final gamesServices = GamesServicesController();

    // Vérifier les seuils de score
    if (score >= 100000) {
      gamesServices.unlockCompetitiveAchievement(CompetitiveAchievement.SCORE_100K);
    } else if (score >= 50000) {
      gamesServices.unlockCompetitiveAchievement(CompetitiveAchievement.SCORE_50K);
    } else if (score >= 10000) {
      gamesServices.unlockCompetitiveAchievement(CompetitiveAchievement.SCORE_10K);
    }

    // Vérifier le temps de jeu (parties rapides)
    if (competitivePlayTime.inMinutes < 10 && isInCrisisMode) {
      gamesServices.unlockCompetitiveAchievement(CompetitiveAchievement.SPEED_RUN);
    }

    // Vérifier l'efficacité
    if (calculateEfficiencyRating() > 8.0) {
      gamesServices.unlockCompetitiveAchievement(CompetitiveAchievement.EFFICIENCY_MASTER);
    }
  }

  // Méthodes déléguées au SaveSystem
  Future<bool> syncSavesToCloud() async {
    return await _saveSystem?.syncSavesToCloud() ?? false;
  }

  // Méthode pour entrer en mode crise
  void enterCrisisMode() {
    if (_crisisManager != null) {
      _crisisManager!.enterCrisisMode();
    }
  }

  // Méthode pour gérer la fin de partie compétitive avec un score
  void _handleCompetitiveGameEndWithScore(int score) {
    if (_gameMode != GameMode.COMPETITIVE || !isInCrisisMode) return;
    // Mettre à jour les statistiques sociales
    updateSocialStats();
    // Mise à jour des classements
    final gamesServices = GamesServicesController();
    gamesServices.submitCompetitiveScore(
        score: score,
        paperclips: totalPaperclipsProduced,
        money: _playerManager?.money ?? 0,
        timePlayed: competitivePlayTime.inSeconds,
        level: _levelSystem?.level ?? 1,
        efficiency: calculateEfficiencyRating()
    );

    // Déverrouiller les succès compétitifs si nécessaire
    _checkCompetitiveAchievements(score);

    // Afficher le résultat si on a un contexte
    if (_context != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(_context!).push(
          MaterialPageRoute(
            builder: (context) => CompetitiveResultScreen(
              score: score,
              paperclips: totalPaperclipsProduced,
              money: _playerManager?.money ?? 0,
              playTime: competitivePlayTime,
              level: _levelSystem?.level ?? 1,
              efficiency: calculateEfficiencyRating(),
              onNewGame: () => _startNewCompetitiveGame(context),
              onShowLeaderboard: () => gamesServices.showCompetitiveLeaderboard(),
            ),
          ),
        );
      });
    }
  }

  // Méthode pour valider la transition de crise
  bool validateCrisisTransition() {
    return _crisisManager?.validateCrisisTransition() ?? false;
  }

  void reset() {
    _stopAllTimers();

    // Réinitialiser les managers
    _playerManager?.resetResources();
    _levelSystem?.reset();
    _marketManager?.reset();
    if (_statistics != null) {
      // Réinitialiser les statistiques...
    }

    _setupTimers();
    notifyListeners();
  }

  void resetMarket() {
    _marketManager = MarketManager(MarketDynamics());
    _marketManager?.updateMarket();
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

    // Timer du marché
    marketTimer = Timer.periodic(
        const Duration(seconds: 1),
            (timer) => _processMarket()
    );

    // Timer du temps de jeu
    _playTimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _totalTimePlayedInSeconds++;
      _statistics?.updatePlayTime(const Duration(seconds: 1));
      notifyListeners();
    });
  }

  void _applyMaintenanceCosts() {
    if (_playerManager?.autoclippers == 0) return;

    _maintenanceCosts = (_playerManager?.autoclippers ?? 0) * GameConstants.STORAGE_MAINTENANCE_RATE;

    if ((_playerManager?.money ?? 0) >= _maintenanceCosts) {
      _playerManager?.updateMoney((_playerManager?.money ?? 0) - _maintenanceCosts);
      notifyListeners();
    } else {
      _playerManager?.updateAutoclippers(((_playerManager?.autoclippers ?? 0) * 0.9).floor());
      EventManager.instance.addEvent(
          EventType.RESOURCE_DEPLETION,
          "Maintenance impayée !",
          description: "Certaines autoclippeuses sont hors service",
          importance: EventImportance.HIGH
      );
    }
  }

  // Implémentation de SaveDataProvider
  @override
  Map<String, dynamic> prepareGameData() {
    // Collecter les données pour la sauvegarde
    final Map<String, dynamic> baseData = {
      'version': GameConstants.VERSION,
      'timestamp': DateTime.now().toIso8601String(),
      'totalTimePlayedInSeconds': _totalTimePlayedInSeconds,
      'totalPaperclipsProduced': _productionManager?.totalPaperclipsProduced ?? 0,
      'gameMode': _gameMode.index,
      'competitiveStartTime': _competitiveStartTime?.toIso8601String(),
    };

    // Ajouter les données des managers si disponibles
    if (_statistics != null) {
      baseData['statistics'] = _statistics!.toJson();
    }

    if (_playerManager != null) {
      baseData['playerManager'] = _playerManager!.toJson();
    }

    if (_marketManager != null) {
      baseData['marketManager'] = _marketManager!.toJson();
    }

    if (_levelSystem != null) {
      baseData['levelSystem'] = _levelSystem!.toJson();
    }

    if (_metalManager != null) {
      baseData['metalManager'] = _metalManager!.toJson();
    }

    if (_productionManager != null) {
      baseData['productionManager'] = _productionManager!.toJson();
    }

    if (_crisisManager != null) {
      baseData['crisisManager'] = _crisisManager!.toJson();
    }

    return baseData;
  }

  @override
  void loadGameData(Map<String, dynamic> gameData) {
    try {
      // Vérifier l'initialisation
      if (!_isInitialized) {
        initialize();
      }

      // Charger les données dans chaque manager
      if (gameData['playerManager'] != null && _playerManager != null) {
        _playerManager!.fromJson(gameData['playerManager']);
      }

      if (gameData['marketManager'] != null && _marketManager != null) {
        _marketManager!.fromJson(gameData['marketManager']);
      }

      if (gameData['levelSystem'] != null && _levelSystem != null) {
        _levelSystem!.loadFromJson(gameData['levelSystem']);
      }

      if (gameData['statistics'] != null && _statistics != null) {
        _statistics!.fromJson(gameData['statistics']);
      }

      if (gameData['metalManager'] != null && _metalManager != null) {
        _metalManager!.fromJson(gameData['metalManager']);
      }

      if (gameData['productionManager'] != null && _productionManager != null) {
        _productionManager!.fromJson(gameData['productionManager']);
      }

      // Charger les données du CrisisManager (format moderne)
      if (gameData['crisisManager'] != null && _crisisManager != null) {
        _crisisManager!.fromJson(gameData['crisisManager']);
      }
      // Compatibilité avec l'ancien format
      else if (gameData['crisisMode'] != null && _crisisManager != null) {
        _crisisManager!.fromJson(gameData['crisisMode'] as Map<String, dynamic>);
      }

      // Charger les propriétés de base
      _totalTimePlayedInSeconds = (gameData['totalTimePlayedInSeconds'] as num?)?.toInt() ?? 0;

      // Charger le mode de jeu
      _gameMode = gameData['gameMode'] != null
          ? GameMode.values[gameData['gameMode'] as int]
          : GameMode.INFINITE;

      // Charger le temps de départ en mode compétitif
      if (gameData['competitiveStartTime'] != null) {
        try {
          _competitiveStartTime = DateTime.parse(gameData['competitiveStartTime'] as String);
        } catch (e) {
          debugPrint('Erreur de parsing de date: ${gameData['competitiveStartTime']}');
          // Utiliser la date actuelle comme fallback
          _competitiveStartTime = _gameMode == GameMode.COMPETITIVE
              ? DateTime.now() : null;
        }
      }

      // Redémarrer les timers
      _setupTimers();
      notifyListeners();

    } catch (e, stack) {
      debugPrint('Erreur lors du chargement des données: $e');
      debugPrint('Stack trace: $stack');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Load game data error');
      rethrow;
    }
  }

  // Méthode pour traiter la production
  void processProduction() {
    if (!_isInitialized || _productionManager == null) return;
    _productionManager!.processProduction();
  }

  void _processMarket() {
    if (!_isInitialized || _marketManager == null || _playerManager == null) return;

    _marketManager!.updateMarket();
    double demand = _marketManager!.calculateDemand(
        _playerManager!.sellPrice,
        _playerManager!.getMarketingLevel()
    );

    if (_playerManager!.paperclips > 0) {
      int potentialSales = min(
          demand.floor(),
          _playerManager!.paperclips.floor()
      );

      if (potentialSales > 0) {
        double qualityBonus = 1.0 +
            (_playerManager!.upgrades['quality']?.level ?? 0) * 0.10;
        double salePrice = _playerManager!.sellPrice * qualityBonus;
        double revenue = potentialSales * salePrice;

        _playerManager!.updatePaperclips(
            _playerManager!.paperclips - potentialSales
        );
        _playerManager!.updateMoney(_playerManager!.money + revenue);
        _marketManager!.recordSale(potentialSales, salePrice);

        // Ajout statistiques
        _statistics?.updateEconomics(
          moneyEarned: revenue,
          sales: potentialSales,
          price: salePrice,
        );
      }
    }
  }

  Future<void> updateSocialStats() async {
    if (!_isInitialized) return;

    // Si _socialUserManager est défini, l'utiliser directement
    if (_socialUserManager != null) {
      await _socialUserManager!.updatePublicStats(this);
      return;
    }

    // Sinon, tenter de l'obtenir via Provider
    try {
      if (_context != null && _context!.mounted) {
        final userManager = Provider.of<UserManager>(_context!, listen: false);
        await userManager.updatePublicStats(this);
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des statistiques sociales: $e');
    }
  }

  // Méthode pour vérifier les ressources
  void checkResourceCrisis() {
    if (!_isInitialized || _metalManager == null || _crisisManager == null) return;

    // Ajout de logs pour le débogage
    debugPrint("Vérification de crise - Stock métal: ${_metalManager!.marketMetalStock}");

    // Modification de la condition pour être plus strict et explicite
    // Ajoutez une vérification pour éviter les déclenchements multiples
    if (_metalManager!.marketMetalStock <= 0.1 && !isInCrisisMode && !_crisisManager!.isCrisisProcessInProgress) {
      debugPrint("Déclenchement de la crise - Stock épuisé");

      // Déclenchement explicite du mode crise
      _crisisManager!.enterCrisisMode();
      saveOnImportantEvent();
      notifyListeners();
    }
  }

  void setSaveSystem(SaveSystem saveSystem) {
    _saveSystem = saveSystem;
    debugPrint('GameState: SaveSystem injecté');
  }

  // Actions du jeu
  void buyMetal() {
    if (!_isInitialized || _metalManager == null || _playerManager == null || _marketManager == null || _statistics == null) return;

    _metalManager!.buyMetal(
        price: _marketManager!.currentMetalPrice,
        playerMoney: _playerManager!.money,
        updatePlayerMoney: (newMoney) => _playerManager!.updateMoney(newMoney)
    );

    _statistics!.updateEconomics(
        moneySpent: _marketManager!.currentMetalPrice,
        metalBought: GameConstants.METAL_PACK_AMOUNT
    );
  }

  bool _canBuyMetal() {
    if (!_isInitialized || _metalManager == null || _playerManager == null || _marketManager == null) return false;

    double metalPrice = _marketManager!.currentMetalPrice;
    double currentMetal = _metalManager!.metal;
    double maxStorage = _metalManager!.maxMetalStorage;

    return _playerManager!.money >= metalPrice &&
        currentMetal + GameConstants.METAL_PACK_AMOUNT <= maxStorage &&
        _marketManager!.marketMetalStock >= GameConstants.METAL_PACK_AMOUNT;
  }

  void buyAutoclipper() {
    if (!_isInitialized || _productionManager == null || _playerManager == null) return;

    _productionManager!.buyAutoclipper(
        _playerManager!.money,
            (newAmount) => _playerManager!.updateMoney(newAmount)
    );
  }

  void producePaperclip() {
    if (!_isInitialized || _productionManager == null) return;

    _productionManager!.produceManualPaperclip();
  }

  void setSellPrice(double newPrice) {
    if (!_isInitialized || _playerManager == null || _marketManager == null || _context == null) return;

    if (_marketManager!.isPriceExcessive(newPrice)) {
      final notification = NotificationEvent(
        title: "Prix Excessif!",
        description: "Ce prix pourrait affecter vos ventes",
        detailedDescription: _marketManager!.getPriceRecommendation(),
        icon: Icons.price_change,
        priority: NotificationPriority.HIGH,
      );

      NotificationManager.showGameNotification(_context!, event: notification);
    }

    _playerManager!.updateSellPrice(newPrice);
    notifyListeners();
  }

  // Gestion des niveaux et missions
  void _handleLevelUp(int newLevel, List<UnlockableFeature> newFeatures) {
    if (!_isInitialized || _statistics == null) return;

    _statistics!.updateProgression(level: newLevel);

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
          if (_playerManager != null) {
            _playerManager!.updateMoney(_playerManager!.money + GameConstants.BASE_AUTOCLIPPER_COST);
          }
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

    // Mise à jour de l'achievement progressif
    final gamesServices = GamesServicesController();
    gamesServices.incrementAchievement(_levelSystem!);

    saveOnImportantEvent();
    checkMilestones();
    notifyListeners();
    updateLeaderboard();
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

  // Méthodes pour les sauvegardes
  Future<void> startNewGame(String name, {GameMode mode = GameMode.INFINITE, bool syncToCloud = false}) async {
    try {
      debugPrint('Starting new game with name: $name, mode: $mode, syncToCloud: $syncToCloud');

      // Vérifier si GameState est initialisé, sinon l'initialiser
      if (!_isInitialized) {
        await initialize();
      }

      // Définir les propriétés de base
      _gameName = name;
      _gameMode = mode;

      // Si mode compétitif, initialiser le timer
      if (_gameMode == GameMode.COMPETITIVE) {
        _competitiveStartTime = DateTime.now();
      }

      // Réinitialiser l'état
      reset();

      // Sauvegarder la nouvelle partie
      if (_saveSystem != null) {
        await _saveSystem!.saveGame(name, syncToCloud: syncToCloud);
      } else {
        debugPrint('WARNING: SaveSystem n\'est pas disponible, impossible de sauvegarder la partie');
      }

      notifyListeners();
    } catch (e, stack) {
      debugPrint('Error starting new game: $e');
      debugPrint('Stack trace: $stack');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Start new game error');
      rethrow;
    }
  }

  // Méthodes qui délèguent au SaveSystem
  Future<void> saveGame(String name, {bool syncToCloud = true}) async {
    if (_saveSystem == null) {
      throw Exception('SaveSystem n\'est pas disponible');
    }

    // Mettre à jour les statistiques sociales à chaque sauvegarde
    await updateSocialStats();

    return await _saveSystem!.saveGame(name, syncToCloud: syncToCloud);
  }

  Future<void> loadGame(String name, {String? cloudId}) async {
    if (_saveSystem == null) {
      throw Exception('SaveSystem n\'est pas disponible');
    }

    try {
      _stopAllTimers();
      debugPrint('Timers stopped');

      await _saveSystem!.loadGame(name, cloudId: cloudId);

      _gameName = name;

      // Si GameState n'est pas initialisé, l'initialiser
      if (!_isInitialized) {
        await initialize();
      } else {
        _setupTimers(); // Redémarrer les timers
      }

      notifyListeners();
    } catch (e, stack) {
      debugPrint('Error loading game: $e');
      debugPrint('Stack trace: $stack');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Load game error');
      rethrow;
    }
  }

  Future<void> showCloudSaveSelector() async {
    if (_saveSystem == null) {
      throw Exception('SaveSystem n\'est pas disponible');
    }

    return await _saveSystem!.showCloudSaveSelector();
  }

  Future<void> saveOnImportantEvent() async {
    if (_saveSystem == null || _gameName == null) return;

    return await _saveSystem!.saveOnImportantEvent();
  }

  Future<void> checkAndRestoreFromBackup() async {
    // Vérifier si SaveSystem est disponible
    if (_saveSystem == null) {
      debugPrint('SaveSystem n\'est pas disponible, impossible de restaurer depuis backup');
      return;
    }

    // Vérifier si le nom de jeu est disponible
    if (gameName == null) return;

    try {
      // Utiliser ?. pour éviter les exceptions si _saveSystem devient null entre-temps
      final saves = await _saveSystem?.listSaves() ?? [];
      final backups = saves.where((save) =>
          save.name.startsWith('${gameName}_backup_'))
          .toList();

      if (backups.isEmpty) return;

      // Tenter de charger le dernier backup valide
      backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      for (var backup in backups) {
        try {
          // Encore une fois, utiliser ?. pour gérer le cas où _saveSystem est null
          await _saveSystem?.loadGame(backup.name);
          debugPrint('Restauration réussie depuis le backup: ${backup.name}');
          return;
        } catch (e) {
          debugPrint('Échec de la restauration depuis ${backup.name}: $e');
          continue;
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification des backups: $e');
    }
  }

  // Méthodes pour les classements
  void updateLeaderboard() async {
    final gamesServices = GamesServicesController();
    if (await gamesServices.isSignedIn()) {
      await gamesServices.updateAllLeaderboards(this);
    }
  }

  void showProductionLeaderboard() async {
    final gamesServices = GamesServicesController();
    if (await gamesServices.isSignedIn()) {
      await gamesServices.showProductionLeaderboard();
    }
  }

  void showBankerLeaderboard() async {
    final gamesServices = GamesServicesController();
    if (await gamesServices.isSignedIn()) {
      await gamesServices.showBankerLeaderboard();
    }
  }

  void showLeaderboard() {
    GamesServicesController().showLeaderboard(leaderboardID: GamesServicesController.generalLeaderboardID);
  }

  void showAchievements() {
    GamesServicesController().showAchievements();
  }

  void _applyUpgradeEffects() {
    if (_playerManager?.upgrades['storage'] != null) {
      int storageLevel = _playerManager!.upgrades['storage']!.level;
      double newCapacity = GameConstants.INITIAL_STORAGE_CAPACITY *
          (1 + (storageLevel * GameConstants.STORAGE_UPGRADE_MULTIPLIER));
      _playerManager!.updateMaxMetalStorage(newCapacity);
      _metalManager?.upgradeStorageCapacity(storageLevel);
    }
  }

  Map<String, bool> getVisibleScreenElements() {
    // S'assurer que LevelSystem est initialisé
    final currentLevel = _levelSystem?.level ?? 1;

    return {
      // Éléments de base
      'metalStock': true,  // Toujours visible
      'paperclipStock': true,  // Toujours visible
      'manualProductionButton': true,  // Toujours visible
      'moneyDisplay': true,  // Toujours visible

      // Éléments de marché
      'market': currentLevel >= GameConstants.MARKET_UNLOCK_LEVEL,
      'marketPrice': currentLevel >= GameConstants.MARKET_UNLOCK_LEVEL,
      'sellButton': currentLevel >= GameConstants.MARKET_UNLOCK_LEVEL,
      'marketStats': currentLevel >= GameConstants.MARKET_UNLOCK_LEVEL,
      'priceChart': currentLevel >= GameConstants.MARKET_UNLOCK_LEVEL,

      // Éléments de production
      'metalPurchaseButton': currentLevel >= 1,
      'autoclippersSection': currentLevel >= 3,
      'productionStats': currentLevel >= 2,
      'efficiencyDisplay': currentLevel >= 3,

      // Éléments d'amélioration
      'upgradesSection': currentLevel >= GameConstants.UPGRADES_UNLOCK_LEVEL,
      'upgradesScreen': currentLevel >= GameConstants.UPGRADES_UNLOCK_LEVEL,

      // Éléments de progression
      'levelDisplay': true,
      'experienceBar': true,
      'comboDisplay': currentLevel >= 2,

      // Éléments de statistiques
      'statsSection': currentLevel >= 4,
      'achievementsSection': currentLevel >= 5,

      // Éléments d'interface
      'settingsButton': true,
      'musicToggle': true,
      'notificationButton': true,
      'saveLoadButtons': true
    };
  }

  bool purchaseUpgrade(String upgradeId) {
    if (!_isInitialized || _playerManager == null || _statistics == null) return false;

    if (!_playerManager!.canAffordUpgrade(upgradeId)) return false;

    final upgrade = _playerManager!.upgrades[upgradeId];
    if (upgrade == null) return false;

    double cost = upgrade.getCost();
    bool success = _playerManager!.purchaseUpgrade(upgradeId);

    if (success) {
      // Mise à jour des statistiques
      _statistics!.updateProgression(
        upgradesBought: 1,
        upgradeType: upgradeId,
      );
      _statistics!.updateEconomics(moneySpent: cost);
    }

    return success;
  }

  void _setupLifecycleListeners() {
    SystemChannels.lifecycle.setMessageHandler((String? state) async {
      if (state == 'paused' || state == 'inactive') {
        await saveOnImportantEvent();
        await _autoSaveService?.createBackup();
      }
      return null;
    });
  }

  // Méthode pour définir le contexte
  void setContext(BuildContext context) {
    _context = context;

    // Mettre à jour le contexte du CrisisManager
    if (_crisisManager != null) {
      _crisisManager!.setContext(context);
    }
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

  // Méthode pour basculer l'interface de crise
  void toggleCrisisInterface() {
    if (_crisisManager != null) {
      _crisisManager!.toggleCrisisInterface();
    }
  }

  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void checkMilestones() {
    if (_levelSystem != null && _levelSystem!.level % 5 == 0) {
      activateXPBoost();
    }
  }

  void activateXPBoost() {
    if (_levelSystem != null) {
      _levelSystem!.applyXPBoost(2.0, const Duration(minutes: 5));
      EventManager.instance.addEvent(
          EventType.XP_BOOST,
          'Bonus XP activé !',
          description: 'x2 XP pendant 5 minutes',
          importance: EventImportance.MEDIUM
      );
    }
  }

  @override
  void dispose() {
    debugPrint('GameState: dispose appelé - nettoyage des ressources');

    // Arrêter tous les timers
    _stopAllTimers();

    // Libérer les autres ressources
    if (_autoSaveService != null) {
      _autoSaveService!.dispose();
    }

    if (_levelSystem != null) {
      _levelSystem!.dispose();
    }

    if (_crisisManager != null) {
      _crisisManager!.dispose();
    }

    // Autres nettoyages si nécessaire...

    super.dispose();
  }
}