// lib/models/resource_manager.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'game_config.dart';
import 'event_system.dart';
import 'player_manager.dart';
import 'json_loadable.dart';

class ResourceManager extends ChangeNotifier implements JsonLoadable {
  // Constantes de ressources

  // État des ressources
  double _metalStorageCapacity = 1000.0;
  double _baseStorageEfficiency = 1.0;
  double _marketMetalStock = GameConstants.INITIAL_MARKET_METAL;


  // Ajout des getters
  double get effectiveStorageCapacity => _metalStorageCapacity;
  double get currentEfficiency => _baseStorageEfficiency;

  // Getters
  double get marketMetalStock => _marketMetalStock;
  double get metalStorageCapacity => _metalStorageCapacity;
  double get baseStorageEfficiency => _baseStorageEfficiency;


  // Calculs de capacité
  double calculateEffectiveStorage(int storageUpgradeLevel) {
    return _metalStorageCapacity * (1 + (storageUpgradeLevel * GameConstants.STORAGE_UPGRADE_MULTIPLIER));
  }


  double calculateStorageEfficiency(int efficiencyUpgradeLevel) {
    return _baseStorageEfficiency * (1 + (efficiencyUpgradeLevel * GameConstants.EFFICIENCY_UPGRADE_MULTIPLIER));
  }

  // Gestion des ressources
  bool canStoreMetal(double amount, int storageUpgradeLevel, double currentMetal) {
    double maxStorage = calculateEffectiveStorage(storageUpgradeLevel);
    return (currentMetal + amount) <= maxStorage;
  }


  void updateResourceEfficiency(int level) {
    _baseStorageEfficiency = 1.0 + (level * 0.1);
    notifyListeners();
  }

  // Ajout d'une méthode de vérification des ressources
  bool hasEnoughResources(double amount) {
    return _marketMetalStock >= amount;
  }

  void updateMarketStock(double amount) {
    _marketMetalStock = (_marketMetalStock + amount).clamp(
        0.0,
        GameConstants.INITIAL_MARKET_METAL
    );
    notifyListeners();
  }

  void consumeResources(double amount) {
    if (!hasEnoughResources(amount)) {
      throw Exception('Ressources insuffisantes');
    }
    _marketMetalStock -= amount;
    notifyListeners();
  }



  // Calculs de maintenance et d'efficacité
  double calculateMaintenanceCost(int storageUpgradeLevel, double currentMetal) {
    return 0.0;  // Plus de coût de maintenance
  }

  double calculateResourceEfficiency(int efficiencyUpgradeLevel) {
    return 1.0 + (efficiencyUpgradeLevel * 0.15);
    return 1.0 + (efficiencyUpgradeLevel * 0.15);
  }

  // Méthodes d'upgrade
  void upgradeStorageCapacity(int level) {
    _metalStorageCapacity = GameConstants.INITIAL_STORAGE_CAPACITY *
        (1 + (level * GameConstants.STORAGE_UPGRADE_MULTIPLIER));
    notifyListeners();
  }

  void improveStorageEfficiency(int level) {
    _baseStorageEfficiency = GameConstants.BASE_EFFICIENCY *
        (1 + (level * GameConstants.EFFICIENCY_UPGRADE_MULTIPLIER));
    notifyListeners();
  }

  // Sérialisation
  Map<String, dynamic> toJson() => {
    'marketMetalStock': _marketMetalStock,
    'metalStorageCapacity': _metalStorageCapacity,
    'baseStorageEfficiency': _baseStorageEfficiency,
  };

  @override
  void fromJson(Map<String, dynamic> json) {
    try {
      _marketMetalStock = (json['marketMetalStock'] as num?)?.toDouble() ??
          GameConstants.INITIAL_MARKET_METAL;
      _metalStorageCapacity = (json['metalStorageCapacity'] as num?)?.toDouble() ??
          GameConstants.INITIAL_STORAGE_CAPACITY;
      _baseStorageEfficiency = (json['baseStorageEfficiency'] as num?)?.toDouble() ??
          GameConstants.BASE_EFFICIENCY;
    } catch (e, stack) {
      print('Error loading resource manager: $e');
      print('Stack trace: $stack');
      resetResources(); // Utilise la méthode existante pour réinitialiser
    }
    notifyListeners();
  }

  // Méthodes de restauration et de réinitialisation
  void restoreMarketStock(double amount) {
    if (_marketMetalStock < GameConstants.INITIAL_MARKET_METAL) {
      double restoration = (_marketMetalStock + amount).clamp(
          0.0,
          GameConstants.INITIAL_MARKET_METAL
      );
      _marketMetalStock = restoration;
      notifyListeners();
    }
  }

  void resetResources() {
    _marketMetalStock = GameConstants.INITIAL_MARKET_METAL;
    _metalStorageCapacity = GameConstants.INITIAL_STORAGE_CAPACITY;
    _baseStorageEfficiency = GameConstants.BASE_EFFICIENCY;  // À ajouter dans GameConstants
    notifyListeners();
  }
}