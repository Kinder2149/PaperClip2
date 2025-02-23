// lib/models/game_state_interfaces.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_config.dart';
import 'market.dart';
import 'player_manager.dart';
import 'progression_system.dart';
import 'package:flutter/foundation.dart';
import 'game_config.dart';

/// Base mixin pour la gestion des timers
mixin GameStateBase on ChangeNotifier {
  Timer? _timer;

  @protected
  void startTimer(Duration duration, void Function(Timer) callback) {
    _timer?.cancel();
    _timer = Timer.periodic(duration, callback);
  }

  @protected
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Gestion du marché
mixin GameStateMarket on ChangeNotifier {
  late MarketManager marketManager;
  Timer? marketTimer;

  double get sellPrice;
  set sellPrice(double value);
  double get metal;
  double get money;
  double get paperclips;
  set paperclips(double value);

  void initializeMarket() {
    marketManager = MarketManager(MarketDynamics());
    startMarketTimer();
  }

  void startMarketTimer() {
    marketTimer?.cancel();
    marketTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) => processMarket(),
    );
  }

  void processMarket();
  int getMarketingLevel();
  Timer? get marketTimerGetter => marketTimer;
}

/// Gestion de la production
mixin GameStateProduction on ChangeNotifier {
  Timer? productionTimer;

  double get metal;
  set metal(double value);
  int get autoclippers;
  double get paperclips;
  set paperclips(double value);
  Map<String, Upgrade> get upgrades;

  void startProductionTimer() {
    productionTimer?.cancel();
    productionTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) => processProduction(),
    );
  }

  void processProduction();
  Timer? get productionTimerGetter => productionTimer;
}

/// Gestion de la sauvegarde
mixin GameStateSave on ChangeNotifier {
  Future<void> saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameData = prepareGameData();
      await prefs.setString(GameConstants.SAVE_KEY, jsonEncode(gameData));
    } catch (e) {
      print('Error saving game: $e');
    }
  }

  Future<void> loadGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(GameConstants.SAVE_KEY);
      if (savedData != null) {
        final gameData = jsonDecode(savedData);
        loadGameData(gameData);
      }
    } catch (e) {
      print('Error loading game: $e');
    }
  }

  Map<String, dynamic> prepareGameData();
  void loadGameData(Map<String, dynamic> gameData);
}

/// Gestion des ressources
mixin GameStateResource on ChangeNotifier {
  static const double STORAGE_MAINTENANCE_RATE = 0.01;
  static const double MIN_METAL_CONSUMPTION = 0.1;

  double _maintenanceCosts = 0.0;
  Timer? _maintenanceTimer;

  void startMaintenanceTimer() {
    _maintenanceTimer?.cancel();
    _maintenanceTimer = Timer.periodic(
        const Duration(minutes: 1),
            (_) => _applyMaintenanceCosts()
    );
  }

  double calculateMaintenanceCost();
  void _applyMaintenanceCosts();
  void checkResourceLevels();
}

/// Gestion du niveau et de la progression
mixin GameStateLevel on ChangeNotifier {
  LevelSystem get levelSystem;

  void handleLevelUp(int newLevel, List<UnlockableFeature> newFeatures);
  void checkProgress();
  void addExperience(double amount);
}

class StatisticsManager with ChangeNotifier {
  // Statistiques de production
  int _totalPaperclipsProduced = 0;
  int _manualPaperclipsProduced = 0;
  int _autoPaperclipsProduced = 0;
  double _totalMetalUsed = 0.0;
  double _totalMetalSaved = 0.0;
  double _currentEfficiency = 0.0;


  // Statistiques économiques
  double _totalMoneyEarned = 0;
  double _totalMoneySpent = 0;
  double _totalMetalBought = 0;
  int _totalSales = 0;
  double _highestPrice = 0;
  double _averagePrice = 0;

  // Statistiques de progression
  int _totalUpgradesBought = 0;
  int _totalAutoclippersBought = 0;
  int _maxComboAchieved = 0;
  Duration _totalPlayTime = Duration.zero;

  double getTotalMoneyEarned() {
    return _totalMoneyEarned;
  }

  // Méthodes de mise à jour
  void updateProduction({
    bool isManual = false,
    int amount = 1,
    required double metalUsed,
    double metalSaved = 0.0,
    double efficiency = 0.0,
  }) {
    if (isManual) {
      _manualPaperclipsProduced += amount;
    } else {
      _autoPaperclipsProduced += amount;
    }
    _totalPaperclipsProduced += amount;
    _totalMetalUsed += metalUsed;
    _totalMetalSaved += metalSaved;
    _currentEfficiency = efficiency;
    notifyListeners();
  }

  void updateEconomics({
    double? moneyEarned,
    double? moneySpent,
    double? metalBought,
    int? sales,
    double? price,
  }) {
    if (moneyEarned != null) _totalMoneyEarned += moneyEarned;
    if (moneySpent != null) _totalMoneySpent += moneySpent;
    if (metalBought != null) _totalMetalBought += metalBought;
    if (sales != null) _totalSales += sales;
    if (price != null) {
      if (price > _highestPrice) _highestPrice = price;
      _averagePrice = (_averagePrice * _totalSales + price) / (_totalSales + 1);
    }
    notifyListeners();
  }
  void updatePlayTime(Duration elapsed) {
    _totalPlayTime += elapsed;
    notifyListeners();
  }

  void updateProgression({
    int? upgradesBought,
    int? autoclippersBought,
    int? maxCombo,
    Duration? playTime,
  }) {
    if (upgradesBought != null) _totalUpgradesBought += upgradesBought;
    if (autoclippersBought != null) _totalAutoclippersBought += autoclippersBought;
    if (maxCombo != null && maxCombo > _maxComboAchieved) _maxComboAchieved = maxCombo;
    if (playTime != null) _totalPlayTime += playTime;
    notifyListeners();
  }
  String _formatNumber(dynamic value) {
    if (value is double) {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(2)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(2)}K';
      }
      return value.toStringAsFixed(2);
    } else if (value is int) {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(2)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(2)}K';
      }
    }
    return value.toString();
  }

  // Getters
  Map<String, Map<String, dynamic>> getAllStats() {
    return {
      'production': {
        'Total Trombones': _formatNumber(_totalPaperclipsProduced),
        'Production Manuelle': _formatNumber(_manualPaperclipsProduced),
        'Production Auto': _formatNumber(_autoPaperclipsProduced),
        'Métal Utilisé': _formatNumber(_totalMetalUsed),
      },
      'economie': {
        'Argent Gagné': _formatNumber(_totalMoneyEarned),
        'Argent Dépensé': _formatNumber(_totalMoneySpent),
        'Métal Acheté': _formatNumber(_totalMetalBought),
        'Ventes Totales': _formatNumber(_totalSales),
        'Prix Max': _formatNumber(_highestPrice),
        'Prix Moyen': _formatNumber(_averagePrice),
      },
      'progression': {
        'Améliorations Achetées': _totalUpgradesBought,
        'Autoclippers Achetés': _totalAutoclippersBought,
        'Combo Max': _maxComboAchieved,
        'Temps de Jeu': _formatDuration(_totalPlayTime),
      },
    };
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours}h ${minutes}m ${seconds}s';
  }

  // Sérialisation
  Map<String, dynamic> toJson() {
    return {
      'totalPaperclipsProduced': _totalPaperclipsProduced,
      'manualPaperclipsProduced': _manualPaperclipsProduced,
      'autoPaperclipsProduced': _autoPaperclipsProduced,
      'totalMetalUsed': _totalMetalUsed,
      'totalMoneyEarned': _totalMoneyEarned,
      'totalMoneySpent': _totalMoneySpent,
      'totalMetalBought': _totalMetalBought,
      'totalSales': _totalSales,
      'highestPrice': _highestPrice,
      'averagePrice': _averagePrice,
      'totalUpgradesBought': _totalUpgradesBought,
      'totalAutoclippersBought': _totalAutoclippersBought,
      'maxComboAchieved': _maxComboAchieved,
      'totalPlayTime': _totalPlayTime.inSeconds,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    try {
      // Conversion sécurisée avec logs
      print('Loading statistics data: $json');

      _totalPaperclipsProduced = _safeIntConversion(json['totalPaperclipsProduced']);
      _manualPaperclipsProduced = _safeIntConversion(json['manualPaperclipsProduced']);
      _autoPaperclipsProduced = _safeIntConversion(json['autoPaperclipsProduced']);
      _totalMetalUsed = _safeDoubleConversion(json['totalMetalUsed']);
      _totalMetalSaved = _safeDoubleConversion(json['totalMetalSaved']);
      _currentEfficiency = _safeDoubleConversion(json['currentEfficiency']);
      _totalMoneyEarned = _safeDoubleConversion(json['totalMoneyEarned']);
      _totalMoneySpent = _safeDoubleConversion(json['totalMoneySpent']);
      _totalMetalBought = _safeDoubleConversion(json['totalMetalBought']);
      _totalSales = _safeIntConversion(json['totalSales']);
      _highestPrice = _safeDoubleConversion(json['highestPrice']);
      _averagePrice = _safeDoubleConversion(json['averagePrice']);
      _totalUpgradesBought = _safeIntConversion(json['totalUpgradesBought']);
      _totalAutoclippersBought = _safeIntConversion(json['totalAutoclippersBought']);
      _maxComboAchieved = _safeIntConversion(json['maxComboAchieved']);
      _totalPlayTime = Duration(seconds: _safeIntConversion(json['totalPlayTime']));

      print('Successfully loaded statistics');
    } catch (e, stack) {
      print('Error loading statistics: $e');
      print('Stack trace: $stack');
      _resetToDefaults();
    }
    notifyListeners();
  }

  // Méthodes utilitaires pour conversion sécurisée
  double _safeDoubleConversion(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return 0.0;
  }

  int _safeIntConversion(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return 0;
  }

  void _resetToDefaults() {
    _totalPaperclipsProduced = 0;
    _manualPaperclipsProduced = 0;
    _autoPaperclipsProduced = 0;
    _totalMetalUsed = 0.0;
    _totalMetalSaved = 0.0;
    _currentEfficiency = 0.0;
    _totalMoneyEarned = 0.0;
    _totalMoneySpent = 0.0;
    _totalMetalBought = 0.0;
    _totalSales = 0;
    _highestPrice = 0.0;
    _averagePrice = 0.0;
    _totalUpgradesBought = 0;
    _totalAutoclippersBought = 0;
    _maxComboAchieved = 0;
    _totalPlayTime = Duration.zero;
  }
}
