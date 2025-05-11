// lib/models/player_manager.dart

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'game_config.dart';
import 'event_system.dart';
import 'progression_system.dart';
import 'market.dart';
import 'package:paperclip2/managers/metal_manager.dart';
import 'game_state.dart';


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
  final GameState _gameState;

  double _money = 0.0;
  double _sellPrice = 0.25;

  final LevelSystem levelSystem;
  final MarketManager marketManager;
  final MetalManager metalManager;
  double maxMetalStorage = GameConstants.INITIAL_STORAGE_CAPACITY;
  bool _lowMetalNotified = false;
  static const double LOW_METAL_THRESHOLD = 20.0;

  // Getters
  double get money => _money;
  double get sellPrice => _sellPrice;
  Map<String, Upgrade> get upgrades => _upgrades;
  MetalManager get resourceManager => metalManager;

  // Getters de redirection vers ProductionManager
  double get paperclips => _gameState.productionManager.paperclips;
  int get autoclippers => _gameState.productionManager.autoclippers;

  Timer? _maintenanceTimer;
  Timer? _autoSaveTimer;
  double _maintenanceCosts = 0.0;

  PlayerManager({
    required GameState gameState, // Ajouter ce paramètre
    required this.levelSystem,
    required this.metalManager,
    required this.marketManager,
  }) : _gameState = gameState {  // Initialiser la référence à GameState
    _initializeUpgrades();
    _startTimers();
  }

  // Getters
  double get maintenanceCosts => _maintenanceCosts;
  double get metal => metalManager.metal;

  final Map<String, Upgrade> _upgrades = {
    'efficiency': Upgrade(
      id: 'efficiency',
      name: 'Efficacité',
      description: 'Réduit la consommation de métal de 11% par niveau',
      baseCost: GameConstants.EFFICIENCY_UPGRADE_BASE,
      costMultiplier: 1.5,
      maxLevel: GameConstants.MAX_EFFICIENCY_LEVEL,
      requiredLevel: 5,
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

  Map<String, dynamic> toJson() => {
    'money': _money,
    'sellPrice': _sellPrice,
    'upgrades': upgrades.map((key, value) => MapEntry(key, value.toJson())),
  };
// Méthode pour rediriger vers ProductionManager
  void updateAutoclippers(int newAmount) {
    _gameState.productionManager.updateAutoclippers(newAmount);
  }

  void updatePaperclips(double newAmount) {
    _gameState.productionManager.updatePaperclips(newAmount);
  }
  double calculateAutoclipperCost() {
    return _gameState.productionManager.calculateAutoclipperCost();
  }

  bool purchaseAutoclipper() {
    return _gameState.productionManager.buyAutoclipper(
        _money,
            (newMoney) => updateMoney(newMoney)
    );
  }

  void fromJson(Map<String, dynamic> json) {
    _money = (json['money'] as num?)?.toDouble() ?? 0.0;
    _sellPrice = (json['sellPrice'] as num?)?.toDouble() ?? GameConstants.INITIAL_PRICE;

    // Réinitialiser d'abord les upgrades
    _initializeUpgrades();

    // Charger les upgrades
    final upgradesData = json['upgrades'] as Map<String, dynamic>? ?? {};
    upgradesData.forEach((key, value) {
      if (_upgrades.containsKey(key)) {
        _upgrades[key]!.level = (value['level'] as num?)?.toInt() ?? 0;

        // Mise à jour immédiate des effets des améliorations
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

  void resetResources() {
    _money = GameConstants.INITIAL_MONEY;
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
      'automation'
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

    // Application des effets des améliorations
    switch (upgradeId) {
      case 'storage':
        resourceManager.upgradeStorageCapacity(upgrade.level);
        // Mise à jour de la capacité de stockage locale
        updateMaxMetalStorage(GameConstants.INITIAL_STORAGE_CAPACITY *
            (1 + (upgrade.level * GameConstants.STORAGE_UPGRADE_MULTIPLIER)));
        break;
      case 'efficiency':
        resourceManager.improveStorageEfficiency(upgrade.level);
        break;
    }

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


// Ajouter cette méthode pour la compatibilité
  void loadFromJson(Map<String, dynamic> json) {
    fromJson(json);
  }

  // Ajout des méthodes manquantes
  void updateMaxMetalStorage(double newCapacity) {
    maxMetalStorage = newCapacity;
    notifyListeners();
  }

  void _applyMaintenanceCosts() {
    // Méthode désormais gérée par ProductionManager
    // Cette méthode reste ici comme stub pour éviter les erreurs
    _maintenanceCosts = 0.0;
    notifyListeners();
  }

  void updateMoney(double newAmount) {
    if (_money != newAmount) {
      _money = newAmount;
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
      // Création de l'objet de sauvegarde
      final saveData = {
        'playerData': toJson(),
        'timestamp': DateTime.now().toIso8601String(),
        'upgrades': _upgrades.map((key, value) => MapEntry(key, value.toJson())),
        'resources': {
          'money': _money,
          'sellPrice': _sellPrice,
        }
      };

      // Enregistrer dans les préférences partagées ou le stockage local
      _saveToStorage(saveData);

      // Notification de sauvegarde réussie
      EventManager.instance.addEvent(
        EventType.INFO,
        "Sauvegarde Automatique",
        description: "Partie sauvegardée avec succès",
        importance: EventImportance.LOW,
      );
    } catch (e) {
      print('Erreur lors de la sauvegarde automatique: $e');
      EventManager.instance.addEvent(
        EventType.INFO,
        "Erreur de Sauvegarde",
        description: "La sauvegarde automatique a échoué",
        importance: EventImportance.HIGH,
      );
    }
  }

  Future<void> _saveToStorage(Map<String, dynamic> data) async {
    // TODO: Implémenter la logique de stockage
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