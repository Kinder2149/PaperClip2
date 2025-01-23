// lib/models/resource_manager.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'game_config.dart';
import 'event_system.dart';
import 'player_manager.dart';

class ResourceManager extends ChangeNotifier {
  // Constantes de ressources
  static const double WARNING_THRESHOLD = GameConstants.WARNING_THRESHOLD;
  static const double CRITICAL_THRESHOLD = GameConstants.CRITICAL_THRESHOLD;
  static const double INITIAL_MARKET_METAL = GameConstants.INITIAL_MARKET_METAL;

  // État des ressources
  double _marketMetalStock = INITIAL_MARKET_METAL;
  double _metalStorageCapacity = 1000.0;
  double _baseStorageEfficiency = 1.0;
  double _resourceDecayRate = 0.01;

  // Getters
  double get marketMetalStock => _marketMetalStock;
  double get metalStorageCapacity => _metalStorageCapacity;
  double get baseStorageEfficiency => _baseStorageEfficiency;

  // Calculs de capacité
  double calculateEffectiveStorage(int storageUpgradeLevel) {
    return _metalStorageCapacity * (1 + (storageUpgradeLevel * 0.5));
  }

  double calculateStorageEfficiency(int efficiencyUpgradeLevel) {
    return _baseStorageEfficiency * (1 + (efficiencyUpgradeLevel * 0.1));
  }

  // Gestion des ressources
  bool canStoreMetal(double amount, int storageUpgradeLevel, double currentMetal) {
    double maxStorage = calculateEffectiveStorage(storageUpgradeLevel);
    return (currentMetal + amount) <= maxStorage;
  }

  void updateMarketStock(double amount) {
    _marketMetalStock = (_marketMetalStock + amount).clamp(0.0, INITIAL_MARKET_METAL);
    _checkResourceLevels();
    notifyListeners();
  }

  // Vérifications des niveaux de ressources
  void _checkResourceLevels() {
    if (_marketMetalStock <= WARNING_THRESHOLD) {
      EventManager.instance.addEvent(
        EventType.RESOURCE_DEPLETION,
        'Stocks de métal bas',
        description: 'Les réserves de métal du marché s\'amenuisent',
        importance: EventImportance.HIGH,
      );
    }

    if (_marketMetalStock <= CRITICAL_THRESHOLD) {
      EventManager.instance.addEvent(
        EventType.RESOURCE_DEPLETION,
        'Niveau critique !',
        description: 'Les réserves de métal sont presque épuisées !',
        importance: EventImportance.CRITICAL,
      );
    }
  }

  // Calculs de maintenance et d'efficacité
  double calculateMaintenanceCost(int storageUpgradeLevel, double currentMetal) {
    double baseMaintenanceCost = currentMetal * _resourceDecayRate;
    double efficiencyFactor = 1.0 / (1 + (storageUpgradeLevel * 0.1));
    return baseMaintenanceCost * efficiencyFactor;
  }

  double calculateResourceEfficiency(int efficiencyUpgradeLevel) {
    return 1.0 + (efficiencyUpgradeLevel * 0.15);
  }

  // Méthodes d'upgrade
  void upgradeStorageCapacity(double amount) {
    _metalStorageCapacity += amount;
    notifyListeners();
  }

  void improveStorageEfficiency(double amount) {
    _baseStorageEfficiency += amount;
    notifyListeners();
  }

  // Sérialisation
  Map<String, dynamic> toJson() => {
    'marketMetalStock': _marketMetalStock,
    'metalStorageCapacity': _metalStorageCapacity,
    'baseStorageEfficiency': _baseStorageEfficiency,
    'resourceDecayRate': _resourceDecayRate,
  };

  void fromJson(Map<String, dynamic> json) {
    _marketMetalStock = (json['marketMetalStock'] as num?)?.toDouble() ?? INITIAL_MARKET_METAL;
    _metalStorageCapacity = (json['metalStorageCapacity'] as num?)?.toDouble() ?? 1000.0;
    _baseStorageEfficiency = (json['baseStorageEfficiency'] as num?)?.toDouble() ?? 1.0;
    _resourceDecayRate = (json['resourceDecayRate'] as num?)?.toDouble() ?? 0.01;
  }

  // Méthodes de restauration et de réinitialisation
  void restoreMarketStock(double amount) {
    if (_marketMetalStock < INITIAL_MARKET_METAL) {
      double restoration = (_marketMetalStock + amount).clamp(0.0, INITIAL_MARKET_METAL);
      _marketMetalStock = restoration;
      notifyListeners();
    }
  }

  void resetResources() {
    _marketMetalStock = INITIAL_MARKET_METAL;
    _metalStorageCapacity = 1000.0;
    _baseStorageEfficiency = 1.0;
    _resourceDecayRate = 0.01;
    notifyListeners();
  }
}