// lib/managers/production_manager.dart

import 'package:flutter/foundation.dart';
import '../models/game_config.dart';
import '../models/event_system.dart';
import '../models/progression_system.dart';
import 'metal_manager.dart';
import 'dart:math' show min;

class ProductionManager extends ChangeNotifier {
  // ===== PROPRIÉTÉS =====
  double _paperclips = 0.0;
  int _autoclippers = 0;
  int _totalPaperclipsProduced = 0;

  // Dépendances
  final MetalManager _metalManager;
  final LevelSystem _levelSystem;

  // Callback pour notifications d'événements
  final Function(String) _showNotification;

  // ===== GETTERS =====
  double get paperclips => _paperclips;
  int get autoclippers => _autoclippers;
  int get totalPaperclipsProduced => _totalPaperclipsProduced;

  // ===== CONSTRUCTEUR =====
  ProductionManager({
    required MetalManager metalManager,
    required LevelSystem levelSystem,
    required Function(String) showNotification,
    double initialPaperclips = 0.0,
    int initialAutoclippers = 0,
    int initialTotalProduced = 0,
  }) :
        _metalManager = metalManager,
        _levelSystem = levelSystem,
        _showNotification = showNotification,
        _paperclips = initialPaperclips,
        _autoclippers = initialAutoclippers,
        _totalPaperclipsProduced = initialTotalProduced;

  // ===== MÉTHODES DE PRODUCTION =====

  /// Production manuelle d'un trombone
  bool produceManualPaperclip() {
    // Tenter de produire un trombone avec le métal disponible
    if (_metalManager.produceManualPaperclip(
        updateStatistics: (amount, metalUsed) {
          // Ces statistiques seraient idéalement gérées par un StatisticsManager
        }
    )) {
      // Mettre à jour les compteurs
      updatePaperclips(_paperclips + 1);
      _totalPaperclipsProduced++;

      // Ajouter de l'expérience pour la production manuelle
      _levelSystem.addManualProduction();

      notifyListeners();
      return true;
    }
    return false;
  }

  /// Processus de production automatique (à appeler périodiquement)
  void processProduction() {
    if (_autoclippers <= 0) return;

    // Calcul des bonus
    double speedBonus = 1.0 + ((getUpgradeLevel('speed') ?? 0) * 0.20);
    double bulkBonus = 1.0 + ((getUpgradeLevel('bulk') ?? 0) * 0.35);
    double efficiencyLevel = (getUpgradeLevel('efficiency') ?? 0).toDouble();

    // Calcul de la production basée sur le métal disponible
    int actualProduction = _metalManager.calculateMetalBasedProduction(
        autoclippers: _autoclippers,
        speedBonus: speedBonus,
        bulkBonus: bulkBonus,
        efficiencyLevel: efficiencyLevel
    );

    if (actualProduction > 0) {
      // Consommer le métal pour la production
      _metalManager.consumeMetalForProduction(
          productionAmount: actualProduction,
          efficiencyLevel: efficiencyLevel,
          updateStatistics: (production, metalUsed, metalSaved) {
            // Ces statistiques seraient idéalement gérées par un StatisticsManager
          }
      );

      // Mettre à jour les compteurs
      updatePaperclips(_paperclips + actualProduction);
      _totalPaperclipsProduced += actualProduction;

      // Ajouter de l'expérience pour la production automatique
      _levelSystem.addAutomaticProduction(actualProduction);

      notifyListeners();
    }
  }

  // ===== MÉTHODES DE GESTION DES AUTOCLIPPERS =====

  /// Calcule le coût d'un nouvel autoclipper
  double calculateAutoclipperCost() {
    double baseCost = GameConstants.BASE_AUTOCLIPPER_COST;
    double automationDiscount = 1.0 - ((getUpgradeLevel('automation') ?? 0) * 0.10);
    return baseCost * (1.15 * _autoclippers) * automationDiscount;
  }

  /// Achat d'un autoclipper
  bool buyAutoclipper(double playerMoney, Function(double) updatePlayerMoney) {
    double cost = calculateAutoclipperCost();
    if (playerMoney >= cost) {
      // Déduire le coût
      updatePlayerMoney(playerMoney - cost);

      // Ajouter l'autoclipper
      updateAutoclippers(_autoclippers + 1);

      // Ajouter de l'expérience pour l'achat
      _levelSystem.addAutoclipperPurchase();

      notifyListeners();
      return true;
    }
    return false;
  }

  /// Calcule le retour sur investissement d'un autoclipper
  double calculateAutoclipperROI(double sellPrice) {
    double cost = calculateAutoclipperCost();
    double revenuePerSecond = GameConstants.BASE_AUTOCLIPPER_PRODUCTION * sellPrice;

    // Si pas de revenu, retourner une valeur infinie
    if (revenuePerSecond <= 0) return double.infinity;

    // Retourner le temps en secondes pour rentabiliser l'investissement
    return cost / revenuePerSecond;
  }

  // ===== MÉTHODES DE CALCUL DE PRODUCTION =====

  /// Calcule le multiplicateur de production basé sur les améliorations
  double getProductionMultiplier() {
    double bulkBonus = (getUpgradeLevel('bulk') ?? 0) * GameConstants.BULK_UPGRADE_BASE;
    return 1.0 + bulkBonus;
  }

  // ===== MÉTHODES UTILITAIRES =====

  /// Met à jour le nombre de trombones
  void updatePaperclips(double newAmount) {
    if (_paperclips != newAmount) {
      _paperclips = newAmount;
      notifyListeners();
    }
  }

  /// Met à jour le nombre d'autoclippers
  void updateAutoclippers(int newAmount) {
    if (_autoclippers != newAmount) {
      _autoclippers = newAmount;

      // Mise à jour des capacités de production
      notifyListeners();
    }
  }

  /// Reset les données de production
  void reset() {
    _paperclips = 0.0;
    _autoclippers = 0;
    _totalPaperclipsProduced = 0;
    notifyListeners();
  }

  // ===== Méthode temporaire (à remplacer par UpgradeManager) =====
  int? getUpgradeLevel(String upgradeId) {
    // Cette méthode devrait idéalement provenir d'un UpgradeManager
    // Pour l'instant, nous utilisons une approche simplifiée
    return 0; // Valeur par défaut
  }

  // ===== SÉRIALISATION =====

  /// Convertit l'état en JSON
  Map<String, dynamic> toJson() => {
    'paperclips': _paperclips,
    'autoclippers': _autoclippers,
    'totalPaperclipsProduced': _totalPaperclipsProduced,
  };

  /// Charge l'état depuis JSON
  void fromJson(Map<String, dynamic> json) {
    _paperclips = (json['paperclips'] as num?)?.toDouble() ?? 0.0;
    _autoclippers = (json['autoclippers'] as num?)?.toInt() ?? 0;
    _totalPaperclipsProduced = (json['totalPaperclipsProduced'] as num?)?.toInt() ?? 0;
    notifyListeners();
  }
}