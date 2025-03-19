// lib/managers/production_manager.dart
import 'package:flutter/foundation.dart';
import '../models/game_config.dart';
import '../models/event_system.dart';
import '../models/progression_system.dart';
import 'metal_manager.dart';
import 'dart:math' show min;

class ProductionManagerException implements Exception {
  final String message;
  ProductionManagerException(this.message);
}

class ProductionResult {
  final int producedPaperclips;
  final double metalUsed;
  final double metalSaved;

  ProductionResult({
    required this.producedPaperclips,
    required this.metalUsed,
    required this.metalSaved,
  });
}

class ProductionManager extends ChangeNotifier {
  // Propriétés privées avec validation
  double _paperclips;
  int _autoclippers;
  int _totalPaperclipsProduced;

  // Dépendances
  final MetalManager _metalManager;
  final LevelSystem _levelSystem;

  // Callbacks
  final Function(String) _showNotification;
  final Function(int, double, double) _updateStatistics;
  final Function(String) getUpgradeLevel;

  // Constructeur avec validation
  ProductionManager({
    required MetalManager metalManager,
    required LevelSystem levelSystem,
    required Function(String) showNotification,
    required this.getUpgradeLevel,
    required Function(int, double, double) updateStatistics,
    double initialPaperclips = 0.0,
    int initialAutoclippers = 0,
    int initialTotalProduced = 0,
  }) :
        _metalManager = metalManager,
        _levelSystem = levelSystem,
        _showNotification = showNotification,
        _updateStatistics = updateStatistics,
        _paperclips = _validatePaperclips(initialPaperclips),
        _autoclippers = _validateAutoclippers(initialAutoclippers),
        _totalPaperclipsProduced = _validateTotalProduced(initialTotalProduced);

  // Méthodes de validation statiques
  static double _validatePaperclips(double value) {
    if (value < 0) throw ProductionManagerException('Paperclips cannot be negative');
    return value;
  }

  static int _validateAutoclippers(int value) {
    if (value < 0) throw ProductionManagerException('Autoclippers cannot be negative');
    return value;
  }

  static int _validateTotalProduced(int value) {
    if (value < 0) throw ProductionManagerException('Total produced cannot be negative');
    return value;
  }

  // Getters
  double get paperclips => _paperclips;
  int get autoclippers => _autoclippers;
  int get totalPaperclipsProduced => _totalPaperclipsProduced;

  // Méthode de production manuelle
  bool produceManualPaperclip() {
    final metalConsumptionResult = _metalManager.produceManualPaperclip(
        updateStatistics: (amount, metalUsed) {
          _updateStatistics(amount.toInt(), metalUsed, 0.0);
        }
    );

    if (metalConsumptionResult) {
      _paperclips += 1;
      _totalPaperclipsProduced++;
      _levelSystem.addManualProduction();
      notifyListeners();
      return true;
    }
    return false;
  }

  void updateAutoclippers(int newAmount) {
    if (_autoclippers != newAmount) {
      _autoclippers = _validateAutoclippers(newAmount);
      notifyListeners();
    }
  }

  void updatePaperclips(double newAmount) {
    if (_paperclips != newAmount) {
      _paperclips = _validatePaperclips(newAmount);
      notifyListeners();
    }
  }

  // Méthode de calcul du ROI des autoclippers
  double calculateAutoclipperROI(double sellPrice) {
    double cost = calculateAutoclipperCost();
    double revenuePerSecond = GameConstants.BASE_AUTOCLIPPER_PRODUCTION * sellPrice;

    // Si pas de revenu, retourner une valeur infinie
    if (revenuePerSecond <= 0) return double.infinity;

    // Retourner le temps en secondes pour rentabiliser l'investissement
    return cost / revenuePerSecond;
  }


  // Méthode de production automatique
  ProductionResult processProduction() {
    if (_autoclippers <= 0) {
      return ProductionResult(
          producedPaperclips: 0,
          metalUsed: 0,
          metalSaved: 0
      );
    }

    // Calcul des bonus
    double speedBonus = 1.0 + ((getUpgradeLevel('speed') ?? 0) * 0.20);
    double bulkBonus = 1.0 + ((getUpgradeLevel('bulk') ?? 0) * 0.35);
    double efficiencyLevel = (getUpgradeLevel('efficiency') ?? 0).toDouble();

    // Calcul de la production
    int actualProduction = _metalManager.calculateMetalBasedProduction(
        autoclippers: _autoclippers,
        speedBonus: speedBonus,
        bulkBonus: bulkBonus,
        efficiencyLevel: efficiencyLevel
    );

    if (actualProduction > 0) {
      // Consommation du métal
      final productionSuccess = _metalManager.consumeMetalForProduction(
          productionAmount: actualProduction,
          efficiencyLevel: efficiencyLevel,
          updateStatistics: (production, metalUsed, metalSaved) {
            _updateStatistics(production, metalUsed, metalSaved);
          }
      );

      if (productionSuccess) {
        _paperclips += actualProduction;
        _totalPaperclipsProduced += actualProduction;
        _levelSystem.addAutomaticProduction(actualProduction);
        notifyListeners();

        return ProductionResult(
            producedPaperclips: actualProduction,
            metalUsed: 0, // À calculer précisément
            metalSaved: 0 // À calculer précisément
        );
      }
    }

    return ProductionResult(
        producedPaperclips: 0,
        metalUsed: 0,
        metalSaved: 0
    );
  }

  // Méthode d'achat d'autoclipper
  bool buyAutoclipper(double playerMoney, Function(double) updatePlayerMoney) {
    double cost = calculateAutoclipperCost();
    if (playerMoney >= cost) {
      updatePlayerMoney(playerMoney - cost);
      _autoclippers++;
      _levelSystem.addAutoclipperPurchase();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Calcul du coût d'un autoclipper
  double calculateAutoclipperCost() {
    double baseCost = GameConstants.BASE_AUTOCLIPPER_COST;
    double automationDiscount = 1.0 - ((getUpgradeLevel('automation') ?? 0) * 0.10);
    return baseCost * (1.15 * _autoclippers) * automationDiscount;
  }

  // Méthodes de sérialisation
  Map<String, dynamic> toJson() => {
    'paperclips': _paperclips,
    'autoclippers': _autoclippers,
    'totalPaperclipsProduced': _totalPaperclipsProduced,
  };

  void fromJson(Map<String, dynamic> json) {
    _paperclips = _validatePaperclips(json['paperclips'] ?? 0.0);
    _autoclippers = _validateAutoclippers(json['autoclippers'] ?? 0);
    _totalPaperclipsProduced = _validateTotalProduced(json['totalPaperclipsProduced'] ?? 0);
    notifyListeners();
  }
}