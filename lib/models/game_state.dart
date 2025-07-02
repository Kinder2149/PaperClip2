// lib/models/game_state.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/competitive_result_screen.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../main.dart' show navigatorKey;
import '../services/background_music.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_config.dart';
import 'event_system.dart';
import 'player_manager.dart';
import 'market.dart';
import 'progression_system.dart';
import 'resource_manager.dart';
import 'game_state_interfaces.dart';
import 'dart:convert';
import '../utils/notification_manager.dart';
import '../dialogs/metal_crisis_dialog.dart';
import '../services/auto_save_service.dart';
import '../screens/main_screen.dart';
import '../services/save_manager_improved.dart';

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
  bool _showingCrisisView = false;

  // Mode de jeu (infini ou compétitif)
  GameMode _gameMode = GameMode.INFINITE;
  DateTime? _competitiveStartTime;

  // Getters
  GameMode get gameMode => _gameMode;
  DateTime? get competitiveStartTime => _competitiveStartTime;

  bool _isInitialized = false;
  String? _gameName;
  BuildContext? _context;

  bool get showingCrisisView => _showingCrisisView;
  DateTime? get crisisStartTime => _crisisStartTime;
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
    try {
      if (!_isInitialized) {
        if (kDebugMode) {
          print('GameState: Début de l\'initialisation des managers');
        }
        
        // Étape 1 : Création des managers
        _createManagers();
        if (kDebugMode) {
          print('GameState: Managers créés avec succès');
        }
        
        // Étape 2 : Configuration et démarrage - ATTENTION: peut bloquer
        try {
          _configureAndStart();
          if (kDebugMode) {
            print('GameState: Configuration et démarrage terminés');
          }
        } catch (e) {
          if (kDebugMode) {
            print('GameState: Erreur lors de la configuration: $e');
          }
        }
        
        // Donner une référence à EventManager vers cette instance de GameState
        try {
          EventManager.instance.setGameState(this);
          if (kDebugMode) {
            print('GameState: Référence à EventManager définie');
          }
        } catch (e) {
          if (kDebugMode) {
            print('GameState: Erreur lors de la configuration d\'EventManager: $e');
          }
        }
        
        _isInitialized = true;
        if (kDebugMode) {
          print('GameState: Initialisation terminée avec succès');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('GameState: ERREUR CRITIQUE lors de l\'initialisation: $e');
      }
      // Marquer comme initialisé même en cas d'erreur pour éviter les boucles infinies
      _isInitialized = true;
    }
  }

  Duration get competitivePlayTime {
    if (_competitiveStartTime == null) return Duration.zero;
    return DateTime.now().difference(_competitiveStartTime!);
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

  void _updateLeaderboardsOnMilestone() {
    // Disabled in offline version
  }

  void _configureAndStart() {
    try {
      _levelSystem.onLevelUp = _handleLevelUp;
      _missionSystem.initialize();
      _autoSaveService.initialize();
      _setupLifecycleListeners();
      _startTimers();
    } catch (e) {
      print('Erreur lors de la configuration: $e');
      rethrow;
    }
  }

  DateTime _lastUpdateTime = DateTime.now();
  DateTime? _lastSaveTime;
  bool _isPaused = false;
  // État privé
  int _totalTimePlayedInSeconds = 0;
  int _totalPaperclipsProduced = 0;
  double _maintenanceCosts = 0.0;

  // Gestionnaire de timers centralisé
  final Map<String, Timer> _timers = {};

  DateTime? get lastSaveTime => _lastSaveTime;

  int get totalTimePlayed => _totalTimePlayedInSeconds;
  int get totalPaperclipsProduced => _totalPaperclipsProduced;
  double get maintenanceCosts => _maintenanceCosts;

  // Timers
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

  void handleCompetitiveGameEnd() {
    if (_gameMode != GameMode.COMPETITIVE || !_isInCrisisMode) return;

    // Calculer les métriques de la partie compétitive
    final competitiveScore = calculateCompetitiveScore();

    // No leaderboards in offline version

    // Déverrouiller les succès compétitifs si nécessaire
    _checkCompetitiveAchievements(competitiveScore);

    // Afficher le résultat si on a un contexte
    if (_context != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(_context!).push(
          MaterialPageRoute(
            builder: (context) => CompetitiveResultScreen(
              score: competitiveScore,
              paperclips: _totalPaperclipsProduced,
              money: playerManager.money,
              playTime: competitivePlayTime,
              level: levelSystem.level,
              efficiency: calculateEfficiencyRating(),
              onNewGame: () => _startNewCompetitiveGame(context),
              onShowLeaderboard: () => {},
            ),
          ),
        );
      });
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
    double productionScore = _totalPaperclipsProduced * 10;

    // Argent gagné (25% du score)
    double moneyScore = playerManager.money * 5;

    // Niveau atteint (15% du score)
    double levelScore = levelSystem.level * 1000;

    // Bonus d'efficacité (10% du score)
    double efficiencyBonus = calculateEfficiencyRating() * 500;

    // Temps de jeu - bonus inversement proportionnel
    // Plus c'est rapide, plus le bonus est élevé
    int minutes = competitivePlayTime.inMinutes;
    double timeMultiplier = 1.0;
    if (minutes > 0) {
      // Multiplicateur qui diminue avec le temps, mais pas trop vite
      timeMultiplier = 2.0 / (1 + (minutes / 30));
    }

    // Score final
    int finalScore = ((productionScore + moneyScore + levelScore + efficiencyBonus) * timeMultiplier).toInt();

    print('Score compétitif calculé: $finalScore (Prod: $productionScore, Argent: $moneyScore, Niveau: $levelScore, Efficacité: $efficiencyBonus, Temps: $timeMultiplier)');

    return finalScore;
  }

  // Méthode pour calculer l'efficacité (ratio trombones/métal)
  double calculateEfficiencyRating() {
    // Obtenir la consommation totale de métal depuis les statistiques
    double totalMetalUsed = _statistics.getTotalMetalUsed();
    if (totalMetalUsed <= 0) return 1.0;

    // Ratio trombones/métal (ajusté pour être significatif)
    return _totalPaperclipsProduced / totalMetalUsed;
  }

  // Vérification des réalisations (achievements) compétitifs
  void _checkCompetitiveAchievements(int score) {
    // Achievements disabled in offline version
  }

  Future<bool> syncSavesToCloud() async {
    // No cloud sync in offline version
    return false;
  }

  void enterCrisisMode() {
    if (_isInCrisisMode) return;

    print("Début de la transition vers le mode crise");

    // Gérer spécifiquement le mode compétitif
    if (_gameMode == GameMode.COMPETITIVE) {
      // Enregistrer que la crise est active
      _isInCrisisMode = true;
      _crisisStartTime = DateTime.now();

      // Notifier le changement de mode
      EventManager.instance.addEvent(
          EventType.CRISIS_MODE,
          "Mode Crise Activé",
          description: "Fin de partie compétitive : plus de métal disponible !",
          importance: EventImportance.CRITICAL,
          additionalData: {
            'timestamp': _crisisStartTime!.toIso8601String(),
            'marketMetalStock': marketManager.marketMetalStock,
            'competitiveMode': true,
          }
      );

      // Sauvegarder l'état avant d'afficher les résultats
      saveOnImportantEvent();

      // Gérer la fin de partie compétitive
      handleCompetitiveGameEnd();
      return;
    }

    // Code existant pour le mode infini...
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

    // Timer du marché - Moins fréquent pour réduire les vérifications excessives
    marketTimer = Timer.periodic(
        const Duration(seconds: 3),  // Réduit la fréquence à 3 secondes au lieu de 1
        (timer) => _processMarket()
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
    // Obtenir l'horodatage actuel
    final DateTime now = DateTime.now();
    
    // Préparation des données de base
    final Map<String, dynamic> baseData = {
      'version': GameConstants.VERSION,
      'timestamp': now.toIso8601String(),
      'statistics': _statistics.toJson(),
      'totalTimePlayedInSeconds': _totalTimePlayedInSeconds,
      'totalPaperclipsProduced': _totalPaperclipsProduced,
      'gameMode': _gameMode.index,
      'competitiveStartTime': _competitiveStartTime?.toIso8601String(),
      // Données de crise complètes
      'crisisMode': {
        'isInCrisisMode': _isInCrisisMode,
        'crisisStartTime': _crisisStartTime?.toIso8601String(),
        'crisisTransitionComplete': _crisisTransitionComplete,
        'showingCrisisView': _showingCrisisView,
      },
      'achievements': {
        'last_sync': now.toIso8601String(),
      },
      // Données de progression avancées
      'progression': {
        'currentXP': levelSystem.currentXP,
        'currentLevel': levelSystem.currentLevel,
        'xpToNextLevel': levelSystem.xpToNextLevel,
        'missionProgress': missionSystem?.getDetailedMissionProgress() ?? {},
        'combos': {
          'currentCombo': levelSystem.comboSystem?.currentCombo ?? 0,
          'comboMultiplier': levelSystem.comboSystem?.comboMultiplier ?? 1.0,
          'comboTimeLeft': levelSystem.comboSystem?.comboTimer != null ?
              5000 - DateTime.now().difference(levelSystem.comboSystem!.lastComboTime).inMilliseconds : 0,
        },
        'dailyBonus': {
          'claimed': levelSystem.dailyBonus?.hasClaimedToday ?? false,
          'lastClaimDate': levelSystem.dailyBonus?.lastClaimDate?.toIso8601String(),
          'streakDays': levelSystem.dailyBonus?.streakDays ?? 0,
          'timeUntilReset': levelSystem.dailyBonus?.resetTimer != null ? 
              _calculateTimeUntilMidnight(now).inMilliseconds : 0,
        },
      },
      // État des timers
      'timers': {
        'lastSaved': now.toIso8601String(),
        'missionRefresh': missionSystem?.missionRefreshTimer != null ? {
          'isActive': true,
          'lastRefreshTime': missionSystem!.lastMissionRefreshTime?.toIso8601String(),
          'timeUntilNextRefresh': _calculateTimeUntilNextMissionRefresh(missionSystem!).inMilliseconds,
        } : { 'isActive': false },
        'maintenance': playerManager.maintenanceTimer != null ? {
          'isActive': true,
          'lastMaintenanceTime': playerManager.lastMaintenanceTime?.toIso8601String(),
          'interval': GameConstants.MAINTENANCE_INTERVAL.inMilliseconds,
        } : { 'isActive': false },
        'marketUpdate': marketManager.isActive ? {
          'interval': GameConstants.MARKET_UPDATE_INTERVAL.inMilliseconds,
        } : { 'isActive': false },
        'metalPriceUpdate': {
          'lastUpdate': marketManager.lastMetalPriceUpdateTime?.toIso8601String(),
          'interval': GameConstants.METAL_PRICE_UPDATE_INTERVAL.inMilliseconds,
        },
      }
    };

    // Ajout des données des managers
    try {
      baseData['playerManager'] = playerManager.toJson();
      baseData['marketManager'] = marketManager.toJson();
      baseData['levelSystem'] = levelSystem.toJson();
      baseData['missionSystem'] = missionSystem?.toJson();

      // Debug logs
      print('PrepareGameData - Sauvegarde des données:');
      print('Mode de jeu: ${_gameMode == GameMode.INFINITE ? "Infini" : "Compétitif"}');
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
    if (!_isInitialized || _isPaused) return;

    // Calcul des bonus
    double speedBonus = 1.0 + ((playerManager.upgrades['speed']?.level ?? 0) * 0.20);
    double bulkBonus = 1.0 + ((playerManager.upgrades['bulk']?.level ?? 0) * 0.35);

    // Nouveau calcul d'efficacité avec 11% par niveau et plafond 85%
    double efficiencyLevel = (playerManager.upgrades['efficiency']?.level ?? 0).toDouble(); 
    double reduction = min(
        efficiencyLevel * GameConstants.EFFICIENCY_UPGRADE_MULTIPLIER,
        GameConstants.EFFICIENCY_MAX_REDUCTION
    );
    double efficiencyBonus = 1.0 - reduction;

    // Nombre total d'autoclippers avec les bonus
    double totalProduction = playerManager.autoclippers * speedBonus * bulkBonus;

    // Métal nécessaire par trombone avec efficacité
    double metalPerClip = GameConstants.METAL_PER_PAPERCLIP * efficiencyBonus;

    // Nombre maximum de trombones possibles avec le métal disponible
    int maxPossibleClips = (playerManager.metal / metalPerClip).floor();

    // Production effective (limitée par le métal disponible)
    int actualProduction = min(totalProduction.floor(), maxPossibleClips);

    if (actualProduction > 0) {
      // Mise à jour des ressources
      double metalUsed = actualProduction * metalPerClip;
      double metalSaved = actualProduction * GameConstants.METAL_PER_PAPERCLIP * reduction; 

      playerManager.updateMetal(playerManager.metal - metalUsed);
      playerManager.updatePaperclips(playerManager.paperclips + actualProduction);
      _totalPaperclipsProduced += actualProduction;

      // Mise à jour des statistiques
      _statistics.updateProduction(
        isManual: false,
        amount: actualProduction,
        metalUsed: metalUsed,
        metalSaved: metalSaved,
        efficiency: reduction * 100
      );

      // Expérience pour la production automatique
      levelSystem.addAutomaticProduction(actualProduction);
      _updateLeaderboardsOnMilestone();
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

  void _processMarket() {
    if (!_isInitialized) return;

    marketManager.updateMarket();
    double demand = marketManager.calculateDemand(
        playerManager.sellPrice,
        playerManager.getMarketingLevel()
    );

    if (playerManager.paperclips > 0) {
      int potentialSales = min(
          demand.floor(), playerManager.paperclips.floor());
      if (potentialSales > 0) {
        double qualityBonus = 1.0 +
            (playerManager.upgrades['quality']?.level ?? 0) * 0.10;
        double salePrice = playerManager.sellPrice * qualityBonus;
        double revenue = potentialSales * salePrice;

        playerManager.updatePaperclips(
            playerManager.paperclips - potentialSales);
        playerManager.updateMoney(playerManager.money + revenue);
        marketManager.recordSale(potentialSales, salePrice);

        // Ajout statistiques
        _statistics.updateEconomics(
          moneyEarned: revenue,
          sales: potentialSales,
          price: salePrice,
        );
        if (revenue >= 1000) { // Seuil arbitraire de 1000
          updateLeaderboard();
        }
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

    // Ajout des statistiques avant de vérifier le mode de crise
    _statistics.updateEconomics(
      moneySpent: metalPrice,
      metalBought: amount,
    );

    // Vérification une seule fois pour le mode de crise
    if (marketManager.marketMetalStock <= 0) {
      print('Stock épuisé - Déclenchement mode crise'); // Debug
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
      _statistics.updateProgression(autoclippersBought: 1);  
      _statistics.updateEconomics(moneySpent: cost);
      saveOnImportantEvent();

      notifyListeners();
    }
  }

  void producePaperclip() {
    if (player.consumeMetal(GameConstants.METAL_PER_PAPERCLIP)) {
      player.updatePaperclips(player.paperclips + 1);
      _totalPaperclipsProduced++;

      // Mettre à jour le leaderboard tous les 100 trombones
      if (_totalPaperclipsProduced % 100 == 0) {
        updateLeaderboard();
      }

      level.addManualProduction();
      _statistics.updateProduction(
        isManual: true,
        amount: 1,
        metalUsed: GameConstants.METAL_PER_PAPERCLIP,
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
    player.updateSellPrice(newPrice);  
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
          player.updateMoney(player.money + GameConstants.BASE_AUTOCLIPPER_COST);
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
    // No achievements in offline version

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

  Future<void> startNewGame(String name, {GameMode mode = GameMode.INFINITE}) async {
    try {
      _gameName = name;
      _gameMode = mode;

      // Réinitialiser l'état de jeu
      reset();

      // Définir le mode de jeu et le temps de début pour le mode compétitif
      if (mode == GameMode.COMPETITIVE) {
        _competitiveStartTime = DateTime.now();
      } else {
        _competitiveStartTime = null;
      }

      // Charger l'état du son pour cette partie
      // On utilise le service global déclaré dans main.dart
      final backgroundMusicService = Provider.of<BackgroundMusicService>(navigatorKey.currentContext!, listen: false);
      await backgroundMusicService.loadGameMusicState(name);

      // Sauvegarder l'état initial
      await saveGame(name);

      // Démarrer l'autosave
      _autoSaveService.start();

      notifyListeners();

      print('Nouvelle partie créée: $name, mode: $mode');

      // Déclencher un événement pour signaler la création d'une nouvelle partie
      EventManager.instance.addEvent(
        EventType.INFO, // Utilisation de INFO au lieu de SYSTEM
        'Nouvelle partie créée',
        description: 'Partie: $name | Mode: ${mode.toString().split('.').last}',
        importance: EventImportance.LOW,
      );

      return;
    } catch (e, stackTrace) {
      print('Erreur lors de la création d\'une nouvelle partie: $e');
      print(stackTrace);
      throw SaveError('CREATE_ERROR', 'Impossible de créer une nouvelle partie: $e');
    }
  }

  /// Réinitialise uniquement les données de jeu sans toucher aux services critiques
  /// Résout le problème de LateInitializationError avec _autoSaveService
  void _resetGameDataOnly() {
    print('Début de la réinitialisation des données de jeu');
    
    // IMPORTANT: Ne pas réinitialiser les valeurs des managers
    // qui seront automatiquement écrasées lors du chargement
    // Cette approche permet de conserver les structures internes sans les réinitialiser
    // à des valeurs par défaut qui seraient ensuite écrasées
    
    // On réinitialise uniquement les états qui ne seraient pas automatiquement
    // écrasés par le chargement ou qui doivent être réinitialisés pour
    // assurer la propreté du chargement
    _gameMode = GameMode.INFINITE;
    _isInCrisisMode = false;
    _showingCrisisView = false;
    _crisisTransitionComplete = false;
    
    // Réinitialiser les attributs principaux du jeu
    _totalTimePlayedInSeconds = 0;
    _totalPaperclipsProduced = 0;
    _lastSaveTime = null;
    _isInCrisisMode = false;
    _showingCrisisView = false;
    _crisisStartTime = null;
    _crisisTransitionComplete = false;
    _competitiveStartTime = null;
    _isInitialized = true;
    _isPaused = false;
    
    // NE PAS toucher à:
    // - _autoSaveService
    // - Autres services avec late initializers
    
    print('Fin de la réinitialisation des données de jeu');
  }

  Future<void> loadGame(String name) async {
    try {
      // Arrêter les timers existants
      _stopAllTimers();
      
      if (kDebugMode) {
        print('Chargement de la partie: $name');
        // Afficher l'état actuel avant le chargement pour débogage
        final currentState = prepareGameData();
        print('État actuel avant chargement:');
        currentState.forEach((key, value) {
          print('$key: ${value is Map ? "[Object]" : value}');
        });
      }

      final loadedData = await SaveManager.loadGame(name);

      // SOLUTION CORRIGÉE: Nous devons réinitialiser l'état
      // mais sans toucher aux services qui provoquent des LateInitializationError
      
      // 1. Désactiver temporairement l'autosave pour éviter les sauvegardes pendant le chargement
      print('Arrêt temporaire de l\'auto-sauvegarde avant chargement');
      _autoSaveService.stop();
      
      // 2. Effectuer une réinitialisation partielle de l'état du jeu
      // sans toucher aux services déjà initialisés
      _resetGameDataOnly();
      
      // Note: Nous n'essayons plus de réassigner _autoSaveService car c'est un champ late
      
      // Définir le nom de la partie
      _gameName = name;

      // Définir le mode de jeu
      // Récupérer les données du SaveGame
      final Map<String, dynamic> gameData = loadedData != null ? SaveManager.extractGameData(loadedData) : {};
      
      if (kDebugMode) {
        print('Structure de données chargée:');
        gameData.forEach((key, value) {
          print('$key: ${value is Map ? "[Object]" : value}');
        });
      }
      
      _gameMode = gameData.containsKey('gameMode') 
          ? GameMode.values[gameData['gameMode'] as int] 
          : GameMode.INFINITE;

      // Gestion des données de compétition
      if (gameData.containsKey('competitiveStartTime')) {
        final startTimeStr = gameData['competitiveStartTime'];
        if (startTimeStr != null) {
          _competitiveStartTime = DateTime.parse(startTimeStr as String);
        }
      }

      // Charger les données du joueur (vérifier les deux clés possibles)
      if (gameData.containsKey('playerManager')) {
        print('Chargement des données depuis la clé "playerManager"');
        _playerManager.fromJson(gameData['playerManager'] as Map<String, dynamic>);
      } else if (gameData.containsKey('player')) {
        print('Chargement des données depuis la clé "player"');
        _playerManager.fromJson(gameData['player'] as Map<String, dynamic>);
      } else {
        print('ERREUR: Aucune donnée joueur trouvée dans la sauvegarde!');
      }
      
      // Charger les données de ressources (vérifier les différentes clés possibles)
      if (gameData.containsKey('resourceManager')) {
        print('Chargement des ressources depuis la clé "resourceManager"');
        _resourceManager.fromJson(gameData['resourceManager'] as Map<String, dynamic>);
      } else if (gameData.containsKey('resources')) {
        print('Chargement des ressources depuis la clé "resources"');
        _resourceManager.fromJson(gameData['resources'] as Map<String, dynamic>);
      } else {
        print('Aucune donnée de ressources trouvée');
      }
      
      // Charger les données du marché (vérifier les différentes clés possibles)
      if (gameData.containsKey('marketManager')) {
        print('Chargement du marché depuis la clé "marketManager"');
        _marketManager.fromJson(gameData['marketManager'] as Map<String, dynamic>);
      } else if (gameData.containsKey('market')) {
        print('Chargement du marché depuis la clé "market"');
        _marketManager.fromJson(gameData['market'] as Map<String, dynamic>);
      } else {
        print('Aucune donnée de marché trouvée');
      }

      // Charger les données de niveau (vérifier les différentes clés possibles)
      if (gameData.containsKey('levelSystem')) {
        print('Chargement du niveau depuis la clé "levelSystem"');
        _levelSystem.fromJson(gameData['levelSystem'] as Map<String, dynamic>);
      } else if (gameData.containsKey('level')) {
        print('Chargement du niveau depuis la clé "level"');
        _levelSystem.fromJson(gameData['level'] as Map<String, dynamic>);
      } else {
        print('Aucune donnée de niveau trouvée');
      }

      // Charger les données de missions (vérifier les différentes clés possibles)
      if (gameData.containsKey('missionSystem')) {
        print('Chargement des missions depuis la clé "missionSystem"');
        _missionSystem.fromJson(gameData['missionSystem'] as Map<String, dynamic>);
      } else if (gameData.containsKey('missions')) {
        print('Chargement des missions depuis la clé "missions"');
        _missionSystem.fromJson(gameData['missions'] as Map<String, dynamic>);
      } else {
        print('Aucune donnée de missions trouvée');
      }

      // Charger les statistiques (vérifier les différentes clés possibles)
      if (gameData.containsKey('statistics')) {
        print('Chargement des statistiques depuis la clé "statistics"');
        _statistics.fromJson(gameData['statistics'] as Map<String, dynamic>);
      } else {
        print('Aucune donnée de statistiques trouvée');
      }
      
      // Charger les informations de progression avancées si disponibles
      if (gameData.containsKey('progression')) {
        final progressionData = gameData['progression'] as Map<String, dynamic>;
        print('Chargement des données de progression avancées');
        
        // Restaurer les informations de combo si disponibles
        if (progressionData.containsKey('combos')) {
          final comboData = progressionData['combos'] as Map<String, dynamic>;
          if (_levelSystem.comboSystem != null) {
            _levelSystem.comboSystem!.currentCombo = (comboData['currentCombo'] as num).toInt();
            if (comboData.containsKey('comboMultiplier')) {
              _levelSystem.comboSystem!.comboMultiplier = (comboData['comboMultiplier'] as num).toDouble();
            }
            print('Combo restauré: ${_levelSystem.comboSystem!.currentCombo} (x${_levelSystem.comboSystem!.comboMultiplier})');
          }
        }
        
        // Restaurer les informations de bonus quotidien si disponibles
        if (progressionData.containsKey('dailyBonus') && _levelSystem.dailyBonus != null) {
          final bonusData = progressionData['dailyBonus'] as Map<String, dynamic>;
          _levelSystem.dailyBonus!.hasClaimedToday = bonusData['claimed'] as bool? ?? false;
          if (bonusData.containsKey('streakDays')) {
            _levelSystem.dailyBonus!.streakDays = (bonusData['streakDays'] as num).toInt();
          }
          if (bonusData.containsKey('lastClaimDate')) {
            _levelSystem.dailyBonus!.lastClaimDate = 
                DateTime.tryParse(bonusData['lastClaimDate'] as String);
          }
          print('Bonus quotidien restauré: streak=${_levelSystem.dailyBonus!.streakDays}, claimed=${_levelSystem.dailyBonus!.hasClaimedToday}');
        }
      }
      
      // Charger les compteurs globaux (temps de jeu, total de trombones produits, etc.)
      if (gameData.containsKey('totalPaperclipsProduced')) {
        _totalPaperclipsProduced = (gameData['totalPaperclipsProduced'] as num).toInt();
        print('Total des trombones produits restauré: $_totalPaperclipsProduced');
      }
      
      if (gameData.containsKey('totalTimePlayedInSeconds')) {
        _totalTimePlayedInSeconds = (gameData['totalTimePlayedInSeconds'] as num).toInt();
        print('Temps de jeu total restauré: $_totalTimePlayedInSeconds secondes');
      }

      // Vérifier et charger les données de mode crise
      if (gameData.containsKey('crisisMode')) {
        _handleCrisisModeData(gameData['crisisMode'] as Map<String, dynamic>);
      }
      
      // Restaurer les informations des timers
      if (gameData.containsKey('timers')) {
        print('Restauration de l\'\u00e9tat des timers');
        final timersData = gameData['timers'] as Map<String, dynamic>;
        
        // Récupérer la date de la dernière sauvegarde
        DateTime? lastSaveTime;
        if (timersData.containsKey('lastSaved')) {
          lastSaveTime = DateTime.tryParse(timersData['lastSaved'] as String);
        }
        
        // Restaurer le timer de rafraîchissement des missions
        if (timersData.containsKey('missionRefresh') && lastSaveTime != null) {
          final missionData = timersData['missionRefresh'] as Map<String, dynamic>;
          if (missionData['isActive'] as bool && _missionSystem != null) {
            // Si le timer était actif, réinitialiser le timer des missions en tenant compte du temps écoulé
            if (missionData.containsKey('lastRefreshTime')) {
              _missionSystem!.lastMissionRefreshTime = DateTime.parse(missionData['lastRefreshTime'] as String);
              print('Dernière mise à jour des missions: ${_missionSystem!.lastMissionRefreshTime}');
            }
          }
        }
        
        // Restaurer le timer de maintenance
        if (timersData.containsKey('maintenance') && lastSaveTime != null) {
          final maintenanceData = timersData['maintenance'] as Map<String, dynamic>;
          if (maintenanceData['isActive'] as bool) {
            // Si le timer était actif, mettre à jour la dernière date de maintenance
            if (maintenanceData.containsKey('lastMaintenanceTime')) {
              _playerManager.lastMaintenanceTime = DateTime.parse(maintenanceData['lastMaintenanceTime'] as String);
              print('Dernière maintenance: ${_playerManager.lastMaintenanceTime}');
            }
          }
        }
        
        // Restaurer l'état de mise à jour du prix du métal
        if (timersData.containsKey('metalPriceUpdate') && lastSaveTime != null) {
          final metalData = timersData['metalPriceUpdate'] as Map<String, dynamic>;
          if (metalData.containsKey('lastUpdate')) {
            _marketManager.lastMetalPriceUpdateTime = DateTime.parse(metalData['lastUpdate'] as String);
            print('Dernière mise à jour du prix du métal: ${_marketManager.lastMetalPriceUpdateTime}');
          }
        }
      }

      // Charger les notifications pour cette sauvegarde
      // TODO: Implémenter le chargement des notifications
      // await _loadNotificationsForGame(name);
      
      // Charger l'état du son spécifique à cette partie
      // On utilise le service global déclaré dans main.dart
      if (navigatorKey.currentContext != null) {
        final backgroundMusicService = Provider.of<BackgroundMusicService>(navigatorKey.currentContext!, listen: false);
        await backgroundMusicService.loadGameMusicState(name);
      }

      // Démarrer les timers
      _startTimers();

      // Redémarrer l'autosave avec la méthode restart() plutôt que start()
      print('Redémarrage de l\'auto-sauvegarde après chargement');
      _autoSaveService.restart();

      // Les événements système et notifications sont gérés automatiquement
      
      // Mettre à jour l'état
      notifyListeners();

      // Enregistrer un événement de chargement
      EventManager.instance.addEvent(
        EventType.INFO, // Utilisation de INFO au lieu de SYSTEM
        'Partie chargée',
        description: 'Nom: $name',
        importance: EventImportance.LOW,
      );

      if (kDebugMode) {
        print('Partie chargée: $name');
        // Afficher l'état après le chargement pour débogage
        final newState = prepareGameData();
        print('État après chargement:');
        newState.forEach((key, value) {
          print('$key: ${value is Map ? "[Object]" : value}');
        });
      }

      return;
    } catch (e, stackTrace) {
      print('Erreur lors du chargement de la partie: $e');
      print(stackTrace);
      throw SaveError('LOAD_ERROR', 'Impossible de charger la partie: $e');
    }
  }

  void _handleCrisisModeData(Map<String, dynamic> gameData) {
    if (gameData['crisisMode'] != null) {
      final crisisData = gameData['crisisMode'] as Map<String, dynamic>;
      _isInCrisisMode = crisisData['isInCrisisMode'] as bool? ?? false;
      _showingCrisisView = crisisData['showingCrisisView'] as bool? ?? false;
      if (_isInCrisisMode) {
        _crisisTransitionComplete = crisisData['crisisTransitionComplete'] as bool? ?? true;
        if (crisisData['crisisStartTime'] != null) {
          _crisisStartTime = DateTime.parse(crisisData['crisisStartTime'] as String);
        }
      }
    }
  }

  void updateLeaderboard() async {
    // No leaderboards in offline version
  }

  void showProductionLeaderboard() async {
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        const SnackBar(
          content: Text('Les classements ne sont pas disponibles dans cette version'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void showBankerLeaderboard() async {
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        const SnackBar(
          content: Text('Les classements ne sont pas disponibles dans cette version'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  
  /// Calcule le temps restant jusqu'à minuit suivant
  Duration _calculateTimeUntilMidnight(DateTime now) {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }
  
  /// Calcule le temps restant jusqu'au prochain rafraîchissement des missions
  Duration _calculateTimeUntilNextMissionRefresh(MissionSystem missionSystem) {
    if (missionSystem.lastMissionRefreshTime == null) {
      return const Duration(hours: 24);
    }
    
    final lastRefresh = missionSystem.lastMissionRefreshTime!;
    final nextRefresh = lastRefresh.add(const Duration(hours: 24));
    final now = DateTime.now();
    
    if (nextRefresh.isAfter(now)) {
      return nextRefresh.difference(now);
    } else {
      return Duration.zero;
    }
  }

  void showLeaderboard() {
    // No leaderboards in offline version
  }

  void showAchievements() {
    // No achievements in offline version
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
      playerManager.fromJson(gameData['playerManager']);
    }
    if (gameData['marketManager'] != null) {
      marketManager.fromJson(gameData['marketManager']);
    }
    if (gameData['levelSystem'] != null) {
      levelSystem.fromJson(gameData['levelSystem']);
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
      // Préparation des données de jeu
      final gameData = prepareGameData();

      // Création de l'objet SaveGame
      final saveData = SaveGame(
        name: name,
        lastSaveTime: DateTime.now(),
        gameData: gameData,
        version: GameConstants.VERSION,
        gameMode: _gameMode,
      );

      // Sauvegarde locale
      await SaveManager.saveGame(saveData);
      _gameName = name;
      _lastSaveTime = DateTime.now();

      notifyListeners();
    } catch (e) {
      print('Erreur dans GameState.saveGame: $e');
      rethrow;
    }
  }

  Future<void> saveOnImportantEvent() async {
    if (!_isInitialized || _gameName == null) return;

    try {
      await saveGame(_gameName!);
      _lastSaveTime = DateTime.now();
    } catch (e) {
      print('Erreur lors de la sauvegarde événementielle: $e');
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
  void toggleCrisisInterface() {
    if (!isInCrisisMode || !crisisTransitionComplete) return;

    _showingCrisisView = !_showingCrisisView;

    EventManager.instance.addInterfaceTransitionEvent(_showingCrisisView);

    notifyListeners();
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