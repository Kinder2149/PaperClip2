import 'dart:math';
import 'package:flutter/material.dart';
import 'level_system.dart';
import 'event_manager.dart';
import 'game_event.dart';

class ResourceManager extends ChangeNotifier {
  static const double INITIAL_MARKET_METAL = 15000.0;
  static const double WARNING_THRESHOLD = 5000.0;
  static const double CRITICAL_THRESHOLD = 2000.0;

  double _marketMetalStock = INITIAL_MARKET_METAL;

  double get marketMetalStock => _marketMetalStock;

  void checkMetalStatus(int playerLevel) {
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

  void consumeMetal(double amount) {
    _marketMetalStock = max(0, _marketMetalStock - amount);
    notifyListeners();
  }

  void triggerWarningSequence() {
    EventManager.addEvent(
        EventType.RESOURCE_DEPLETION,
        "Alerte : Pénurie de métal",
        description: "Les ressources mondiales de métal s'amenuisent rapidement",
        importance: EventImportance.HIGH
    );
  }
  void loadFromJson(Map<String, dynamic> json) {
    _marketMetalStock = (json['marketMetalStock'] as num?)?.toDouble() ?? INITIAL_MARKET_METAL;
    notifyListeners();
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
}