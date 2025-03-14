import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:async';
import 'package:paperclip2/constants/game_constants.dart';
import 'package:paperclip2/services/event_manager.dart';
import 'package:paperclip2/models/event_type.dart';
import 'package:paperclip2/models/event_importance.dart';

import '../../domain/services/event_manager.dart';
import 'event_system.dart';
import 'game_config.dart';
import 'market.dart';
import 'progression_system.dart';
import 'resource_manager.dart';



// lib/models/player_manager.dart

/// ReprÃ©sente une amÃ©lioration du jeu
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
      // VÃ©rifier les prÃ©requis spÃ©cifiques
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
          name: 'EfficacitÃ©',
          description: 'RÃ©duit la consommation de mÃ©tal',
          baseCost: 100,
          requiredLevel: 5,
          maxLevel: 8,
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
          name: 'QualitÃ©',
          description: 'Augmente le prix de vente',
          baseCost: 200,
          requiredLevel: 8,
        );
      case 'marketing':
        return Upgrade(
          id: 'marketing',
          name: 'Marketing',
          description: 'AmÃ©liore les ventes',
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
          description: 'Augmente la capacitÃ© de stockage',
          baseCost: 175,
          requiredLevel: 6,
        );
    // Ajout du cas pour 'automation'
      case 'automation':
        return Upgrade(
          id: 'automation',
          name: 'Automation',
          description: 'RÃ©duit le coÃ»t des autoclippeuses de 10%',
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
  double _paperclips = 0.0;
  double _metal = 100.0;
  double _money = 0.0;
  int _autoclippers = 0;
  double _sellPrice = 0.25;
  double autoclipperPaperclips = 0; // Pour suivre les trombones produits par les autoclippers
  final ResourceManager resourceManager;
  final MarketManager marketManager;
  final LevelSystem levelSystem;
  double maxMetalStorage = GameConstants.INITIAL_STORAGE_CAPACITY;
  bool _lowMetalNotified = false;
  static const double LOW_METAL_THRESHOLD = 20.0;





  // Getters
  double get metal => _metal;
  double get paperclips => _paperclips;
  double get money => _money;
  int get autoclippers => _autoclippers;
  double get sellPrice => _sellPrice;
  // Getters
  Map<String, Upgrade> get upgrades => _upgrades;


  Timer? _maintenanceTimer;
  Timer? _autoSaveTimer;
  double _maintenanceCosts = 0.0;
  PlayerManager({
    required this.levelSystem,
    required this.resourceManager,
    required this.marketManager,
  }) {
    _initializeUpgrades();
    _startTimers();
  }

  // Getters
  double get maintenanceCosts => _maintenanceCosts;





  final Map<String, Upgrade> _upgrades = {
    'efficiency': Upgrade(
      id: 'efficiency',
      name: 'EfficacitÃ©',
      description: 'RÃ©duit la consommation de mÃ©tal de 11% par niveau',
      baseCost: GameConstants.EFFICIENCY_UPGRADE_BASE,
      costMultiplier: 1.5,
      maxLevel: GameConstants.MAX_EFFICIENCY_LEVEL,
      requiredLevel: 5,
    ),

    'marketing': Upgrade(
      id: "marketing",
      name: 'Marketing',
      description: 'Augmente la demande du marchÃ© de 30 %',
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
      description: 'Augmente la capacitÃ© de stockage de mÃ©tal de 50 %',
      baseCost: 60.0,
      maxLevel: 5,
    ),
    'automation': Upgrade(
      id: "automation",
      name: 'Automation',
      description: 'RÃ©duit le coÃ»t des autoclippeuses de 10 % par niveau',
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

  void _updateProductionMultiplier() {
    // Utiliser getProductionMultiplier qui existe dÃ©jÃ 
    double multiplier = getProductionMultiplier();
    // Mettre Ã  jour la production des autoclippeuses
    autoclipperPaperclips = _autoclippers * GameConstants.BASE_AUTOCLIPPER_PRODUCTION * multiplier;
    notifyListeners();
  }
  void updateMaxMetalStorage(double newCapacity) {
    maxMetalStorage = newCapacity;
    notifyListeners();
  }

  double calculateAutoclipperROI() {
    double cost = calculateAutoclipperCost();
    double revenuePerSecond = GameConstants.BASE_AUTOCLIPPER_PRODUCTION * _sellPrice;
    // Si pas de revenu, retourner une valeur infinie
    if (revenuePerSecond <= 0) return double.infinity;
    // Retourner le temps en secondes pour rentabiliser l'investissement
    return cost / revenuePerSecond;
  }



  // Dans lib/models/player_manager.dart
  void fromJson(Map<String, dynamic> json) {
    _paperclips = (json['paperclips'] as num?)?.toDouble() ?? 0.0;
    _money = (json['money'] as num?)?.toDouble() ?? 0.0;
    _metal = (json['metal'] as num?)?.toDouble() ?? 0.0;
    _autoclippers = (json['autoclippers'] as num?)?.toInt() ?? 0;
    _sellPrice = (json['sellPrice'] as num?)?.toDouble() ?? GameConstants.INITIAL_PRICE;

    // RÃ©initialiser d'abord les upgrades
    _initializeUpgrades();

    // Charger les upgrades
    final upgradesData = json['upgrades'] as Map<String, dynamic>? ?? {};
    upgradesData.forEach((key, value) {
      if (_upgrades.containsKey(key)) {
        _upgrades[key]!.level = (value['level'] as num?)?.toInt() ?? 0;

        // Mise Ã  jour immÃ©diate des effets des amÃ©liorations
        if (key == 'storage') {
          double newCapacity = GameConstants.INITIAL_STORAGE_CAPACITY *
              (1 + (_upgrades[key]!.level * GameConstants.STORAGE_UPGRADE_MULTIPLIER));
          maxMetalStorage = newCapacity;
          resourceManager.upgradeStorageCapacity(_upgrades[key]!.level);
        }
      }
    });

    notifyListeners();
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

    // Application des effets des amÃ©liorations
    switch (upgradeId) {
      case 'storage':
        resourceManager.upgradeStorageCapacity(upgrade.level);
        // Mise Ã  jour de la capacitÃ© de stockage locale
        updateMaxMetalStorage(GameConstants.INITIAL_STORAGE_CAPACITY *
            (1 + (upgrade.level * GameConstants.STORAGE_UPGRADE_MULTIPLIER)));
        break;
      case 'efficiency':
        resourceManager.improveStorageEfficiency(upgrade.level);
        break;
      case 'bulk':
        _updateProductionMultiplier();
        break;
      case 'marketing':
        marketManager.updateMarketingBonus(upgrade.level);
        break;
    }

    levelSystem.addUpgradePurchase(upgrade.level);

    if (upgrade.level == upgrade.maxLevel) {
      EventManager().addEvent(
          EventType.UPGRADE_AVAILABLE,
          "AmÃ©lioration maximale !",
          description: "${upgrade.name} a atteint son niveau maximum",
          importance: EventImportance.MEDIUM
      );
    }

    notifyListeners();
    return true;
  }
  double getProductionMultiplier() {
    double bulkBonus = (upgrades['bulk']?.level ?? 0) * GameConstants.BULK_UPGRADE_BASE;
    return 1.0 + bulkBonus;
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
      EventManager().addEvent(
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
      _metal = newAmount.clamp(0, maxMetalStorage);

      // Check pour notification de stock bas
      if (_metal <= LOW_METAL_THRESHOLD && !_lowMetalNotified) {
        _lowMetalNotified = true;
        EventManager().addEvent(
            EventType.RESOURCE_DEPLETION,
            'Stock Personnel Bas',
            description: 'Votre stock de métal est inférieur à 20 unités',
            importance: EventImportance.MEDIUM
        );
      } else if (_metal > LOW_METAL_THRESHOLD) {
        _lowMetalNotified = false;
      }

      notifyListeners();
    }
  }


  void updateMoney(double newAmount) {
    if (_money != newAmount) {
      _money = newAmount;
      notifyListeners();
    }
  }

  // MÃ©thode pour ajouter de l'argent au joueur
  void addMoney(double amount) {
    if (amount > 0) {
      _money += amount;
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
    try {
      // CrÃ©ation de l'objet de sauvegarde
      final saveData = {
        'playerData': toJson(),
        'timestamp': DateTime.now().toIso8601String(),
        'upgrades': _upgrades.map((key, value) => MapEntry(key, value.toJson())),
        'resources': {
          'metal': _metal,
          'paperclips': _paperclips,
          'money': _money,
          'autoclippers': _autoclippers,
          'sellPrice': _sellPrice,
        }
      };

      // Enregistrer dans les prÃ©fÃ©rences partagÃ©es ou le stockage local
      // Note: Nous devons implÃ©menter cette partie selon le systÃ¨me de stockage utilisÃ©
      _saveToStorage(saveData);

      // Notification de sauvegarde rÃ©ussie
      EventManager().addEvent(
        EventType.INFO,
        "Sauvegarde Automatique",
        description: "Partie sauvegardÃ©e avec succÃ¨s",
        importance: EventImportance.LOW,
      );
    } catch (e) {
      print('Erreur lors de la sauvegarde automatique: $e');
      EventManager().addEvent(
        EventType.INFO,
        "Erreur de Sauvegarde",
        description: "La sauvegarde automatique a Ã©chouÃ©",
        importance: EventImportance.HIGH,
      );
    }
  }

// MÃ©thode Ã  implÃ©menter pour le stockage effectif des donnÃ©es
  Future<void> _saveToStorage(Map<String, dynamic> data) async {
    // TODO: ImplÃ©menter la logique de stockage
    // Cette mÃ©thode devrait Ãªtre implÃ©mentÃ©e selon le systÃ¨me de stockage choisi
    // (SharedPreferences, Hive, SQLite, etc.)
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

class Player {
  String name;
  int score;

  Player({required this.name, required this.score});

  String getName() {
    return name;
  }

  int getScore() {
    return score;
  }
}






