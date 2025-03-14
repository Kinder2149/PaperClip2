import 'package:flutter/foundation.dart';

import 'game_config.dart';




/// Classe reprÃ©sentant une amÃ©lioration individuelle
class Upgrade {
  final String id;
  final String name;
  final String description;
  final String category;
  final double baseCost;
  final double costMultiplier;
  final int maxLevel;
  final int? requiredLevel;
  final Map<String, dynamic>? requirements;
  int level;
  bool isVisible;
  bool isUnlocked;

  Upgrade({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.baseCost,
    this.costMultiplier = 1.5,
    this.maxLevel = 10,
    this.requiredLevel,
    this.requirements,
    this.level = 0,
    this.isVisible = true,
    this.isUnlocked = true,
  });

  double getCost() {
    if (level >= maxLevel) return double.infinity;
    return baseCost * pow(costMultiplier, level);
  }

  bool canBePurchased(double money, int playerLevel) {
    if (level >= maxLevel) return false;
    if (!isUnlocked) return false;
    if (requiredLevel != null && playerLevel < requiredLevel!) return false;
    if (requirements != null) {
      // VÃ©rifier les prÃ©requis spÃ©cifiques
      for (var req in requirements!.entries) {
        if (req.key.startsWith('upgrade_') && req.value is int) {
          String upgradeId = req.key.substring(8);
          int requiredLevel = req.value as int;
          // Cette vÃ©rification sera effectuÃ©e par UpgradeSystem
          // en passant l'objet Upgrade Ã  canBePurchased
        }
      }
    }
    return money >= getCost();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'level': level,
    'isVisible': isVisible,
    'isUnlocked': isUnlocked,
  };

  factory Upgrade.fromJson(Map<String, dynamic> json, Upgrade template) {
    template.level = json['level'] ?? 0;
    template.isVisible = json['isVisible'] ?? true;
    template.isUnlocked = json['isUnlocked'] ?? true;
    return template;
  }
}

/// Gestionnaire centralisÃ© pour les amÃ©liorations
class UpgradeSystem extends ChangeNotifier {
  // CatÃ©gories d'amÃ©liorations
  static const String CATEGORY_PRODUCTION = 'production';
  static const String CATEGORY_STORAGE = 'storage';
  static const String CATEGORY_MARKET = 'market';
  static const String CATEGORY_AUTOMATION = 'automation';
  static const String CATEGORY_SPECIAL = 'special';

  // Liste des amÃ©liorations disponibles
  final Map<String, Upgrade> _upgrades = {};
  
  // Getters
  Map<String, Upgrade> get upgrades => _upgrades;
  
  // Constructeur
  UpgradeSystem() {
    _initialize();
  }
  
  void _initialize() {
    // CrÃ©er toutes les amÃ©liorations disponibles
    _createUpgrades();
  }
  
  void _createUpgrades() {
    // AmÃ©liorations de production
    _addUpgrade(Upgrade(
      id: 'production_efficiency',
      name: 'EfficacitÃ© de Production',
      description: 'RÃ©duit la consommation de mÃ©tal par trombone',
      category: CATEGORY_PRODUCTION,
      baseCost: 100,
      requiredLevel: 2,
    ));
    
    _addUpgrade(Upgrade(
      id: 'production_speed',
      name: 'Vitesse de Production',
      description: 'Augmente la vitesse de production des trombones',
      category: CATEGORY_PRODUCTION,
      baseCost: 150,
      requiredLevel: 3,
    ));
    
    _addUpgrade(Upgrade(
      id: 'production_quality',
      name: 'QualitÃ© des Trombones',
      description: 'Augmente le prix de vente des trombones',
      category: CATEGORY_PRODUCTION,
      baseCost: 200,
      requiredLevel: 5,
    ));
    
    // AmÃ©liorations de stockage
    _addUpgrade(Upgrade(
      id: 'storage_capacity',
      name: 'CapacitÃ© de Stockage',
      description: 'Augmente la capacitÃ© de stockage du mÃ©tal',
      category: CATEGORY_STORAGE,
      baseCost: 120,
      requiredLevel: 2,
    ));
    
    _addUpgrade(Upgrade(
      id: 'storage_efficiency',
      name: 'EfficacitÃ© de Stockage',
      description: 'AmÃ©liore l\'efficacitÃ© du stockage du mÃ©tal',
      category: CATEGORY_STORAGE,
      baseCost: 180,
      requiredLevel: 4,
    ));
    
    // AmÃ©liorations de marchÃ©
    _addUpgrade(Upgrade(
      id: 'market_intelligence',
      name: 'Intelligence de MarchÃ©',
      description: 'AmÃ©liore les informations sur le marchÃ©',
      category: CATEGORY_MARKET,
      baseCost: 250,
      requiredLevel: 6,
    ));
    
    _addUpgrade(Upgrade(
      id: 'market_negotiation',
      name: 'NÃ©gociation',
      description: 'AmÃ©liore les prix d\'achat et de vente',
      category: CATEGORY_MARKET,
      baseCost: 300,
      requiredLevel: 7,
    ));
    
    // AmÃ©liorations d'automatisation
    _addUpgrade(Upgrade(
      id: 'automation_basic',
      name: 'Automatisation de Base',
      description: 'Permet la production automatique de trombones',
      category: CATEGORY_AUTOMATION,
      baseCost: 500,
      requiredLevel: 10,
      maxLevel: 1,
    ));
    
    _addUpgrade(Upgrade(
      id: 'automation_speed',
      name: 'Vitesse d\'Automatisation',
      description: 'Augmente la vitesse de production automatique',
      category: CATEGORY_AUTOMATION,
      baseCost: 750,
      requiredLevel: 12,
      requirements: {'upgrade_automation_basic': 1},
      isVisible: false,
      isUnlocked: false,
    ));
    
    // AmÃ©liorations spÃ©ciales
    _addUpgrade(Upgrade(
      id: 'special_marketing',
      name: 'Campagne Marketing',
      description: 'Augmente la demande de trombones',
      category: CATEGORY_SPECIAL,
      baseCost: 1000,
      requiredLevel: 15,
    ));
  }
  
  void _addUpgrade(Upgrade upgrade) {
    _upgrades[upgrade.id] = upgrade;
  }
  
  // Obtenir une amÃ©lioration par ID
  Upgrade? getUpgrade(String id) {
    return _upgrades[id];
  }
  
  // Obtenir toutes les amÃ©liorations d'une catÃ©gorie
  List<Upgrade> getUpgradesByCategory(String category) {
    return _upgrades.values
        .where((upgrade) => upgrade.category == category && upgrade.isVisible)
        .toList();
  }
  
  // VÃ©rifier si une amÃ©lioration peut Ãªtre achetÃ©e
  bool canPurchaseUpgrade(String id, double money, int playerLevel) {
    Upgrade? upgrade = getUpgrade(id);
    if (upgrade == null) return false;
    
    if (!_checkUpgradeRequirements(upgrade)) return false;
    
    return upgrade.canBePurchased(money, playerLevel);
  }
  
  // VÃ©rifier les prÃ©requis d'une amÃ©lioration
  bool _checkUpgradeRequirements(Upgrade upgrade) {
    if (upgrade.requirements == null) return true;
    
    for (var req in upgrade.requirements!.entries) {
      if (req.key.startsWith('upgrade_')) {
        String upgradeId = req.key.substring(8);
        int requiredLevel = req.value as int;
        
        Upgrade? requiredUpgrade = getUpgrade(upgradeId);
        if (requiredUpgrade == null || requiredUpgrade.level < requiredLevel) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  // Acheter une amÃ©lioration
  bool purchaseUpgrade(String id, double money) {
    Upgrade? upgrade = getUpgrade(id);
    if (upgrade == null) return false;
    
    double cost = upgrade.getCost();
    if (money < cost) return false;
    
    upgrade.level++;
    
    // VÃ©rifier si de nouvelles amÃ©liorations doivent Ãªtre dÃ©bloquÃ©es
    _checkForUnlocks();
    
    notifyListeners();
    return true;
  }
  
  // VÃ©rifier si de nouvelles amÃ©liorations doivent Ãªtre dÃ©bloquÃ©es
  void _checkForUnlocks() {
    for (var upgrade in _upgrades.values) {
      if (!upgrade.isVisible && _checkUpgradeRequirements(upgrade)) {
        upgrade.isVisible = true;
        upgrade.isUnlocked = true;
      }
    }
  }
  
  // Obtenir le niveau d'une amÃ©lioration
  int getUpgradeLevel(String id) {
    Upgrade? upgrade = getUpgrade(id);
    return upgrade?.level ?? 0;
  }
  
  // Obtenir le coÃ»t de la prochaine amÃ©lioration
  double getNextUpgradeCost(String id) {
    Upgrade? upgrade = getUpgrade(id);
    return upgrade?.getCost() ?? double.infinity;
  }
  
  // RÃ©initialiser le systÃ¨me d'amÃ©liorations
  void reset() {
    for (var upgrade in _upgrades.values) {
      upgrade.level = 0;
      upgrade.isVisible = upgrade.requiredLevel == null && upgrade.requirements == null;
      upgrade.isUnlocked = upgrade.requiredLevel == null && upgrade.requirements == null;
    }
    notifyListeners();
  }
  
  // SÃ©rialisation
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    for (var upgrade in _upgrades.values) {
      json[upgrade.id] = upgrade.toJson();
    }
    return json;
  }
  
  // DÃ©sÃ©rialisation
  void fromJson(Map<String, dynamic> json) {
    // RÃ©initialiser d'abord
    for (var upgrade in _upgrades.values) {
      upgrade.level = 0;
      upgrade.isVisible = upgrade.requiredLevel == null && upgrade.requirements == null;
      upgrade.isUnlocked = upgrade.requiredLevel == null && upgrade.requirements == null;
    }
    
    // Charger les donnÃ©es sauvegardÃ©es
    for (var entry in json.entries) {
      Upgrade? upgrade = getUpgrade(entry.key);
      if (upgrade != null && entry.value is Map<String, dynamic>) {
        upgrade.level = entry.value['level'] ?? 0;
        upgrade.isVisible = entry.value['isVisible'] ?? true;
        upgrade.isUnlocked = entry.value['isUnlocked'] ?? true;
      }
    }
    
    notifyListeners();
  }
}



