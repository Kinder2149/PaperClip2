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
    // Ajout du cas pour 'automation'
      case 'automation':
        return Upgrade(
          id: 'automation',
          name: 'Automation',
          description: 'Réduit le coût des autoclippeuses de 10%',
          baseCost: 200,
          requiredLevel: 7,
          costMultiplier: 1.5,
          maxLevel: 5,
        );
      default:
        throw Exception('Unknown upgrade ID: $id');
    }
  }
}
class UpgradeManager {
  static const List<String> VALID_UPGRADE_IDS = [
    'efficiency',
    'marketing',
    'bulk',
    'speed',
    'storage',
    'automation',
    'quality'
  ];

  static bool isValidUpgradeId(String id) {
    return VALID_UPGRADE_IDS.contains(id);
  }
}

/// Gestionnaire des ressources du joueur
class PlayerManager extends ChangeNotifier {
  double maxMetalStorage = 1000.0;
  double _paperclips = 0.0;
  double _metal = 100.0;
  double _money = 0.0;
  int _autoclippers = 0;
  double _sellPrice = 0.25;
  double autoclipperPaperclips = 0; // Pour suivre les trombones produits par les autoclippers


  // Getters
  double get metal => _metal;
  double get paperclips => _paperclips;
  double get money => _money;
  int get autoclippers => _autoclippers;
  double get sellPrice => _sellPrice;




  final Map<String, Upgrade> _upgrades = {
    'efficiency': Upgrade(
      id: "efficiency",
      name: 'Metal Efficiency',
      description: 'Réduit la consommation de métal de 15 %',
      baseCost: 45.0,
      maxLevel: 10,
    ),
    'marketing': Upgrade(
      id: "marketing",
      name: 'Marketing',
      description: 'Augmente la demande du marché de 30 %',
      baseCost: 75.0,
      maxLevel: 8,
    ),
    'bulk': Upgrade(
      id: "bulk",
      name: 'Bulk Production',
      description: 'Les autoclippeuses produisent 35 % plus vite',
      baseCost: 150.0,
      maxLevel: 8,
    ),
    'speed': Upgrade(
      id: "speed",
      name: 'Speed Boost',
      description: 'Augmente la vitesse de production de 20 %',
      baseCost: 100.0,
      maxLevel: 5,
    ),
    'storage': Upgrade(
      id: "storage",
      name: 'Storage Upgrade',
      description: 'Augmente la capacité de stockage de métal de 50 %',
      baseCost: 60.0,
      maxLevel: 5,
    ),
    'automation': Upgrade(
      id: "automation",
      name: 'Automation',
      description: 'Réduit le coût des autoclippeuses de 10 % par niveau',
      baseCost: 200.0,
      maxLevel: 5,
    ),
    'quality': Upgrade(
      id: "quality",
      name: 'Quality Control',
      description: 'Augmente le prix de vente des trombones de 10 % par niveau',
      baseCost: 80.0,
      maxLevel: 10,
    ),
  };


  // Getters
  Map<String, Upgrade> get upgrades => _upgrades;


  final LevelSystem levelSystem;
  Timer? _maintenanceTimer;
  Timer? _autoSaveTimer;
  double _maintenanceCosts = 0.0;


  void fromJson(Map<String, dynamic> json) {
    try {
      _paperclips = (json['paperclips'] as num?)?.toDouble() ?? 0.0;
      _money = (json['money'] as num?)?.toDouble() ?? 0.0;
      _metal = (json['metal'] as num?)?.toDouble() ?? 0.0;
      _autoclippers = (json['autoclippers'] as num?)?.toInt() ?? 0;
      _sellPrice = (json['sellPrice'] as num?)?.toDouble() ?? GameConstants.INITIAL_PRICE;

      // Réinitialiser d'abord les upgrades
      _initializeUpgrades();

      // Charger les upgrades
      final upgradesData = json['upgrades'] as Map<String, dynamic>? ?? {};
      upgradesData.forEach((key, value) {
        try {
          if (upgrades.containsKey(key)) {
            upgrades[key]!.level = (value['level'] as num?)?.toInt() ?? 0;
          }
        } catch (e) {
          print('Erreur lors du chargement de l\'upgrade $key: $e');
        }
      });

      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des données du joueur: $e');
      // En cas d'erreur, réinitialiser aux valeurs par défaut
      resetResources();
      _initializeUpgrades();
    }
  }
  bool consumeMetal(double amount) {
    if (_metal >= amount) {
      updateMetal(_metal - amount);
      return true;
    }
    return false;
  }


  Map<String, dynamic> toJson() => {
    'paperclips': _paperclips,
    'money': _money,
    'metal': _metal,
    'autoclippers': _autoclippers,
    'sellPrice': _sellPrice,
    'upgrades': upgrades.map((key, value) => MapEntry(key, value.toJson())),
  };

  void loadFromJson(Map<String, dynamic> json) => fromJson(json);

  PlayerManager(this.levelSystem) {
    _initializeUpgrades();
    _startTimers();
  }

  // Getters
  double get maintenanceCosts => _maintenanceCosts;



  void resetResources() {
    _metal = GameConstants.INITIAL_METAL;
    _money = GameConstants.INITIAL_MONEY;
    _paperclips = 0;
    _autoclippers = 0;
    _sellPrice = GameConstants.INITIAL_PRICE;
    notifyListeners();
  }



  void _initializeUpgrades() {
    final upgradeIds = [
      'efficiency',
      'speed',
      'quality',
      'marketing',
      'bulk',
      'storage',
      'automation'  // Ajout de 'automation' ici
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
    double baseCost = GameConstants.BASE_AUTOCLIPPER_COST;
    double automationDiscount = 1.0 - ((upgrades['automation']?.level ?? 0) * 0.10);
    return baseCost * pow(1.1, _autoclippers) * automationDiscount;
  }

  bool purchaseAutoclipper() {
    double cost = calculateAutoclipperCost();
    if (_money < cost) return false;

    _money -= cost;
    _autoclippers++;
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
  void updateMetal(double newAmount) {
    if (_metal != newAmount) {
      print('Metal update: $_metal -> $newAmount');
      _metal = newAmount.clamp(0, maxMetalStorage);
      notifyListeners();
    }
  }


  void updateMoney(double newAmount) {
    if (_money != newAmount) {
      _money = newAmount;
      notifyListeners();
    }
  }

  void updatePaperclips(double newAmount) {
    if (_paperclips != newAmount) {
      _paperclips = newAmount;
      notifyListeners();
    }
  }

  void updateAutoclippers(int newAmount) {
    if (_autoclippers != newAmount) {
      _autoclippers = newAmount;
      notifyListeners();
    }
  }


  void updateSellPrice(double newPrice) {
    if (_sellPrice != newPrice) {
      _sellPrice = newPrice;
      notifyListeners();
    }
  }

  void _triggerAutoSave() {
    // Implémenter la logique de sauvegarde automatique ici
  }

  void updateUpgrade(String id, int level) {
    if (upgrades.containsKey(id)) {
      upgrades[id]!.level = level;
      notifyListeners();
    }
  }
  int getMarketingLevel() {
    return upgrades['marketing']?.level ?? 0;
  }



  @override
  void dispose() {
    _maintenanceTimer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}