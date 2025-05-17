// lib/managers/metal_manager.dart

import 'package:flutter/foundation.dart';
import 'dart:math' show min;
import '../models/game_config.dart';
import '../models/event_system.dart';

class MetalManagerException implements Exception {
  final String message;
  MetalManagerException(this.message);
}

class MetalManager extends ChangeNotifier {
  // ===== PROPRIÉTÉS =====

  static const double LOW_METAL_THRESHOLD = 20.0;


  // Propriétés privées avec validation
  double _metal;
  double _marketMetalStock;
  double _metalStorageCapacity;
  double _baseStorageEfficiency;
  bool _lowMetalNotified = false;
  final Function? onCrisisTriggered;

  // ===== GETTERS =====

  double get metalStorageCapacity => _metalStorageCapacity;
  double get baseStorageEfficiency => _baseStorageEfficiency;
  double get effectiveStorageCapacity => _metalStorageCapacity;
  double get currentEfficiency => _baseStorageEfficiency;
  // Getters avec logique de protection
  double get metal => _metal;
  double get marketMetalStock => _marketMetalStock;
  double get maxMetalStorage => _metalStorageCapacity;

  // ===== CONSTRUCTEUR =====
  MetalManager({
    double initialMetal = GameConstants.INITIAL_METAL,
    double initialMarketStock = GameConstants.INITIAL_MARKET_METAL,
    double initialStorageCapacity = GameConstants.INITIAL_STORAGE_CAPACITY,
    this.onCrisisTriggered,
  }) :
        _metal = _validateMetal(initialMetal),
        _marketMetalStock = _validateMarketStock(initialMarketStock),
        _metalStorageCapacity = _validateStorageCapacity(initialStorageCapacity),
        _baseStorageEfficiency = GameConstants.BASE_EFFICIENCY;

  // Méthodes de validation statiques
  static double _validateMetal(double value) {
    if (value < 0) throw MetalManagerException('Le métal ne peut pas être négatif');
    return value;
  }

  static double _validateMarketStock(double value) {
    if (value < 0 || value > GameConstants.INITIAL_MARKET_METAL)
      throw MetalManagerException('Stock de métal invalide');
    return value;
  }

  static double _validateStorageCapacity(double value) {
    if (value <= 0) throw MetalManagerException('Capacité de stockage invalide');
    return value;
  }

  // ===== MÉTHODES DE MISE À JOUR =====

  /// Met à jour la quantité de métal du joueur
  void updateMetal(double newAmount) {
    final validatedAmount = _validateMetal(newAmount);
    if (_metal != validatedAmount) {
      _metal = min(validatedAmount, maxMetalStorage);
      _checkLowMetalNotification();
      notifyListeners();
    }
  }

  /// Met à jour le stock de métal du marché
  void updateMarketStock(double amount) {
    double previousStock = _marketMetalStock;
    final newStock = _marketMetalStock + amount;

    // Appliquer le changement avec limite à 0
    _marketMetalStock = _validateMarketStock(
        newStock.clamp(0.0, GameConstants.INITIAL_MARKET_METAL)
    );

    // Ajout de log pour suivre les changements de stock
    debugPrint("Stock de métal mis à jour: $previousStock -> $_marketMetalStock");

    // Vérification de seuil critique pour la crise
    // Ajouter une vérification pour l'état de progression du processus de crise
    if (_marketMetalStock <= 0.1 && previousStock > 0.1) {
      debugPrint("⚠️ SEUIL CRITIQUE ATTEINT: Métal épuisé");

      // Appel explicite du callback de crise
      onCrisisTriggered?.call();
    }

    notifyListeners();
  }

  /// Consomme une quantité de métal si disponible
  bool consumeMetal(double amount) {
    if (_metal >= amount) {
      updateMetal(_metal - amount);
      return true;
    }
    return false;
  }


  // ===== MÉTHODES POUR LES TRANSACTIONS DE MÉTAL =====

  bool buyMetal({
    required double price,
    required double playerMoney,
    required Function(double) updatePlayerMoney,
    double amount = GameConstants.METAL_PACK_AMOUNT
  }) {
    if (!canBuyMetal(metalPrice: price, playerMoney: playerMoney, amount: amount)) {
      return false;
    }

    updateMetal(_metal + amount);
    updateMarketStock(-amount);
    updatePlayerMoney(playerMoney - price);

    return true;
  }


  /// Vérifier si le joueur peut acheter du métal
  bool canBuyMetal({
    required double metalPrice,
    required double playerMoney,
    double amount = GameConstants.METAL_PACK_AMOUNT
  }) {
    return playerMoney >= metalPrice &&
        _metal + amount <= maxMetalStorage &&
        _marketMetalStock >= amount;
  }

  /// Vérifier si le marché peut vendre du métal
  bool canSellMetal(double quantity, int maxMetalStorage, double currentPlayerMetal) {
    return _marketMetalStock >= quantity &&
        (currentPlayerMetal + quantity) <= maxMetalStorage;
  }

  /// Effectue la vente de métal du marché au joueur
  bool sellMetal(double quantity, int maxMetalStorage, {
    required double currentPlayerMetal,
    required double currentMetalPrice,
    required Function(double) addMetal,
    required Function(double) subtractMoney
  }) {
    // Vérifications
    if (_marketMetalStock < quantity) {
      return false;  // Pas assez de métal dans le marché
    }
    if ((currentPlayerMetal + quantity) > maxMetalStorage) {
      return false;  // Capacité de stockage dépassée
    }

    // Effectuer la transaction
    _marketMetalStock -= quantity;
    addMetal(quantity);
    subtractMoney(quantity * currentMetalPrice);
    notifyListeners();
    return true;
  }

  // ===== MÉTHODES POUR LES CAPACITÉS ET EFFICACITÉ =====

  /// Calcule la capacité de stockage effective
  double calculateEffectiveStorage(int storageUpgradeLevel) {
    return _metalStorageCapacity * (1 + (storageUpgradeLevel * GameConstants.STORAGE_UPGRADE_MULTIPLIER));
  }

  /// Améliore la capacité de stockage
  void upgradeStorageCapacity(int level) {
    _metalStorageCapacity = GameConstants.INITIAL_STORAGE_CAPACITY *
        (1 + (level * GameConstants.STORAGE_UPGRADE_MULTIPLIER));
    notifyListeners();
  }

  /// Met à jour la capacité maximale de stockage
  void updateMaxMetalStorage(double newCapacity) {
    _metalStorageCapacity = newCapacity;
    notifyListeners();
  }

  /// Améliore l'efficacité du stockage
  void improveStorageEfficiency(int level) {
    _baseStorageEfficiency = GameConstants.BASE_EFFICIENCY *
        (1 + (level * GameConstants.EFFICIENCY_UPGRADE_MULTIPLIER));
    notifyListeners();
  }

  /// Calcule l'efficacité du stockage
  double calculateStorageEfficiency(int efficiencyUpgradeLevel) {
    return _baseStorageEfficiency * (1 + (efficiencyUpgradeLevel * GameConstants.EFFICIENCY_UPGRADE_MULTIPLIER));
  }

  /// Vérifie si le joueur peut stocker plus de métal
  bool canStoreMetal(double amount, int storageUpgradeLevel, double currentMetal) {
    double maxStorage = calculateEffectiveStorage(storageUpgradeLevel);
    return (currentMetal + amount) <= maxStorage;
  }

  // ===== MÉTHODES POUR LA GESTION DES RESSOURCES =====

  /// Vérifie si les ressources sont suffisantes
  bool hasEnoughResources(double amount) {
    return _marketMetalStock >= amount;
  }

  /// Consomme des ressources
  void consumeResources(double amount) {
    if (!hasEnoughResources(amount)) {
      throw Exception('Ressources insuffisantes');
    }
    _marketMetalStock -= amount;
    notifyListeners();
  }

  /// Restaure le stock de métal du marché
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

  // ===== MÉTHODES POUR LA SÉRIALISATION ET LA RÉINITIALISATION =====

  /// Convertit l'état en JSON
  Map<String, dynamic> toJson() => {
    'metal': _metal,
    'marketMetalStock': _marketMetalStock,
    'metalStorageCapacity': _metalStorageCapacity,
    'baseStorageEfficiency': _baseStorageEfficiency,
  };

  /// Charge l'état depuis JSON
  void fromJson(Map<String, dynamic> json) {
    _metal = (json['metal'] as num?)?.toDouble() ?? GameConstants.INITIAL_METAL;
    _marketMetalStock = (json['marketMetalStock'] as num?)?.toDouble() ?? GameConstants.INITIAL_MARKET_METAL;
    _metalStorageCapacity = (json['metalStorageCapacity'] as num?)?.toDouble() ?? GameConstants.INITIAL_STORAGE_CAPACITY;
    _baseStorageEfficiency = (json['baseStorageEfficiency'] as num?)?.toDouble() ?? GameConstants.BASE_EFFICIENCY;
    notifyListeners();
  }

  /// Réinitialise les ressources à leurs valeurs par défaut
  void resetResources() {
    _metal = GameConstants.INITIAL_METAL;
    _marketMetalStock = GameConstants.INITIAL_MARKET_METAL;
    _metalStorageCapacity = GameConstants.INITIAL_STORAGE_CAPACITY;
    _baseStorageEfficiency = GameConstants.BASE_EFFICIENCY;
    _lowMetalNotified = false;
    notifyListeners();
  }


  // Méthode de production complète qui gère la consommation du métal
  int calculateMetalBasedProduction({
    required int autoclippers,
    required double speedBonus,
    required double bulkBonus,
    required double efficiencyLevel,
  }) {
    // Calculer l'efficacité
    double reduction = min(
        efficiencyLevel * GameConstants.EFFICIENCY_UPGRADE_MULTIPLIER,
        GameConstants.EFFICIENCY_MAX_REDUCTION
    );
    double efficiencyBonus = 1.0 - reduction;

    // Calculer la production potentielle
    double totalProduction = autoclippers * speedBonus * bulkBonus;

    // Métal nécessaire par trombone avec efficacité
    double metalPerClip = GameConstants.METAL_PER_PAPERCLIP * efficiencyBonus;

    // Nombre maximum de trombones possibles avec le métal disponible
    int maxPossibleClips = (_metal / metalPerClip).floor();

    // Production effective (limitée par le métal disponible)
    int actualProduction = min(totalProduction.floor(), maxPossibleClips);

    return actualProduction;
  }

  // Méthode pour consommer le métal lors de la production
  bool consumeMetalForProduction({
    required int productionAmount,
    required double efficiencyLevel,
    required Function(int, double, double) updateStatistics
  }) {
    if (productionAmount <= 0) return false;

    // Calculer l'efficacité
    double reduction = min(
        efficiencyLevel * GameConstants.EFFICIENCY_UPGRADE_MULTIPLIER,
        GameConstants.EFFICIENCY_MAX_REDUCTION
    );
    double efficiencyBonus = 1.0 - reduction;

    // Calculer le métal consommé
    double metalPerClip = GameConstants.METAL_PER_PAPERCLIP * efficiencyBonus;
    double metalUsed = productionAmount * metalPerClip;
    double metalSaved = productionAmount * GameConstants.METAL_PER_PAPERCLIP * reduction;

    // Vérifier si on a assez de métal
    if (_metal < metalUsed) return false;

    // Consommer le métal
    updateMetal(_metal - metalUsed);

    // Mettre à jour les statistiques
    updateStatistics(productionAmount, metalUsed, metalSaved);

    return true;
  }

  // Méthode spécifique pour produire un trombone manuellement
  bool produceManualPaperclip({
    required Function(double, double) updateStatistics
  }) {
    // Tenter de consommer le métal nécessaire
    if (consumeMetal(GameConstants.METAL_PER_PAPERCLIP)) {
      // Mettre à jour les statistiques
      updateStatistics(1, GameConstants.METAL_PER_PAPERCLIP);
      return true;
    }
    return false;
  }

  // Méthode pour évaluer l'état des stocks de métal
  bool isMetalCriticallyLow() {
    return _marketMetalStock <= GameConstants.CRITICAL_THRESHOLD;
  }

  bool isMetalLow() {
    return _marketMetalStock <= GameConstants.WARNING_THRESHOLD;
  }

  // Méthode pour calculer le pourcentage de métal restant sur le marché
  double getMarketMetalPercentage() {
    return (_marketMetalStock / GameConstants.INITIAL_MARKET_METAL) * 100;
  }
  // Méthodes de vérification et de notification
  void _checkLowMetalNotification() {
    if (_metal <= 20.0 && !_lowMetalNotified) {
      _lowMetalNotified = true;
      EventManager.instance.addEvent(
          EventType.RESOURCE_DEPLETION,
          'Stock Personnel Bas',
          description: 'Votre stock de métal est inférieur à 20 unités',
          importance: EventImportance.MEDIUM
      );
    } else if (_metal > 20.0) {
      _lowMetalNotified = false;
    }
  }

  // Méthode pour notifier d'un niveau bas de métal
  void checkAndNotifyLowMetal() {
    if (isMetalLow() && !_lowMetalNotified) {
      EventManager.instance.addEvent(
          EventType.RESOURCE_DEPLETION,
          'Stock Mondial Bas',
          description: 'Les réserves mondiales de métal sont faibles !',
          importance: EventImportance.HIGH
      );
      _lowMetalNotified = true;
    }
  }
}