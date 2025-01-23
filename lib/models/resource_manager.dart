import 'package:flutter/material.dart';
import 'event_manager.dart';
import 'game_enums.dart';
import 'constants.dart';
import 'dart:math';
import 'package:paperclip2/models/notification_event.dart';
import 'package:paperclip2/models/notification_manager.dart';
import 'package:paperclip2/models/market/market_manager.dart';
import 'package:paperclip2/models/market/market_dynamics.dart';
import 'package:paperclip2/main.dart' show navigatorKey;

class ResourceManager extends ChangeNotifier {
  static const double INITIAL_MARKET_METAL = 15000.0;
  static const double WARNING_THRESHOLD = 1000.0;
  static const double CRITICAL_THRESHOLD = 500.0;
  static const double STORAGE_WARNING_THRESHOLD = 0.9;

  // Propriétés
  double _marketMetalStock = INITIAL_MARKET_METAL;
  double get marketMetalStock => _marketMetalStock;
  double _maintenanceCost = 0.01;
  final MarketManager marketManager;  // Déclaration sans initialisation

  // Constructor
  ResourceManager() : marketManager = MarketManager(MarketDynamics());

  // Getters
  double getCurrentMetalPrice() {
    return marketManager.getCurrentPrice(); // ou la méthode appropriée de votre MarketManager
  }

  bool canAddMetal(double amount, int maxStorage) {
    return (_marketMetalStock + amount) <= maxStorage;
  }

  double calculateMaintenanceCost() {
    return _marketMetalStock * _maintenanceCost;
  }

  void checkMetalStatus(int playerLevel, int maxStorage, double metal) {
    if (_marketMetalStock <= CRITICAL_THRESHOLD) {
      final notification = NotificationEvent(
        title: "Stock Critique!",
        description: "Le marché manque cruellement de métal",
        detailedDescription: """
État du marché de métal :

• Stock actuel : ${_marketMetalStock.toInt()} unités
• Seuil critique : $CRITICAL_THRESHOLD unités
• Impact : Hausse probable des prix

Actions recommandées :
1. Réduisez votre consommation
2. Stockez du métal pour plus tard
3. Optimisez votre production
        """,
        icon: Icons.warning,
        priority: NotificationPriority.CRITICAL,
        additionalData: {
          "Stock actuel": _marketMetalStock.toInt(),
          "Seuil critique": CRITICAL_THRESHOLD,
          "Prix actuel": getCurrentMetalPrice().toStringAsFixed(2)
        },
        canBeSuppressed: false,
      );

      if (navigatorKey.currentContext != null) {
        NotificationManager.showGameNotification(
          navigatorKey.currentContext!,
          event: notification,
        );
      }
    } else if (_marketMetalStock <= WARNING_THRESHOLD) {
      final notification = NotificationEvent(
        title: "Stock Faible",
        description: "Les réserves de métal diminuent",
        detailedDescription: """
État du marché de métal :

• Stock actuel : ${_marketMetalStock.toInt()} unités
• Seuil d'alerte : $WARNING_THRESHOLD unités
• Tendance : À surveiller

Recommandations :
1. Surveillez l'évolution des prix
2. Envisagez de constituer des réserves
3. Planifiez votre production
        """,
        icon: Icons.warning_amber,
        priority: NotificationPriority.HIGH,
        additionalData: {
          "Stock actuel": _marketMetalStock.toInt(),
          "Seuil d'alerte": WARNING_THRESHOLD,
          "Prix actuel": getCurrentMetalPrice().toStringAsFixed(2)
        },
        canBeSuppressed: true,
        suppressionDuration: const Duration(minutes: 10),
      );

      if (navigatorKey.currentContext != null) {
        NotificationManager.showGameNotification(
          navigatorKey.currentContext!,
          event: notification,
        );
      }
    }

    // Vérification du stockage personnel
    double stockPercentage = metal / maxStorage;
    if (stockPercentage >= STORAGE_WARNING_THRESHOLD) {
      final notification = NotificationEvent(
        title: "Stockage Critique",
        description: "Stockage à ${(stockPercentage * 100).toInt()}%",
        detailedDescription: """
Votre stockage de métal atteint ses limites !

État actuel :
• Capacité totale: $maxStorage
• Métal stocké: ${metal.toInt()}
• Taux d'occupation: ${(stockPercentage * 100).toInt()}%

Actions recommandées :
1. Augmentez votre capacité de stockage
2. Accélérez la production
3. Vendez l'excès de métal
        """,
        icon: Icons.warehouse,
        priority: NotificationPriority.HIGH,
        additionalData: {
          "Capacité maximale": maxStorage,
          "Stock actuel": metal.toInt(),
          "Espace restant": (maxStorage - metal).toInt(),
          "Taux remplissage": "${(stockPercentage * 100).toInt()}%"
        },
        canBeSuppressed: true,
        suppressionDuration: const Duration(minutes: 5),
      );

      if (navigatorKey.currentContext != null) {
        NotificationManager.showGameNotification(
          navigatorKey.currentContext!,
          event: notification,
        );
      }
    }

    if (playerLevel < 35) {
      if (_marketMetalStock < WARNING_THRESHOLD) {
        replenishMetal(1000.0);
        EventManager.addEvent(
            EventType.MARKET_CHANGE,
            "Approvisionnement en métal",
            description: "Le marché a été réapprovisionné en métal",
            importance: EventImportance.MEDIUM
        );
      }
    } else {
      if (_marketMetalStock <= CRITICAL_THRESHOLD) {
        triggerEndgameSequence();
      } else if (_marketMetalStock <= WARNING_THRESHOLD) {
        triggerWarningSequence();
      }
    }
  }

  void replenishMetal(double amount) {
    _marketMetalStock += amount;
    notifyListeners();
  }

  bool consumeMetal(double amount, double efficiency) {
    double actualConsumption = amount * (1 - efficiency);
    actualConsumption = max(actualConsumption, amount * 0.1);

    if (_marketMetalStock >= actualConsumption) {
      _marketMetalStock -= actualConsumption;
      notifyListeners();
      return true;
    }
    return false;
  }

  void triggerWarningSequence() {
    EventManager.addEvent(
        EventType.RESOURCE_DEPLETION,
        "Alerte : Pénurie de métal",
        description: "Les ressources mondiales de métal s'amenuisent rapidement",
        importance: EventImportance.HIGH
    );
  }

  void triggerEndgameSequence() {
    EventManager.addEvent(
        EventType.RESOURCE_DEPLETION,
        "CRITIQUE : Épuisement du métal",
        description: "Les ressources mondiales de métal sont presque épuisées",
        importance: EventImportance.CRITICAL
    );

    EventManager.triggerNotificationPopup(
        title: "Fin de phase approche",
        description: "Le monde tel que nous le connaissons est sur le point de changer...",
        icon: Icons.warning
    );
  }

  void loadFromJson(Map<String, dynamic> json) {
    _marketMetalStock = (json['marketMetalStock'] as num?)?.toDouble() ?? INITIAL_MARKET_METAL;
    notifyListeners();
  }
}