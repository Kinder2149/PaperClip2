// lib/models/game_state.dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/runtime/domain_ports.dart';
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
import '../services/offline_progress_service.dart';
import '../services/competitive/competitive_result_service.dart';
import '../ui/utils/ui_formatting_utils.dart';
import '../services/progression/progression_rules_service.dart';
import '../services/upgrades/upgrade_effects_calculator.dart';
import '../services/persistence/game_persistence_mapper.dart';
import '../services/pricing/pricing_advice_service.dart';
import '../gameplay/game_engine.dart';
import '../gameplay/events/bus/game_event_bus.dart';
import '../gameplay/events/game_event.dart';
import '../services/runtime/clock.dart';

class GameState extends ChangeNotifier implements DomainPorts {
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

  // Ports UI/Navigation retirés du domaine (découplage via GameEventBus)

  // État global
  bool _isInCrisisMode = false;
  bool _crisisTransitionComplete = false;
  bool _showingCrisisView = false;
  DateTime? _crisisStartTime;

  // Mode de jeu (infini ou compétitif)
  GameMode _gameMode = GameMode.INFINITE;
  DateTime? _competitiveStartTime;

  bool _isInitialized = false;
  Object? _initializationError;
  StackTrace? _initializationStackTrace;
  String? _gameName;
  String? _partieId; // ID technique unique (UUID v4)

  // Suivi interne du temps de jeu et des compteurs globaux
  DateTime? _lastSaveTime;
  DateTime? _lastActiveAt;
  DateTime? _lastOfflineAppliedAt;
  String? _offlineSpecVersion;
  bool _isPaused = false;
  String _storageMode = 'local'; // 'local' | 'cloud'

  void markLastSaveTime(DateTime value) {
    _lastSaveTime = value;
  }

  // Défini explicitement l'identifiant technique de la partie (utilisé lors du chargement)
  void setPartieId(String id) {
    _partieId = id;
  }

  void markLastActiveAt(DateTime value) {
    _lastActiveAt = value;
  }

  void markLastOfflineAppliedAt(DateTime value) {
    _lastOfflineAppliedAt = value;
  }

  void markOfflineSpecVersion(String value) {
    _offlineSpecVersion = value;
  }

  void applyOfflineProgressV2({DateTime? nowOverride}) {
    if (!_isInitialized || isPaused) return;
    // PR3: déporté vers GameRuntimeCoordinator via événement
    _eventBus.emit(
      GameEvent(
        type: GameEventType.importantEventOccurred,
        source: 'GameState',
        severity: GameEventSeverity.info,
        data: {
          'reason': 'offline_progress_request',
          if (nowOverride != null) 'nowOverride': nowOverride.toIso8601String(),
        },
      ),
    );
  }

  // Getters complémentaires utilisés par l'UI
  DateTime? get lastSaveTime => _lastSaveTime;

  int get totalTimePlayed => _statistics.totalGameTimeSec;
  int get totalPaperclipsProduced => _statistics.totalPaperclipsProduced;
  double get maintenanceCosts => 0.0; // La maintenance est désactivée pour le moment.
  ResourceManager get resources => _resourceManager;
  AutoSaveService get autoSaveService => _autoSaveService;

  // Accès lecture aux métadonnées offline (pour Coordinator)
  DateTime? get lastActiveAt => _lastActiveAt;
  DateTime? get lastOfflineAppliedAt => _lastOfflineAppliedAt;
  String? get offlineSpecVersion => _offlineSpecVersion;

  // Getters publics
  StatisticsManager get statistics => _statistics;
  bool get isInCrisisMode => _isInCrisisMode;
  bool get crisisTransitionComplete => _crisisTransitionComplete;
  bool get showingCrisisView => _showingCrisisView;
  DateTime? get crisisStartTime => _crisisStartTime;
  bool get isInitialized => _isInitialized;
  Object? get initializationError => _initializationError;
  StackTrace? get initializationStackTrace => _initializationStackTrace;
  String? get gameName => _gameName;
  String? get partieId => _partieId;
  String get storageMode => _storageMode;
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
    return _clock.now().difference(_competitiveStartTime!);
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

  // Méthodes de ports UI retirées; la présentation s'abonne désormais au bus d'événements

  // Audio déporté hors du domaine (Coordinator/AudioFacade)

  // Abstraction évènementielle (exposée pour le Coordinator)
  void addEventListener(GameEventListener listener) => _eventBus.addListener(listener);
  void removeEventListener(GameEventListener listener) => _eventBus.removeListener(listener);

  bool canBuyMetal() => _resourceManager.canPurchaseMetal();

  // Alias de compatibilité pour les écrans qui appellent gameState.purchaseMetal()
  bool purchaseMetal() {
    // Appliquer la remise d'achat métal selon l'upgrade 'procurement'
    final procurementLevel = _playerManager.upgrades['procurement']?.level ?? 0;
    final unitPrice = _marketManager.marketMetalPrice;
    double? discountedUnitPrice;
    if (procurementLevel > 0) {
      final discount = UpgradeEffectsCalculator.metalDiscount(level: procurementLevel);
      discountedUnitPrice = unitPrice * (1.0 - discount);
    }

    final success = _resourceManager.purchaseMetal(discountedUnitPrice);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  final Clock _clock;

  GameState({Clock? clock}) : _clock = clock ?? SystemClock() {
    _initializeManagers();
    _lastActiveAt = _clock.now();
  }

  // Méthode de compatibilité pour les tests qui appellent initialize()
  void initialize() {
    _initializeManagers();
  }

  void _initializeManagers() {
    if (_isInitialized) {
      return;
    }

    _initializationError = null;
    _initializationStackTrace = null;

    try {
      if (kDebugMode) {
        print('GameState: Début de l\'initialisation des managers');
      }

      _createManagers();

      if (kDebugMode) {
        print('GameState: Managers créés avec succès');
      }

      _isInitialized = true;
      if (kDebugMode) {
        print('GameState: Initialisation terminée avec succès');
      }
    } catch (e, st) {
      _initializationError = e;
      _initializationStackTrace = st;
      if (kDebugMode) {
        print('GameState: ERREUR CRITIQUE lors de l\'initialisation: $e');
        print(st);
      }
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

  @override
  void applyTick(double elapsedSeconds) {
    tick(elapsedSeconds: elapsedSeconds);
  }

  OfflineProgressResult applyOfflineWithService({
    required DateTime now,
    DateTime? lastActiveAt,
    DateTime? lastOfflineAppliedAt,
  }) {
    return OfflineProgressService.apply(
      engine: _engine,
      autoSellEnabled: autoSellEnabled,
      lastActiveAt: lastActiveAt,
      lastOfflineAppliedAt: lastOfflineAppliedAt,
      nowOverride: now,
    );
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
    return GamePersistenceMapper.prepareGameData(
      playerManager: _playerManager,
      marketManager: _marketManager,
      levelSystem: _levelSystem,
      missionSystem: _missionSystem,
      statistics: _statistics,
      gameMode: _gameMode,
      competitiveStartTime: _competitiveStartTime,
    );
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
    return UiFormattingUtils.formatDurationHms(
      Duration(seconds: _statistics.totalGameTimeSec),
    );
  }

  int calculateCompetitiveScore() {
    final data = CompetitiveResultService.compute(
      paperclips: _playerManager.paperclips.round(),
      money: _playerManager.money,
      level: _levelSystem.currentLevel,
      playTime: competitivePlayTime,
    );
    return data.score;
  }

  void handleCompetitiveGameEnd() {
    if (_gameMode != GameMode.COMPETITIVE) {
      return;
    }

    final data = CompetitiveResultService.compute(
      paperclips: _playerManager.paperclips.round(),
      money: _playerManager.money,
      level: _levelSystem.currentLevel,
      playTime: competitivePlayTime,
    );
    // Émet un événement UI (navigation) au lieu d'appeler directement la façade Flutter
    _eventBus.emit(
      GameEvent(
        type: GameEventType.importantEventOccurred,
        source: 'GameState',
        severity: GameEventSeverity.info,
        data: {
          'reason': 'ui_show_competitive_result',
          'score': data.score,
          'paperclips': data.paperclips,
          'money': data.money,
          'level': data.level,
          'playTimeSeconds': data.playTime.inSeconds,
          'efficiency': data.efficiency,
        },
      ),
    );
  }

  void buyAutoclipper() {
    final success = _engine.buyAutoclipper();
    if (success) {
      // Émettre un évènement dédié; l'autosave sera déclenchée côté runtime (post-frame + coalescing)
      _eventBus.emit(
        GameEvent(
          type: GameEventType.autoclipperPurchased,
          source: 'GameState',
          severity: GameEventSeverity.info,
          data: <String, Object?>{
            'autoclippers': _playerManager.autoClipperCount,
          },
        ),
      );
      notifyListeners();
    }
  }

  void addMetal(double amount) {
    if (amount <= 0) {
      return;
    }
    player.updateMetal(player.metal + amount);
    notifyListeners();
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
    PricingAdviceService.handleSetSellPrice(
      market: market,
      newPrice: newPrice,
      onAccept: () {
        player.setSellPrice(newPrice);
        notifyListeners();
      },
      onWarning: ({required String title, required String description, String? detailedDescription}) {
        // Événement pour UI adapter (au lieu d'un appel direct au port UI)
        _eventBus.emit(
          GameEvent(
            type: GameEventType.importantEventOccurred,
            source: 'GameState',
            severity: GameEventSeverity.warning,
            data: {
              'reason': 'ui_price_excessive_warning',
              'title': title,
              'description': description,
              if (detailedDescription != null) 'detailedDescription': detailedDescription,
            },
          ),
        );
      },
    );
  }

  Future<void> startNewGame(String name, {GameMode mode = GameMode.INFINITE}) async {
    try {
      _gameName = name;
      // Générer un identifiant unique de partie s'il n'existe pas encore (ID-first)
      _partieId ??= const Uuid().v4();
      // Réinitialiser l'état de jeu
      reset();

      _gameMode = mode;

      // Définir le mode de jeu et le temps de début pour le mode compétitif
      if (mode == GameMode.COMPETITIVE) {
        _competitiveStartTime = _clock.now();
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

    _gameMode = GamePersistenceMapper.applyLoadedGameDataWithoutSnapshot(
      playerManager: _playerManager,
      resourceManager: _resourceManager,
      marketManager: _marketManager,
      levelSystem: _levelSystem,
      missionSystem: _missionSystem,
      statistics: _statistics,
      gameData: gameData,
    );
  }

  Future<void> finishLoadGameAfterSnapshot(String name, Map<String, dynamic> gameData) async {
    await GamePersistenceMapper.finishLoadGameAfterSnapshot(
      levelSystem: _levelSystem,
      statistics: _statistics,
      gameData: gameData,
      onCrisisMode: (crisisData) => _handleCrisisModeData(crisisData),
    );

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

  void setStorageMode(String mode) {
    if (mode != 'local' && mode != 'cloud') return;
    _storageMode = mode;
    notifyListeners();
  }

  void showProductionLeaderboard() async {
    // Émet un événement pour la façade UI
    _eventBus.emit(
      GameEvent(
        type: GameEventType.importantEventOccurred,
        source: 'GameState',
        severity: GameEventSeverity.info,
        data: {
          'reason': 'ui_show_production_leaderboard',
        },
      ),
    );
  }

  void showBankerLeaderboard() async {
    _eventBus.emit(
      GameEvent(
        type: GameEventType.importantEventOccurred,
        source: 'GameState',
        severity: GameEventSeverity.info,
        data: {
          'reason': 'ui_show_banker_leaderboard',
        },
      ),
    );
  }

  void showLeaderboard() {
    _eventBus.emit(
      GameEvent(
        type: GameEventType.importantEventOccurred,
        source: 'GameState',
        severity: GameEventSeverity.info,
        data: {
          'reason': 'ui_show_leaderboard',
        },
      ),
    );
  }

  void showAchievements() {
    _eventBus.emit(
      GameEvent(
        type: GameEventType.importantEventOccurred,
        source: 'GameState',
        severity: GameEventSeverity.info,
        data: {
          'reason': 'ui_show_achievements',
        },
      ),
    );
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
    final now = _clock.now();
    final metadata = <String, dynamic>{
      'schemaVersion': 1,
      'snapshotSchemaVersion': 1,
      'gameId': _gameName,
      'partieId': _partieId,
      'gameMode': _gameMode.toString(),
      'storageMode': _storageMode,
      'savedAt': now.toIso8601String(),
      'lastActiveAt': (_lastActiveAt ?? now).toIso8601String(),
      if (_lastOfflineAppliedAt != null)
        'lastOfflineAppliedAt': _lastOfflineAppliedAt!.toIso8601String(),
      if (_offlineSpecVersion != null) 'offlineSpecVersion': _offlineSpecVersion,
      'gameVersion': GameConstants.VERSION,
      'appVersion': GameConstants.VERSION,
      'saveFormatVersion': GameConstants.CURRENT_SAVE_FORMAT_VERSION,
    };

    final core = <String, dynamic>{
      'playerManager': _playerManager.toJson(),
      'marketManager': _marketManager.toJson(),
      'resourceManager': _resourceManager.toJson(),
      'levelSystem': _levelSystem.toJson(),
      'missionSystem': _missionSystem.toJson(),
      'productionManager': _productionManager.toJson(),
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

    final lastActiveRaw = metadata['lastActiveAt'] as String?;
    _lastActiveAt = lastActiveRaw != null ? DateTime.tryParse(lastActiveRaw) : _lastActiveAt;

    final lastOfflineAppliedRaw = metadata['lastOfflineAppliedAt'] as String?;
    _lastOfflineAppliedAt = lastOfflineAppliedRaw != null
        ? DateTime.tryParse(lastOfflineAppliedRaw)
        : _lastOfflineAppliedAt;

    _offlineSpecVersion = metadata['offlineSpecVersion'] as String? ?? _offlineSpecVersion;

    final metaName = metadata['gameId'] as String?;
    if (_gameName == null && metaName != null && metaName.isNotEmpty) {
      _gameName = metaName;
    }

    // ID technique (UUID) si présent dans les métadonnées du snapshot
    final metaPartieId = metadata['partieId'] as String?;
    if (_partieId == null && metaPartieId != null && metaPartieId.isNotEmpty) {
      _partieId = metaPartieId;
    }

    final modeString = metadata['gameMode'] as String?;
    if (modeString != null) {
      if (modeString.contains('COMPETITIVE')) {
        _gameMode = GameMode.COMPETITIVE;
      } else {
        _gameMode = GameMode.INFINITE;
      }
    }

    if (core['playerManager'] is Map) {
      _playerManager.fromJson(Map<String, dynamic>.from(core['playerManager'] as Map));
    }

    if (core['marketManager'] is Map) {
      _marketManager.fromJson(Map<String, dynamic>.from(core['marketManager'] as Map));
    }

    if (core['resourceManager'] is Map) {
      _resourceManager.fromJson(Map<String, dynamic>.from(core['resourceManager'] as Map));
    }

    if (core['levelSystem'] is Map) {
      _levelSystem.fromJson(Map<String, dynamic>.from(core['levelSystem'] as Map));
    }

    if (core['missionSystem'] is Map) {
      _missionSystem.fromJson(Map<String, dynamic>.from(core['missionSystem'] as Map));
    }

    if (core['productionManager'] is Map) {
      _productionManager.fromJson(Map<String, dynamic>.from(core['productionManager'] as Map));
    }

    final statsCore = snapshot.stats;
    if (statsCore != null) {
      _statistics.loadFromJson(statsCore);
    }

    notifyListeners();
  }

  void _loadGameData(Map<String, dynamic> gameData) {
    GamePersistenceMapper.loadGameData(
      playerManager: _playerManager,
      marketManager: _marketManager,
      levelSystem: _levelSystem,
      missionSystem: _missionSystem,
      statistics: _statistics,
      gameData: gameData,
    );
  }

  Future<void> saveOnImportantEvent() async {
    try {
      // Émission d'un événement pour orchestration externe (autosave, télémétrie, etc.)
      _eventBus.emit(
        GameEvent(
          type: GameEventType.importantEventOccurred,
          source: 'GameState',
          severity: GameEventSeverity.info,
          data: {
            'reason': 'game_state_saveOnImportantEvent',
          },
        ),
      );
    } catch (e) {
      print('Erreur lors de la sauvegarde événementielle: $e');
    }
  }

  Map<String, bool> getVisibleScreenElements() {
    return _progressionRules.getVisibleScreenElements(_levelSystem.level);
  }

  VisibleUiElements getVisibleUiElements() {
    return _progressionRules.getVisibleUiElements(_levelSystem.level);
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
    // Événement pour la façade UI
    _eventBus.emit(
      GameEvent(
        type: GameEventType.importantEventOccurred,
        source: 'GameState',
        severity: GameEventSeverity.info,
        data: {
          'reason': 'ui_unlock_notification',
          'message': message,
        },
      ),
    );
  }

  void toggleCrisisInterface() {
    if (!_isInCrisisMode || !_crisisTransitionComplete) return;

    _showingCrisisView = !_showingCrisisView;
    notifyListeners();
  }

  // Contrôle explicite de la pause par le runtime
  void pause() {
    if (_isPaused) return;
    _isPaused = true;
    notifyListeners();
  }

  void resume() {
    if (!_isPaused) return;
    _isPaused = false;
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