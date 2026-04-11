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
import '../managers/rare_resources_manager.dart';
import '../managers/research_manager.dart';
import '../managers/agent_manager.dart';
import '../managers/reset_manager.dart';
import 'reset_history_entry.dart';

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
import '../core/constants/constantes.dart';

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
  // CHANTIER-02 : Manager ressources rares
  late final RareResourcesManager _rareResourcesManager;
  // CHANTIER-03 : Manager arbre de recherche
  late final ResearchManager _researchManager;
  // CHANTIER-04 : Manager agents IA
  late final AgentManager _agentManager;
  // CHANTIER-05 : Manager reset progression
  late final ResetManager _resetManager;

  // Services auxiliaires
  late final AutoSaveService _autoSaveService;

  // Ports UI/Navigation retirés du domaine (découplage via GameEventBus)

  // État global
  bool _isInCrisisMode = false;
  bool _crisisTransitionComplete = false;
  bool _showingCrisisView = false;
  DateTime? _crisisStartTime;

  bool _isInitialized = false;
  Object? _initializationError;
  StackTrace? _initializationStackTrace;
  // CHANTIER-01 : Entreprise unique
  String? _enterpriseId; // UUID v4 généré une fois
  String _enterpriseName = 'Mon Entreprise';
  DateTime? _enterpriseCreatedAt;
  
  // CHANTIER-02 : Ressources rares gérées par RareResourcesManager
  
  // CHANTIER-05 : Historique des resets progression
  List<ResetHistoryEntry> _resetHistory = [];
  int _resetCount = 0;

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
  // CHANTIER-01 : Getters entreprise
  String? get enterpriseId => _enterpriseId;
  String get enterpriseName => _enterpriseName;
  DateTime? get enterpriseCreatedAt => _enterpriseCreatedAt;
  
  // CHANTIER-02 : Getters ressources rares (délégation vers RareResourcesManager)
  int get quantum => _rareResourcesManager.quantum;
  int get pointsInnovation => _rareResourcesManager.pointsInnovation;
  int get totalResets => _rareResourcesManager.totalResets;
  
  // CHANTIER-05 : Getters historique resets
  List<ResetHistoryEntry> get resetHistory => List.unmodifiable(_resetHistory);
  int get resetCount => _resetCount;
  
  // Accès direct au manager pour fonctionnalités avancées
  RareResourcesManager get rareResources => _rareResourcesManager;
  ResearchManager get research => _researchManager;
  AgentManager get agents => _agentManager;
  ResetManager get resetManager => _resetManager;
  
  String get storageMode => _storageMode;
  
  // CHANTIER-01 : Setters entreprise
  void setEnterpriseId(String id) {
    final uuidV4 = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');
    if (!uuidV4.hasMatch(id)) {
      throw ArgumentError('enterpriseId must be a valid UUID v4');
    }
    _enterpriseId = id;
    notifyListeners();
  }
  
  void setEnterpriseName(String name) {
    final trimmed = name.trim();
    if (trimmed.length < 3) {
      throw ArgumentError('Enterprise name must be at least 3 characters');
    }
    if (trimmed.length > 30) {
      throw ArgumentError('Enterprise name cannot exceed 30 characters');
    }
    final validChars = RegExp(r"^[a-zA-Z0-9\s\-_.\']+$");
    if (!validChars.hasMatch(trimmed)) {
      throw ArgumentError('Enterprise name contains invalid characters');
    }
    _enterpriseName = trimmed;
    notifyListeners();
  }
  
  // CHANTIER-02 : Méthodes ressources rares (délégation vers RareResourcesManager)
  void addQuantum(int amount) {
    _rareResourcesManager.addQuantum(amount);
  }
  
  void addPointsInnovation(int amount) {
    _rareResourcesManager.addPointsInnovation(amount);
  }
  
  bool spendQuantum(int amount) {
    return _rareResourcesManager.spendQuantum(amount);
  }
  
  bool spendPointsInnovation(int amount) {
    return _rareResourcesManager.spendPointsInnovation(amount);
  }
  
  // CHANTIER-05 : Méthodes historique resets
  void addResetEntry(ResetHistoryEntry entry) {
    _resetHistory.add(entry);
    _resetCount++;
    notifyListeners();
  }
  
  PlayerManager get playerManager => _playerManager;
  MarketManager get marketManager => _marketManager;
  ResourceManager get resourceManager => _resourceManager;
  LevelSystem get levelSystem => _levelSystem;
  MissionSystem get missionSystem => _missionSystem;
  bool get isPaused => _isPaused;
  ProductionManager get productionManager => _productionManager;


  // Alias de compatibilité
  int get totalTimePlayedInSeconds => _statistics.totalGameTimeSec;
  bool get isCrisisTransitionComplete => _crisisTransitionComplete;
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
      // Émission d'un événement analytics/jeu: achat de métal
      final double amount = GameConstants.METAL_PACK_AMOUNT;
      final double appliedUnitPrice = (discountedUnitPrice ?? unitPrice);
      final double discountPct = (procurementLevel > 0)
          ? UpgradeEffectsCalculator.metalDiscount(level: procurementLevel) * 100.0
          : 0.0;

      _eventBus.emit(
        GameEvent(
          type: GameEventType.metalPurchased,
          data: {
            'amount': amount,
            'unitPrice': appliedUnitPrice,
            'totalSpent': amount * appliedUnitPrice,
            'discountPct': discountPct,
          },
        ),
      );

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
      
      // CHANTIER-02 : Manager ressources rares
      _rareResourcesManager = RareResourcesManager();
      
      // CHANTIER-03 : Manager arbre de recherche
      _researchManager = ResearchManager(_rareResourcesManager, _playerManager);
      
      // CHANTIER-03 : Injecter ResearchManager dans PlayerManager pour bonus metalStorage
      _playerManager.setResearchManager(_researchManager);
      
      // CHANTIER-04 : Manager agents IA
      _agentManager = AgentManager(
        _rareResourcesManager,
        _researchManager,
        _playerManager,
        _marketManager,
        _resourceManager,
      );

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
        researchManager: _researchManager,
      );
      
      // CHANTIER-04 : Injecter AgentManager dans ProductionManager
      _productionManager.setAgentManager(_agentManager);
      
      // CHANTIER-05 : Manager reset progression (architecture refactorée)
      _resetManager = ResetManager(this);

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
      _resourceManager.setResearchManager(_researchManager);
      _marketManager.setManagers(_playerManager, _statistics, _researchManager, levelSystem: _levelSystem);
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
      
      // CHANTIER-04 : Tick agents IA avec GameState pour actions réelles
      _agentManager.tick(elapsedSeconds, gameState: this);
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
      researchManager: _researchManager,
    );
  }

  // tickMarket() supprimé — chemin unique : GameSessionController → tick(realElapsed)

  // Prépare une structure de données minimale pour la persistance legacy
  Map<String, dynamic> prepareGameData() {
    return GamePersistenceMapper.prepareGameData(
      playerManager: _playerManager,
      marketManager: _marketManager,
      levelSystem: _levelSystem,
      missionSystem: _missionSystem,
      statistics: _statistics,
    );
  }

  // Réinitialisation simple de l'état de jeu
  void reset() {
    _resetGameDataOnly();

    _lastSaveTime = null;
    _isPaused = false;
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
  
  // ============================================================================
  // CHANTIER-05 : Reset Progression (Prestige)
  // ============================================================================
  
  /// Méthode publique pour effectuer un reset progression
  /// 
  /// Retourne le résultat du reset (succès ou échec avec message d'erreur)
  Future<ResetResult> performProgressionReset() async {
    return await _resetManager.performReset();
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

  // Mode compétitif supprimé dans CHANTIER-01
  int calculateCompetitiveScore() {
    return 0;
  }

  void handleCompetitiveGameEnd() {
    // Mode compétitif supprimé dans CHANTIER-01
    return;
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

  // CHANTIER-01 : Création nouvelle entreprise unique
  Future<void> createNewEnterprise(String name) async {
    try {
      // Générer UUID v4 pour l'entreprise
      final uuid = const Uuid().v4();
      _enterpriseId = uuid;
      
      // Valider et définir le nom
      setEnterpriseName(name);
      
      // Date de création
      _enterpriseCreatedAt = _clock.now();
      
      // Réinitialiser l'état de jeu
      reset();
      
      // Initialiser tous les managers (initialize() est synchrone)
      // Note: initialize() crée déjà tous les managers y compris _rareResourcesManager
      initialize();
      
      notifyListeners();
      
      if (kDebugMode) {
        print('[GameState] Nouvelle entreprise créée: $name, enterpriseId: $uuid');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[GameState] Erreur création entreprise: $e');
        print(stackTrace);
      }
      throw SaveError('CREATE_ENTERPRISE_ERROR', 'Impossible de créer l\'entreprise: $e');
    }
  }
  
  // CHANTIER-01 : Suppression entreprise (testeurs uniquement)
  Future<void> deleteEnterprise() async {
    _enterpriseId = null;
    _enterpriseName = 'Mon Entreprise';
    _enterpriseCreatedAt = null;
    // Réinitialiser ressources rares (tout supprimer)
    _rareResourcesManager.resetResources(keepRareResources: false);
    // Note: totalResets est également réinitialisé lors de la suppression complète
    
    // Réinitialiser le GameState
    initialize();
    notifyListeners();
    
    if (kDebugMode) {
      print('[GameState] Entreprise supprimée');
    }
  }

  // DEPRECATED : Garder pour compatibilité temporaire
  Future<void> startNewGame(String name) async {
    try {
      // CORRECTION #2: Validation du nom
      final trimmedName = name.trim();
      if (trimmedName.length < 3) {
        throw SaveError('INVALID_NAME', 'Le nom doit contenir au moins 3 caractères (reçu: "$name")');
      }
      // Réinitialiser l'état de jeu
      reset();

      // IMPORTANT (Mission 2):
      // - La persistance (save initial) et le démarrage autosave sont orchestrés hors de GameState.
      // - GameState ne fait ici que réinitialiser l'état métier.
      notifyListeners();

      // CORRECTION #3: Utiliser logger au lieu de print()
      if (kDebugMode) {
        print('[GameState] Nouvelle entreprise créée: $trimmedName, enterpriseId: $_enterpriseId');
      }

      return;
    } catch (e, stackTrace) {
      // CORRECTION #3: Utiliser logger pour erreurs
      if (kDebugMode) {
        print('[GameState] Erreur lors de la création d\'une nouvelle partie: $e');
        print(stackTrace);
      }
      throw SaveError('CREATE_ERROR', 'Impossible de créer une nouvelle partie: $e');
    }
  }

  void applyLoadedGameDataWithoutSnapshot(String name, Map<String, dynamic> gameData) {
    _resetGameDataOnly();

    _enterpriseName = name;

    GamePersistenceMapper.applyLoadedGameDataWithoutSnapshot(
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
      'snapshotSchemaVersion': 3, // CHANTIER-01: Version 3 pour entreprise unique
      'enterpriseId': _enterpriseId,
      'storageMode': _storageMode,
      'savedAt': now.toIso8601String(),
      // Version contractuelle obligatoire
      'version': GAME_SNAPSHOT_CONTRACT_VERSION,
      // CHANTIER-01: Champs requis par validation backend v3
      'createdAt': (_enterpriseCreatedAt ?? now).toIso8601String(),
      'lastModified': now.toIso8601String(),
      'enterpriseName': _enterpriseName,
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
      'agentManager': _agentManager.toJson(),
      'rareResourcesManager': _rareResourcesManager.toJson(),
      'researchManager': _researchManager.toJson(),
      'resetHistory': _resetHistory.map((e) => e.toJson()).toList(),
      'resetCount': _resetCount,
      'game': {
        'enterpriseName': _enterpriseName,
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

    // Nom d'entreprise depuis snapshot
    final metaName = metadata['enterpriseName'] as String?;
    if (metaName != null && metaName.isNotEmpty) {
      _enterpriseName = metaName;
    }

    // ID technique (UUID) si présent dans les métadonnées du snapshot
    final metaEnterpriseId = metadata['enterpriseId'] as String?;
    if (metaEnterpriseId != null && metaEnterpriseId.isNotEmpty) {
      _enterpriseId = metaEnterpriseId;
    }

    // gameMode supprimé dans CHANTIER-01

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
    
    if (core['rareResourcesManager'] is Map) {
      _rareResourcesManager.fromJson(Map<String, dynamic>.from(core['rareResourcesManager'] as Map));
    }
    
    if (core['researchManager'] is Map) {
      _researchManager.fromJson(Map<String, dynamic>.from(core['researchManager'] as Map));
    }
    
    if (core['agentManager'] is Map) {
      _agentManager.fromJson(Map<String, dynamic>.from(core['agentManager'] as Map));
      // Synchroniser avec recherche après chargement
      _agentManager.syncWithResearch();
    }

    // Charger historique resets (CHANTIER-05)
    if (core['resetHistory'] is List) {
      _resetHistory = (core['resetHistory'] as List)
          .map((e) => ResetHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _resetCount = (core['resetCount'] as int?) ?? 0;

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
      // CORRECTION #3: Utiliser logger au lieu de print()
      if (kDebugMode) {
        print('[GameState] Erreur lors de la sauvegarde événementielle: $e');
      }
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
