import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'game_config.dart';
import 'event_system.dart';
import 'resource_manager.dart';

/// Gestionnaire centralisé pour la production et la gestion des trombones
class PaperclipManager extends ChangeNotifier {
  // Propriétés de production
  int _totalPaperclipsProduced = 0;
  int _paperclipsInInventory = 0;
  double _productionRate = GameConstants.INITIAL_PRODUCTION_RATE;
  double _productionEfficiency = 1.0;
  double _productionQuality = 1.0;
  double _metalPerPaperclip = GameConstants.INITIAL_METAL_PER_PAPERCLIP;
  
  // Propriétés d'automatisation
  bool _isAutomated = false;
  double _automationSpeed = 1.0;
  int _automationLevel = 0;
  
  // Propriétés de vente
  double _basePrice = GameConstants.INITIAL_PAPERCLIP_PRICE;
  double _priceMultiplier = 1.0;
  
  // Getters
  int get totalPaperclipsProduced => _totalPaperclipsProduced;
  int get paperclipsInInventory => _paperclipsInInventory;
  double get productionRate => _productionRate;
  double get productionEfficiency => _productionEfficiency;
  double get productionQuality => _productionQuality;
  double get metalPerPaperclip => _metalPerPaperclip;
  bool get isAutomated => _isAutomated;
  double get automationSpeed => _automationSpeed;
  int get automationLevel => _automationLevel;
  double get basePrice => _basePrice;
  double get priceMultiplier => _priceMultiplier;
  
  // Calcul du prix actuel des trombones
  double get currentPrice => _basePrice * _priceMultiplier * _productionQuality;
  
  // Calcul de la consommation de métal par trombone
  double get effectiveMetalPerPaperclip => _metalPerPaperclip / _productionEfficiency;
  
  // Constructeur
  PaperclipManager() {
    _initialize();
  }
  
  void _initialize() {
    // Initialisation des valeurs par défaut
    _totalPaperclipsProduced = 0;
    _paperclipsInInventory = 0;
    _productionRate = GameConstants.INITIAL_PRODUCTION_RATE;
    _productionEfficiency = 1.0;
    _productionQuality = 1.0;
    _metalPerPaperclip = GameConstants.INITIAL_METAL_PER_PAPERCLIP;
    _isAutomated = false;
    _automationSpeed = 1.0;
    _automationLevel = 0;
    _basePrice = GameConstants.INITIAL_PAPERCLIP_PRICE;
    _priceMultiplier = 1.0;
  }
  
  // Production manuelle de trombones
  bool produceManually(ResourceManager resourceManager, double playerMetal) {
    // Vérifier si assez de métal
    double metalNeeded = effectiveMetalPerPaperclip;
    if (playerMetal < metalNeeded) {
      return false;
    }
    
    // Produire un trombone
    _paperclipsInInventory++;
    _totalPaperclipsProduced++;
    
    // Notifier les changements
    notifyListeners();
    return true;
  }
  
  // Production automatique de trombones
  int produceAutomatically(ResourceManager resourceManager, double playerMetal, double deltaTime) {
    if (!_isAutomated) return 0;
    
    // Calculer combien de trombones peuvent être produits
    double productionPerSecond = _productionRate * _automationSpeed;
    double potentialProduction = productionPerSecond * deltaTime;
    int maxPossibleProduction = potentialProduction.floor();
    
    // Vérifier la limite de métal
    double metalNeeded = effectiveMetalPerPaperclip * maxPossibleProduction;
    if (playerMetal < metalNeeded) {
      maxPossibleProduction = (playerMetal / effectiveMetalPerPaperclip).floor();
    }
    
    if (maxPossibleProduction <= 0) return 0;
    
    // Produire les trombones
    _paperclipsInInventory += maxPossibleProduction;
    _totalPaperclipsProduced += maxPossibleProduction;
    
    // Notifier les changements
    notifyListeners();
    return maxPossibleProduction;
  }
  
  // Vendre des trombones
  int sellPaperclips(int amount) {
    int actualAmount = min(amount, _paperclipsInInventory);
    if (actualAmount <= 0) return 0;
    
    _paperclipsInInventory -= actualAmount;
    notifyListeners();
    return actualAmount;
  }
  
  // Améliorer l'efficacité de production
  void upgradeEfficiency(double multiplier) {
    _productionEfficiency *= multiplier;
    notifyListeners();
  }
  
  // Améliorer la qualité de production
  void upgradeQuality(double multiplier) {
    _productionQuality *= multiplier;
    notifyListeners();
  }
  
  // Améliorer la vitesse de production
  void upgradeProductionRate(double multiplier) {
    _productionRate *= multiplier;
    notifyListeners();
  }
  
  // Activer l'automatisation
  void enableAutomation() {
    _isAutomated = true;
    notifyListeners();
  }
  
  // Améliorer l'automatisation
  void upgradeAutomation(double speedMultiplier) {
    _automationLevel++;
    _automationSpeed *= speedMultiplier;
    notifyListeners();
  }
  
  // Réinitialiser le gestionnaire
  void reset() {
    _initialize();
    notifyListeners();
  }
  
  // Sérialisation
  Map<String, dynamic> toJson() => {
    'totalPaperclipsProduced': _totalPaperclipsProduced,
    'paperclipsInInventory': _paperclipsInInventory,
    'productionRate': _productionRate,
    'productionEfficiency': _productionEfficiency,
    'productionQuality': _productionQuality,
    'metalPerPaperclip': _metalPerPaperclip,
    'isAutomated': _isAutomated,
    'automationSpeed': _automationSpeed,
    'automationLevel': _automationLevel,
    'basePrice': _basePrice,
    'priceMultiplier': _priceMultiplier,
  };
  
  // Désérialisation
  void fromJson(Map<String, dynamic> json) {
    _totalPaperclipsProduced = json['totalPaperclipsProduced'] ?? 0;
    _paperclipsInInventory = json['paperclipsInInventory'] ?? 0;
    _productionRate = (json['productionRate'] as num?)?.toDouble() ?? GameConstants.INITIAL_PRODUCTION_RATE;
    _productionEfficiency = (json['productionEfficiency'] as num?)?.toDouble() ?? 1.0;
    _productionQuality = (json['productionQuality'] as num?)?.toDouble() ?? 1.0;
    _metalPerPaperclip = (json['metalPerPaperclip'] as num?)?.toDouble() ?? GameConstants.INITIAL_METAL_PER_PAPERCLIP;
    _isAutomated = json['isAutomated'] ?? false;
    _automationSpeed = (json['automationSpeed'] as num?)?.toDouble() ?? 1.0;
    _automationLevel = json['automationLevel'] ?? 0;
    _basePrice = (json['basePrice'] as num?)?.toDouble() ?? GameConstants.INITIAL_PAPERCLIP_PRICE;
    _priceMultiplier = (json['priceMultiplier'] as num?)?.toDouble() ?? 1.0;
    
    notifyListeners();
  }
} 