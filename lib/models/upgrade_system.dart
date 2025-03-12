import 'package:flutter/foundation.dart';
import 'dart:math';
import 'game_config.dart';

/// Classe représentant une amélioration individuelle
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
      // Vérifier les prérequis spécifiques
      for (var req in requirements!.entries) {
        if (req.key.startsWith('upgrade_') && req.value is int) {
          String upgradeId = req.key.substring(8);
          int requiredLevel = req.value as int;
          // Cette vérification sera effectuée par UpgradeSystem
          // en passant l'objet Upgrade à canBePurchased
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

/// Gestionnaire centralisé pour les améliorations
class UpgradeSystem extends ChangeNotifier {
  // Catégories d'améliorations
  static const String CATEGORY_PRODUCTION = 'production';
  static const String CATEGORY_STORAGE = 'storage';
  static const String CATEGORY_MARKET = 'market';
  static const String CATEGORY_AUTOMATION = 'automation';
  static const String CATEGORY_SPECIAL = 'special';

  // Liste des améliorations disponibles
  final Map<String, Upgrade> _upgrades = {};
  
  // Getters
  Map<String, Upgrade> get upgrades => _upgrades;
  
  // Constructeur
  UpgradeSystem() {
    _initialize();
  }
  
  void _initialize() {
    // Créer toutes les améliorations disponibles
    _createUpgrades();
  }
  
  void _createUpgrades() {
    // Améliorations de production
    _addUpgrade(Upgrade(
      id: 'production_efficiency',
      name: 'Efficacité de Production',
      description: 'Réduit la consommation de métal par trombone',
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
      name: 'Qualité des Trombones',
      description: 'Augmente le prix de vente des trombones',
      category: CATEGORY_PRODUCTION,
      baseCost: 200,
      requiredLevel: 5,
    ));
    
    // Améliorations de stockage
    _addUpgrade(Upgrade(
      id: 'storage_capacity',
      name: 'Capacité de Stockage',
      description: 'Augmente la capacité de stockage du métal',
      category: CATEGORY_STORAGE,
      baseCost: 120,
      requiredLevel: 2,
    ));
    
    _addUpgrade(Upgrade(
      id: 'storage_efficiency',
      name: 'Efficacité de Stockage',
      description: 'Améliore l\'efficacité du stockage du métal',
      category: CATEGORY_STORAGE,
      baseCost: 180,
      requiredLevel: 4,
    ));
    
    // Améliorations de marché
    _addUpgrade(Upgrade(
      id: 'market_intelligence',
      name: 'Intelligence de Marché',
      description: 'Améliore les informations sur le marché',
      category: CATEGORY_MARKET,
      baseCost: 250,
      requiredLevel: 6,
    ));
    
    _addUpgrade(Upgrade(
      id: 'market_negotiation',
      name: 'Négociation',
      description: 'Améliore les prix d\'achat et de vente',
      category: CATEGORY_MARKET,
      baseCost: 300,
      requiredLevel: 7,
    ));
    
    // Améliorations d'automatisation
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
    
    // Améliorations spéciales
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
  
  // Obtenir une amélioration par ID
  Upgrade? getUpgrade(String id) {
    return _upgrades[id];
  }
  
  // Obtenir toutes les améliorations d'une catégorie
  List<Upgrade> getUpgradesByCategory(String category) {
    return _upgrades.values
        .where((upgrade) => upgrade.category == category && upgrade.isVisible)
        .toList();
  }
  
  // Vérifier si une amélioration peut être achetée
  bool canPurchaseUpgrade(String id, double money, int playerLevel) {
    Upgrade? upgrade = getUpgrade(id);
    if (upgrade == null) return false;
    
    if (!_checkUpgradeRequirements(upgrade)) return false;
    
    return upgrade.canBePurchased(money, playerLevel);
  }
  
  // Vérifier les prérequis d'une amélioration
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
  
  // Acheter une amélioration
  bool purchaseUpgrade(String id, double money) {
    Upgrade? upgrade = getUpgrade(id);
    if (upgrade == null) return false;
    
    double cost = upgrade.getCost();
    if (money < cost) return false;
    
    upgrade.level++;
    
    // Vérifier si de nouvelles améliorations doivent être débloquées
    _checkForUnlocks();
    
    notifyListeners();
    return true;
  }
  
  // Vérifier si de nouvelles améliorations doivent être débloquées
  void _checkForUnlocks() {
    for (var upgrade in _upgrades.values) {
      if (!upgrade.isVisible && _checkUpgradeRequirements(upgrade)) {
        upgrade.isVisible = true;
        upgrade.isUnlocked = true;
      }
    }
  }
  
  // Obtenir le niveau d'une amélioration
  int getUpgradeLevel(String id) {
    Upgrade? upgrade = getUpgrade(id);
    return upgrade?.level ?? 0;
  }
  
  // Obtenir le coût de la prochaine amélioration
  double getNextUpgradeCost(String id) {
    Upgrade? upgrade = getUpgrade(id);
    return upgrade?.getCost() ?? double.infinity;
  }
  
  // Réinitialiser le système d'améliorations
  void reset() {
    for (var upgrade in _upgrades.values) {
      upgrade.level = 0;
      upgrade.isVisible = upgrade.requiredLevel == null && upgrade.requirements == null;
      upgrade.isUnlocked = upgrade.requiredLevel == null && upgrade.requirements == null;
    }
    notifyListeners();
  }
  
  // Sérialisation
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    for (var upgrade in _upgrades.values) {
      json[upgrade.id] = upgrade.toJson();
    }
    return json;
  }
  
  // Désérialisation
  void fromJson(Map<String, dynamic> json) {
    // Réinitialiser d'abord
    for (var upgrade in _upgrades.values) {
      upgrade.level = 0;
      upgrade.isVisible = upgrade.requiredLevel == null && upgrade.requirements == null;
      upgrade.isUnlocked = upgrade.requiredLevel == null && upgrade.requirements == null;
    }
    
    // Charger les données sauvegardées
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