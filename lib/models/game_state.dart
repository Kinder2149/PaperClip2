import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../utils/update_manager.dart';
import './upgrade.dart';

class SaleRecord {
  final DateTime timestamp;
  final int quantity;
  final double price;
  final double revenue;

  SaleRecord({
    required this.timestamp,
    required this.quantity,
    required this.price,
    required this.revenue,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'quantity': quantity,
    'price': price,
    'revenue': revenue,
  };

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    return SaleRecord(
      timestamp: DateTime.parse(json['timestamp']),
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      revenue: json['revenue'].toDouble(),
    );
  }
}

class GameState extends ChangeNotifier {
  // Constants
  static const double INITIAL_METAL = 100;
  static const double INITIAL_MONEY = 0;
  static const double INITIAL_PRICE = 0.25;
  static const double METAL_PER_PAPERCLIP = 0.15;
  static const double METAL_PACK_AMOUNT = 100.0;
  static const double MIN_METAL_PRICE = 14.0;
  static const double MAX_METAL_PRICE = 39.0;
  static const String SAVE_KEY = 'paperclip_game_save';
  static const String SAVE_DIR_KEY = 'paperclip_save_directory';
  static const double BASE_AUTOCLIPPER_COST = 25.0;

  // Private properties
  double _paperclips = 0;
  double _metal = INITIAL_METAL;
  double _money = INITIAL_MONEY;
  double _productionRate = 1;
  double _sellPrice = INITIAL_PRICE;
  int _autoclippers = 0;
  double _marketDemand = 1.0;
  double _currentMetalPrice = MIN_METAL_PRICE;
  Timer? _productionTimer;
  Timer? _marketTimer;
  Timer? _metalPriceTimer;
  DateTime? _lastSaleTime;
  List<SaleRecord> _salesHistory = [];
  int _totalPaperclipsProduced = 0;
  int _totalTimePlayedInSeconds = 0;
  Timer? _playTimeTimer;
  String? _customSaveDirectory;

  // Public getters
  double get paperclips => _paperclips;
  double get metal => _metal;
  double get money => _money;
  double get productionRate => _productionRate;
  double get sellPrice => _sellPrice;
  int get autoclippers => _autoclippers;
  double get autocliperCost => BASE_AUTOCLIPPER_COST * (1.25 * _autoclippers);
  double get marketDemand => _marketDemand;
  double get currentMetalPrice => _currentMetalPrice;
  List<SaleRecord> get salesHistory => _salesHistory;
  DateTime? get lastSaleTime => _lastSaleTime;
  int get totalPaperclipsProduced => _totalPaperclipsProduced;
  int get totalTimePlayed => _totalTimePlayedInSeconds;
  String? get customSaveDirectory => _customSaveDirectory;

  // Upgrade system
  Map<String, Upgrade> upgrades = {
    'efficiency': Upgrade(
      name: 'Metal Efficiency',
      description: 'Reduces metal consumption by 15%',
      baseCost: 45.0,
      level: 0,
      maxLevel: 4,
    ),
    'marketing': Upgrade(
      name: 'Marketing',
      description: 'Increases market demand by 30%',
      baseCost: 75.0,
      level: 0,
      maxLevel: 3,
    ),
    'bulk': Upgrade(
      name: 'Bulk Production',
      description: 'Autoclippers produce 35% faster',
      baseCost: 150.0,
      level: 0,
      maxLevel: 3,
    ),
  };

  GameState() {
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    await _loadSaveDirectory(); // Assurez-vous que cette méthode existe.
    await _loadGame(); // Vérifiez que cette méthode existe.
    _startTimers();
    _startMetalPriceVariation();
    _startPlayTimeTracking();
  }
  Future<void> _loadSaveDirectory() async {
    // Implémentez ici la logique pour charger le répertoire de sauvegarde.
    // Par exemple :
    print("Chargement du répertoire de sauvegarde...");
  }

  void _startPlayTimeTracking() {
    _playTimeTimer?.cancel();
    _playTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _totalTimePlayedInSeconds++;
    });
  }

  void _stopTimers() {
    _productionTimer?.cancel();
    _marketTimer?.cancel();
    _metalPriceTimer?.cancel();
    _playTimeTimer?.cancel();
  }

  Future<void> selectSaveDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choisir le dossier de sauvegarde',
    );

    if (selectedDirectory != null) {
      _customSaveDirectory = selectedDirectory;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SAVE_DIR_KEY, selectedDirectory);
      notifyListeners();
    }
  }

  Future<String> get _saveDirectory async {
    if (_customSaveDirectory != null) {
      return _customSaveDirectory!;
    }
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/saves';
  }

  void _startMetalPriceVariation() {
    _metalPriceTimer?.cancel();
    _metalPriceTimer = Timer.periodic(
        const Duration(seconds: 4),
            (timer) async {
          double variation = (Random().nextDouble() * 4) - 2;
          _currentMetalPrice = (_currentMetalPrice + variation)
              .clamp(MIN_METAL_PRICE, MAX_METAL_PRICE);
          notifyListeners();
          await Future.delayed(
              Duration(milliseconds: Random().nextInt(6000) + 4000)
          );
        }
    );
  }

  void _startTimers() {
    _stopTimers();
    _productionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_autoclippers > 0) {
        double bulkBonus = 1.0 + (upgrades['bulk']?.level ?? 0) * 0.35;
        double efficiencyBonus = 1.0 - ((upgrades['efficiency']?.level ?? 0) * 0.15);
        double metalNeeded = _autoclippers * METAL_PER_PAPERCLIP * efficiencyBonus;

        if (_metal >= metalNeeded) {
          double production = _autoclippers * bulkBonus;
          _paperclips += production;
          _totalPaperclipsProduced += production.floor();
          _metal -= metalNeeded;
          notifyListeners();
        }
      }
    });

    _marketTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _processMarket();
    });
  }

  void producePaperclip() {
    if (_metal >= METAL_PER_PAPERCLIP) {
      _paperclips++;
      _totalPaperclipsProduced++;
      _metal -= METAL_PER_PAPERCLIP;
      notifyListeners();
    }
  }

  void buyMetal() {
    if (_money >= _currentMetalPrice) {
      _metal += METAL_PACK_AMOUNT;
      _money -= _currentMetalPrice;
      notifyListeners();
    }
  }

  void buyAutoclipper() {
    if (_money >= autocliperCost) {
      _money -= autocliperCost;
      _autoclippers++;
      notifyListeners();
      _saveGame();
    }
  }


  void setSellPrice(double price) {
    if (price >= 0) {
      _sellPrice = price;
      notifyListeners();
    }
  }

  void _processMarket() {
    double baseMarketDemand = 1.0 + ((upgrades['marketing']?.level ?? 0) * 0.3);
    double calculatedDemand;
    int potentialSales;

    // Ajustement de la demande selon le prix
    if (_sellPrice <= 0.15) {
      calculatedDemand = baseMarketDemand * (1 + (0.15 - _sellPrice) * 3);
      potentialSales = (5 * calculatedDemand).floor();
    } else if (_sellPrice <= 0.35) {
      calculatedDemand = baseMarketDemand * (1.5 - (_sellPrice - 0.15) * 2);
      potentialSales = (10 * calculatedDemand).floor();
    } else if (_sellPrice <= 0.50) {
      calculatedDemand = baseMarketDemand * (0.8 - (_sellPrice - 0.35));
      potentialSales = (3 * calculatedDemand).floor();
    } else {
      calculatedDemand = baseMarketDemand * 0.3;
      potentialSales = calculatedDemand.floor();
    }

    // Ajustements selon la progression
    if (_totalPaperclipsProduced < 1000) {
      calculatedDemand *= 0.8;
    }

    double marketingMultiplier = 1.0 + (upgrades['marketing']?.level ?? 0) * 0.3;
    calculatedDemand *= marketingMultiplier;
    calculatedDemand = calculatedDemand.clamp(0.0, double.infinity);

    if (_paperclips >= potentialSales && potentialSales > 0) {
      _processSale(potentialSales, calculatedDemand);
    }
  }

  void _processSale(int quantity, double demand) {
    double revenue = quantity * _sellPrice;

    _salesHistory.add(SaleRecord(
      timestamp: DateTime.now(),
      quantity: quantity,
      price: _sellPrice,
      revenue: revenue,
    ));

    if (_salesHistory.length > 100) {
      _salesHistory.removeAt(0);
    }

    _paperclips -= quantity;
    _money += revenue;
    _marketDemand = demand;
    _lastSaleTime = DateTime.now();
    notifyListeners();
    _saveGame();
  }

  Future<void> _saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameData = _prepareGameData();
      await prefs.setString(SAVE_KEY, jsonEncode(gameData));
    } catch (e) {
      print('Error saving game: $e');
    }
  }

  Map<String, dynamic> _prepareGameData() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'version': UpdateManager.CURRENT_VERSION,
      'buildNumber': UpdateManager.CURRENT_BUILD_NUMBER,
      'gameData': {
        'paperclips': _paperclips,
        'metal': _metal,
        'money': _money,
        'autoclippers': _autoclippers,
        'sellPrice': _sellPrice,
        'totalPaperclipsProduced': _totalPaperclipsProduced,
        'currentMetalPrice': _currentMetalPrice,
        'totalTimePlayedInSeconds': _totalTimePlayedInSeconds,
        'salesHistory': _salesHistory.map((sale) => sale.toJson()).toList(),
        'upgrades': upgrades.map((key, upgrade) => MapEntry(key, {
          'level': upgrade.level,
        })),
      }
    };
  }

  Future<void> _loadGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveData = prefs.getString(SAVE_KEY);

      if (saveData != null) {
        final data = jsonDecode(saveData);
        if (UpdateManager.needsMigration(data['version'])) {
          final migratedData = UpdateManager.migrateData(data);
          await _loadGameData(migratedData['gameData']);
          await _saveGame(); // Save migrated version
        } else {
          await _loadGameData(data['gameData']);
        }
      }
    } catch (e) {
      print('Error loading game: $e');
    }
  }

  Future<void> _loadGameData(Map<String, dynamic> data) async {
    _paperclips = data['paperclips']?.toDouble() ?? 0.0;
    _metal = data['metal']?.toDouble() ?? INITIAL_METAL;
    _money = data['money']?.toDouble() ?? 0.0;
    _autoclippers = data['autoclippers'] ?? 0;
    _sellPrice = data['sellPrice']?.toDouble() ?? INITIAL_PRICE;
    _totalPaperclipsProduced = data['totalPaperclipsProduced'] ?? 0;
    _currentMetalPrice = data['currentMetalPrice'] ?? MIN_METAL_PRICE;
    _totalTimePlayedInSeconds = data['totalTimePlayedInSeconds'] ?? 0;

    if (data['salesHistory'] != null) {
      _salesHistory = (data['salesHistory'] as List)
          .map((sale) => SaleRecord.fromJson(sale))
          .toList();
    }

    final savedUpgrades = data['upgrades'] as Map<String, dynamic>?;
    if (savedUpgrades != null) {
      savedUpgrades.forEach((key, upgradeData) {
        if (upgrades.containsKey(key)) {
          upgrades[key]!.level = upgradeData['level'] ?? 0;
        }
      });
    }
  }

  void purchaseUpgrade(String upgradeId) {
    var upgrade = upgrades[upgradeId];
    if (upgrade != null) {
      double cost = upgrade.currentCost;
      if (_money >= cost && upgrade.level < upgrade.maxLevel) {
        _money -= cost;
        upgrade.level++;
        notifyListeners();
        _saveGame();
      }
    }
  }

  Future<void> exportSave(String filename) async {
    final saveDir = await _saveDirectory;
    final directory = Directory(saveDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final file = File('$saveDir/$filename.json');
    final gameData = _prepareGameData();

    try {
      await file.writeAsString(jsonEncode(gameData));
      // Also save to SharedPreferences as backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SAVE_KEY, jsonEncode(gameData));
    } catch (e) {
      print('Error saving game: $e');
      throw Exception('Error saving game');
    }
  }

  Future<List<String>> listSaves() async {
    final saveDir = await _saveDirectory;
    final directory = Directory(saveDir);

    if (!await directory.exists()) return [];

    return directory
        .listSync()
        .where((file) => file.path.endsWith('.json'))
        .map((file) => file.path.split(Platform.pathSeparator).last.replaceAll('.json', ''))
        .toList();
  }

  Future<bool> importSave(String filename) async {
    try {
      final saveDir = await _saveDirectory;
      final file = File('$saveDir/$filename.json');

      if (!await file.exists()) return false;

      final content = await file.readAsString();
      final saveData = jsonDecode(content);

      // Check if migration is needed
      if (UpdateManager.needsMigration(saveData['version'])) {
        saveData['gameData'] = UpdateManager.migrateData(saveData['gameData']);
      }

      final data = saveData['gameData'];
      _loadGameData(data);

      // Save migrated version
      await file.writeAsString(jsonEncode(saveData));

      notifyListeners();
      return true;
    } catch (e) {
      print('Error importing save: $e');
      return false;
    }
  }

  Future<void> deleteSave(String filename) async {
    final saveDir = await _saveDirectory;
    final file = File('$saveDir/$filename.json');

    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}