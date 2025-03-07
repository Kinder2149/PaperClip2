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
import 'resource_manager.dart';
import 'game_state_interfaces.dart';
import 'dart:convert';
import '../utils/notification_manager.dart';
import '../dialogs/metal_crisis_dialog.dart';
import '../services/auto_save_service.dart';
import 'package:paperclip2/services/games_services_controller.dart';
import 'package:games_services/games_services.dart' hide SaveGame;
import '../screens/main_screen.dart';
import 'package:paperclip2/services/cloud_save_manager.dart';
import 'package:games_services/games_services.dart' as gs;
import '../services/save_manager.dart' show SaveGame, SaveError, SaveGameInfo, SaveManager;

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
    if (!_isInitialized) {
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
      // Configuration des timers
      _startTimers();

      // Configuration des écouteurs
      _setupEventListeners();
      _setupLifecycleListeners();

      // Initialisation des services
      _autoSaveService.initialize();

      print('Configuration et démarrage terminés avec succès');
    } catch (e) {
      print('Erreur lors de la configuration et du démarrage: $e');
      rethrow;
    }
  }

  void _startTimers() {
    // Timer de temps de jeu
    _playTimeTimer?.cancel();
    _playTimeTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updatePlayTime(),
    );

    // Timer de marché
    marketTimer?.cancel();
    marketTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _processMarket(),
    );
  }

  void _updatePlayTime() {
    _statistics.updatePlayTime(const Duration(seconds: 1));
  }

  void _processMarket() {
    if (!_isInitialized) return;

    try {
      // Mise à jour du marché
      _marketManager.updateMarket();

      // Vérification des conditions de crise
      _checkCrisisConditions();

      // Mise à jour des statistiques
      _updateMarketStatistics();
    } catch (e) {
      print('Erreur lors du traitement du marché: $e');
    }
  }

  void _checkCrisisConditions() {
    if (!_isInCrisisMode && _shouldTriggerCrisis()) {
      _triggerCrisis();
    } else if (_isInCrisisMode && _shouldEndCrisis()) {
      _endCrisis();
    }
  }

  bool _shouldTriggerCrisis() {
    return _marketManager.currentMetalPrice > GameConstants.CRISIS_TRIGGER_PRICE &&
        _marketManager.marketMetalStock < GameConstants.CRISIS_TRIGGER_STOCK;
  }

  bool _shouldEndCrisis() {
    return _marketManager.currentMetalPrice < GameConstants.CRISIS_END_PRICE &&
        _marketManager.marketMetalStock > GameConstants.CRISIS_END_STOCK;
  }

  void _triggerCrisis() {
    _isInCrisisMode = true;
    _crisisStartTime = DateTime.now();
    _showCrisisDialog();
    notifyListeners();
  }

  void _endCrisis() {
    _isInCrisisMode = false;
    _crisisStartTime = null;
    _crisisTransitionComplete = false;
    _showingCrisisView = false;
    notifyListeners();
  }

  void _showCrisisDialog() {
    if (_context != null) {
      showDialog(
        context: _context!,
        barrierDismissible: false,
        builder: (context) => MetalCrisisDialog(
          onContinue: () {
            _crisisTransitionComplete = true;
            notifyListeners();
          },
        ),
      );
    }
  }

  void _updateMarketStatistics() {
    // Mise à jour des statistiques de marché
    _statistics.updateEconomics(
      price: _marketManager.currentMetalPrice,
    );
  }

  void _setupEventListeners() {
    EventManager.instance.addListener((event) {
      if (event is LevelUpEvent) {
        _handleLevelUp(event.newLevel);
      } else if (event is MarketEvent) {
        _handleMarketEvent(event);
      }
    });
  }

  void _handleLevelUp(int newLevel) {
    final unlockedFeatures = _getUnlockedFeatures(newLevel);
    for (var feature in unlockedFeatures) {
      _showUnlockNotification(feature.description);
    }
  }

  void _handleMarketEvent(MarketEvent event) {
    switch (event.type) {
      case MarketEventType.PRICE_SPIKE:
        _notifyPriceSpike();
        break;
      case MarketEventType.PRICE_CRASH:
        _notifyPriceCrash();
        break;
      case MarketEventType.STOCK_SHORTAGE:
        _notifyStockShortage();
        break;
    }
  }

  void _notifyPriceSpike() {
    EventManager.instance.addNotification(
      NotificationEvent(
        title: 'Hausse des Prix !',
        description: 'Les prix du métal augmentent rapidement.',
        icon: Icons.trending_up,
        priority: NotificationPriority.HIGH,
      ),
    );
  }

  void _notifyPriceCrash() {
    EventManager.instance.addNotification(
      NotificationEvent(
        title: 'Chute des Prix !',
        description: 'Les prix du métal s\'effondrent.',
        icon: Icons.trending_down,
        priority: NotificationPriority.HIGH,
      ),
    );
  }

  void _notifyStockShortage() {
    EventManager.instance.addNotification(
      NotificationEvent(
        title: 'Pénurie !',
        description: 'Le stock de métal est très bas.',
        icon: Icons.warning,
        priority: NotificationPriority.HIGH,
      ),
    );
  }

  List<UnlockableFeature> _getUnlockedFeatures(int level) {
    return [
      if (level == GameConstants.MARKET_UNLOCK_LEVEL)
        UnlockableFeature(
          'Marché',
          'Le marché est maintenant disponible !',
          FeatureType.MARKET,
        ),
      if (level == GameConstants.UPGRADES_UNLOCK_LEVEL)
        UnlockableFeature(
          'Améliorations',
          'Les améliorations sont maintenant disponibles !',
          FeatureType.UPGRADES,
        ),
      if (level == GameConstants.AUTOMATION_UNLOCK_LEVEL)
        UnlockableFeature(
          'Automation',
          'L\'automation est maintenant disponible !',
          FeatureType.AUTOMATION,
        ),
    ];
  }

  Map<String, bool> getAvailableFeatures() {
    return {
      // Éléments de marché
      'market': levelSystem.level >= GameConstants.MARKET_UNLOCK_LEVEL,
      'marketPrice': levelSystem.level >= GameConstants.MARKET_UNLOCK_LEVEL,
      'sellButton': levelSystem.level >= GameConstants.MARKET_UNLOCK_LEVEL,
      'marketStats': levelSystem.level >= GameConstants.MARKET_UNLOCK_LEVEL,
      'priceChart': levelSystem.level >= GameConstants.MARKET_UNLOCK_LEVEL,

      // Éléments de production
      'metalPurchaseButton': levelSystem.level >= 1,
      'autoclippersSection': levelSystem.level >= 3,
      'productionStats': levelSystem.level >= 2,
      'efficiencyDisplay': levelSystem.level >= 3,

      // Éléments d'amélioration
      'upgradesSection': levelSystem.level >= GameConstants.UPGRADES_UNLOCK_LEVEL,
      'upgradesScreen': levelSystem.level >= GameConstants.UPGRADES_UNLOCK_LEVEL,

      // Éléments de progression
      'levelDisplay': true,
      'experienceBar': true,
      'comboDisplay': levelSystem.level >= 2,

      // Éléments de statistiques
      'statsSection': levelSystem.level >= 4,
      'achievementsSection': levelSystem.level >= 5,

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

  // Méthodes de sauvegarde et chargement
  Future<void> saveGame(String name) async {
    if (!_isInitialized) return;

    try {
      final saveData = SaveGame(
        name: name,
        lastSaveTime: DateTime.now(),
        gameData: prepareGameData(),
        version: GameConstants.VERSION,
        gameMode: _gameMode,
      );

      await SaveManager.saveGame(saveData);
      _gameName = name;

      print('Jeu sauvegardé avec succès: $name');
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      rethrow;
    }
  }

  Future<void> loadGame(String name, {String? cloudId}) async {
    if (!_isInitialized) return;

    try {
      SaveGame? saveGame;
      if (cloudId != null) {
        // Charger depuis le cloud
        final cloudManager = CloudSaveManager();
        saveGame = await cloudManager.loadSave(cloudId);
      } else {
        // Charger depuis le stockage local
        saveGame = await SaveManager.loadGame(name);
      }

      if (saveGame == null) {
        throw SaveError('Sauvegarde non trouvée: $name');
      }

      // Valider les données
      final validationResult = SaveDataValidator.validate(saveGame.gameData);
      if (!validationResult.isValid) {
        throw SaveError('Données de sauvegarde invalides: ${validationResult.errors.join(', ')}');
      }

      // Charger les données validées
      loadGameData(saveGame.gameData, name, saveGame);
    } catch (e) {
      print('Erreur lors du chargement: $e');
      rethrow;
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

  void loadGameData(Map<String, dynamic> gameData, String name, SaveGame saveGame) {
    try {
      // Réinitialiser l'état
      _stopTimers();
      _resetState();

      // Charger les statistiques
      _statistics.fromJson(gameData['statistics'] ?? {});

      // Charger les autres données
      levelSystem.loadFromJson(gameData['levelSystem'] ?? {});
      _playerManager.fromJson(gameData['playerManager'] ?? {});
      _marketManager.fromJson(gameData['marketManager'] ?? {});

      // Charger le mode de jeu
      _gameMode = gameData['gameMode'] != null
          ? GameMode.values[gameData['gameMode'] as int]
          : GameMode.INFINITE;

      // Charger le temps de départ en mode compétitif
      if (gameData['competitiveStartTime'] != null) {
        _competitiveStartTime = DateTime.parse(gameData['competitiveStartTime'] as String);
      }

      _applyUpgradeEffects();

      // Charger les données globales avec conversion sécurisée
      _totalTimePlayedInSeconds = (gameData['totalTimePlayedInSeconds'] as num?)?.toInt() ?? 0;
      _totalPaperclipsProduced = (gameData['totalPaperclipsProduced'] as num?)?.toInt() ?? 0;

      _handleCrisisModeData(gameData);

      _gameName = name;
      _lastSaveTime = saveGame.lastSaveTime;

      print('Game loaded successfully');
      _startTimers();
      notifyListeners();
    } catch (e, stack) {
      print('Error loading game: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }

  void _handleCrisisModeData(Map<String, dynamic> gameData) {
    if (gameData['crisisMode'] != null) {
      final crisisData = gameData['crisisMode'] as Map<String, dynamic>;
      _isInCrisisMode = crisisData['isInCrisisMode'] as bool? ?? false;
      _crisisTransitionComplete = crisisData['crisisTransitionComplete'] as bool? ?? false;
      _showingCrisisView = crisisData['showingCrisisView'] as bool? ?? false;

      if (crisisData['crisisStartTime'] != null) {
        _crisisStartTime = DateTime.parse(crisisData['crisisStartTime'] as String);
      }
    }
  }

  void _applyUpgradeEffects() {
    for (var upgrade in _playerManager.upgrades.values) {
      if (upgrade.isUnlocked) {
        _playerManager.applyUpgradeEffect(upgrade);
      }
    }
  }

  void _stopTimers() {
    _playTimeTimer?.cancel();
    marketTimer?.cancel();
    _playTimeTimer = null;
    marketTimer = null;
  }

  void _resetState() {
    _isInCrisisMode = false;
    _crisisTransitionComplete = false;
    _showingCrisisView = false;
    _crisisStartTime = null;
    _competitiveStartTime = null;
    _gameMode = GameMode.INFINITE;
  }

  Future<void> showCloudSaveSelector() async {
    try {
      final gamesServices = GamesServicesController();
      if (!await gamesServices.isSignedIn()) {
        await gamesServices.signIn();
      }

      if (await gamesServices.isSignedIn()) {
        final selectedSave = await gamesServices.showSaveSelector();
        if (selectedSave != null && _context != null) {
          // Sauvegarder d'abord la partie actuelle si elle existe
          if (_isInitialized && _gameName != null) {
            await saveGame(_gameName!);
          }

          // Charger la partie sélectionnée
          await loadGame(selectedSave.name, cloudId: selectedSave.cloudId);
        }
      }
    } catch (e) {
      print('Erreur lors de la sélection de la sauvegarde cloud: $e');
      rethrow;
    }
  }

  Future<void> startNewGame(String name) async {
    try {
      // Réinitialiser l'état
      _stopTimers();
      _resetState();

      // Réinitialiser les managers
      _statistics = StatisticsManager();
      _resourceManager = ResourceManager();
      _marketManager = MarketManager(MarketDynamics());
      _levelSystem = LevelSystem();
      _missionSystem = MissionSystem();

      _playerManager = PlayerManager(
        levelSystem: _levelSystem,
        resourceManager: _resourceManager,
        marketManager: _marketManager,
      );

      // Configurer et démarrer
      _configureAndStart();

      // Sauvegarder la nouvelle partie
      await saveGame(name);

      notifyListeners();
    } catch (e) {
      print('Erreur lors de la création d\'une nouvelle partie: $e');
      rethrow;
    }
  }

  Future<void> endCompetitiveGame() async {
    if (_gameMode != GameMode.COMPETITIVE) return;

    try {
      final score = _calculateCompetitiveScore();
      final playTime = competitivePlayTime;

      // Sauvegarder le score
      await gs.GamesServices.submitScore(
        score: Score(
          androidLeaderboardID: 'competitive_mode',
          iOSLeaderboardID: 'competitive_mode',
          value: score,
        ),
      );

      // Afficher l'écran de résultats
      if (_context != null) {
        Navigator.pushReplacement(
          _context!,
          MaterialPageRoute(
            builder: (context) => CompetitiveResultScreen(
              score: score,
              playTime: playTime,
            ),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la fin du mode compétitif: $e');
    }
  }

  int _calculateCompetitiveScore() {
    final baseScore = _statistics.getTotalMoneyEarned().round();
    final timeBonus = _calculateTimeBonus();
    final efficiencyBonus = _calculateEfficiencyBonus();
    return (baseScore * (1 + timeBonus + efficiencyBonus)).round();
  }

  double _calculateTimeBonus() {
    final playTime = competitivePlayTime.inMinutes;
    if (playTime <= 0) return 0;
    return min(1.0, 60 / playTime);
  }

  double _calculateEfficiencyBonus() {
    final metalUsed = _statistics.getTotalMetalUsed();
    if (metalUsed <= 0) return 0;
    final efficiency = _totalPaperclipsProduced / metalUsed;
    return min(1.0, efficiency / 10);
  }

  Future<void> saveOnImportantEvent() async {
    if (!_isInitialized || _gameName == null) return;
    await saveGame(_gameName!);
  }
} 