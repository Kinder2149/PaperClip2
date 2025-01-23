// lib/models/player_manager.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'game_config.dart';
import 'event_system.dart';
import 'progression_system.dart';
import 'resource_manager.dart';

/// Représente une amélioration du jeu
class Upgrade {
  final String id;
  final String name;
  final String description;
  int level;
  final double baseCost;
  final double costMultiplier;
  final int maxLevel;
  final int? requiredLevel;
  final Map<String, dynamic>? requirements;

  Upgrade({
    required this.id,
    required this.name,
    required this.description,
    this.level = 0,
    required this.baseCost,
    this.costMultiplier = 1.5,
    this.maxLevel = 10,
    this.requiredLevel,
    this.requirements,
  });

  double getCost() {
    if (level >= maxLevel) return double.infinity;
    return baseCost * pow(costMultiplier, level);
  }

  bool canBePurchased(double money, int playerLevel) {
    if (level >= maxLevel) return false;
    if (requiredLevel != null && playerLevel < requiredLevel!) return false;
    if (requirements != null) {
      // Vérifier les prérequis spécifiques
      for (var req in requirements!.entries) {
        if (req.value is int && req.value > (level)) return false;
      }
    }
    return money >= getCost();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'level': level,
  };

  factory Upgrade.fromJson(Map<String, dynamic> json) {
    var template = getUpgradeTemplate(json['id']);
    template.level = json['level'] ?? 0;
    return template;
  }

  static Upgrade getUpgradeTemplate(String id) {
    switch (id) {
      case 'efficiency':
        return Upgrade(
          id: 'efficiency',
          name: 'Efficacité',
          description: 'Réduit la consommation de métal',
          baseCost: 100,
          requiredLevel: 5,
        );
      case 'speed':
        return Upgrade(
          id: 'speed',
          name: 'Vitesse',
          description: 'Augmente la vitesse de production',
          baseCost: 150,
          requiredLevel: 5,
        );
      case 'quality':
        return Upgrade(
          id: 'quality',
          name: 'Qualité',
          description: 'Augmente le prix de vente',
          baseCost: 200,
          requiredLevel: 8,
        );
      case 'marketing':
        return Upgrade(
          id: 'marketing',
          name: 'Marketing',
          description: 'Améliore les ventes',
          baseCost: 250,
          requiredLevel: 8,
        );
      case 'bulk':
        return Upgrade(
          id: 'bulk',
          name: 'Production en masse',
          description: 'Augmente la production des autoclippeuses',
          baseCost: 300,
          requiredLevel: 10,
        );
      case 'storage':
        return Upgrade(
          id: 'storage',
          name: 'Stockage',
          description: 'Augmente la capacité de stockage',
          baseCost: 175,
          requiredLevel: 6,
        );
      default:
        throw Exception('Unknown upgrade ID: $id');
    }
  }
}

/// Gestionnaire des ressources du joueur
class PlayerManager extends ChangeNotifier {
  double _metal = GameConstants.INITIAL_METAL;
  double _money = GameConstants.INITIAL_MONEY;
  double _paperclips = 0;
  int _autoclippers = 0;
  double _sellPrice = GameConstants.INITIAL_PRICE;
  Map<String, Upgrade> upgrades = {};

  final LevelSystem levelSystem;
  Timer? _maintenanceTimer;
  Timer? _autoSaveTimer;
  double _maintenanceCosts = 0.0;

  PlayerManager(this.levelSystem) {
    _initializeUpgrades();
    _startTimers();
  }

  // Getters
  double get metal => _metal;
  double get money => _money;
  double get paperclips => _paperclips;
  int get autoclippers => _autoclippers;
  double get sellPrice => _sellPrice;
  double get maintenanceCosts => _maintenanceCosts;

  // Setters avec validation
  set metal(double value) {
    if (value != _metal) {
      _metal = value;
      notifyListeners();
    }
  }

  set money(double value) {
    if (value != _money) {
      _money = value;
      notifyListeners();
    }
  }

  set paperclips(double value) {
    if (value != _paperclips) {
      _paperclips = value;
      notifyListeners();
    }
  }

  set sellPrice(double value) {
    double clampedValue = value.clamp(
        GameConstants.MIN_PRICE,
        GameConstants.MAX_PRICE
    );
    if (clampedValue != _sellPrice) {
      _sellPrice = clampedValue;
      notifyListeners();
    }
  }

  void _initializeUpgrades() {
    final upgradeIds = [
      'efficiency', 'speed', 'quality',
      'marketing', 'bulk', 'storage'
    ];

    for (var id in upgradeIds) {
      upgrades[id] = Upgrade.getUpgradeTemplate(id);
    }
  }

  void _startTimers() {
    _maintenanceTimer?.cancel();
    _autoSaveTimer?.cancel();

    _maintenanceTimer = Timer.periodic(
        const Duration(minutes: 1),
            (_) => _applyMaintenanceCosts()
    );

    _autoSaveTimer = Timer.periodic(
        const Duration(minutes: 5),
            (_) => _triggerAutoSave()
    );
  }

  bool canAffordUpgrade(String upgradeId) {
    final upgrade = upgrades[upgradeId];
    if (upgrade == null) return false;
    return upgrade.canBePurchased(_money, levelSystem.level);
  }

  bool purchaseUpgrade(String upgradeId) {
    final upgrade = upgrades[upgradeId];
    if (upgrade == null || !canAffordUpgrade(upgradeId)) return false;

    double cost = upgrade.getCost();
    _money -= cost;
    upgrade.level++;

    levelSystem.addUpgradePurchase(upgrade.level);

    if (upgrade.level == upgrade.maxLevel) {
      EventManager.instance.addEvent(
          EventType.UPGRADE_AVAILABLE,
          "Amélioration maximale !",
          description: "${upgrade.name} a atteint son niveau maximum",
          importance: EventImportance.MEDIUM
      );
    }

    notifyListeners();
    return true;
  }

  bool canBuyAutoclipper() {
    double cost = calculateAutoclipperCost();
    return _money >= cost;
  }

  double calculateAutoclipperCost() {
    return GameConstants.BASE_AUTOCLIPPER_COST *
        pow(1.1, _autoclippers);
  }

  bool purchaseAutoclipper() {
    double cost = calculateAutoclipperCost();
    if (_money < cost) return false;

    _money -= cost;
    _autoclippers++;
    levelSystem.addAutoclipperPurchase();
    notifyListeners();
    return true;
  }

  void _applyMaintenanceCosts() {
    if (_autoclippers == 0) return;

    _maintenanceCosts = _autoclippers *
        GameConstants.STORAGE_MAINTENANCE_RATE;

    if (_money >= _maintenanceCosts) {
      _money -= _maintenanceCosts;
      notifyListeners();
    } else {
      // Pénalité pour maintenance impayée
      _autoclippers = (_autoclippers * 0.9).floor();
      EventManager.instance.addEvent(
          EventType.RESOURCE_DEPLETION,
          "Maintenance impayée !",
          description: "Certaines autoclippeuses sont hors service",
          importance: EventImportance.HIGH
      );
      notifyListeners();
    }
  }

  void _triggerAutoSave() {
    // Implémenter la logique de sauvegarde automatique ici
  }

  Map<String, dynamic> toJson() => {
    'metal': _metal,
    'money': _money,
    'paperclips': _paperclips,
    'autoclippers': _autoclippers,
    'sellPrice': _sellPrice,
    'upgrades': upgrades.map((key, value) => MapEntry(key, value.toJson())),
  };

  void loadFromJson(Map<String, dynamic> json) {
    _metal = (json['metal'] as num?)?.toDouble() ?? GameConstants.INITIAL_METAL;
    _money = (json['money'] as num?)?.toDouble() ?? GameConstants.INITIAL_MONEY;
    _paperclips = (json['paperclips'] as num?)?.toDouble() ?? 0;
    _autoclippers = (json['autoclippers'] as num?)?.toInt() ?? 0;
    _sellPrice = (json['sellPrice'] as num?)?.toDouble() ??
        GameConstants.INITIAL_PRICE;

    if (json['upgrades'] != null) {
      final upgradesJson = json['upgrades'] as Map<String, dynamic>;
      upgradesJson.forEach((key, value) {
        upgrades[key] = Upgrade.fromJson(value as Map<String, dynamic>);
      });
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _maintenanceTimer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}