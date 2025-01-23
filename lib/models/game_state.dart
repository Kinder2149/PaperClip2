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

class GameState extends ChangeNotifier {
  // Gestionnaires principaux
  late final PlayerManager playerManager;
  late final MarketManager marketManager;
  late final LevelSystem levelSystem;
  late final MissionSystem missionSystem;

  // Timers
  Timer? _productionTimer;
  Timer? _marketTimer;
  Timer? _metalPriceTimer;
  Timer? _playTimeTimer;
  Timer? _autoSaveTimer;
  Timer? _maintenanceTimer;

  // État du jeu
  bool _isInitialized = false;
  bool _isPaused = false;
  String? _gameName;
  BuildContext? _context;
  DateTime _lastUpdateTime = DateTime.now();
  int _totalTimePlayedInSeconds = 0;
  int _totalPaperclipsProduced = 0;
  DateTime? _lastSaveTime;
  double _maintenanceCosts = 0.0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPaused => _isPaused;
  String? get gameName => _gameName;
  DateTime? get lastSaveTime => _lastSaveTime;
  int get totalTimePlayed => _totalTimePlayedInSeconds;
  int get totalPaperclipsProduced => _totalPaperclipsProduced;
  double get maintenanceCosts => _maintenanceCosts;

  double get autocliperCost {
    double baseCost = GameConstants.BASE_AUTOCLIPPER_COST * (1.15 * playerManager.autoclippers);
    double automationDiscount = 1.0 - ((playerManager.upgrades['automation']?.level ?? 0) * 0.10);
    return baseCost * automationDiscount;
  }

  final Map<String, Upgrade> _upgrades = {
    'efficiency': Upgrade(
      name: 'Metal Efficiency',
      description: 'Réduit la consommation de métal de 15 %',
      baseCost: 45.0,
      level: 0,
      maxLevel: 10,
    ),
    'marketing': Upgrade(
      name: 'Marketing',
      description: 'Augmente la demande du marché de 30 %',
      baseCost: 75.0,
      level: 0,
      maxLevel: 8,
    ),
    'bulk': Upgrade(
      name: 'Bulk Production',
      description: 'Les autoclippeuses produisent 35 % plus vite',
      baseCost: 150.0,
      level: 0,
      maxLevel: 8,
    ),
    'speed': Upgrade(
      name: 'Speed Boost',
      description: 'Augmente la vitesse de production de 20 %',
      baseCost: 100.0,
      level: 0,
      maxLevel: 5,
    ),
    'storage': Upgrade(
      name: 'Storage Upgrade',
      description: 'Augmente la capacité de stockage de métal de 50 %',
      baseCost: 60.0,
      level: 0,
      maxLevel: 5,
    ),
    'automation': Upgrade(
      name: 'Automation',
      description: 'Réduit le coût des autoclippeuses de 10 % par niveau',
      baseCost: 200.0,
      level: 0,
      maxLevel: 5,
    ),
    'quality': Upgrade(
      name: 'Quality Control',
      description: 'Augmente le prix de vente des trombones de 10 % par niveau',
      baseCost: 80.0,
      level: 0,
      maxLevel: 10,
    ),
  };

  // Constructeur et initialisation
  GameState() {
    _initializeGame();
  }

  void _initializeGame() {
    if (_isInitialized) return;

    levelSystem = LevelSystem()
      ..onLevelUp = _handleLevelUp;

    playerManager = PlayerManager(levelSystem);

    marketManager = MarketManager(MarketDynamics())
      ..updateMarket();

    missionSystem = MissionSystem()
      ..initialize()
      ..onMissionCompleted = _handleMissionCompleted;

    _loadSavedGame();
    _startTimers();
    _isInitialized = true;
    notifyListeners();
  }

  // Gestion des timers
  void _startTimers() {
    _stopTimers();

    _productionTimer = Timer.periodic(
        const Duration(seconds: 1),
            (_) => _processProduction()
    );

    _marketTimer = Timer.periodic(
        const Duration(milliseconds: 500),
            (_) => _processMarket()
    );

    _metalPriceTimer = Timer.periodic(
        const Duration(seconds: 4),
            (_) {
          marketManager.updateMetalPrice();
          notifyListeners();
        }
    );

    _playTimeTimer = Timer.periodic(
        const Duration(seconds: 1),
            (_) {
          _totalTimePlayedInSeconds++;
          notifyListeners();
        }
    );

    _startAutoSave();

    _maintenanceTimer = Timer.periodic(
        const Duration(minutes: 1),
            (_) => _applyMaintenanceCosts()
    );
  }

  void _stopTimers() {
    _productionTimer?.cancel();
    _marketTimer?.cancel();
    _metalPriceTimer?.cancel();
    _playTimeTimer?.cancel();
    _autoSaveTimer?.cancel();
    _maintenanceTimer?.cancel();
  }

  // Production et marché
  void _processProduction() {
    if (_isPaused) return;

    final now = DateTime.now();
    final elapsed = now.difference(_lastUpdateTime).inMilliseconds / 1000;
    _lastUpdateTime = now;

    double manualProduction = _calculateManualProduction(elapsed);
    double autoProduction = _calculateAutoProduction(elapsed);
    _applyProduction(manualProduction + autoProduction);

    checkMetalStorage();
    checkResourceCrisis();
    notifyListeners();
  }

  double _calculateManualProduction(double elapsed) {
    if (playerManager.metal < GameConstants.METAL_PER_PAPERCLIP) return 0;

    double metalUsed = GameConstants.METAL_PER_PAPERCLIP;
    double efficiencyBonus = 1.0 + (playerManager.upgrades['efficiency']?.level ?? 0) * 0.1;
    metalUsed /= efficiencyBonus;

    playerManager.metal -= metalUsed;
    return 1.0 * elapsed;
  }

  double _calculateAutoProduction(double elapsed) {
    if (playerManager.autoclippers == 0) return 0;
    if (playerManager.metal < GameConstants.MIN_METAL_CONSUMPTION) return 0;

    double baseProduction = playerManager.autoclippers * elapsed;
    double efficiencyBonus = 1.0 + (playerManager.upgrades['efficiency']?.level ?? 0) * 0.15;
    double speedBonus = 1.0 + (playerManager.upgrades['speed']?.level ?? 0) * 0.20;
    double bulkBonus = 1.0 + (playerManager.upgrades['bulk']?.level ?? 0) * 0.35;

    double totalProduction = baseProduction * speedBonus * bulkBonus;
    double metalNeeded = totalProduction * GameConstants.METAL_PER_PAPERCLIP / efficiencyBonus;

    if (metalNeeded > playerManager.metal) {
      totalProduction = (playerManager.metal * efficiencyBonus) / GameConstants.METAL_PER_PAPERCLIP;
      metalNeeded = playerManager.metal;
    }

    playerManager.metal -= metalNeeded;
    return totalProduction;
  }
  void _applyProduction(double amount) {
    if (amount <= 0) return;

    playerManager.paperclips += amount;
    _totalPaperclipsProduced += amount.floor();
    levelSystem.addAutomaticProduction(amount.floor());

    missionSystem.updateMissions(
        MissionType.PRODUCE_PAPERCLIPS,
        amount
    );
  }

  void _processMarket() {
    if (_isPaused) return;

    marketManager.updateMarket();

    double demand = marketManager.calculateDemand(
        playerManager.sellPrice,
        playerManager.upgrades['marketing']?.level ?? 0
    );

    int sales = min(demand.floor(), playerManager.paperclips.floor());
    if (sales > 0) {
      _processSales(sales);
    }
  }

  void _processSales(int quantity) {
    double qualityBonus = 1.0 + (playerManager.upgrades['quality']?.level ?? 0) * 0.1;
    double salePrice = playerManager.sellPrice * qualityBonus;
    double revenue = quantity * salePrice;

    playerManager.paperclips -= quantity;
    playerManager.money += revenue;

    marketManager.recordSale(quantity, salePrice);
    levelSystem.addSale(quantity, salePrice);

    missionSystem.updateMissions(
        MissionType.SELL_PAPERCLIPS,
        quantity.toDouble()
    );
  }

  // Gestion des notifications et événements
  void checkMetalStorage() {
    double stockPercentage = playerManager.metal / playerManager.maxMetalStorage;
    if (stockPercentage >= 0.9) {
      final notification = NotificationEvent(
        title: "Stockage Critique",
        description: "Stockage à ${(stockPercentage * 100).toInt()}%",
        detailedDescription: """
Votre stockage de métal atteint ses limites !

État actuel :
• Capacité totale: ${playerManager.maxMetalStorage}
• Métal stocké: ${playerManager.metal.toInt()}
• Taux d'occupation: ${(stockPercentage * 100).toInt()}%

Actions recommandées :
1. Augmentez votre capacité de stockage
2. Accélérez la production
3. Vendez l'excès de métal
      """,
        icon: Icons.warehouse,
        priority: NotificationPriority.HIGH,
      );

      if (_context != null) {
        NotificationManager.showGameNotification(
          _context!,
          event: notification,
        );
      }
    }
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
    double metalPrice = marketManager.getCurrentPrice();
    if (playerManager.money >= metalPrice) {
      double amount = GameConstants.METAL_PACK_AMOUNT;

      if (playerManager.metal + amount <= playerManager.maxMetalStorage) {
        playerManager.metal += amount;
        playerManager.money -= metalPrice;
        notifyListeners();
      } else {
        EventManager.instance.addEvent(
            EventType.RESOURCE_DEPLETION,
            "Stockage plein",
            description: "Impossible d'acheter plus de métal. Améliorez votre stockage!",
            importance: EventImportance.HIGH
        );
      }
    }
  }

  void buyAutoclipper() {
    if (playerManager.money >= autocliperCost) {
      playerManager.money -= autocliperCost;
      playerManager.autoclippers++;
      levelSystem.addAutoclipperPurchase();
      notifyListeners();
    }
  }

  void producePaperclip() {
    if (playerManager.metal >= GameConstants.METAL_PER_PAPERCLIP) {
      playerManager.paperclips++;
      _totalPaperclipsProduced++;
      playerManager.metal -= GameConstants.METAL_PER_PAPERCLIP;
      levelSystem.addManualProduction();
      notifyListeners();
    }
  }

  void setSellPrice(double newPrice) {
    if (marketManager.isPriceExcessive(newPrice)) {
      final notification = NotificationEvent(
        title: "Prix Excessif!",
        description: "Ce prix pourrait affecter vos ventes",
        detailedDescription: marketManager.getPriceRecommendation(),
        icon: Icons.price_change,
        priority: NotificationPriority.HIGH,
      );

      if (_context != null) {
        NotificationManager.showGameNotification(
          _context!,
          event: notification,
        );
      }
    }
    playerManager.sellPrice = newPrice;
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
          playerManager.money += GameConstants.BASE_AUTOCLIPPER_COST;
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

  // Gestion de la sauvegarde
  Future<void> _loadSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(GameConstants.SAVE_KEY);
    if (savedData != null) {
      final gameData = jsonDecode(savedData);
      _loadGameData(gameData);
    }
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (_gameName != null) {
        await saveGame(_gameName!);
      }
    });
  }

  Future<void> saveGame(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _gameName = name;
      _lastSaveTime = DateTime.now();

      final gameData = {
        'version': GameConstants.VERSION,
        'timestamp': _lastSaveTime!.toIso8601String(),
        'playerManager': playerManager.toJson(),
        'marketManager': marketManager.toJson(),
        'levelSystem': levelSystem.toJson(),
        'missionSystem': missionSystem.toJson(),
        'totalTimePlayedInSeconds': _totalTimePlayedInSeconds,
        'totalPaperclipsProduced': _totalPaperclipsProduced,
      };

      await prefs.setString('save_$name', jsonEncode(gameData));
    } catch (e) {
      print('Error saving game: $e');
      rethrow;
    }
  }

  void _loadGameData(Map<String, dynamic> data) {
    playerManager.loadFromJson(data['playerManager'] ?? {});
    marketManager.fromJson(data['marketManager'] ?? {});
    levelSystem.loadFromJson(data['levelSystem'] ?? {});
    missionSystem.fromJson(data['missionSystem'] ?? {});

    _totalTimePlayedInSeconds = (data['totalTimePlayedInSeconds'] as num?)?.toInt() ?? 0;
    _totalPaperclipsProduced = (data['totalPaperclipsProduced'] as num?)?.toInt() ?? 0;

    _lastUpdateTime = DateTime.now();
    notifyListeners();
  }

  // Utilitaires et autres
  void setContext(BuildContext context) {
    _context = context;
    _startAutoSave();
  }

  void _showUnlockNotification(String message) {
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(_context!).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
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
    _stopTimers();
    playerManager.dispose();
    levelSystem.dispose();
    missionSystem.dispose();
    super.dispose();
  }
}