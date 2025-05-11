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

import 'package:games_services/games_services.dart' as gs;

import '../managers/metal_manager.dart';
import '../managers/statistics_manager.dart';
import '../managers/production_manager.dart';
import '../services/save/save_system.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../services/user/user_manager.dart';

class GameState extends ChangeNotifier implements SaveDataProvider {
  late final PlayerManager _playerManager;
  late final MarketManager _marketManager;
  late final MetalManager _metalManager;
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

  // Getter pour accéder au metalManager depuis l'extérieur
  MetalManager get metalManager => _metalManager;
  MetalManager get resources => _metalManager;

  // Ajouter un getter pour le nouveau manager
  ProductionManager get productionManager => _productionManager;
  late final ProductionManager _productionManager;

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

  LevelSystem get levelSystem => _levelSystem;
  MissionSystem get missionSystem => _missionSystem;

  // Utilisation de l'injection pour obtenir les instances
  late UserManager _userManager;
  late SaveSystem _saveSystem;

  GameState() {
    _initializeManagers();
  }

  void _initializeManagers() {
    if (!_isInitialized) {
      // Obtenir les instances par injection plutôt que par création
      _userManager = UserManager();
      _saveSystem = SaveSystem();

      // Étape 1 : Création des managers
      _createManagers();

      // Étape 2 : Configuration et démarrage
      _configureAndStart();

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
      _levelSystem = LevelSystem();
      _missionSystem = MissionSystem();
      _metalManager = MetalManager(
          onCrisisTriggered: () {
            enterCrisisMode();
          }
      );
      _marketManager = MarketManager(MarketDynamics());
      final saveSystem = SaveSystem();
      _autoSaveService = AutoSaveService(saveSystem, this);

      // Création de ProductionManager
      _productionManager = ProductionManager(
        metalManager: _metalManager,
        levelSystem: _levelSystem,
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
          _statistics.updateProduction(
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

      // Création du PlayerManager avec référence à this (GameState)
      _playerManager = PlayerManager(
        gameState: this,
        levelSystem: _levelSystem,
        metalManager: _metalManager,
        marketManager: _marketManager,
      );
    } catch (e) {
      print('Erreur lors de la création des managers: $e');
      rethrow;
    }
  }

  void _updateLeaderboardsOnMilestone() {
    if (_totalPaperclipsProduced % 100 == 0 ||     // Tous les 100 trombones
        levelSystem.level % 5 == 0 ||               // Tous les 5 niveaux
        _totalTimePlayedInSeconds % 3600 == 0) {    // Toutes les heures
      updateLeaderboard();
    }
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
  DateTime? get lastSaveTime => SaveSystem().lastSaveTime;

  int get totalTimePlayed => _totalTimePlayedInSeconds;
  int get totalPaperclipsProduced => _productionManager.totalPaperclipsProduced;
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

    // Mise à jour des classements
    final gamesServices = GamesServicesController();
    gamesServices.submitCompetitiveScore(
        score: competitiveScore,
        paperclips: _totalPaperclipsProduced,
        money: playerManager.money,
        timePlayed: competitivePlayTime.inSeconds,
        level: levelSystem.level,
        efficiency: calculateEfficiencyRating()
    );

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
              onShowLeaderboard: () => gamesServices.showCompetitiveLeaderboard(),
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
    if (competitivePlayTime.inMinutes < 10 && _isInCrisisMode) {
      gamesServices.unlockCompetitiveAchievement(CompetitiveAchievement.SPEED_RUN);
    }

    // Vérifier l'efficacité
    if (calculateEfficiencyRating() > 8.0) {
      gamesServices.unlockCompetitiveAchievement(CompetitiveAchievement.EFFICIENCY_MASTER);
    }
  }

  // Méthodes déléguées au SaveSystem
  Future<bool> syncSavesToCloud() async {
    return await SaveSystem().syncSavesToCloud();
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
  LevelSystem get level => levelSystem;

  double get autocliperCost => _productionManager.calculateAutoclipperCost();

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
    if (_metalManager.metal < GameConstants.METAL_PER_PAPERCLIP) return 0;

    double metalUsed = GameConstants.METAL_PER_PAPERCLIP;
    double efficiencyBonus = 1.0 + (playerManager.upgrades['efficiency']?.level ?? 0) * 0.1;
    metalUsed /= efficiencyBonus;

    _metalManager.updateMetal(_metalManager.metal - metalUsed);
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
      _statistics.updatePlayTime(const Duration(seconds: 1));
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

  // Implémentation de SaveDataProvider
  @override
  Map<String, dynamic> prepareGameData() {
    // Préparation des données de base
    final Map<String, dynamic> baseData = {
      'version': GameConstants.VERSION,
      'timestamp': DateTime.now().toIso8601String(),
      'statistics': _statistics.toJson(),
      'totalTimePlayedInSeconds': _totalTimePlayedInSeconds,
      'totalPaperclipsProduced': _productionManager.totalPaperclipsProduced,
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
        'last_sync': DateTime.now().toIso8601String(),
      }
    };

    // Ajout des données des managers
    try {
      baseData['playerManager'] = playerManager.toJson();
      baseData['marketManager'] = marketManager.toJson();
      baseData['levelSystem'] = levelSystem.toJson();
      baseData['metalManager'] = _metalManager.toJson();
      baseData['productionManager'] = _productionManager.toJson();

      // Compatibilité rétrograde: copier paperclips dans playerManager
      if (!baseData['playerManager'].containsKey('paperclips')) {
        // Cloner playerManager pour éviter la modification directe
        var playerData = Map<String, dynamic>.from(baseData['playerManager']);
        // Ajouter paperclips depuis productionManager
        playerData['paperclips'] = _productionManager.paperclips;
        // Remplacer playerManager par la version mise à jour
        baseData['playerManager'] = playerData;
      }

      // Compatibilité rétrograde: copier autoclippers dans playerManager
      if (!baseData['playerManager'].containsKey('autoclippers')) {
        // Cloner si pas déjà fait
        var playerData = baseData['playerManager'] is Map
            ? Map<String, dynamic>.from(baseData['playerManager'])
            : <String, dynamic>{};
        // Ajouter autoclippers depuis productionManager
        playerData['autoclippers'] = _productionManager.autoclippers;
        // Remplacer playerManager par la version mise à jour
        baseData['playerManager'] = playerData;
      }

      if (_missionSystem != null) {
        baseData['missionSystem'] = _missionSystem!.toJson();
      }

      return baseData;
    } catch (e) {
      print('Erreur dans prepareGameData: $e');
      rethrow;
    }
  }

  @override
  void loadGameData(Map<String, dynamic> gameData) {
    try {
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

      if (gameData['metalManager'] != null) {
        _metalManager.fromJson(gameData['metalManager']);
      }

      // Chargement compatible avec les anciennes versions
      if (gameData['productionManager'] != null) {
        try {
          _productionManager.fromJson(gameData['productionManager']);
        } catch (e, stack) {
          print('Erreur lors du chargement de productionManager: $e');
          FirebaseCrashlytics.instance.recordError(e, stack, reason: 'ProductionManager loading error');

          // Tentative de récupération avec conversion manuelle
          try {
            final prodData = gameData['productionManager'] as Map<String, dynamic>;
            Map<String, dynamic> safeData = {
              'paperclips': _safeDoubleConversion(prodData['paperclips']),
              'autoclippers': _safeIntConversion(prodData['autoclippers']),
              'totalPaperclipsProduced': _safeIntConversion(prodData['totalPaperclipsProduced']),
            };
            _productionManager.fromJson(safeData);
          } catch (e2) {
            print('Échec de la récupération de productionManager: $e2');
            // Dernière tentative - réinitialiser à des valeurs par défaut
            _productionManager.updatePaperclips(0.0);
            _productionManager.updateAutoclippers(0);
          }
        }
      } else if (gameData['playerManager'] != null &&
          (gameData['playerManager'] as Map<String, dynamic>).containsKey('paperclips')) {
        // Ancienne structure: paperclips dans playerManager
        final playerData = gameData['playerManager'] as Map<String, dynamic>;

        // Mettre à jour le ProductionManager
        Map<String, dynamic> productionData = {
          'paperclips': playerData['paperclips'],
          'autoclippers': playerData['autoclippers'] ?? 0,
          'totalPaperclipsProduced': gameData['totalPaperclipsProduced'] ?? playerData['paperclips'] ?? 0,
        };

        _productionManager.fromJson(productionData);
      }

      _totalTimePlayedInSeconds = (gameData['totalTimePlayedInSeconds'] as num?)?.toInt() ?? 0;

      // Assurer la cohérence avec ProductionManager pour totalPaperclipsProduced
      _totalPaperclipsProduced = _productionManager.totalPaperclipsProduced;

      // Charger le mode de jeu
      _gameMode = gameData['gameMode'] != null
          ? GameMode.values[gameData['gameMode'] as int]
          : GameMode.INFINITE;

      // Charger le temps de départ en mode compétitif
      if (gameData['competitiveStartTime'] != null) {
        try {
          _competitiveStartTime = DateTime.parse(gameData['competitiveStartTime'] as String);
        } catch (e) {
          print('Erreur de parsing de date: ${gameData['competitiveStartTime']}');
          // Utiliser la date actuelle comme fallback
          _competitiveStartTime = gameData['gameMode'] == GameMode.COMPETITIVE.index
              ? DateTime.now() : null;
        }
      }

      // Charger les données du mode crise
      _handleCrisisModeData(gameData);

      // Rétablir les timers
      _startTimers();
      notifyListeners();
    } catch (e, stack) {
      print('Erreur lors du chargement des données: $e');
      print('Stack trace: $stack');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'LoadGameData error');
      rethrow;
    }
  }
// Méthodes utilitaires pour les conversions
  double _safeDoubleConversion(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }

  int _safeIntConversion(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return 0;
      }
    }
    return 0;
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

  void processProduction() {
    // Obtenir l'état avant la production
    int previousTotal = _totalPaperclipsProduced;
    double metalBefore = _metalManager.metal;

    // Appeler la méthode de production originale
    _productionManager.processProduction();

    // Calculer la quantité produite et le métal utilisé
    int productionAmount = _totalPaperclipsProduced - previousTotal;
    double metalAfter = _metalManager.metal;
    double metalUsed = metalBefore - metalAfter;

    // Si la production a eu lieu, mettre à jour les statistiques
    if (productionAmount > 0) {
      // Calculer les autres métriques
      double metalSaved = 0.0; // À calculer selon votre logique d'efficacité
      double efficiency = 0.0; // À calculer selon votre logique

      // Mettre à jour les statistiques
      _statistics.updateProduction(
          isManual: false,
          amount: productionAmount,
          metalUsed: metalUsed,
          metalSaved: metalSaved,
          efficiency: efficiency
      );

      // Enregistrer les records si nécessaire
      _statistics.updateRecord('maxProduction', productionAmount);
    }
  }

  void _applyProduction(double amount) {
    if (amount <= 0) return;

    player.updatePaperclips(player.paperclips + amount);
    _totalPaperclipsProduced += amount.floor();
    level.addAutomaticProduction(amount.floor());

    _statistics.updateProduction(
        isManual: false,
        amount: amount.floor(), // Utiliser une variable disponible pour la quantité produite
        metalUsed: _metalManager.metal, // Utiliser une variable disponible pour le métal utilisé
        metalSaved: 0.0, // Ajuster selon votre logique
        efficiency: 0.0 // Ajuster selon votre logique
    );

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
            saleRecord: SaleRecord(
                timestamp: DateTime.now(),
                quantity: potentialSales,
                price: salePrice,
                revenue: revenue
            )
        );
      }
    }
  }

  void checkResourceCrisis() {
    if (_metalManager.marketMetalStock <= 0 && !_isInCrisisMode) {
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
    _metalManager.buyMetal(
        price: marketManager.currentMetalPrice,
        playerMoney: playerManager.money,
        updatePlayerMoney: (newMoney) => playerManager.updateMoney(newMoney)
    );
    _statistics.updateEconomics(
        moneySpent: marketManager.currentMetalPrice,
        metalBought: GameConstants.METAL_PACK_AMOUNT
    );
  }

  bool _canBuyMetal() {
    double metalPrice = marketManager.currentMetalPrice;
    double currentMetal = _metalManager.metal;
    double maxStorage = _metalManager.maxMetalStorage;

    return playerManager.money >= metalPrice &&
        currentMetal + GameConstants.METAL_PACK_AMOUNT <= maxStorage &&
        marketManager.marketMetalStock >= GameConstants.METAL_PACK_AMOUNT;
  }

  void buyAutoclipper() {
    _productionManager.buyAutoclipper(
        _playerManager.money,
            (newAmount) => _playerManager.updateMoney(newAmount)
    );
  }

  void producePaperclip() {
    _productionManager.produceManualPaperclip();
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
    _statistics.updateProgression(level: newLevel);
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
    final gamesServices = GamesServicesController();
    gamesServices.incrementAchievement(levelSystem);

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

  Future<void> startNewGame(String name, {GameMode mode = GameMode.INFINITE, bool syncToCloud = false}) async {
    try {
      print('Starting new game with name: $name, mode: $mode, syncToCloud: $syncToCloud');

      // Vérifier les limites pour les parties compétitives
      if (mode == GameMode.COMPETITIVE) {
        final userManager = UserManager();
        // Utiliser await pour attendre le résultat de canCreateCompetitiveSave
        if (!(await userManager.canCreateCompetitiveSave())) {
          throw Exception('Vous avez atteint la limite de 3 parties compétitives. Veuillez en supprimer une pour en créer une nouvelle.');
        }
      }

      _gameName = name;
      _gameMode = mode;

      // Si mode compétitif, initialiser le timer
      if (_gameMode == GameMode.COMPETITIVE) {
        _competitiveStartTime = DateTime.now();
      }

      // Réinitialiser l'état si déjà initialisé
      if (_isInitialized) {
        reset();
      }

      // Initialiser les managers
      _initializeManagers();

      // Sauvegarder la nouvelle partie
      await SaveSystem().saveGame(name, syncToCloud: syncToCloud);

      notifyListeners();
    } catch (e) {
      print('Error starting new game: $e');
      rethrow;
    }
  }

  // Méthodes qui délèguent au SaveSystem
  Future<void> saveGame(String name, {bool syncToCloud = true}) async {
    return await _saveSystem.saveGame(name, syncToCloud: syncToCloud);
  }

  Future<void> loadGame(String name, {String? cloudId}) async {
    try {
      _stopAllTimers();
      print('Timers stopped');

      await _saveSystem.loadGame(name, cloudId: cloudId);

      _gameName = name;
      _startTimers();
      notifyListeners();
    } catch (e, stack) {
      print('Error loading game: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }



  Future<void> showCloudSaveSelector() async {
    return await _saveSystem.showCloudSaveSelector();
  }

  Future<void> saveOnImportantEvent() async {
    if (_gameName == null) return;
    return await _saveSystem.saveOnImportantEvent();
  }

  Future<void> checkAndRestoreFromBackup() async {
    return await _saveSystem.checkAndRestoreFromBackup();
  }


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
    if (_playerManager.upgrades['storage'] != null) {
      int storageLevel = _playerManager.upgrades['storage']!.level;
      double newCapacity = GameConstants.INITIAL_STORAGE_CAPACITY *
          (1 + (storageLevel * GameConstants.STORAGE_UPGRADE_MULTIPLIER));
      _playerManager.updateMaxMetalStorage(newCapacity);
      _metalManager.upgradeStorageCapacity(storageLevel);
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
      // Après levelSystem.addUpgradePurchase(upgrade.level);
      _statistics.updateProgression(
          upgradesBought: 1,
          upgradeType: upgradeId
      );
      _statistics.updateEconomics(moneySpent: cost);
    }

    return success;
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
    SaveSystem().setContext(context);
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