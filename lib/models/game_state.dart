import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/update_manager.dart';
import 'constants.dart';
import 'upgrade.dart';
import 'market/market_manager.dart';
import 'interfaces/game_state_market.dart';
import 'interfaces/game_state_production.dart';
import 'interfaces/game_state_save.dart';
import '../models/level_system.dart';
import '../services/save_manager.dart';

class SaveGame {
  final String id;
  final String name;
  final DateTime lastSaveTime;
  final double paperclips;
  final double metal;
  final double money;
  final Map<String, dynamic> gameData;

  SaveGame({
    required this.id,
    required this.name,
    required this.lastSaveTime,
    required this.paperclips,
    required this.metal,
    required this.money,
    required this.gameData,
  });

  factory SaveGame.fromJson(Map<String, dynamic> json) {
    return SaveGame(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? 'Sauvegarde sans nom',
      lastSaveTime: DateTime.tryParse(json['lastSaveTime'] ?? '') ?? DateTime.now(),
      paperclips: (json['paperclips'] ?? 0).toDouble(),
      metal: (json['metal'] ?? 0).toDouble(),
      money: (json['money'] ?? 0).toDouble(),
      gameData: json,
    );
  }

  Map<String, dynamic> toJson() => gameData;
}

class GameState extends ChangeNotifier with GameStateMarket, GameStateProduction, GameStateSave {
  // Private properties
  double _paperclips = 0;
  double _metal = GameConstants.INITIAL_METAL;
  double _money = GameConstants.INITIAL_MONEY;
  double _sellPrice = GameConstants.INITIAL_PRICE;
  int _autoclippers = 0;
  double _currentMetalPrice = GameConstants.MIN_METAL_PRICE;
  Timer? _metalPriceTimer;
  int _totalPaperclipsProduced = 0;
  int _totalTimePlayedInSeconds = 0;
  Timer? _playTimeTimer;
  DateTime? _lastSaveTime;
  int _marketingLevel = 0;
  double _productionCost = 0.05;
  BuildContext? _context;
  List<Map<String, dynamic>> _statsHistory = [];

  // Properties ajoutées
  LevelSystem _levelSystem = LevelSystem();
  LevelSystem get levelSystem => _levelSystem;

  dynamic _activeEvent;
  dynamic get activeEvent => _activeEvent;

  List<dynamic> _eventHistory = [];
  List<dynamic> get eventHistory => _eventHistory;

  // Public getters & setters
  double get paperclips => _paperclips;
  double get metal => _metal;
  double get money => _money;
  double get sellPrice => _sellPrice;
  int get autoclippers => _autoclippers;
  double get autocliperCost {
    double baseCost = GameConstants.BASE_AUTOCLIPPER_COST * (1.15 * _autoclippers);
    double automationDiscount = 1.0 - ((upgrades['automation']?.level ?? 0) * 0.10);
    return baseCost * automationDiscount;
  }
  double get currentMetalPrice => _currentMetalPrice;
  int get totalTimePlayed => _totalTimePlayedInSeconds;
  int get totalPaperclipsProduced => _totalPaperclipsProduced;
  DateTime? get lastSaveTime => _lastSaveTime;
  int get marketingLevel => _marketingLevel;
  double get productionCost => _productionCost;
  int get maxMetalStorage => (1000 * (1 + (upgrades['storage']?.level ?? 0) * 0.50)).toInt();

  @override
  Map<String, Upgrade> get upgrades => _upgrades;
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

  // Setters
  set paperclips(double value) {
    _paperclips = value;
    notifyListeners();
  }

  set metal(double value) {
    _metal = value;
    notifyListeners();
  }

  set sellPrice(double value) {
    _sellPrice = value;
    notifyListeners();
  }

  set money(double value) {
    _money = value;
    notifyListeners();
  }

  void setProductionCost(double cost) {
    _productionCost = cost;
    notifyListeners();
  }

  void setContext(BuildContext context) {
    _context = context;
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

  void _startPlayTimeTracking() {
    _playTimeTimer?.cancel();
    _playTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _totalTimePlayedInSeconds++;
    });
  }

  Future<void> startNewGame(String name) async {
    _paperclips = 0;
    _metal = GameConstants.INITIAL_METAL;
    _money = GameConstants.INITIAL_MONEY;
    _sellPrice = GameConstants.INITIAL_PRICE;
    _autoclippers = 0;
    _currentMetalPrice = GameConstants.MIN_METAL_PRICE;
    _totalPaperclipsProduced = 0;
    _totalTimePlayedInSeconds = 0;
    _marketingLevel = 0;
    _productionCost = 0.05;

    upgrades.forEach((key, value) => value.reset());

    initializeMarket();
    startProductionTimer();
    _startMetalPriceVariation();
    _startPlayTimeTracking();

    await SaveManager.saveGame(this);
    notifyListeners();
  }

  void buyMetal() {
    if (_money >= _currentMetalPrice && _metal < maxMetalStorage) {
      _metal += GameConstants.METAL_PACK_AMOUNT;
      _money -= _currentMetalPrice;
      notifyListeners();
    }
  }

  void buyAutoclipper() {
    if (_money >= autocliperCost) {
      _money -= autocliperCost;
      _autoclippers++;
      _levelSystem.addAutoclipperPurchase(); // Ajout XP achat autoclipper
      notifyListeners();
    }
  }

  void setSellPrice(double price) {
    if (price >= GameConstants.MIN_PRICE && price <= GameConstants.MAX_PRICE) {
      _sellPrice = price;
      notifyListeners();
    }
  }

  void purchaseUpgrade(String id) {
    final upgrade = upgrades[id];
    if (upgrade != null && _money >= upgrade.currentCost && upgrade.level < upgrade.maxLevel) {
      _money -= upgrade.currentCost;
      upgrade.level++;
      _levelSystem.addUpgradePurchase(upgrade.level); // Ajout XP amélioration
      notifyListeners();
    }
  }

  void producePaperclip() {
    if (_metal >= GameConstants.METAL_PER_PAPERCLIP) {
      _paperclips++;
      _totalPaperclipsProduced++;
      _metal -= GameConstants.METAL_PER_PAPERCLIP;
      _levelSystem.addManualProduction(); // Ajout XP production manuelle
      notifyListeners();
    }
  }

  @override
  void processMarket() {
    double calculatedDemand = marketManager.calculateDemand(_sellPrice, getMarketingLevel());
    int potentialSales = calculatedDemand.floor();
    if (_paperclips >= potentialSales && potentialSales > 0) {
      double qualityBonus = 1.0 + (upgrades['quality']?.level ?? 0) * 0.10;
      double salePrice = _sellPrice * qualityBonus;
      _paperclips -= potentialSales;
      _money += potentialSales * salePrice;
      marketManager.recordSale(potentialSales, salePrice);
      _levelSystem.addSale(potentialSales, salePrice); // Ajout XP ventes
      notifyListeners();
    }
  }

  @override
  void processProduction() {
    if (_autoclippers > 0) {
      double bulkBonus = 1.0 + (upgrades['bulk']?.level ?? 0) * 0.35;
      double efficiencyBonus = 1.0 - ((upgrades['efficiency']?.level ?? 0) * 0.15);
      double speedBonus = 1.0 + (upgrades['speed']?.level ?? 0) * 0.20;
      double metalNeeded = _autoclippers * GameConstants.METAL_PER_PAPERCLIP * efficiencyBonus;
      if (_metal >= metalNeeded) {
        double production = _autoclippers * bulkBonus * speedBonus;
        _paperclips += production;
        _totalPaperclipsProduced += production.floor();
        _metal -= metalNeeded;
        _levelSystem.addAutomaticProduction(production.floor()); // Ajout XP production auto
        notifyListeners();
      }
    }
  }

  GameState() {
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    await loadGame();
    initializeMarket();
    startProductionTimer();
    _startMetalPriceVariation();
    _startPlayTimeTracking();
  }

  @override
  Map<String, dynamic> prepareGameData() {
    return {
      'version': UpdateManager.CURRENT_VERSION,
      'buildNumber': UpdateManager.CURRENT_BUILD_NUMBER,
      'lastSaveTime': DateTime.now().toIso8601String(),
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
      'statsHistory': _statsHistory,
      'levelSystem': _levelSystem.toJson(),
    };
  }

  Future<void> saveGame() async {
    await SaveManager.saveGame(this);
    _lastSaveTime = DateTime.now();
    notifyListeners();
  }

  Future<void> loadGame() async {
    final gameData = await SaveManager.loadGame();
    if (gameData != null) {
      await _loadGameData(gameData);
      print('Game loaded successfully: $gameData'); // Log to check loaded data
    }
  }

  Future<void> _loadGameData(Map<String, dynamic> gameData) async {
    _paperclips = (gameData['paperclips'] ?? 0).toDouble();
    _metal = (gameData['metal'] ?? GameConstants.INITIAL_METAL).toDouble();
    _money = (gameData['money'] ?? GameConstants.INITIAL_MONEY).toDouble();
    _sellPrice = (gameData['sellPrice'] ?? GameConstants.INITIAL_PRICE).toDouble();
    _autoclippers = gameData['autoclippers'] ?? 0;
    _currentMetalPrice = (gameData['currentMetalPrice'] ?? GameConstants.MIN_METAL_PRICE).toDouble();
    _totalPaperclipsProduced = gameData['totalPaperclipsProduced'] ?? 0;
    _totalTimePlayedInSeconds = gameData['totalTimePlayedInSeconds'] ?? 0;
    _lastSaveTime = DateTime.tryParse(gameData['lastSaveTime'] ?? '');
    if (gameData['upgrades'] != null) {
      Map<String, dynamic> savedUpgrades = gameData['upgrades'];
      savedUpgrades.forEach((key, value) {
        if (upgrades.containsKey(key)) {
          upgrades[key] = Upgrade.fromJson(value);
        }
      });
    }
    _statsHistory = List<Map<String, dynamic>>.from(gameData['statsHistory'] ?? []);
    marketManager.reputation = (gameData['marketReputation'] ?? 1.0).toDouble();
    notifyListeners();
  }

  Future<void> quickSave() async {
    await SaveManager.saveGame(this);
    _lastSaveTime = DateTime.now();
    notifyListeners();
  }

  void startAutoSave(BuildContext context) {
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      await quickSave();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jeu sauvegardé automatiquement')),
        );
      }
    });
  }

  void processStatsHistory() {
    final currentStats = {
      'paperclips': _paperclips,
      'metal': _metal,
      'money': _money,
      'time': DateTime.now().toIso8601String()
    };
    _statsHistory.add(currentStats);
    notifyListeners();
  }

  Future<List<SaveGame>> listGames() async {
    final prefs = await SharedPreferences.getInstance();
    final saves = prefs.getStringList('saves') ?? [];

    return saves.map((saveStr) {
      final saveData = jsonDecode(saveStr);
      return SaveGame.fromJson(saveData);
    }).toList();
  }

  Future<void> loadGameById(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final saves = prefs.getStringList('saves') ?? [];

    for (String saveStr in saves) {
      final saveData = jsonDecode(saveStr);
      if (saveData['id'] == gameId) {
        await _loadGameData(saveData);
        await prefs.setString(GameConstants.SAVE_KEY, saveStr);
        print('Game loaded by ID: $gameId'); // Log to check loaded data by ID
        return;
      }
    }

    throw Exception('Sauvegarde non trouvée');
  }

  Future<void> deleteGame(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saves = prefs.getStringList('saves') ?? [];

    saves.removeWhere((saveStr) {
      final saveData = jsonDecode(saveStr);
      return saveData['id'] == gameId;
    });

    await prefs.setStringList('saves', saves);
    notifyListeners();
  }

  @override
  void dispose() {
    marketTimer?.cancel();
    productionTimer?.cancel();
    _metalPriceTimer?.cancel();
    _playTimeTimer?.cancel();
    super.dispose();
  }

  @override
  int getMarketingLevel() {
    return upgrades['marketing']?.level ?? 0;
  }
}