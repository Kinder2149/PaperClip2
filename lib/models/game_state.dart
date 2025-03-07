// lib/models/game_state.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// lib/models/game_state.dart
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
import 'interfaces/game_state_interface.dart';
import 'player.dart';
import 'level.dart';
import 'market_manager.dart';
import 'constants/game_constants.dart';
import 'package:get_it/get_it.dart';
import '../services/service_container.dart';
import 'interfaces/interfaces.dart';
import 'implementations/implementations.dart';

class GameState extends ChangeNotifier {
  final ISaveService _saveService = GetIt.I<ISaveService>();
  final INotificationService _notificationService = GetIt.I<INotificationService>();
  final IAchievementService _achievementService = GetIt.I<IAchievementService>();
  final ILeaderboardService _leaderboardService = GetIt.I<ILeaderboardService>();
  final IAnalyticsService _analyticsService = GetIt.I<IAnalyticsService>();

  late final IPlayer _player;
  late final IMarket _market;
  late final ILevel _level;
  late final List<IUpgrade> _upgrades;

  GameState() {
    _initializeGame();
  }

  void _initializeGame() {
    _player = Player();
    _market = Market();
    _level = Level();
    _upgrades = [];
  }

  // Getters
  IPlayer get player => _player;
  IMarket get market => _market;
  ILevel get level => _level;
  List<IUpgrade> get upgrades => _upgrades;

  Future<void> _initializeGame() async {
    try {
      await _analyticsService.startSession();
      await _loadGame();
      _initializeUpgrades();
      notifyListeners();
    } catch (e) {
      _notificationService.showError('Erreur lors de l\'initialisation du jeu: $e');
    }
  }

  Future<void> _loadGame() async {
    try {
      final gameData = await _saveService.loadGame('current_save');
      _player = Player.fromJson(gameData['player']);
      _market = Market.fromJson(gameData['market']);
      _level = Level.fromJson(gameData['level']);
      notifyListeners();
    } catch (e) {
      _notificationService.showError('Erreur lors du chargement de la partie: $e');
    }
  }

  Future<void> saveGame() async {
    try {
      final gameData = {
        'player': _player.toJson(),
        'market': _market.toJson(),
        'level': _level.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _saveService.saveGame('current_save', gameData);
    } catch (e) {
      _notificationService.showError('Erreur lors de la sauvegarde: $e');
    }
  }

  void _initializeUpgrades() {
    _upgrades = [
      Upgrade(
        name: 'Autoclippeuse',
        description: 'Produit automatiquement des trombones',
        cost: 10,
        maxLevel: 100,
        requiredLevel: 1,
      ),
      Upgrade(
        name: 'Vitesse de Production',
        description: 'Augmente la vitesse de production',
        cost: 50,
        maxLevel: 50,
        requiredLevel: 1,
      ),
    ];
  }

  void producePaperclip() {
    final production = _player.producePaperclip();
    _player.addPaperclips(production);
    _checkAchievements();
    _checkLevelUp();
    notifyListeners();
  }

  void _checkAchievements() {
    if (_player.totalPaperclips >= 1000) {
      _achievementService.unlockAchievement('paperclip_master');
      _notificationService.showAchievement(
        'Maître des Trombones',
        'Vous avez produit 1000 trombones !',
      );
    }
  }

  void _checkLevelUp() {
    if (_level.checkLevelUp(_player.experience)) {
      final newFeatures = _level.getNewUnlockableFeatures();
      _notificationService.showLevelUp(_level.level, newFeatures);
    }
  }

  Future<void> purchaseUpgrade(String upgradeId) async {
    final upgrade = _upgrades.firstWhere((u) => u.name == upgradeId);
    if (_player.money >= upgrade.getCost()) {
      _player.spendMoney(upgrade.getCost().toInt());
      upgrade.incrementLevel();
      _notificationService.showNotification(
        title: 'Amélioration Achetée',
        message: '${upgrade.name} niveau ${upgrade.level}',
        icon: Icons.arrow_upward,
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _analyticsService.endSession();
    super.dispose();
  }
}