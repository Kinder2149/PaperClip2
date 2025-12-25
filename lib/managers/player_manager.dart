// lib/managers/player_manager.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import '../constants/game_config.dart'; // Mis à jour pour utiliser le dossier constants
import '../models/json_loadable.dart';
import '../models/game_state_interfaces.dart';
import '../models/upgrade.dart';
import '../services/upgrades/upgrade_effects_calculator.dart';
import '../services/units/value_objects.dart';

/// Manager pour les ressources et états du joueur
class PlayerManager extends ChangeNotifier implements JsonLoadable {
  // Ressources du joueur
  double _money = GameConstants.INITIAL_MONEY;
  double _paperclips = 0.0;
  // L'ancienne propriété '_wire' a été fusionnée avec '_metal'
  double _metal = GameConstants.INITIAL_METAL;
  int _trust = 0;
  double _processors = 0.0;
  double _memory = 0.0;
  
  // Stockage
  double _maxMetalStorage = GameConstants.INITIAL_STORAGE_CAPACITY;
  double _maintenanceCosts = 0.0;
  DateTime? _lastMaintenanceTime;
  Timer? _maintenanceTimer;
  
  // Stats et états
  double _sellPrice = GameConstants.INITIAL_PRICE;
  int _autoClipperCount = 0;
  int _megaClipperCount = 0;
  double _autoClipperCost = GameConstants.BASE_AUTOCLIPPER_COST;
  double _megaClipperCost = 30.0; // À définir dans GameConstants
  double _metalCost = 14.0; // À définir dans GameConstants
  int _metalPurchaseCount = 0;
  
  // Niveaux et upgrades
  double _productionSpeedMultiplier = 1.0;
  double _productionBatchSizeMultiplier = 1.0;
  bool _autoMetalBuyerEnabled = false;
  double _metalAutoBuyerLevel = 0;
  double _autoClipperLevel = 0;
  
  // Getters
  double get money => _money;
  double get paperclips => _paperclips;
  double get metal => _metal;
  double get sellPrice => _sellPrice;
  int get autoClipperCount => _autoClipperCount;
  int get megaClipperCount => _megaClipperCount;
  double get autoClipperCost => _autoClipperCost;
  double get megaClipperCost => _megaClipperCost;
  double get metalCost => _metalCost;
  int get metalPurchaseCount => _metalPurchaseCount;
  double get productionSpeedMultiplier => _productionSpeedMultiplier;
  double get productionBatchSizeMultiplier => _productionBatchSizeMultiplier;
  bool get autoMetalBuyerEnabled => _autoMetalBuyerEnabled;
  double get metalAutoBuyerLevel => _metalAutoBuyerLevel;
  double get autoClipperLevel => _autoClipperLevel;
  int get trust => _trust;
  double get processors => _processors;
  double get memory => _memory;
  
  // Getters pour les propriétés importantes
  double get maxMetalStorage => _maxMetalStorage;
  double get maintenanceCosts => _maintenanceCosts;
  
  // Total de trombones produits (statistique)
  double _totalPaperclips = 0.0;
  double get totalPaperclips => _totalPaperclips;
  
  // Getter pour les upgrades
  Map<String, Upgrade> get upgrades => _upgrades;
  
  // Getters et setters pour maintenance
  DateTime? get lastMaintenanceTime => _lastMaintenanceTime;
  set lastMaintenanceTime(DateTime? value) {
    _lastMaintenanceTime = value;
    notifyListeners();
  }
  
  Timer? get maintenanceTimer => _maintenanceTimer;
  
  // Map des améliorations
  final Map<String, Upgrade> _upgrades = {
    'efficiency': Upgrade(
      id: 'efficiency',
      name: 'Efficacité',
      description: 'Améliore l\'efficacité de production',
      baseCost: GameConstants.EFFICIENCY_UPGRADE_BASE,
      maxLevel: GameConstants.MAX_EFFICIENCY_LEVEL,
      requiredLevel: GameConstants.UPGRADES_UNLOCK_LEVEL,
    ),
    'speed': Upgrade(
      id: 'speed',
      name: 'Vitesse',
      description: 'Augmente la vitesse de production',
      baseCost: 25.0,
      maxLevel: 10,
      requiredLevel: GameConstants.UPGRADES_UNLOCK_LEVEL,
    ),
    'bulk': Upgrade(
      id: 'bulk',
      name: 'Production en masse',
      description: 'Augmente la quantité produite par opération',
      baseCost: 40.0,
      maxLevel: GameConstants.MAX_BULK_LEVEL,
      requiredLevel: GameConstants.UPGRADES_UNLOCK_LEVEL,
    ),
    'storage': Upgrade(
      id: 'storage',
      name: 'Stockage',
      description: 'Augmente la capacité de stockage de métal',
      baseCost: 30.0,
      maxLevel: GameConstants.MAX_STORAGE_LEVEL,
      requiredLevel: GameConstants.UPGRADES_UNLOCK_LEVEL,
    ),
    'quality': Upgrade(
      id: 'quality',
      name: 'Qualité',
      description: 'Améliore la qualité des trombones produits',
      baseCost: 50.0,
      maxLevel: 8,
      requiredLevel: GameConstants.UPGRADES_UNLOCK_LEVEL,
    ),
    'automation': Upgrade(
      id: 'automation',
      name: 'Automatisation',
      description: 'Réduit le coût des autoclippers',
      baseCost: 75.0,
      maxLevel: 5,
      requiredLevel: GameConstants.UPGRADES_UNLOCK_LEVEL,
    ),
    // --- Marché ---
    'marketing': Upgrade(
      id: 'marketing',
      name: 'Marketing',
      description: 'Augmente la demande du marché',
      baseCost: 60.0,
      maxLevel: 10,
      requiredLevel: GameConstants.UPGRADES_UNLOCK_LEVEL,
    ),
    'reputation': Upgrade(
      id: 'reputation',
      name: 'Réputation',
      description: 'Améliore la réputation et la demande',
      baseCost: 45.0,
      maxLevel: 10,
      requiredLevel: GameConstants.UPGRADES_UNLOCK_LEVEL,
    ),
    'marketResearch': Upgrade(
      id: 'marketResearch',
      name: 'Étude de marché',
      description: 'Réduit la volatilité du marché',
      baseCost: 70.0,
      maxLevel: 10,
      requiredLevel: GameConstants.UPGRADES_UNLOCK_LEVEL,
    ),
    'procurement': Upgrade(
      id: 'procurement',
      name: 'Négociation',
      description: 'Réduit le prix d\'achat du métal',
      baseCost: 55.0,
      maxLevel: 10,
      requiredLevel: GameConstants.UPGRADES_UNLOCK_LEVEL,
    ),
  };
  
  /// Met à jour le montant d'argent du joueur
  void updateMoney(double newValue) {
    if (newValue < 0) newValue = 0;
    _money = newValue;
    notifyListeners();
  }
  
  /// Ajoute ou soustrait de l'argent au joueur
  void addMoney(double amount) {
    _money += amount;
    if (_money < 0) _money = 0;
    notifyListeners();
  }
  
  /// Mise à jour du nombre de trombones du joueur
  void updatePaperclips(double newValue) {
    if (newValue < 0) newValue = 0;
    double added = newValue - _paperclips;
    if (added > 0) {
      _totalPaperclips += added;
    }
    _paperclips = newValue;
    notifyListeners();
  }
  
  /// Ajoute ou soustrait des trombones au joueur
  void addPaperclips(double amount) {
    _paperclips += amount;
    if (_paperclips < 0) _paperclips = 0;
    notifyListeners();
  }
  
  /// Met à jour la quantité de métal du joueur
  void updateMetal(double newValue) {
    if (newValue < 0) newValue = 0;
    if (newValue > _maxMetalStorage) newValue = _maxMetalStorage;
    _metal = newValue;
    notifyListeners();
  }
  
  /// Détermine si le joueur peut acheter un article au prix spécifié
  bool canAfford(double price) {
    return _money >= price;
  }
  
  /// Détermine si le joueur a suffisamment de métal pour produire des trombones
  bool hasEnoughMetal(double amount) {
    return _metal >= amount;
  }
  
  
  /// Reset complet des ressources principales (compatibilité avec l'ancien GameState)
  void resetResources() {
    _money = GameConstants.INITIAL_MONEY;
    _paperclips = 0.0;
    _metal = GameConstants.INITIAL_METAL;
    _maintenanceCosts = 0.0;
    notifyListeners();
  }
  
  /// Définit le prix de vente des trombones
  void setSellPrice(double price) {
    if (price < 0.01) price = 0.01;
    _sellPrice = price;
    notifyListeners();
  }
  
  /// Acheter un autoclip (machine automatique de fabrication)
  bool purchaseAutoClipper() {
    final cost = calculateAutoclipperCost();
    if (canAfford(cost)) {
      _autoClipperCount++;
      _money -= cost;
      if (_money < 0) _money = 0;
      // Conserver un mirroring pour compatibilité (UI/saves legacy),
      // la source de vérité est désormais le calcul dynamique.
      _autoClipperCost = calculateAutoclipperCost();
      notifyListeners();
      return true;
    }
    return false;
  }
  
  
  // Méthode supprimée: purchaseAutoclipper() (alias pour buyAutoClipper)
  
  /// Calcule le coût d'achat d'un autoclipper
  double calculateAutoclipperCost() {
    return UpgradeEffectsCalculator.autoclipperCost(
      autoclippersOwned: _autoClipperCount,
      automationLevel: _upgrades['automation']?.level ?? 0,
    );
  }
  
  /// Calcule le retour sur investissement (ROI) d'un autoclipper
  double calculateAutoclipperROI() {
    if (_autoClipperCount == 0) return 0.0;
    double cost = calculateAutoclipperCost();
    final productionPerMinute = UnitsPerSecond(
      _autoClipperCount * GameConstants.BASE_AUTOCLIPPER_PRODUCTION,
    ).toPerMinute().value;
    double sellPrice = _sellPrice;
    
    // Si le prix de vente est trop bas, le ROI sera négatif
    if (sellPrice < 0.05) return 0.0;
    
    double revenuePerMinute = productionPerMinute * sellPrice;
    double minutesToROI = cost / revenuePerMinute;
    
    // Conversion en pourcentage de ROI par minute
    return revenuePerMinute / cost * 100;
  }
  
  /// Met à jour le nombre d'autoclippers
  void updateAutoclippers(int count) {
    if (count < 0) count = 0;
    _autoClipperCount = count;
    notifyListeners();
  }
  
  /// Acheter un megaclip (machine de fabrication avancée)
  bool purchaseMegaClipper() {
    if (canAfford(_megaClipperCost)) {
      _megaClipperCount++;
      _money -= _megaClipperCost;
      if (_money < 0) _money = 0;
      // Augmenter le coût pour le prochain achat
      _megaClipperCost *= 1.1;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  /// Méthode de rétrocompatibilité qui redirige vers purchaseMegaClipper
  bool buyMegaClipper() {
    return purchaseMegaClipper();
  }
  
  /// Retourne le niveau de marketing actuel
  int getMarketingLevel() {
    return _upgrades['marketing']?.level ?? 0;
  }
  
  
  
  /// Met à jour la capacité maximale de stockage de métal
  void updateMaxMetalStorage(double capacity) {
    _maxMetalStorage = capacity;
    notifyListeners();
  }
  
  /// Met à jour la capacité de stockage en fonction du niveau d'amélioration
  void upgradeStorageCapacity(int storageLevel) {
    double newCapacity = GameConstants.INITIAL_STORAGE_CAPACITY *
        (1 + (storageLevel * GameConstants.STORAGE_UPGRADE_MULTIPLIER));
    updateMaxMetalStorage(newCapacity);
    notifyListeners();
  }
  
  /// Dépense du métal pour produire des trombones
  bool spendMetal(double amount) {
    if (amount <= 0 || amount > _metal) {
      return false;
    }
    
    _metal -= amount;
    notifyListeners();
    return true;
  }
  
  /// Alias de compatibilité: utilisé par la production
  bool consumeMetal(double amount) {
    return spendMetal(amount);
  }
  
  /// Vérifie si le joueur peut acheter une amélioration
  bool canAffordUpgrade(String upgradeId) {
    final upgrade = _upgrades[upgradeId];
    if (upgrade == null) return false;
    if (upgrade.isMaxLevel) return false;
    return canAfford(upgrade.getCost());
  }
  
  /// Achète une amélioration
  bool purchaseUpgrade(String upgradeId) {
    final upgrade = _upgrades[upgradeId];
    if (upgrade == null) return false;

    if (upgrade.isMaxLevel) return false;
    
    double cost = upgrade.getCost();
    if (!canAfford(cost)) return false;
    
    _money -= cost;
    if (_money < 0) _money = 0;
    upgrade.level++;

    notifyListeners();
    return true;
  }
  
  /// Sérialisation en JSON
  Map<String, dynamic> toJson() {
    return {
      'money': _money,
      'paperclips': _paperclips,
      'metal': _metal,
      'sellPrice': _sellPrice,
      'autoClipperCount': _autoClipperCount,
      'megaClipperCount': _megaClipperCount,
      'autoClipperCost': _autoClipperCost,
      'megaClipperCost': _megaClipperCost,
      'metalCost': _metalCost,
      'metalPurchaseCount': _metalPurchaseCount,
      'productionSpeedMultiplier': _productionSpeedMultiplier,
      'productionBatchSizeMultiplier': _productionBatchSizeMultiplier,
      'autoMetalBuyerEnabled': _autoMetalBuyerEnabled,
      'metalAutoBuyerLevel': _metalAutoBuyerLevel,
      'autoClipperLevel': _autoClipperLevel,
      'trust': _trust,
      'processors': _processors,
      'memory': _memory,
      'totalPaperclips': _totalPaperclips,
      'maxMetalStorage': _maxMetalStorage,
      'maintenanceCosts': _maintenanceCosts,
      'lastMaintenanceTime': _lastMaintenanceTime?.toIso8601String(),
      'upgrades': _upgrades.map((key, upgrade) => MapEntry(key, upgrade.toJson())),
      // Ajoutez d'autres propriétés au besoin
    };
  }
  
  /// Désérialisation depuis JSON
  @override
  void fromJson(Map<String, dynamic> json) {
    try {
      // Chargement des ressources du joueur
      _money = (json['money'] as num?)?.toDouble() ?? GameConstants.INITIAL_MONEY;
      _paperclips = (json['paperclips'] as num?)?.toDouble() ?? 0.0;
      _metal = (json['metal'] as num?)?.toDouble() ?? GameConstants.INITIAL_METAL;
      _sellPrice = (json['sellPrice'] as num?)?.toDouble() ?? GameConstants.INITIAL_PRICE;
      
      // Chargement du nombre d'autoclippers
      _autoClipperCount = (json['autoClipperCount'] as num?)?.toInt() ?? 0;
      
      _megaClipperCount = (json['megaClipperCount'] as num?)?.toInt() ?? 0;
      _autoClipperCost = (json['autoClipperCost'] as num?)?.toDouble() ?? GameConstants.BASE_AUTOCLIPPER_COST;
      _megaClipperCost = (json['megaClipperCost'] as num?)?.toDouble() ?? 30.0;
      _metalCost = (json['metalCost'] as num?)?.toDouble() ?? 14.0;
      _metalPurchaseCount = (json['metalPurchaseCount'] as num?)?.toInt() ?? 0;
      _productionSpeedMultiplier = (json['productionSpeedMultiplier'] as num?)?.toDouble() ?? 1.0;
      _productionBatchSizeMultiplier = (json['productionBatchSizeMultiplier'] as num?)?.toDouble() ?? 1.0;
      _autoMetalBuyerEnabled = json['autoMetalBuyerEnabled'] as bool? ?? false;
      _metalAutoBuyerLevel = (json['metalAutoBuyerLevel'] as num?)?.toDouble() ?? 0.0;
      _autoClipperLevel = (json['autoClipperLevel'] as num?)?.toDouble() ?? 0.0;
      _trust = (json['trust'] as num?)?.toInt() ?? 0;
      _processors = (json['processors'] as num?)?.toDouble() ?? 0.0;
      _memory = (json['memory'] as num?)?.toDouble() ?? 0.0;
      _totalPaperclips = (json['totalPaperclips'] as num?)?.toDouble() ?? 0.0;
      _maxMetalStorage = (json['maxMetalStorage'] as num?)?.toDouble() ?? GameConstants.INITIAL_STORAGE_CAPACITY;
      _maintenanceCosts = (json['maintenanceCosts'] as num?)?.toDouble() ?? 0.0;
      
      // Chargement de la date de dernière maintenance
      if (json['lastMaintenanceTime'] != null) {
        try {
          _lastMaintenanceTime = DateTime.parse(json['lastMaintenanceTime'].toString());
        } catch (e) {
          print('Erreur lors du parsing de lastMaintenanceTime dans PlayerManager: $e');
          _lastMaintenanceTime = DateTime.now();
        }
      }
      
      // Chargement des upgrades
      if (json['upgrades'] != null) {
        final upgradesJson = json['upgrades'] as Map<String, dynamic>;
        upgradesJson.forEach((key, value) {
          if (_upgrades.containsKey(key)) {
            _upgrades[key]!.level = (value['level'] as num?)?.toInt() ?? 0;
          }
        });

        // Réappliquer les effets dépendants du niveau au chargement (ex: capacité de stockage)
        final storage = _upgrades['storage'];
        if (storage != null) {
          final newCapacity = UpgradeEffectsCalculator.metalStorageCapacity(
            storageLevel: storage.level,
          );
          _maxMetalStorage = newCapacity;
          if (_metal > _maxMetalStorage) {
            _metal = _maxMetalStorage;
          }
        }
      } else {
        // Fallback legacy : anciennes sauvegardes peuvent ne pas contenir `upgrades`.
        // Assurer la cohérence de la capacité en se basant sur le niveau courant (par défaut 0)
        final effectiveStorageLevel = _upgrades['storage']?.level ?? 0;
        final newCapacity = UpgradeEffectsCalculator.metalStorageCapacity(
          storageLevel: effectiveStorageLevel,
        );
        _maxMetalStorage = newCapacity;
        if (_metal > _maxMetalStorage) {
          _metal = _maxMetalStorage;
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement du PlayerManager: $e');
    }
  }
  
  /// Réinitialisation des états du joueur
  void resetPlayerState() {
    _money = GameConstants.INITIAL_MONEY;
    _paperclips = 0.0;
    _metal = GameConstants.INITIAL_METAL;
    _sellPrice = GameConstants.INITIAL_PRICE;
    _autoClipperCount = 0;
    _megaClipperCount = 0;
    _autoClipperCost = GameConstants.BASE_AUTOCLIPPER_COST;
    _megaClipperCost = 30.0;
    _metalCost = 14.0;
    _metalPurchaseCount = 0;
    _productionSpeedMultiplier = 1.0;
    _productionBatchSizeMultiplier = 1.0;
    _autoMetalBuyerEnabled = false;
    _metalAutoBuyerLevel = 0;
    _autoClipperLevel = 0;
    _trust = 0;
    _processors = 0.0;
    _memory = 0.0;
    _maxMetalStorage = GameConstants.INITIAL_STORAGE_CAPACITY;
    _maintenanceCosts = 0.0;
    _lastMaintenanceTime = null;
    _maintenanceTimer?.cancel();
    _maintenanceTimer = null;
    notifyListeners();
  }
}
