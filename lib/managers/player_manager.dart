// lib/managers/player_manager.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import '../constants/game_config.dart'; // Mis à jour pour utiliser le dossier constants
import '../models/json_loadable.dart';
import '../models/game_state_interfaces.dart';
import '../models/upgrade.dart';

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
  int _marketingLevel = 0;
  int _autoClipperCount = 0;
  int _megaClipperCount = 0;
  double _autoClipperCost = GameConstants.BASE_AUTOCLIPPER_COST;
  double _megaClipperCost = 30.0; // À définir dans GameConstants
  double _metalCost = 14.0; // À définir dans GameConstants
  int _metalPurchaseCount = 0;
  
  // Niveaux et upgrades
  int _storageUpgradeLevel = 0;
  int _efficiencyUpgradeLevel = 0;
  double _productionSpeedMultiplier = 1.0;
  double _productionBatchSizeMultiplier = 1.0;
  bool _autoMetalBuyerEnabled = false;
  double _metalAutoBuyerLevel = 0;
  double _autoClipperLevel = 0;
  
  // Getters
  double get money => _money;
  double get paperclips => _paperclips;
  // L'ancien getter 'wire' redirige désormais vers 'metal' pour rétrocompatibilité
  double get wire => _metal;
  double get metal => _metal;
  double get sellPrice => _sellPrice;
  int get marketingLevel => _marketingLevel;
  int get autoClipperCount => _autoClipperCount;
  int get megaClipperCount => _megaClipperCount;
  double get autoClipperCost => _autoClipperCost;
  double get megaClipperCost => _megaClipperCost;
  // Getter de rétrocompatibilité pour autoclippers
  int get autoclippers => _autoClipperCount;
  double get wireCost => _metalCost; // Rétrocompatibilité
  double get metalCost => _metalCost;
  int get wirePurchaseCount => _metalPurchaseCount; // Rétrocompatibilité
  int get metalPurchaseCount => _metalPurchaseCount;
  int get storageUpgradeLevel => _storageUpgradeLevel;
  int get efficiencyUpgradeLevel => _efficiencyUpgradeLevel;
  double get productionSpeedMultiplier => _productionSpeedMultiplier;
  double get productionBatchSizeMultiplier => _productionBatchSizeMultiplier;
  bool get autoWireBuyerEnabled => _autoMetalBuyerEnabled; // Rétrocompatibilité
  bool get autoMetalBuyerEnabled => _autoMetalBuyerEnabled;
  double get wireAutoBuyerLevel => _metalAutoBuyerLevel; // Rétrocompatibilité
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
    ),
    'speed': Upgrade(
      id: 'speed',
      name: 'Vitesse',
      description: 'Augmente la vitesse de production',
      baseCost: 25.0,
      maxLevel: 10,
    ),
    'bulk': Upgrade(
      id: 'bulk',
      name: 'Production en masse',
      description: 'Augmente la quantité produite par opération',
      baseCost: 40.0,
      maxLevel: GameConstants.MAX_BULK_LEVEL,
    ),
    'storage': Upgrade(
      id: 'storage',
      name: 'Stockage',
      description: 'Augmente la capacité de stockage de métal',
      baseCost: 30.0,
      maxLevel: GameConstants.MAX_STORAGE_LEVEL,
    ),
    'quality': Upgrade(
      id: 'quality',
      name: 'Qualité',
      description: 'Améliore la qualité des trombones produits',
      baseCost: 50.0,
      maxLevel: 8,
    ),
    'automation': Upgrade(
      id: 'automation',
      name: 'Automatisation',
      description: 'Réduit le coût des autoclippers',
      baseCost: 75.0,
      maxLevel: 5,
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
  
  /// Détermine si le joueur a suffisamment de fil (redirigé vers hasEnoughMetal pour compatibilité)
  bool hasEnoughWire(double amount) {
    return hasEnoughMetal(amount);
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

  /// Alias de compatibilité pour l'ancien code qui appelait updateSellPrice
  void updateSellPrice(double price) {
    setSellPrice(price);
  }
  
  /// Acheter un autoclip (machine automatique de fabrication)
  bool purchaseAutoClipper() {
    if (canAfford(_autoClipperCost)) {
      _autoClipperCount++;
      _money -= _autoClipperCost;
      // Augmenter le coût pour l'achat suivant
      _autoClipperCost = calculateAutoclipperCost();
      notifyListeners();
      return true;
    }
    return false;
  }
  
  /// Méthode de rétrocompatibilité qui redirige vers purchaseAutoClipper
  bool buyAutoClipper() {
    return purchaseAutoClipper();
  }
  
  // Méthode supprimée: purchaseAutoclipper() (alias pour buyAutoClipper)
  
  /// Calcule le coût d'achat d'un autoclipper
  double calculateAutoclipperCost() {
    return _autoClipperCost;
  }
  
  /// Calcule le retour sur investissement (ROI) d'un autoclipper
  double calculateAutoclipperROI() {
    if (_autoClipperCount == 0) return 0.0;
    double cost = calculateAutoclipperCost();
    double productionPerMinute = _autoClipperCount * 60; // production par minute
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
  
  /// Acheter une amélioration marketing
  bool purchaseMarketingUpgrade() {
    double cost = calculateMarketingCost();
    if (canAfford(cost)) {
      _marketingLevel++;
      _money -= cost;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  /// Méthode de rétrocompatibilité qui redirige vers purchaseMarketingUpgrade
  bool upgradeMarketing() {
    return purchaseMarketingUpgrade();
  }
  
  /// Calcule le coût d'une amélioration marketing
  double calculateMarketingCost() {
    return 25.0 * pow(1.1, _marketingLevel); // Constantes à ajouter dans GameConstants
  }
  
  /// Retourne le niveau de marketing actuel
  int getMarketingLevel() {
    return _marketingLevel;
  }
  
  /// Met à jour le niveau de stockage
  void updateStorageLevel(int level) {
    _storageUpgradeLevel = level;
    notifyListeners();
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
  
  /// Méthode de rétrocompatibilité qui redirige vers spendMetal
  bool consumeMetal(double amount) {
    return spendMetal(amount);
  }
  
  /// Vérifie si le joueur peut acheter une amélioration
  bool canAffordUpgrade(String upgradeId) {
    final upgrade = _upgrades[upgradeId];
    if (upgrade == null) return false;
    return canAfford(upgrade.getCost());
  }
  
  /// Achète une amélioration
  bool purchaseUpgrade(String upgradeId) {
    final upgrade = _upgrades[upgradeId];
    if (upgrade == null) return false;
    
    double cost = upgrade.getCost();
    if (!canAfford(cost)) return false;
    
    _money -= cost;
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
      'marketingLevel': _marketingLevel,
      'autoClipperCount': _autoClipperCount,
      // Pour compatibilité avec le validateur de sauvegarde
      'autoclippers': _autoClipperCount,
      'megaClipperCount': _megaClipperCount,
      'autoClipperCost': _autoClipperCost,
      'megaClipperCost': _megaClipperCost,
      'metalCost': _metalCost,
      'metalPurchaseCount': _metalPurchaseCount,
      'storageUpgradeLevel': _storageUpgradeLevel,
      'efficiencyUpgradeLevel': _efficiencyUpgradeLevel,
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
      // Fusionner l'ancien 'wire' avec 'metal' pour assurer la rétrocompatibilité
      double wireValue = (json['wire'] as num?)?.toDouble() ?? 0.0;
      _metal = (json['metal'] as num?)?.toDouble() ?? GameConstants.INITIAL_METAL;
      
      // Si on a des données 'wire' dans la sauvegarde, on les ajoute au metal
      if (wireValue > 0) {
        _metal += wireValue;
      }
      _sellPrice = (json['sellPrice'] as num?)?.toDouble() ?? GameConstants.INITIAL_PRICE;
      _marketingLevel = (json['marketingLevel'] as num?)?.toInt() ?? 0;
      
      // Chargement du nombre d'autoclippers
      _autoClipperCount = (json['autoClipperCount'] as num?)?.toInt() ?? 0;
      
      _megaClipperCount = (json['megaClipperCount'] as num?)?.toInt() ?? 0;
      _autoClipperCost = (json['autoClipperCost'] as num?)?.toDouble() ?? GameConstants.BASE_AUTOCLIPPER_COST;
      _megaClipperCost = (json['megaClipperCost'] as num?)?.toDouble() ?? 30.0;
      // Charger metalCost (avec rétrocompatibilité pour wireCost)
      _metalCost = (json['metalCost'] as num?)?.toDouble() ?? 
                (json['wireCost'] as num?)?.toDouble() ?? 14.0;
      _metalPurchaseCount = (json['metalPurchaseCount'] as num?)?.toInt() ?? 
                       (json['wirePurchaseCount'] as num?)?.toInt() ?? 0;
      _storageUpgradeLevel = (json['storageUpgradeLevel'] as num?)?.toInt() ?? 0;
      _efficiencyUpgradeLevel = (json['efficiencyUpgradeLevel'] as num?)?.toInt() ?? 0;
      _productionSpeedMultiplier = (json['productionSpeedMultiplier'] as num?)?.toDouble() ?? 1.0;
      _productionBatchSizeMultiplier = (json['productionBatchSizeMultiplier'] as num?)?.toDouble() ?? 1.0;
      // Charger les paramètres d'achat automatique (avec rétrocompatibilité)
      _autoMetalBuyerEnabled = json['autoMetalBuyerEnabled'] as bool? ?? 
                         json['autoWireBuyerEnabled'] as bool? ?? false;
      _metalAutoBuyerLevel = (json['metalAutoBuyerLevel'] as num?)?.toDouble() ?? 
                        (json['wireAutoBuyerLevel'] as num?)?.toDouble() ?? 0.0;
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
    _marketingLevel = 0;
    _autoClipperCount = 0;
    _megaClipperCount = 0;
    _autoClipperCost = GameConstants.BASE_AUTOCLIPPER_COST;
    _megaClipperCost = 30.0;
    _metalCost = 14.0;
    _metalPurchaseCount = 0;
    _storageUpgradeLevel = 0;
    _efficiencyUpgradeLevel = 0;
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
