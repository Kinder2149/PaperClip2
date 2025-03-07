import 'package:flutter/foundation.dart';
import 'dart:math';
import 'game_config.dart';
import 'event_system.dart';
import 'market.dart';
import 'progression_system.dart';
import 'resource_manager.dart';

class Upgrade {
  final String id;
  final String name;
  final String description;
  final double baseCost;
  final double costMultiplier;
  final UpgradeType type;
  int level;
  bool isUnlocked;

  Upgrade({
    required this.id,
    required this.name,
    required this.description,
    required this.baseCost,
    required this.costMultiplier,
    required this.type,
    this.level = 0,
    this.isUnlocked = false,
  });

  double get cost => baseCost * pow(costMultiplier, level);

  Map<String, dynamic> toJson() => {
    'id': id,
    'level': level,
    'isUnlocked': isUnlocked,
  };

  factory Upgrade.fromJson(Map<String, dynamic> json) {
    return Upgrade(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      baseCost: (json['baseCost'] as num).toDouble(),
      costMultiplier: (json['costMultiplier'] as num).toDouble(),
      type: UpgradeType.values[json['type'] as int],
      level: json['level'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
    );
  }
}

class PlayerManager extends ChangeNotifier {
  final LevelSystem levelSystem;
  final ResourceManager resourceManager;
  final MarketManager marketManager;

  double _money = GameConstants.INITIAL_MONEY;
  double _metal = GameConstants.INITIAL_METAL;
  double _paperclips = 0.0;
  int _autoclippers = 0;
  double _sellPrice = GameConstants.INITIAL_PRICE;
  Map<String, Upgrade> _upgrades = {};
  int _combo = 0;
  DateTime? _lastComboTime;
  bool _isAutomationEnabled = false;

  PlayerManager({
    required this.levelSystem,
    required this.resourceManager,
    required this.marketManager,
  }) {
    _initializeUpgrades();
  }

  // Getters
  double get money => _money;
  double get metal => _metal;
  double get paperclips => _paperclips;
  int get autoclippers => _autoclippers;
  double get sellPrice => _sellPrice;
  Map<String, Upgrade> get upgrades => _upgrades;
  int get combo => _combo;
  bool get isAutomationEnabled => _isAutomationEnabled;

  void _initializeUpgrades() {
    _upgrades = {
      'efficiency': Upgrade(
        id: 'efficiency',
        name: 'Efficacité',
        description: 'Améliore l\'efficacité de la production',
        baseCost: 50.0,
        costMultiplier: 1.5,
        type: UpgradeType.EFFICIENCY,
      ),
      'storage': Upgrade(
        id: 'storage',
        name: 'Stockage',
        description: 'Augmente la capacité de stockage',
        baseCost: 100.0,
        costMultiplier: 2.0,
        type: UpgradeType.STORAGE,
      ),
      'marketing': Upgrade(
        id: 'marketing',
        name: 'Marketing',
        description: 'Améliore les ventes',
        baseCost: 75.0,
        costMultiplier: 1.75,
        type: UpgradeType.MARKETING,
      ),
      'automation': Upgrade(
        id: 'automation',
        name: 'Automation',
        description: 'Améliore la production automatique',
        baseCost: 150.0,
        costMultiplier: 2.5,
        type: UpgradeType.AUTOMATION,
      ),
    };
  }

  // Méthodes de production
  void producePaperclip() {
    if (_metal < GameConstants.METAL_PER_PAPERCLIP) return;

    _metal -= GameConstants.METAL_PER_PAPERCLIP;
    _paperclips += 1;

    _updateCombo();
    levelSystem.addExperience(
      GameConstants.MANUAL_PRODUCTION_XP * (1 + _combo * GameConstants.COMBO_MULTIPLIER),
      ExperienceType.PRODUCTION
    );

    notifyListeners();
  }

  void _updateCombo() {
    final now = DateTime.now();
    if (_lastComboTime != null &&
        now.difference(_lastComboTime!) <= const Duration(seconds: 1)) {
      _combo = (_combo + 1).clamp(0, GameConstants.MAX_COMBO_COUNT);
    } else {
      _combo = 0;
    }
    _lastComboTime = now;
  }

  void processAutoProduction() {
    if (!_isAutomationEnabled || _autoclippers <= 0) return;

    double metalNeeded = GameConstants.METAL_PER_PAPERCLIP * _autoclippers;
    if (_metal < metalNeeded) return;

    _metal -= metalNeeded;
    _paperclips += _autoclippers;

    levelSystem.addExperience(
      GameConstants.AUTO_PRODUCTION_XP * _autoclippers,
      ExperienceType.PRODUCTION
    );

    notifyListeners();
  }

  // Méthodes de vente
  void sellPaperclips() {
    if (_paperclips <= 0) return;

    int quantityToSell = _paperclips.floor();
    double revenue = quantityToSell * _sellPrice;

    _paperclips -= quantityToSell;
    _money += revenue;

    marketManager.addSaleRecord(quantityToSell, _sellPrice);
    levelSystem.addExperience(
      GameConstants.SALE_BASE_XP * quantityToSell,
      ExperienceType.SALE
    );

    notifyListeners();
  }

  void setSellPrice(double newPrice) {
    _sellPrice = newPrice.clamp(
      GameConstants.MIN_PRICE,
      GameConstants.MAX_PRICE
    );
    notifyListeners();
  }

  // Méthodes d'achat
  void buyMetal() {
    double cost = marketManager.currentMetalPrice * GameConstants.METAL_PACK_AMOUNT;
    if (_money < cost) return;

    _money -= cost;
    _metal += GameConstants.METAL_PACK_AMOUNT;
    marketManager.updateMarketStock(-GameConstants.METAL_PACK_AMOUNT);

    notifyListeners();
  }

  void buyAutoclipper() {
    double cost = GameConstants.BASE_AUTOCLIPPER_COST * pow(1.5, _autoclippers);
    if (_money < cost) return;

    _money -= cost;
    _autoclippers++;
    _isAutomationEnabled = true;

    levelSystem.addExperience(
      GameConstants.AUTOCLIPPER_PURCHASE_XP,
      ExperienceType.UPGRADE
    );

    notifyListeners();
  }

  bool canBuyUpgrade(String upgradeId) {
    final upgrade = _upgrades[upgradeId];
    if (upgrade == null) return false;
    return _money >= upgrade.cost && levelSystem.level >= GameConstants.UPGRADES_UNLOCK_LEVEL;
  }

  void buyUpgrade(String upgradeId) {
    final upgrade = _upgrades[upgradeId];
    if (upgrade == null || !canBuyUpgrade(upgradeId)) return;

    _money -= upgrade.cost;
    upgrade.level++;
    upgrade.isUnlocked = true;

    _applyUpgradeEffects(upgrade);

    levelSystem.addExperience(
      GameConstants.UPGRADE_XP_MULTIPLIER * upgrade.level,
      ExperienceType.UPGRADE
    );

    notifyListeners();
  }

  void _applyUpgradeEffects(Upgrade upgrade) {
    switch (upgrade.type) {
      case UpgradeType.EFFICIENCY:
        // Effet déjà géré par le ResourceManager
        break;
      case UpgradeType.STORAGE:
        resourceManager.upgradeStorageCapacity(upgrade.level);
        break;
      case UpgradeType.MARKETING:
        marketManager.updateMarketingBonus(upgrade.level);
        break;
      case UpgradeType.AUTOMATION:
        // Améliore l'efficacité des autoclippers
        break;
      case UpgradeType.PRODUCTION:
        // Améliore la production manuelle
        break;
    }
  }

  // Méthodes utilitaires
  double calculateEfficiency() {
    return _paperclips / (_metal + 0.001);
  }

  void toggleAutomation() {
    _isAutomationEnabled = !_isAutomationEnabled;
    notifyListeners();
  }

  void reset() {
    _money = GameConstants.INITIAL_MONEY;
    _metal = GameConstants.INITIAL_METAL;
    _paperclips = 0.0;
    _autoclippers = 0;
    _sellPrice = GameConstants.INITIAL_PRICE;
    _combo = 0;
    _lastComboTime = null;
    _isAutomationEnabled = false;
    _initializeUpgrades();
    notifyListeners();
  }

  // Sérialisation
  Map<String, dynamic> toJson() => {
    'money': _money,
    'metal': _metal,
    'paperclips': _paperclips,
    'autoclippers': _autoclippers,
    'sellPrice': _sellPrice,
    'combo': _combo,
    'lastComboTime': _lastComboTime?.toIso8601String(),
    'isAutomationEnabled': _isAutomationEnabled,
    'upgrades': _upgrades.map((key, value) => MapEntry(key, value.toJson())),
  };

  void fromJson(Map<String, dynamic> json) {
    _money = (json['money'] as num?)?.toDouble() ?? GameConstants.INITIAL_MONEY;
    _metal = (json['metal'] as num?)?.toDouble() ?? GameConstants.INITIAL_METAL;
    _paperclips = (json['paperclips'] as num?)?.toDouble() ?? 0.0;
    _autoclippers = (json['autoclippers'] as num?)?.toInt() ?? 0;
    _sellPrice = (json['sellPrice'] as num?)?.toDouble() ?? GameConstants.INITIAL_PRICE;
    _combo = (json['combo'] as num?)?.toInt() ?? 0;
    _isAutomationEnabled = json['isAutomationEnabled'] as bool? ?? false;

    if (json['lastComboTime'] != null) {
      _lastComboTime = DateTime.parse(json['lastComboTime']);
    }

    if (json['upgrades'] != null) {
      final upgradesData = json['upgrades'] as Map<String, dynamic>;
      upgradesData.forEach((key, value) {
        if (_upgrades.containsKey(key)) {
          _upgrades[key]!.level = (value['level'] as num?)?.toInt() ?? 0;
          _upgrades[key]!.isUnlocked = value['isUnlocked'] as bool? ?? false;
        }
      });
    }
  }
} 