import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'services/service_container.dart';
import 'models/models.dart';
import 'models/interfaces/interfaces.dart';

class GameState extends ChangeNotifier {
  final ISaveService _saveService = getIt<ISaveService>();
  final INotificationService _notificationService = getIt<INotificationService>();
  final IAchievementService _achievementService = getIt<IAchievementService>();
  final ILeaderboardService _leaderboardService = getIt<ILeaderboardService>();
  final IAnalyticsService _analyticsService = getIt<IAnalyticsService>();

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
        id: 'auto_clipper',
        name: 'Autoclippeuse',
        description: 'Produit automatiquement des trombones',
        cost: 10,
        maxLevel: 100,
      ),
      Upgrade(
        id: 'production_speed',
        name: 'Vitesse de Production',
        description: 'Augmente la vitesse de production',
        cost: 50,
        maxLevel: 50,
      ),
      // Ajoutez d'autres améliorations ici
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
      _notificationService.showLevelUp(_level.currentLevel, newFeatures);
    }
  }

  Future<void> purchaseUpgrade(String upgradeId) async {
    final upgrade = _upgrades.firstWhere((u) => u.id == upgradeId);
    if (_player.money >= upgrade.getCost()) {
      _player.spendMoney(upgrade.getCost());
      upgrade.incrementLevel();
      _notificationService.showNotification(
        NotificationEvent(
          title: 'Amélioration Achetée',
          description: '${upgrade.name} niveau ${upgrade.level}',
          icon: Icons.arrow_upward,
        ),
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