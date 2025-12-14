// lib/models/game_state.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/competitive_result_screen.dart';
import 'dart:async';
import 'dart:math';
import 'package:provider/provider.dart';
import '../main.dart' show navigatorKey;
import '../services/background_music.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/persistence/game_snapshot.dart';
import '../services/persistence/game_persistence_orchestrator.dart';
import '../constants/game_config.dart';
import 'event_system.dart';
import '../managers/player_manager.dart';
import '../managers/market_manager.dart';
import 'progression_system.dart';
import '../managers/resource_manager.dart';
import '../managers/production_manager.dart';

import 'game_state_interfaces.dart';
import 'statistics_manager.dart';
import '../models/upgrade.dart';

import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/notification_manager.dart';
import '../dialogs/metal_crisis_dialog.dart';
import '../services/auto_save_service.dart';
import '../screens/main_screen.dart';
import '../services/save_game.dart';

class GameState extends ChangeNotifier {
  // Managers coeur de jeu
  late final PlayerManager _playerManager;
  late final MarketManager _marketManager;
  late final ResourceManager _resourceManager;
  late final LevelSystem _levelSystem;
  // MissionSystem (Option A — mise en pause):
  // - conservé pour compatibilité/persistance (JSON) et future feature
  // - non initialisé au runtime (pas de timer, pas de callbacks, pas d'événements gameplay)
  late final MissionSystem _missionSystem;
  late final StatisticsManager _statistics;
  late final ProductionManager _productionManager;

  // Services auxiliaires
  late final AutoSaveService _autoSaveService;

  // État global
  bool _isInCrisisMode = false;
  bool _crisisTransitionComplete = false;
  bool _showingCrisisView = false;
  DateTime? _crisisStartTime;

  // Mode de jeu (infini ou compétitif)
  GameMode _gameMode = GameMode.INFINITE;
  DateTime? _competitiveStartTime;

  bool _isInitialized = false;
  String? _gameName;
  BuildContext? _context;

  // Suivi interne du temps de jeu et des compteurs globaux
  DateTime _lastUpdateTime = DateTime.now();
  DateTime? _lastSaveTime;
  bool _isPaused = false;
  int _totalTimePlayedInSeconds = 0;
  int _totalPaperclipsProduced = 0;

  void markLastSaveTime(DateTime value) {
    _lastSaveTime = value;
  }

  // Getters complémentaires utilisés par l'UI
  DateTime? get lastSaveTime => _lastSaveTime;
  int get totalTimePlayed => _totalTimePlayedInSeconds;
  int get totalPaperclipsProduced => _totalPaperclipsProduced;
  double get maintenanceCosts => 0.0; // placeholder simple
  ResourceManager get resources => _resourceManager;

  // Getters publics
  StatisticsManager get statistics => _statistics;
  bool get isInCrisisMode => _isInCrisisMode;
  bool get crisisTransitionComplete => _crisisTransitionComplete;
  bool get showingCrisisView => _showingCrisisView;
  DateTime? get crisisStartTime => _crisisStartTime;
  bool get isInitialized => _isInitialized;
  String? get gameName => _gameName;
  PlayerManager get playerManager => _playerManager;
  MarketManager get marketManager => _marketManager;
  ResourceManager get resourceManager => _resourceManager;
  LevelSystem get levelSystem => _levelSystem;
  MissionSystem get missionSystem => _missionSystem;
  GameMode get gameMode => _gameMode;
  DateTime? get competitiveStartTime => _competitiveStartTime;
  bool get isPaused => _isPaused;
  ProductionManager get productionManager => _productionManager;

  // Durée de jeu en mode compétitif (utilisée par plusieurs widgets)
  Duration get competitivePlayTime {
    if (_competitiveStartTime == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(_competitiveStartTime!);
  }

  // Alias de compatibilité
  int get totalTimePlayedInSeconds => _totalTimePlayedInSeconds;
  bool get isCrisisTransitionComplete => _crisisTransitionComplete;
  String? get gameId => _gameName;
  double get autocliperCost => _playerManager.autoClipperCost;

  bool get autoSellEnabled => _marketManager.autoSellEnabled;

  void setAutoSellEnabled(bool value) {
    _marketManager.autoSellEnabled = value;
    notifyListeners();
  }

  bool canBuyMetal() => _canBuyMetal();

  // Alias de compatibilité pour les écrans qui appellent gameState.purchaseMetal()
  bool purchaseMetal() {
    return _resourceManager.purchaseMetal();
  }

  GameState() {
    _initializeManagers();
  }

  // Méthode de compatibilité pour les tests qui appellent initialize()
  void initialize() {
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

  void _createManagers() {
    try {
      _statistics = StatisticsManager();
      _resourceManager = ResourceManager();
      _marketManager = MarketManager();
      _levelSystem = LevelSystem();
      // MissionSystem (Option A — mise en pause):
      // - conservé pour compatibilité/persistance (JSON) et future feature
      // - non initialisé au runtime (pas de timer, pas de callbacks, pas d'événements gameplay)
      _missionSystem = MissionSystem();
      _autoSaveService = AutoSaveService(this);

      _playerManager = PlayerManager();

      // Manager de production basé sur les managers cœur de jeu
      _productionManager = ProductionManager(
        playerManager: _playerManager,
        statistics: _statistics,
        levelSystem: _levelSystem,
      );

      // Lier les managers entre eux
      _resourceManager.setPlayerManager(_playerManager);
      _resourceManager.setMarketManager(_marketManager);
      _marketManager.setManagers(_playerManager, _statistics);
    } catch (e) {
      print('Erreur lors de la création des managers: $e');
      rethrow;
    }
  }

  /// Tick métier pour le temps de jeu.
  ///
  /// Appelé par GameSessionController; aucun Timer n'est géré ici.
  void incrementGameTime(int seconds) {
    _statistics.updateGameTime(seconds);

    // Compatibilité legacy (UI/persistance): miroir du compteur officiel.
    _totalTimePlayedInSeconds = _statistics.totalGameTimeSec;
  }

  /// Tick métier pour le marché.
  ///
  /// Appelé par GameSessionController; aucun Timer n'est géré ici.
  void tickMarket() {
    if (!_isInitialized || _isPaused) return;
    try {
      if (kDebugMode) {
        print('GameState: tick de marché, updateMarketState() + processSales()');
      }

      // 1) Mise à jour de l'état du marché (tendances/saturation/prix métal)
      _marketManager.updateMarketState();

      // 2) Vente (chemin officiel unique)
      final sale = _marketManager.processSales(
        playerPaperclips: _playerManager.paperclips,
        sellPrice: _playerManager.sellPrice,
        marketingLevel: _playerManager.getMarketingLevel(),
        updatePaperclips: (delta) {
          _playerManager.updatePaperclips(_playerManager.paperclips + delta);
        },
        updateMoney: (delta) {
          _playerManager.updateMoney(_playerManager.money + delta);
        },
        updateMarketState: false,
        requireAutoSellEnabled: true,
      );

      // 3) XP de vente
      if (sale.quantity > 0) {
        _levelSystem.addSale(sale.quantity, sale.unitPrice);
      }
    } catch (e) {
      if (kDebugMode) {
        print('GameState: erreur lors du tick de marché: $e');
      }
    }
    notifyListeners();
  }

  // Prépare une structure de données minimale pour la persistance legacy
  Map<String, dynamic> prepareGameData() {
    return {
      'playerManager': _playerManager.toJson(),
      'marketManager': _marketManager.toJson(),
      'levelSystem': _levelSystem.toJson(),
      // MissionSystem (Option A — mise en pause): persistance conservée volontairement.
      'missionSystem': _missionSystem.toJson(),
      'statistics': _statistics.toJson(),
      'totalTimePlayedInSeconds': _totalTimePlayedInSeconds,
      'totalPaperclipsProduced': _totalPaperclipsProduced,
      'gameMode': _gameMode.index,
      if (_competitiveStartTime != null)
        'competitiveStartTime': _competitiveStartTime!.toIso8601String(),
    };
  }

  // Réinitialisation simple de l'état de jeu
  void reset() {
    _totalTimePlayedInSeconds = 0;
    _totalPaperclipsProduced = 0;
    _statistics.setTotalGameTimeSec(0);
    _lastSaveTime = null;
    _isPaused = false;
  }

  // Alias supplémentaires pour compatibilité avec l'ancien code UI
  PlayerManager get player => _playerManager;
  MarketManager get market => _marketManager;
  LevelSystem get level => _levelSystem;

  // Représentation formatée du temps de jeu total
  String get formattedPlayTime {
    final int hours = totalTimePlayedInSeconds ~/ 3600;
    final int minutes = (totalTimePlayedInSeconds % 3600) ~/ 60;
    final int seconds = totalTimePlayedInSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  int calculateCompetitiveScore() {
    // Les trombones sont stockés en double dans le PlayerManager, mais
    // on les ramène ici à un entier pour le score compétitif.
    final int paperclips = _playerManager.paperclips.round();
    final double money = _playerManager.money;
    final int level = _levelSystem.currentLevel;
    final Duration playTime = competitivePlayTime;

    final int timeSeconds = playTime.inSeconds;
    final double efficiency = timeSeconds > 0
        ? paperclips / timeSeconds
        : paperclips.toDouble();

    final double score =
        paperclips.toDouble() + money + level * 100 + efficiency * 50;
    return score.round();
  }

  void handleCompetitiveGameEnd() {
    if (_gameMode != GameMode.COMPETITIVE) {
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null) {
      return;
    }

    final int score = calculateCompetitiveScore();

    final Duration playTime = competitivePlayTime;
    final int paperclips = _playerManager.paperclips.round();
    final double money = _playerManager.money;
    final int level = _levelSystem.currentLevel;
    final int timeSeconds = playTime.inSeconds == 0 ? 1 : playTime.inSeconds;
    final double efficiency = paperclips / timeSeconds;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompetitiveResultScreen(
          score: score,
          paperclips: paperclips,
          money: money,
          playTime: playTime,
          level: level,
          efficiency: efficiency,
          onNewGame: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const MainScreen(),
              ),
            );
          },
          onShowLeaderboard: () {},
        ),
      ),
    );
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
    final success = _productionManager.buyAutoclipperOfficial();
    if (success) {
      saveOnImportantEvent();
      notifyListeners();
    }
  }

  void producePaperclip() {
    // Flux officiel : délègue à ProductionManager.
    // La mise à jour des stats/XP/leaderboard est centralisée côté ProductionManager.
    final before = _statistics.totalPaperclipsProduced;
    _productionManager.producePaperclip();

    // Compatibilité temporaire : conserver le compteur GameState en miroir des statistiques.
    final after = _statistics.totalPaperclipsProduced;
    if (after != before) {
      _totalPaperclipsProduced = after;
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

      // Charger l'état du son pour cette partie si un contexte est disponible
      // (en tests unitaires, navigatorKey.currentContext peut être null)
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        final backgroundMusicService = Provider.of<BackgroundMusicService>(ctx, listen: false);
        await backgroundMusicService.loadGameMusicState(name);
      }

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
    _statistics.setTotalGameTimeSec(0);
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
      await GamePersistenceOrchestrator.instance.loadGame(this, name);
      return;
    } catch (e, stackTrace) {
      print('Erreur lors du chargement de la partie: $e');
      print(stackTrace);
      throw SaveError('LOAD_ERROR', 'Impossible de charger la partie: $e');
    }
  }

  void applyLoadedGameDataWithoutSnapshot(String name, Map<String, dynamic> gameData) {
    print('Arrêt temporaire de l\'auto-sauvegarde avant chargement');
    _autoSaveService.stop();

    _resetGameDataOnly();

    _gameName = name;

    _gameMode = gameData.containsKey('gameMode')
        ? GameMode.values[gameData['gameMode'] as int]
        : GameMode.INFINITE;

    if (gameData.containsKey('competitiveStartTime')) {
      final startTimeStr = gameData['competitiveStartTime'];
      if (startTimeStr != null) {
        _competitiveStartTime = DateTime.parse(startTimeStr as String);
      }
    }

    if (gameData.containsKey('playerManager')) {
      _playerManager.fromJson(gameData['playerManager'] as Map<String, dynamic>);
    } else if (gameData.containsKey('player')) {
      _playerManager.fromJson(gameData['player'] as Map<String, dynamic>);
    }

    if (gameData.containsKey('resourceManager')) {
      _resourceManager.fromJson(gameData['resourceManager'] as Map<String, dynamic>);
    } else if (gameData.containsKey('resources')) {
      _resourceManager.fromJson(gameData['resources'] as Map<String, dynamic>);
    }

    if (gameData.containsKey('marketManager')) {
      _marketManager.fromJson(gameData['marketManager'] as Map<String, dynamic>);
    } else if (gameData.containsKey('market')) {
      _marketManager.fromJson(gameData['market'] as Map<String, dynamic>);
    }

    if (gameData.containsKey('levelSystem')) {
      _levelSystem.fromJson(gameData['levelSystem'] as Map<String, dynamic>);
    } else if (gameData.containsKey('level')) {
      _levelSystem.fromJson(gameData['level'] as Map<String, dynamic>);
    }

    if (gameData.containsKey('missionSystem')) {
      _missionSystem.fromJson(gameData['missionSystem'] as Map<String, dynamic>);
    } else if (gameData.containsKey('missions')) {
      _missionSystem.fromJson(gameData['missions'] as Map<String, dynamic>);
    }

    if (gameData.containsKey('statistics')) {
      _statistics.fromJson(gameData['statistics'] as Map<String, dynamic>);
    }
  }

  Future<void> finishLoadGameAfterSnapshot(String name, Map<String, dynamic> gameData) async {
    if (gameData.containsKey('progression')) {
      final progressionData = gameData['progression'] as Map<String, dynamic>;
      if (progressionData.containsKey('combos')) {
        final comboData = progressionData['combos'] as Map<String, dynamic>;
        if (_levelSystem.comboSystem != null) {
          _levelSystem.comboSystem!.currentCombo =
              (comboData['currentCombo'] as num).toInt();
          if (comboData.containsKey('comboMultiplier')) {
            _levelSystem.comboSystem!.comboMultiplier =
                (comboData['comboMultiplier'] as num).toDouble();
          }
        }
      }
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
      }
    }

    if (gameData.containsKey('totalPaperclipsProduced')) {
      _totalPaperclipsProduced = (gameData['totalPaperclipsProduced'] as num).toInt();
    }

    if (gameData.containsKey('totalTimePlayedInSeconds')) {
      final loadedTime = (gameData['totalTimePlayedInSeconds'] as num?)?.toInt();
      if (loadedTime != null) {
        _totalTimePlayedInSeconds = loadedTime;
        _statistics.setTotalGameTimeSec(loadedTime);
      } else {
        _totalTimePlayedInSeconds = _statistics.totalGameTimeSec;
      }
    }

    if (gameData.containsKey('crisisMode')) {
      _handleCrisisModeData(gameData['crisisMode'] as Map<String, dynamic>);
    }

    if (gameData.containsKey('timers')) {
      final timersData = gameData['timers'] as Map<String, dynamic>;
      DateTime? lastSaveTime;
      if (timersData.containsKey('lastSaved')) {
        lastSaveTime = DateTime.tryParse(timersData['lastSaved'] as String);
      }

      if (timersData.containsKey('missionRefresh') && lastSaveTime != null) {
        final missionData = timersData['missionRefresh'] as Map<String, dynamic>;
        if (missionData['isActive'] as bool && _missionSystem != null) {
          if (missionData.containsKey('lastRefreshTime')) {
            _missionSystem!.lastMissionRefreshTime =
                DateTime.parse(missionData['lastRefreshTime'] as String);
          }
        }
      }

      if (timersData.containsKey('maintenance') && lastSaveTime != null) {
        final maintenanceData = timersData['maintenance'] as Map<String, dynamic>;
        if (maintenanceData['isActive'] as bool) {
          if (maintenanceData.containsKey('lastMaintenanceTime')) {
            _playerManager.lastMaintenanceTime =
                DateTime.parse(maintenanceData['lastMaintenanceTime'] as String);
          }
        }
      }

      if (timersData.containsKey('metalPriceUpdate') && lastSaveTime != null) {
        final metalData = timersData['metalPriceUpdate'] as Map<String, dynamic>;
        if (metalData.containsKey('lastUpdate')) {
          _marketManager.lastMetalPriceUpdateTime =
              DateTime.parse(metalData['lastUpdate'] as String);
        }
      }
    }

    _applyUpgradeEffects();

    if (navigatorKey.currentContext != null) {
      final backgroundMusicService = Provider.of<BackgroundMusicService>(
          navigatorKey.currentContext!,
          listen: false);
      await backgroundMusicService.loadGameMusicState(name);
    }

    _autoSaveService.restart();

    notifyListeners();

    EventManager.instance.addEvent(
      EventType.INFO,
      'Partie chargée',
      description: 'Nom: $name',
      importance: EventImportance.LOW,
    );
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

  /// Crée un snapshot sérialisable de l'état courant du jeu
  GameSnapshot toSnapshot() {
    final metadata = <String, dynamic>{
      'gameId': _gameName,
      'gameMode': _gameMode.toString(),
      'savedAt': DateTime.now().toIso8601String(),
      'gameVersion': GameConstants.VERSION,
      'totalTimePlayedInSeconds': totalTimePlayedInSeconds,
      'totalPaperclipsProduced': _totalPaperclipsProduced,
    };

    final core = <String, dynamic>{
      'player': {
        'money': _playerManager.money,
        'paperclips': _playerManager.paperclips,
        'metal': _playerManager.metal,
      },
      'game': {
        'gameName': _gameName,
        'gameMode': _gameMode.toString(),
      },
    };

    final stats = _statistics.toJson();

    return GameSnapshot(
      metadata: metadata,
      core: core,
      stats: stats,
    );
  }

  /// Applique un GameSnapshot sur l'état courant du jeu
  void applySnapshot(GameSnapshot snapshot) {
    final metadata = snapshot.metadata;
    final core = snapshot.core;

    _gameName = metadata['gameId'] as String? ?? _gameName;

    final modeString = metadata['gameMode'] as String?;
    if (modeString != null) {
      if (modeString.contains('COMPETITIVE')) {
        _gameMode = GameMode.COMPETITIVE;
      } else {
        _gameMode = GameMode.INFINITE;
      }
    }

    _totalTimePlayedInSeconds =
        (metadata['totalTimePlayedInSeconds'] as num?)?.toInt() ?? _totalTimePlayedInSeconds;
    _totalPaperclipsProduced =
        (metadata['totalPaperclipsProduced'] as num?)?.toInt() ?? _totalPaperclipsProduced;

    final playerCore = core['player'];
    if (playerCore is Map) {
      final playerMap = Map<String, dynamic>.from(playerCore as Map);
      final money = (playerMap['money'] as num?)?.toDouble();
      final paperclips = (playerMap['paperclips'] as num?)?.toDouble();
      final metal = (playerMap['metal'] as num?)?.toDouble();

      if (money != null) {
        _playerManager.updateMoney(money);
      }
      if (paperclips != null) {
        _playerManager.updatePaperclips(paperclips);
      }
      if (metal != null) {
        _playerManager.updateMetal(metal);
      }
    }

    final statsCore = snapshot.stats;
    if (statsCore != null) {
      _statistics.loadFromJson(statsCore);
    }

    notifyListeners();
  }

  void _loadGameData(Map<String, dynamic> gameData) {
    if (gameData['playerManager'] != null) {
      _playerManager.fromJson(gameData['playerManager']);
    }
    if (gameData['marketManager'] != null) {
      _marketManager.fromJson(gameData['marketManager']);
    }
    if (gameData['levelSystem'] != null) {
      _levelSystem.fromJson(gameData['levelSystem']);
    }
    if (gameData['missionSystem'] != null) {
      _missionSystem.fromJson(gameData['missionSystem']);
    }
    if (gameData['statistics'] != null) {
      _statistics.fromJson(gameData['statistics']);
    }

    final loadedTime = (gameData['totalTimePlayedInSeconds'] as num?)?.toInt();
    if (loadedTime != null) {
      _totalTimePlayedInSeconds = loadedTime;
      _statistics.setTotalGameTimeSec(loadedTime);
    } else {
      _totalTimePlayedInSeconds = _statistics.totalGameTimeSec;
    }
    _totalPaperclipsProduced =
        (gameData['totalPaperclipsProduced'] as num?)?.toInt() ?? 0;
  }

  Future<void> saveGame(String name) async {
    try {
      await GamePersistenceOrchestrator.instance.saveGame(this, name);
      _gameName = name;
      _lastSaveTime = DateTime.now();
      notifyListeners();
    } catch (e) {
      print('Erreur dans GameState.saveGame: $e');
    }
  }

  Future<void> saveOnImportantEvent() async {
    try {
      await GamePersistenceOrchestrator.instance.saveOnImportantEvent(this);
    } catch (e) {
      print('Erreur lors de la sauvegarde événementielle: $e');
    }
  }

  Map<String, bool> getVisibleScreenElements() {
    final lvl = _levelSystem.level;
    return {
      'metalStock': true,
      'paperclipStock': true,
      'manualProductionButton': true,
      'moneyDisplay': true,

      'market': lvl >= GameConstants.MARKET_UNLOCK_LEVEL,
      'marketPrice': lvl >= GameConstants.MARKET_UNLOCK_LEVEL,
      'sellButton': lvl >= GameConstants.MARKET_UNLOCK_LEVEL,
      'marketStats': lvl >= GameConstants.MARKET_UNLOCK_LEVEL,
      'priceChart': lvl >= GameConstants.MARKET_UNLOCK_LEVEL,

      'metalPurchaseButton': lvl >= 1,
      'autoclippersSection': lvl >= 3,
      'productionStats': lvl >= 2,
      'efficiencyDisplay': lvl >= 3,

      'upgradesSection': lvl >= GameConstants.UPGRADES_UNLOCK_LEVEL,
      'upgradesScreen': lvl >= GameConstants.UPGRADES_UNLOCK_LEVEL,

      'levelDisplay': true,
      'experienceBar': true,
      'comboDisplay': lvl >= 2,

      'statsSection': lvl >= 4,
      'achievementsSection': lvl >= 5,

      'settingsButton': true,
      'musicToggle': true,
      'notificationButton': true,
      'saveLoadButtons': true,
    };
  }

  bool purchaseUpgrade(String upgradeId) {
    if (!_playerManager.canAffordUpgrade(upgradeId)) return false;

    final upgrade = _playerManager.upgrades[upgradeId];
    if (upgrade == null) return false;

    final double cost = upgrade.getCost();
    final bool success = _playerManager.purchaseUpgrade(upgradeId);

    if (success) {
      _applyUpgradeEffects();
      _levelSystem.addUpgradePurchase(upgrade.level);
      _statistics.updateProgression(upgradesBought: 1);
      _statistics.updateEconomics(moneySpent: cost);
      saveOnImportantEvent();
    }

    return success;
  }

  Future<void> checkAndRestoreFromBackup() async {
    await GamePersistenceOrchestrator.instance.checkAndRestoreFromBackup(this);
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
    if (!_isInCrisisMode || !_crisisTransitionComplete) return;

    _showingCrisisView = !_showingCrisisView;
    EventManager.instance.addInterfaceTransitionEvent(_showingCrisisView);
    notifyListeners();
  }

  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void checkMilestones() {
    if (_levelSystem.level % 5 == 0) {
      activateXPBoost();
    }
  }

  void activateXPBoost() {
    _levelSystem.applyXPBoost(2.0, const Duration(minutes: 5));
    EventManager.instance.addEvent(
      EventType.XP_BOOST,
      'Bonus XP activé !',
      description: 'x2 XP pendant 5 minutes',
      importance: EventImportance.MEDIUM,
    );
  }

  @override
  void dispose() {
    _autoSaveService.dispose();
    _playerManager.dispose();
    _productionManager.dispose();
    _levelSystem.dispose();
    super.dispose();
  }
}