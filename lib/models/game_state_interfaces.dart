// lib/models/game_state_interfaces.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../constants/game_config.dart';
import '../services/persistence/game_persistence_orchestrator.dart';
import 'game_state.dart';
import '../managers/market_manager.dart';
import '../managers/player_manager.dart';
import 'progression_system.dart';
import 'json_loadable.dart';
import 'upgrade.dart';

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
    marketManager = MarketManager();
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
      if (this is GameState) {
        final gameState = this as GameState;
        await GamePersistenceOrchestrator.instance.requestManualSave(
          gameState,
          slotId: gameState.gameName,
          reason: 'game_state_interfaces_saveGame',
        );
      }
    } catch (e) {
      print('Error saving game: $e');
    }
  }

  Future<void> loadGame() async {
    try {
      if (this is GameState) {
        final gameState = this as GameState;
        final name = gameState.gameName;
        if (name == null) {
          return;
        }
        await GamePersistenceOrchestrator.instance.loadGame(gameState, name);
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
  // Utilisation des constantes centralisées dans GameConstants
  // static const double STORAGE_MAINTENANCE_RATE = 0.01;
  // static const double MIN_METAL_CONSUMPTION = 0.1;

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

// La classe StatisticsManager a été déplacée vers statistics_manager.dart
// Elle n'est plus définie ici pour éviter la double implémentation
