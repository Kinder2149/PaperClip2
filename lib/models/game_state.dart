// lib/models/game_state.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/persistence/game_snapshot.dart';
import '../services/persistence/game_persistence_orchestrator.dart';
import '../constants/game_config.dart';
import '../managers/player_manager.dart';
import '../managers/market_manager.dart';
import 'progression_system.dart';
import '../managers/resource_manager.dart';
import '../managers/production_manager.dart';

import 'game_state_interfaces.dart';
import 'statistics_manager.dart';
import '../models/upgrade.dart';

import 'dart:convert';
import '../services/auto_save_service.dart';
import '../services/save_game.dart';
import '../services/ui/game_ui_port.dart';
import '../services/audio/game_audio_port.dart';
import '../services/progression/progression_rules_service.dart';
import '../services/upgrades/upgrade_effects_calculator.dart';
import '../gameplay/game_engine.dart';
import '../gameplay/events/bus/game_event_bus.dart';

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
  late final ProgressionRulesService _progressionRules;
  late final GameEngine _engine;
  late final GameEventBus _eventBus;

  // Services auxiliaires
  late final AutoSaveService _autoSaveService;

  // Ports (UI/runtime Flutter) — injectés depuis l'application (hors GameState)
  GameNotificationPort? _notificationPort;
  GameNavigationPort? _navigationPort;
  GameAudioPort? _audioPort;

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

  // Suivi interne du temps de jeu et des compteurs globaux
  DateTime _lastUpdateTime = DateTime.now();
  DateTime? _lastSaveTime;
  bool _isPaused = false;

  void markLastSaveTime(DateTime value) {
    _lastSaveTime = value;
  }

  // Getters complémentaires utilisés par l'UI
  DateTime? get lastSaveTime => _lastSaveTime;
  int get totalTimePlayed => _statistics.totalGameTimeSec;
  int get totalPaperclipsProduced => _statistics.totalPaperclipsProduced;
  double get maintenanceCosts => 0.0; // La maintenance est désactivée pour le moment.
  ResourceManager get resources => _resourceManager;
  AutoSaveService get autoSaveService => _autoSaveService;

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
  int get totalTimePlayedInSeconds => _statistics.totalGameTimeSec;
  bool get isCrisisTransitionComplete => _crisisTransitionComplete;
  String? get gameId => _gameName;
  double get autocliperCost => _playerManager.autoClipperCost;

  bool get autoSellEnabled => _marketManager.autoSellEnabled;

  void setAutoSellEnabled(bool value) {
    _marketManager.autoSellEnabled = value;
    notifyListeners();
  }

  void setUiPort(GameUiPort port) {
    _notificationPort = port;
    _navigationPort = port;
  }

  void setNotificationPort(GameNotificationPort port) {
    _notificationPort = port;
  }

  void setNavigationPort(GameNavigationPort port) {
    _navigationPort = port;
  }

  void setAudioPort(GameAudioPort port) {
    _audioPort = port;
  }

  bool canBuyMetal() => _resourceManager.canPurchaseMetal();

  // Alias de compatibilité pour les écrans qui appellent gameState.purchaseMetal()
  bool purchaseMetal() {
    final success = _resourceManager.purchaseMetal();
    if (success) {
      notifyListeners();
    }
    return success;
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

      _progressionRules = ProgressionRulesService(
        levelSystem: _levelSystem,
        playerManager: _playerManager,
      );

      _levelSystem.onLevelUp = (level, newFeatures) {
        _progressionRules.handleLevelUp(
          newLevel: level,
          newFeatures: newFeatures,
          notifyUnlock: (message) {
            _showUnlockNotification(message);
          },
          saveOnImportantEvent: () async {
            await saveOnImportantEvent();
          },
        );
      };

      _levelSystem.onPathChoiceRequired = (level, options) {
        _showUnlockNotification('Choix de chemin de progression disponible !');
      };

      // Manager de production basé sur les managers cœur de jeu
      _productionManager = ProductionManager(
        playerManager: _playerManager,
        statistics: _statistics,
        levelSystem: _levelSystem,
      );

      _eventBus = GameEventBus();
      _eventBus.addListener(_statistics.onGameEvent);
      _eventBus.addListener(_progressionRules.onGameEvent);

      _engine = GameEngine(
        player: _playerManager,
        market: _marketManager,
        production: _productionManager,
        level: _levelSystem,
        statistics: _statistics,
        progressionRules: _progressionRules,
        eventBus: _eventBus,
      );

      // Lier les managers entre eux
      _resourceManager.setPlayerManager(_playerManager);
      _resourceManager.setMarketManager(_marketManager);
      _resourceManager.setStatisticsManager(_statistics);
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
  }

  void tick({required double elapsedSeconds}) {
    if (!_isInitialized || _isPaused) return;
    try {
      _engine.tick(
        elapsedSeconds: elapsedSeconds,
        autoSellEnabled: autoSellEnabled,
      );
    } catch (e) {
      if (kDebugMode) {
        print('GameState: erreur lors du tick unifié: $e');
      }
    }

    notifyListeners();
  }

  /// Tick métier pour le marché.
  ///
  /// Appelé par GameSessionController; aucun Timer n'est géré ici.
  void tickMarket() {
    if (!_isInitialized || _isPaused) return;
    try {
      _engine.tickMarket();
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
      // MissionSystem (Option A — mise en pause):
      // - conservé pour compatibilité/persistance (JSON) et future feature
      // - non initialisé au runtime (pas de timer, pas de callbacks, pas d'événements gameplay)
      'missionSystem': _missionSystem.toJson(),
      'statistics': _statistics.toJson(),
      'gameMode': _gameMode.index,
      if (_competitiveStartTime != null)
        'competitiveStartTime': _competitiveStartTime!.toIso8601String(),
    };
  }

  // Réinitialisation simple de l'état de jeu
  void reset() {
    _resetGameDataOnly();

    _lastSaveTime = null;
    _isPaused = false;
    _gameMode = GameMode.INFINITE;
    _competitiveStartTime = null;
  }

  void _resetGameDataOnly() {
    _playerManager.resetResources();
    _marketManager.reset();
    _resourceManager.resetResources();
    _productionManager.reset();
    _levelSystem.reset();
    _statistics.reset();

    _isInCrisisMode = false;
    _crisisTransitionComplete = false;
    _showingCrisisView = false;
    _crisisStartTime = null;
  }

  // Alias supplémentaires pour compatibilité avec l'ancien code UI
  PlayerManager get player => _playerManager;
  MarketManager get market => _marketManager;
  LevelSystem get level => _levelSystem;

  // Représentation formatée du temps de jeu total
  String get formattedPlayTime {
    final int hours = _statistics.totalGameTimeSec ~/ 3600;
    final int minutes = (_statistics.totalGameTimeSec % 3600) ~/ 60;
    final int seconds = _statistics.totalGameTimeSec % 60;

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

    final int score = calculateCompetitiveScore();

    final Duration playTime = competitivePlayTime;
    final int paperclips = _playerManager.paperclips.round();
    final double money = _playerManager.money;
    final int level = _levelSystem.currentLevel;
    final int timeSeconds = playTime.inSeconds == 0 ? 1 : playTime.inSeconds;
    final double efficiency = paperclips / timeSeconds;

    _navigationPort?.showCompetitiveResult(
      CompetitiveResultData(
        score: score,
        paperclips: paperclips,
        money: money,
        playTime: playTime,
        level: level,
        efficiency: efficiency,
      ),
    );
  }

  void buyAutoclipper() {
    final success = _engine.buyAutoclipper();
    if (success) {
      saveOnImportantEvent();
      notifyListeners();
    }
  }

  void producePaperclip() {
    // Flux officiel : délègue à ProductionManager.
    // La mise à jour des stats/XP/leaderboard est centralisée côté ProductionManager.
    final before = _statistics.totalPaperclipsProduced;
    _engine.producePaperclip();

    // Les compteurs sont maintenant lus depuis StatisticsManager.
    notifyListeners();
  }

  void setSellPrice(double newPrice) {
    if (market.isPriceExcessive(newPrice)) {
      _notificationPort?.showPriceExcessiveWarning(
        title: 'Prix Excessif!',
        description: 'Ce prix pourrait affecter vos ventes',
        detailedDescription: market.getPriceRecommendation(),
      );
    }
    player.updateSellPrice(newPrice);  
    notifyListeners();
  }

  Future<void> startNewGame(String name, {GameMode mode = GameMode.INFINITE}) async {
    try {
      _gameName = name;
      // Réinitialiser l'état de jeu
      reset();

      _gameMode = mode;

      // Définir le mode de jeu et le temps de début pour le mode compétitif
      if (mode == GameMode.COMPETITIVE) {
        _competitiveStartTime = DateTime.now();
      } else {
        _competitiveStartTime = null;
      }

      // IMPORTANT (Mission 2):
      // - La persistance (save initial) et le démarrage autosave sont orchestrés hors de GameState.
      // - GameState ne fait ici que réinitialiser l'état métier.
      notifyListeners();

      print('Nouvelle partie créée: $name, mode: $mode');

      return;
    } catch (e, stackTrace) {
      print('Erreur lors de la création d\'une nouvelle partie: $e');
      print(stackTrace);
      throw SaveError('CREATE_ERROR', 'Impossible de créer une nouvelle partie: $e');
    }
  }

  void applyLoadedGameDataWithoutSnapshot(String name, Map<String, dynamic> gameData) {
    _resetGameDataOnly();

    _gameName = name;

    _gameMode = gameData.containsKey('gameMode')
        ? GameMode.values[gameData['gameMode'] as int]
        : GameMode.INFINITE;

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
      _statistics.setTotalPaperclipsProduced(
        (gameData['totalPaperclipsProduced'] as num).toInt(),
      );
    }

    if (gameData.containsKey('totalTimePlayedInSeconds')) {
      final loadedTime = (gameData['totalTimePlayedInSeconds'] as num?)?.toInt();
      if (loadedTime != null) {
        _statistics.setTotalGameTimeSec(loadedTime);
      } else {
        _statistics.setTotalGameTimeSec(_statistics.totalGameTimeSec);
      }
    }

    if (gameData.containsKey('crisisMode')) {
      _handleCrisisModeData(gameData['crisisMode'] as Map<String, dynamic>);
    }

    _applyUpgradeEffects();

    // IMPORTANT (Mission 2):
    // - Les hooks runtime (audio) et l'orchestration autosave sont hors de GameState.
    // - GameState termine ici uniquement l'application des données.
    notifyListeners();
  }

  void _handleCrisisModeData(Map<String, dynamic> gameData) {
    if (gameData['crisisMode'] != null) {
      final crisisData = gameData['crisisMode'] as Map<String, dynamic>;
      _isInCrisisMode = crisisData['isInCrisisMode'] as bool? ?? false;
      _showingCrisisView = crisisData['showingCrisisView'] as bool? ?? false;
      if (_isInCrisisMode) {
        _crisisTransitionComplete = crisisData['crisisTransitionComplete'] as bool? ?? true;
        if (crisisData.containsKey('crisisStartTime')) {
          _crisisStartTime = DateTime.parse(crisisData['crisisStartTime'] as String);
        }
      }
    }
  }

  void updateLeaderboard() async {
    // No leaderboards in offline version
  }

  void showProductionLeaderboard() async {
    _notificationPort?.showLeaderboardUnavailable(
      'Les classements ne sont pas disponibles dans cette version',
    );
  }

  void showBankerLeaderboard() async {
    _notificationPort?.showLeaderboardUnavailable(
      'Les classements ne sont pas disponibles dans cette version',
    );
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
      double newCapacity = UpgradeEffectsCalculator.metalStorageCapacity(
        storageLevel: storageLevel,
      );
      _playerManager.updateMaxMetalStorage(newCapacity);
    }
  }

  /// Crée un snapshot sérialisable de l'état courant du jeu
  GameSnapshot toSnapshot() {
    final metadata = <String, dynamic>{
      'gameId': _gameName,
      'gameMode': _gameMode.toString(),
      'savedAt': DateTime.now().toIso8601String(),
      'gameVersion': GameConstants.VERSION,
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

    final metaTime = (metadata['totalTimePlayedInSeconds'] as num?)?.toInt();
    if (metaTime != null) {
      _statistics.setTotalGameTimeSec(metaTime);
    }
    final metaProduced = (metadata['totalPaperclipsProduced'] as num?)?.toInt();
    if (metaProduced != null) {
      _statistics.setTotalPaperclipsProduced(metaProduced);
    }

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
      _statistics.setTotalGameTimeSec(loadedTime);
    } else {
      _statistics.setTotalGameTimeSec(_statistics.totalGameTimeSec);
    }
    final loadedProduced = (gameData['totalPaperclipsProduced'] as num?)?.toInt();
    if (loadedProduced != null) {
      _statistics.setTotalPaperclipsProduced(loadedProduced);
    }
  }

  Future<void> saveGame(String name) async {
    try {
      await GamePersistenceOrchestrator.instance.requestManualSave(
        this,
        slotId: name,
        reason: 'game_state_saveGame',
      );
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

  Future<void> loadGame(String name) async {
    await GamePersistenceOrchestrator.instance.loadGame(this, name);
  }

  Map<String, bool> getVisibleScreenElements() {
    return _progressionRules.getVisibleScreenElements(_levelSystem.level);
  }

  void chooseProgressionPath(ProgressionPath path) {
    _engine.chooseProgressionPath(path);
    saveOnImportantEvent();
    notifyListeners();
  }

  bool canPurchaseUpgrade(String upgradeId) {
    return _engine.canPurchaseUpgrade(upgradeId);
  }

  bool purchaseUpgrade(String upgradeId) {
    final success = _engine.purchaseUpgrade(upgradeId);
    if (success) {
      saveOnImportantEvent();
    }
    return success;
  }

  Future<void> checkAndRestoreFromBackup() async {
    await GamePersistenceOrchestrator.instance.checkAndRestoreFromBackup(this);
  }

  void _showUnlockNotification(String message) {
    _notificationPort?.showUnlockNotification(message);
  }

  void toggleCrisisInterface() {
    if (!_isInCrisisMode || !_crisisTransitionComplete) return;

    _showingCrisisView = !_showingCrisisView;
    notifyListeners();
  }

  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
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