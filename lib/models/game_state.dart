import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
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
  String? _customSaveDirectory;

  // Public getters
  double get paperclips => _paperclips;
  double get metal => _metal;
  double get money => _money;
  double get sellPrice => _sellPrice;
  int get autoclippers => _autoclippers;
  double get autocliperCost =>
      GameConstants.BASE_AUTOCLIPPER_COST * (1.15 * _autoclippers);
  double get currentMetalPrice => _currentMetalPrice;
  int get totalTimePlayed => _totalTimePlayedInSeconds;
  int get totalPaperclipsProduced => _totalPaperclipsProduced;
  String? get customSaveDirectory => _customSaveDirectory;

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

  set customSaveDirectory(String? value) {
    _customSaveDirectory = value;
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
  };

  GameState() {
    _initializeGame();
  }
  int _marketingLevel = 0;

  int get marketingLevel => _marketingLevel;

  void upgradeMarketing() {
    _marketingLevel++;
    notifyListeners();
  }
  double _productionCost = 0.05; // Exemple de coût de production par trombone

  double get productionCost => _productionCost;

  void setProductionCost(double cost) {
    _productionCost = cost;
    notifyListeners();
  }

  set money(double value) {
    _money = value;
    notifyListeners();
  }
  Future<void> _initializeGame() async {
    await loadSaveDirectory();
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
    _metalPriceTimer = Timer.periodic(
        const Duration(seconds: 4),
            (timer) async {
          double variation = (Random().nextDouble() * 4) - 2;
          _currentMetalPrice = (_currentMetalPrice + variation)
              .clamp(
              GameConstants.MIN_METAL_PRICE, GameConstants.MAX_METAL_PRICE);
          notifyListeners();
          await Future.delayed(
              Duration(milliseconds: Random().nextInt(6000) + 4000));
        }
    );
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

  @override
  void processMarket() {
    double calculatedDemand = marketManager.calculateDemand(
      _sellPrice,
      getMarketingLevel(),
    );

    int potentialSales = calculatedDemand.floor();

    if (_paperclips >= potentialSales && potentialSales > 0) {
      _paperclips -= potentialSales;
      _money += potentialSales * _sellPrice;
      marketManager.recordSale(potentialSales, _sellPrice);
      notifyListeners();
    }
  }

  @override
  void processProduction() {
    if (_autoclippers > 0) {
      double bulkBonus = 1.0 + (upgrades['bulk']?.level ?? 0) * 0.35;
      double efficiencyBonus = 1.0 -
          ((upgrades['efficiency']?.level ?? 0) * 0.15);
      double metalNeeded = _autoclippers * GameConstants.METAL_PER_PAPERCLIP *
          efficiencyBonus;

      if (_metal >= metalNeeded) {
        double production = _autoclippers * bulkBonus;
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
      'customSaveDirectory': _customSaveDirectory,
    };
  }

  @override
  Future<void> loadGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(GameConstants.SAVE_KEY);

      if (savedData != null) {
        Map<String, dynamic> gameData = jsonDecode(savedData);

        // Vérifier si une migration est nécessaire
        if (UpdateManager.needsMigration(gameData['version'] as String?)) {
          gameData = UpdateManager.migrateData(gameData);
        }

        _paperclips = (gameData['paperclips'] ?? 0).toDouble();
        _metal = (gameData['metal'] ?? GameConstants.INITIAL_METAL).toDouble();
        _money = (gameData['money'] ?? GameConstants.INITIAL_MONEY).toDouble();
        _sellPrice = (gameData['sellPrice'] ?? GameConstants.INITIAL_PRICE).toDouble();
        _autoclippers = gameData['autoclippers'] ?? 0;
        _currentMetalPrice = (gameData['currentMetalPrice'] ?? GameConstants.MIN_METAL_PRICE).toDouble();
        _totalPaperclipsProduced = gameData['totalPaperclipsProduced'] ?? 0;
        _totalTimePlayedInSeconds = gameData['totalTimePlayedInSeconds'] ?? 0;
        _customSaveDirectory = gameData['customSaveDirectory'];

        // Charger les upgrades
        if (gameData['upgrades'] != null) {
          Map<String, dynamic> savedUpgrades = gameData['upgrades'];
          savedUpgrades.forEach((key, value) {
            if (upgrades.containsKey(key)) {
              upgrades[key] = Upgrade.fromJson(value);
            }
          });
        }

        // Initialiser le marché avec la réputation sauvegardée
        marketManager.reputation = (gameData['marketReputation'] ?? 1.0).toDouble();

        notifyListeners();
      }
    } catch (e) {
      print('Error loading game: $e');
    }
  }

  Future<bool> importSave(String filename) async {
    try {
      final directory = await saveDirectory;
      final file = File('$directory/$filename.json');

      if (!await file.exists()) return false;

      final content = await file.readAsString();
      Map<String, dynamic> gameData = jsonDecode(content);

      if (UpdateManager.needsMigration(gameData['version'] as String?)) {
        gameData = UpdateManager.migrateData(gameData);
      }

      // Mettre à jour les données du jeu
      _paperclips = (gameData['paperclips'] ?? 0).toDouble();
      _metal = (gameData['metal'] ?? GameConstants.INITIAL_METAL).toDouble();
      _money = (gameData['money'] ?? GameConstants.INITIAL_MONEY).toDouble();
      _sellPrice = (gameData['sellPrice'] ?? GameConstants.INITIAL_PRICE).toDouble();
      _autoclippers = gameData['autoclippers'] ?? 0;
      _currentMetalPrice = (gameData['currentMetalPrice'] ?? GameConstants.MIN_METAL_PRICE).toDouble();
      _totalPaperclipsProduced = gameData['totalPaperclipsProduced'] ?? 0;
      _totalTimePlayedInSeconds = gameData['totalTimePlayedInSeconds'] ?? 0;

      // Charger les upgrades
      if (gameData['upgrades'] != null) {
        Map<String, dynamic> savedUpgrades = gameData['upgrades'];
        savedUpgrades.forEach((key, value) {
          if (upgrades.containsKey(key)) {
            upgrades[key] = Upgrade.fromJson(value);
          }
        });
      }

      marketManager.reputation = (gameData['marketReputation'] ?? 1.0).toDouble();

      // Sauvegarder dans les préférences
      await saveGame();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error importing save: $e');
      return false;
    }
  }

  @override
  Future<void> selectSaveDirectory() async {
    try {
      final String? result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Sélectionner le dossier de sauvegarde',
      );

      if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(GameConstants.SAVE_DIR_KEY, result);
        _customSaveDirectory = result;
        notifyListeners();
      }
    } catch (e) {
      print('Error selecting save directory: $e');
    }
  }

  Future<List<String>> listSaves() async {
    try {
      final directory = await saveDirectory;
      final dir = Directory(directory);

      if (!await dir.exists()) {
        await dir.create(recursive: true);
        return [];
      }

      final files = await dir.list().toList();
      return files
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .map((f) => f.path.split('/').last.replaceAll('.json', ''))
          .toList();
    } catch (e) {
      print('Error listing saves: $e');
      return [];
    }
  }

  Future<void> deleteSave(String filename) async {
    try {
      final directory = await saveDirectory;
      final file = File('$directory/$filename.json');

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting save: $e');
      throw Exception('Erreur lors de la suppression de la sauvegarde');
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
}
