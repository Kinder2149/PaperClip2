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
import 'market/sale_record.dart';
import 'interfaces/game_state_market.dart';
import 'interfaces/game_state_production.dart';
import 'interfaces/game_state_save.dart';

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
  DateTime? _lastSaveTime; // Ajout pour stocker la dernière heure de sauvegarde
  int _marketingLevel = 0;
  double _productionCost = 0.05; // Exemple de coût de production par trombone

  // Public getters
  double get paperclips => _paperclips;
  double get metal => _metal;
  double get money => _money;
  double get sellPrice => _sellPrice;
  int get autoclippers => _autoclippers;
  double get autocliperCost {
    double baseCost = GameConstants.BASE_AUTOCLIPPER_COST * (1.15 * _autoclippers);
    double automationDiscount = 1.0 - ((upgrades['automation']?.level ?? 0) * 0.10); // Réduction du coût
    return baseCost * automationDiscount;
  }
  double get currentMetalPrice => _currentMetalPrice;
  int get totalTimePlayed => _totalTimePlayedInSeconds;
  int get totalPaperclipsProduced => _totalPaperclipsProduced;
  DateTime? get lastSaveTime => _lastSaveTime; // Getter pour la dernière heure de sauvegarde
  int get marketingLevel => _marketingLevel;
  double get productionCost => _productionCost;

  // Capacité de stockage
  int get maxMetalStorage => (1000 * (1 + (upgrades['storage']?.level ?? 0) * 0.50)).toInt();

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

  // Upgrade system
  final Map<String, Upgrade> upgrades = {
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

  GameState() {
    _initializeGame();
  }

  void upgradeMarketing() {
    _marketingLevel++;
    notifyListeners();
  }

  Future<void> _initializeGame() async {
    await loadGame();
    initializeMarket();
    startProductionTimer();
    _startMetalPriceVariation();
    _startPlayTimeTracking();
  }

  void purchaseUpgrade(String id) {
    final upgrade = upgrades[id];
    if (upgrade != null && money >= upgrade.currentCost && upgrade.level < upgrade.maxLevel) {
      money -= upgrade.currentCost;
      upgrade.level++;
      notifyListeners();
    }
  }

  void _startPlayTimeTracking() {
    _playTimeTimer?.cancel();
    _playTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _totalTimePlayedInSeconds++;
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

  void producePaperclip() {
    if (_metal >= GameConstants.METAL_PER_PAPERCLIP) {
      _paperclips++;
      _totalPaperclipsProduced++;
      _metal -= GameConstants.METAL_PER_PAPERCLIP;
      notifyListeners();
    }
  }

  void buyMetal() {
    if (_money >= _currentMetalPrice) {
      _metal += GameConstants.METAL_PACK_AMOUNT;
      _money -= _currentMetalPrice;
      notifyListeners();
    }
  }

  void buyAutoclipper() {
    if (_money >= autocliperCost) {
      _money -= autocliperCost;
      _autoclippers++;
      notifyListeners();
      saveGame();
    }
  }

  void setSellPrice(double price) {
    if (price >= GameConstants.MIN_PRICE && price <= GameConstants.MAX_PRICE) {
      _sellPrice = price;
      notifyListeners();
    }
  }

  void startNewGame(String gameName) {
    // Réinitialiser les valeurs du jeu pour commencer une nouvelle partie
    _paperclips = 0;
    _metal = GameConstants.INITIAL_METAL;
    _money = GameConstants.INITIAL_MONEY;
    _sellPrice = GameConstants.INITIAL_PRICE;
    _autoclippers = 0;
    _currentMetalPrice = GameConstants.MIN_METAL_PRICE;
    _totalPaperclipsProduced = 0;
    _totalTimePlayedInSeconds = 0;
    _marketingLevel = 0;
    _productionCost = 0.05; // Exemple de coût de production par trombone

    // Réinitialiser les upgrades
    upgrades.forEach((key, value) {
      value.reset();
    });

    // Autres initialisations nécessaires
    initializeMarket();
    startProductionTimer();
    _startMetalPriceVariation();
    _startPlayTimeTracking();

    notifyListeners();
  }

  @override
  void processMarket() {
    double calculatedDemand = marketManager.calculateDemand(_sellPrice, getMarketingLevel());
    int potentialSales = calculatedDemand.floor();
    if (_paperclips >= potentialSales && potentialSales > 0) {
      double qualityBonus = 1.0 + (upgrades['quality']?.level ?? 0) * 0.10; // Bonus de qualité
      double salePrice = _sellPrice * qualityBonus; // Application du bonus de qualité
      _paperclips -= potentialSales;
      _money += potentialSales * salePrice;
      marketManager.recordSale(potentialSales, salePrice);
      notifyListeners();
    }
  }

  @override
  void processProduction() {
    if (_autoclippers > 0) {
      double bulkBonus = 1.0 + (upgrades['bulk']?.level ?? 0) * 0.35;
      double efficiencyBonus = 1.0 - ((upgrades['efficiency']?.level ?? 0) * 0.15);
      double speedBonus = 1.0 + (upgrades['speed']?.level ?? 0) * 0.20; // Ajout du bonus de vitesse
      double metalNeeded = _autoclippers * GameConstants.METAL_PER_PAPERCLIP * efficiencyBonus;
      if (_metal >= metalNeeded) {
        double production = _autoclippers * bulkBonus * speedBonus; // Application du bonus de vitesse
        _paperclips += production;
        _totalPaperclipsProduced += production.floor();
        _metal -= metalNeeded;
        notifyListeners();
      }
    }
  }

  @override
  Map<String, dynamic> prepareGameData() {
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
      'lastSaveTime': _lastSaveTime?.toIso8601String(), // Ajout de la dernière heure de sauvegarde
    };
  }

  void _loadGameData(Map<String, dynamic> gameData) {
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
    marketManager.reputation = (gameData['marketReputation'] ?? 1.0).toDouble();
    notifyListeners();
  }

  Future<void> importSave(String filename) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(GameConstants.SAVE_KEY);
      if (savedData != null) {
        final gameData = jsonDecode(savedData);
        _loadGameData(gameData);
        notifyListeners();
      }
    } catch (e) {
      print('Error importing save: $e');
    }
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

  // Fonction de sauvegarde
  @override
  Future<void> saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    final gameData = prepareGameData();
    await prefs.setString(GameConstants.SAVE_KEY, jsonEncode(gameData));
    _lastSaveTime = DateTime.now(); // Mettre à jour la dernière heure de sauvegarde
    notifyListeners();
  }

  void showAutoSaveMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jeu sauvegardé automatiquement')),
    );
  }

  // Initialiser la sauvegarde automatique
  void startAutoSave(BuildContext context) {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      saveGame();
      showAutoSaveMessage(context);
    });
  }
}