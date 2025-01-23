// lib/models/game_state_interfaces.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_config.dart';
import 'market.dart';
import 'player_manager.dart';
import 'progression_system.dart';

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
      const Duration(milliseconds: 500),
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