import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../utils/update_manager.dart';
import 'constants.dart';
import 'upgrade.dart';
import 'market/market_manager.dart';
import 'market/sale_record.dart';
import 'interfaces/game_state_market.dart';
import 'interfaces/game_state_production.dart';
import 'interfaces/game_state_save.dart';
import '../services/save_manager.dart';
import 'level_system.dart';
import 'mission_system.dart';

class GameState extends ChangeNotifier with GameStateMarket, GameStateProduction, GameStateSave {
  final SaveManager _saveManager = SaveManager();
  String? _currentGameId;
  DateTime? _lastSaveTime;
  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  DateTime? get lastSaveTime => _lastSaveTime;

  // Propriétés privées
  double _paperclips = 0;
  double _metal = GameConstants.INITIAL_METAL;
  double _money = GameConstants.INITIAL_MONEY;
  double _sellPrice = GameConstants.INITIAL_PRICE;
  int _autoclippers = 0;
  double _currentMetalPrice = GameConstants.MIN_METAL_PRICE;
  Timer? _metalPriceTimer;
  Timer? _playTimeTimer;
  Timer? _autoSaveTimer;
  int _totalPaperclipsProduced = 0;
  int _totalTimePlayedInSeconds = 0;
  int _marketingLevel = 0;
  double _productionCost = 0.10;

  // Systèmes
  final LevelSystem levelSystem = LevelSystem();
  final MissionSystem missionSystem = MissionSystem();

  // Getters publics
  @override double get paperclips => _paperclips;
  @override double get metal => _metal;
  @override double get money => _money;
  @override double get sellPrice => _sellPrice;
  @override int get autoclippers => _autoclippers;
  double get currentMetalPrice => _currentMetalPrice;
  int get totalTimePlayed => _totalTimePlayedInSeconds;
  int get totalPaperclipsProduced => _totalPaperclipsProduced;
  int get marketingLevel => _marketingLevel;
  double get productionCost => _productionCost;

  double get autocliperCost {
    double baseCost = GameConstants.BASE_AUTOCLIPPER_COST * (1.3 * _autoclippers);
    double automationDiscount = 1.0 - ((upgrades['automation']?.level ?? 0) * 0.05);
    return baseCost * automationDiscount;
  }

  int get maxMetalStorage => (500 * (1 + (upgrades['storage']?.level ?? 0) * 0.25)).toInt();
  // Système d'upgrades
  @override
  final Map<String, Upgrade> upgrades = {
    'efficiency': Upgrade(
      name: 'Metal Efficiency',
      description: 'Réduit la consommation de métal de 10 %',
      baseCost: 100.0,
      level: 0,
      maxLevel: 10,
    ),
    'marketing': Upgrade(
      name: 'Marketing',
      description: 'Augmente la demande du marché de 20 %',
      baseCost: 150.0,
      level: 0,
      maxLevel: 8,
    ),
    'bulk': Upgrade(
      name: 'Bulk Production',
      description: 'Les autoclippeuses produisent 20 % plus vite',
      baseCost: 300.0,
      level: 0,
      maxLevel: 8,
    ),
    'speed': Upgrade(
      name: 'Speed Boost',
      description: 'Augmente la vitesse de production de 15 %',
      baseCost: 200.0,
      level: 0,
      maxLevel: 5,
    ),
    'storage': Upgrade(
      name: 'Storage Upgrade',
      description: 'Augmente la capacité de stockage de métal de 25 %',
      baseCost: 120.0,
      level: 0,
      maxLevel: 5,
    ),
    'automation': Upgrade(
      name: 'Automation',
      description: 'Réduit le coût des autoclippeuses de 5 % par niveau',
      baseCost: 250.0,
      level: 0,
      maxLevel: 5,
    ),
    'quality': Upgrade(
      name: 'Quality Control',
      description: 'Augmente le prix de vente des trombones de 5 % par niveau',
      baseCost: 160.0,
      level: 0,
      maxLevel: 10,
    ),
  };

  // Système d'événements
  Map<String, String>? _activeEvent;
  List<Map<String, String>> _eventHistory = [];

  Map<String, String>? get activeEvent => _activeEvent;
  List<Map<String, String>> get eventHistory => _eventHistory;

  void _addEventToHistory(String title, String description) {
    final event = {
      'title': title,
      'description': description,
      'time': DateTime.now().toString()
    };

    _activeEvent = event;
    _eventHistory.insert(0, event);
    saveGame();
    notifyListeners();

    if (_context != null) {
      _showEventPopup(_context!, title, description);
    }
  }

  void _showEventPopup(BuildContext context, String title, String message) {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      );
    }
  }

  // Constructeur et initialisation
  GameState() {
    _initializeGame();
    levelSystem.onLevelUp = _handleLevelUp;
    missionSystem.onMissionCompleted = _handleMissionComplete;
    _startRandomEvents();
  }

  Future<void> _initializeGame() async {
    try {
      await loadGame(_currentGameId ?? 'default');
      initializeMarket();
      startProductionTimer();
      _startMetalPriceVariation();
      _startPlayTimeTracking();
    } catch (e) {
      print('Error initializing game: $e');
    }
  }
  // Implémentations des interfaces et gestion des timers
  @override
  void processMarket() {
    double calculatedDemand = marketManager.calculateDemand(_sellPrice, getMarketingLevel());
    int potentialSales = calculatedDemand.floor();
    if (_paperclips >= potentialSales && potentialSales > 0) {
      double qualityBonus = 1.0 + (upgrades['quality']?.level ?? 0) * 0.05;
      double levelBonus = levelSystem.salesMultiplier;
      double salePrice = _sellPrice * qualityBonus * levelBonus;
      _paperclips -= potentialSales;
      _money += potentialSales * salePrice;
      marketManager.recordSale(potentialSales, salePrice);
      levelSystem.addSale(potentialSales, salePrice);
      missionSystem.updateMissions(MissionType.SELL_PAPERCLIPS, potentialSales.toDouble());
      notifyListeners();

      if (potentialSales >= 100) {
        saveGame();
      }
    }
  }

  @override
  void processProduction() {
    if (_autoclippers > 0) {
      double bulkBonus = 1.0 + (upgrades['bulk']?.level ?? 0) * 0.20;
      double efficiencyBonus = 1.0 - ((upgrades['efficiency']?.level ?? 0) * 0.10);
      double speedBonus = 1.0 + (upgrades['speed']?.level ?? 0) * 0.15;
      double levelBonus = levelSystem.productionMultiplier;
      double metalNeeded = _autoclippers * GameConstants.METAL_PER_PAPERCLIP * efficiencyBonus;

      if (_metal >= metalNeeded) {
        double production = _autoclippers * bulkBonus * speedBonus * levelBonus;
        _paperclips += production;
        int producedAmount = production.floor();
        _totalPaperclipsProduced += producedAmount;
        _metal -= metalNeeded;
        levelSystem.addAutomaticProduction(producedAmount);
        missionSystem.updateMissions(MissionType.PRODUCE_PAPERCLIPS, producedAmount.toDouble());
        notifyListeners();
      }
    }
  }

  @override
  int getMarketingLevel() => upgrades['marketing']?.level ?? 0;

  void _startRandomEvents() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      int eventType = Random().nextInt(4); // 0 à 3 pour quatre types d'événements

      switch (eventType) {
        case 0:
          _triggerEconomicCrisis();
          break;
        case 1:
          _triggerDemandSurge();
          break;
        case 2:
          _triggerMetalShortage();
          break;
        case 3:
          _triggerReputationBonus();
          break;
      }
    });
  }

  void _startPlayTimeTracking() {
    _playTimeTimer?.cancel();
    _playTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _totalTimePlayedInSeconds++;
      if (_totalTimePlayedInSeconds % 300 == 0) {
        saveGame();
      }
    });
  }

  void _startMetalPriceVariation() {
    _metalPriceTimer?.cancel();
    _metalPriceTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      double variation = (Random().nextDouble() * 4) - 2;
      _currentMetalPrice = (_currentMetalPrice + variation)
          .clamp(GameConstants.MIN_METAL_PRICE, GameConstants.MAX_METAL_PRICE);
      notifyListeners();
      await Future.delayed(Duration(milliseconds: Random().nextInt(6000) + 4000));
    });
  }

  // Setters avec notification
  @override
  set metal(double value) {
    _metal = value;
    notifyListeners();
  }

  @override
  set paperclips(double value) {
    _paperclips = value;
    notifyListeners();
  }

  @override
  set sellPrice(double value) {
    _sellPrice = value;
    notifyListeners();
    saveGame();
  }

  void producePaperclip() {
    if (_metal >= GameConstants.METAL_PER_PAPERCLIP) {
      _paperclips++;
      _totalPaperclipsProduced++;
      _metal -= GameConstants.METAL_PER_PAPERCLIP;
      levelSystem.addManualProduction();
      missionSystem.updateMissions(MissionType.PRODUCE_PAPERCLIPS, 1);
      notifyListeners();
    }
  }

  // Méthodes d'achat et de mise à niveau
  Future<void> buyMetal() async {
    if (_money >= _currentMetalPrice) {
      _metal += GameConstants.METAL_PACK_AMOUNT;
      _money -= _currentMetalPrice;
      notifyListeners();
      await saveGame();
    }
  }

  Future<void> buyAutoclipper() async {
    if (_money >= autocliperCost) {
      _money -= autocliperCost;
      _autoclippers++;
      levelSystem.addAutoclipperPurchase();
      missionSystem.updateMissions(MissionType.BUY_AUTOCLIPPERS, 1);
      notifyListeners();
      await saveGame();
    }
  }

  Future<void> upgradeMarketing() async {
    _marketingLevel++;
    notifyListeners();
    await saveGame();
  }

  Future<void> purchaseUpgrade(String id) async {
    final upgrade = upgrades[id];
    if (upgrade != null && _money >= upgrade.currentCost && upgrade.level < upgrade.maxLevel) {
      _money -= upgrade.currentCost;
      upgrade.level++;
      levelSystem.addUpgradePurchase(upgrade.level);
      missionSystem.updateMissions(MissionType.UPGRADE_PURCHASE, 1);
      notifyListeners();
      await saveGame();
    }
  }

  // Méthodes de sauvegarde
  @override
  Future<void> saveGame([String? gameName]) async {
    if (_currentGameId == null) return;

    try {
      final gameData = await prepareGameData();
      await _saveManager.saveGame(gameData, _currentGameId!, gameName ?? 'Default Save');
      _lastSaveTime = DateTime.now();
      notifyListeners();
    } catch (e) {
      print('Error saving game: $e');
    }
  }

  @override
  Future<void> loadGame(String gameId) async {
    try {
      final gameData = await _saveManager.loadGame(gameId);
      if (gameData != null) {
        _currentGameId = gameId;
        _loadGameData(gameData);
        _lastSaveTime = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading game: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> prepareGameData() async {
    return {
      'version': UpdateManager.CURRENT_VERSION,
      'buildNumber': UpdateManager.CURRENT_BUILD_NUMBER,
      'paperclips': _paperclips,
      'metal': _metal,
      'money': _money,
      'sellPrice': _sellPrice,
      'autoclippers': _autoclippers,
      'currentMetalPrice': _currentMetalPrice,
      'totalPaperclipsProduced': _totalPaperclipsProduced,
      'totalTimePlayedInSeconds': _totalTimePlayedInSeconds,
      'upgrades': upgrades.map((key, value) => MapEntry(key, value.toJson())),
      'marketReputation': marketManager.reputation,
      'marketingLevel': _marketingLevel,
      'productionCost': _productionCost,
      'gameId': _currentGameId,
      'levelSystem': levelSystem.toJson(),
      'missionSystem': missionSystem.toJson(),
      'eventHistory': _eventHistory,
      'activeEvent': _activeEvent,
    };
  }

  @override
  Future<void> startNewGame(String gameName) async {
    _currentGameId = DateTime.now().millisecondsSinceEpoch.toString();
    _resetGameState();
    final gameData = await prepareGameData();
    await _saveManager.saveGame(gameData, _currentGameId!, gameName);
    notifyListeners();
  }

  void _resetGameState() {
    _paperclips = 0;
    _metal = GameConstants.INITIAL_METAL;
    _money = GameConstants.INITIAL_MONEY;
    _sellPrice = GameConstants.INITIAL_PRICE;
    _autoclippers = 0;
    _currentMetalPrice = GameConstants.MIN_METAL_PRICE;
    _totalPaperclipsProduced = 0;
    _totalTimePlayedInSeconds = 0;
    _marketingLevel = 0;
    _productionCost = 0.10;
    _eventHistory = [];
    _activeEvent = null;
    upgrades.forEach((key, value) => value.reset());
    marketManager.reputation = 1.0;
    initializeMarket();
    startProductionTimer();
    _startMetalPriceVariation();
    _startPlayTimeTracking();
  }

  @override
  Future<List<Map<String, dynamic>>> listGames() async {
    return _saveManager.listGames();
  }

  @override
  Future<void> deleteGame(String gameId) async {
    await _saveManager.deleteGame(gameId);
    if (gameId == _currentGameId) {
      _currentGameId = null;
    }
  }

  @override
  void dispose() {
    marketTimer?.cancel();
    productionTimer?.cancel();
    _metalPriceTimer?.cancel();
    _playTimeTimer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _handleLevelUp(int level, List<String> unlocks) {
    // TODO: Implémenter la logique des déblocages
  }

  void _handleMissionComplete(Mission mission) {
    levelSystem.gainExperience(mission.experienceReward);
  }

  void _startRandomEvents() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      int eventType = Random().nextInt(4); // 0 à 3 pour quatre types d'événements

      switch (eventType) {
        case 0:
          _triggerEconomicCrisis();
          break;
        case 1:
          _triggerDemandSurge();
          break;
        case 2:
          _triggerMetalShortage();
          break;
        case 3:
          _triggerReputationBonus();
          break;
      }
    });
  }

  void _showEventPopup(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  void _triggerEconomicCrisis() {
    _sellPrice *= 0.5;
    _productionCost *= 2;
    notifyListeners();

    if (_context != null) {
      _showEventPopup(_context!, 'Crise Économique', 'Le prix de vente des trombones a été réduit et le coût de production a augmenté.');
      _addEventToHistory('Crise Économique', 'Le prix de vente des trombones a été réduit et le coût de production a augmenté.');
    }

    Future.delayed(const Duration(minutes: 2), () {
      _sellPrice /= 0.5;
      _productionCost /= 2;
      notifyListeners();
    });
  }

  void _triggerDemandSurge() {
    _sellPrice *= 1.5;
    notifyListeners();

    if (_context != null) {
      _showEventPopup(_context!, 'Augmentation de la Demande', 'La demande de trombones a temporairement augmenté.');
      _addEventToHistory('Augmentation de la Demande', 'La demande de trombones a temporairement augmenté.');
    }

    Future.delayed(const Duration(minutes: 2), () {
      _sellPrice /= 1.5;
      notifyListeners();
    });
  }

  void _triggerMetalShortage() {
    _currentMetalPrice *= 2;
    notifyListeners();

    if (_context != null) {
      _showEventPopup(_context!, 'Pénurie de Métal', 'Le prix du métal a temporairement augmenté.');
      _addEventToHistory('Pénurie de Métal', 'Le prix du métal a temporairement augmenté.');
    }

    Future.delayed(const Duration(minutes: 2), () {
      _currentMetalPrice /= 2;
      notifyListeners();
    });
  }

  void _triggerReputationBonus() {
    marketManager.reputation *= 1.5;
    notifyListeners();

    if (_context != null) {
      _showEventPopup(_context!, 'Bonus de Réputation', 'La réputation du marché a temporairement augmenté.');
      _addEventToHistory('Bonus de Réputation', 'La réputation du marché a temporairement augmenté.');
    }

    Future.delayed(const Duration(minutes: 2), () {
      marketManager.reputation /= 1.5;
      notifyListeners();
    });
  }

  @override
  void startAutoSave(BuildContext context) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await saveGame();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jeu sauvegardé automatiquement')),
      );
    });
  }

  void _loadGameData(Map<String, dynamic> gameData) {
    _paperclips = gameData['paperclips'];
    _metal = gameData['metal'];
    _money = gameData['money'];
    _sellPrice = gameData['sellPrice'];
    _autoclippers = gameData['autoclippers'];
    _currentMetalPrice = gameData['currentMetalPrice'];
    _totalPaperclipsProduced = gameData['totalPaperclipsProduced'];
    _totalTimePlayedInSeconds = gameData['totalTimePlayedInSeconds'];
    _marketingLevel = gameData['marketingLevel'];
    _productionCost = gameData['productionCost'];
    _currentGameId = gameData['gameId'];
    levelSystem.fromJson(gameData['levelSystem']);
    missionSystem.fromJson(gameData['missionSystem']);
    _eventHistory = List<Map<String, String>>.from(gameData['eventHistory']);
    _activeEvent = Map<String, String>.from(gameData['activeEvent']);
    upgrades.forEach((key, value) {
      if (gameData['upgrades'][key] != null) {
        value.fromJson(gameData['upgrades'][key]);
      }
    });
    notifyListeners();
  }
}