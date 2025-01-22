import 'dart:math';
import 'package:flutter/material.dart';


enum ProgressionPath {
  PRODUCTION,
  MARKETING,
  EFFICIENCY,
  INNOVATION
}

enum EventType {
  LEVEL_UP,
  MARKET_CHANGE,
  RESOURCE_DEPLETION,
  UPGRADE_AVAILABLE,
  SPECIAL_ACHIEVEMENT
}

enum EventImportance {
  LOW(0),
  MEDIUM(1),
  HIGH(2),
  CRITICAL(3);

  final int value;
  const EventImportance(this.value);

  bool operator >=(EventImportance other) {
    return value >= other.value;
  }
}

enum ExperienceType {
  GENERAL,
  PRODUCTION,
  SALE,
  UPGRADE
}

enum UnlockableFeature {
  MANUAL_PRODUCTION,
  METAL_PURCHASE,
  MARKET_SALES,
  MARKET_SCREEN,
  AUTOCLIPPERS,
  UPGRADES,
}
class GameEvent {
  final EventType type;
  final String title;
  final String description;
  final EventImportance importance;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  GameEvent({
    required this.type,
    required this.title,
    required this.description,
    this.importance = EventImportance.LOW,
    this.data = const {},
  }) : timestamp = DateTime.now();
}
class EventManager {
  static List<GameEvent> _events = [];
  static final ValueNotifier<NotificationEvent?> _notificationController =
  ValueNotifier<NotificationEvent?>(null);

  static ValueNotifier<NotificationEvent?> get notificationStream => _notificationController;

  static List<GameEvent> getEvents() {
    return List.from(_events);
  }

  static void addEvent(
      EventType type,
      String title,
      {
        String description = '',
        EventImportance importance = EventImportance.LOW
      }
      ) {
    final event = GameEvent(
        type: type,
        title: title,
        description: description,
        importance: importance
    );
    _events.add(event);
  }

  static void clearEvents() {
    _events.clear();
  }

  // Méthode pour déclencher une notification
  static void triggerNotificationPopup({
    required String title,
    required String description,
    required IconData icon,
  }) {
    _notificationController.value = NotificationEvent(
        title: title,
        description: description,
        icon: icon,
        timestamp: DateTime.now()
    );
  }

  static List<GameEvent> getEventsByImportance(EventImportance minImportance) {
    return _events.where((event) => event.importance >= minImportance).toList();
  }
}

class NotificationEvent {
  final String title;
  final String description;
  final IconData icon;
  final DateTime timestamp;

  NotificationEvent({
    required this.title,
    required this.description,
    required this.icon,
    required this.timestamp,
  });
}
class GameFeatureUnlocker {
  final Map<UnlockableFeature, int> _featureLevelRequirements = {
    UnlockableFeature.MANUAL_PRODUCTION: 1,
    UnlockableFeature.METAL_PURCHASE: 1,
    UnlockableFeature.AUTOCLIPPERS: 3,
    UnlockableFeature.UPGRADES: 5,
    UnlockableFeature.MARKET_SCREEN: 7,
    UnlockableFeature.MARKET_SALES: 9,
  };

  bool isFeatureUnlocked(UnlockableFeature feature, int currentLevel) {
    return currentLevel >= (_featureLevelRequirements[feature] ?? 100);
  }

  List<UnlockableFeature> getNewlyUnlockedFeatures(int previousLevel,
      int newLevel) {
    return _featureLevelRequirements.entries
        .where((entry) =>
    entry.value > previousLevel &&
        entry.value <= newLevel)
        .map((entry) => entry.key)
        .toList();
  }

  Map<String, bool> getVisibleScreenElements(int currentLevel) {
    return {
      'metalStock': true,
      'paperclipStock': true,
      'manualProductionButton': true,
      'metalPurchaseButton': isFeatureUnlocked(
          UnlockableFeature.METAL_PURCHASE, currentLevel),
      'marketPrice': isFeatureUnlocked(
          UnlockableFeature.MARKET_SALES, currentLevel),
      'sellButton': isFeatureUnlocked(
          UnlockableFeature.MARKET_SALES, currentLevel),
      'autoclippersSection': isFeatureUnlocked(
          UnlockableFeature.AUTOCLIPPERS, currentLevel),
      'upgradesSection': isFeatureUnlocked(
          UnlockableFeature.UPGRADES, currentLevel),
    };
  }
}

class LevelSystem {
  double _experience = 0;
  int _level = 1;
  ProgressionPath _currentPath = ProgressionPath.PRODUCTION;
  final GameFeatureUnlocker featureUnlocker = GameFeatureUnlocker();

  // Structure de progression avec plus de profondeur
  final Map<int, LevelUnlock> _levelUnlocks = {
    1: LevelUnlock(
        description: "Première production manuelle",
        unlockedFeatures: ['manual_production'],
        initialExperienceRequirement: 10
    ),
    3: LevelUnlock(
        description: "Première autoclippeuse",
        unlockedFeatures: ['first_autoclipper'],
        pathOptions: [
          PathOption(ProgressionPath.PRODUCTION, 0.2),
          PathOption(ProgressionPath.EFFICIENCY, 0.1)
        ],
        initialExperienceRequirement: 150
    ),
    5: LevelUnlock(
        description: "Accès aux améliorations",
        unlockedFeatures: ['upgrades'],
        initialExperienceRequirement: 500
    ),
    7: LevelUnlock(
        description: "Accès au marché",
        unlockedFeatures: ['advanced_marketing', 'basic_market', 'metal_purchase'],
        pathOptions: [
          PathOption(ProgressionPath.MARKETING, 0.3),
          PathOption(ProgressionPath.INNOVATION, 0.2)
        ],
        initialExperienceRequirement: 1000
    )
  };

  // Getters
  double get experience => _experience;
  int get level => _level;
  ProgressionPath get currentPath => _currentPath;
  double get productionMultiplier {
    return 1 + (_level * 0.01);
  }

  double get salesMultiplier {
    return 1 + (_level * 0.005);
  }

  double get experienceForNextLevel => calculateExperienceRequirement(_level + 1);
  double get experienceProgress => _experience / experienceForNextLevel;

  // Calcul exponentiel de l'expérience requise
  double calculateExperienceRequirement(int level) {
    if (level <= 5) {
      return 50 * pow(1.5, level) + (level * level * 5);
    } else {
      return 50 * pow(2.5, level) + (level * level * 10);
    }
  }
  Function(int level, List<UnlockableFeature> newFeatures)? onLevelUp;

  // Gains d'XP
  void addManualProduction() {
    gainExperience(1);
  }

  void addAutomaticProduction(int amount) {
    gainExperience(0.05 * amount);
  }

  void addSale(int amount, double price) {
    double saleXp = 0.2 * amount * (1 + (price - 0.25));
    gainExperience(saleXp.clamp(0, 5));
  }

  void addAutoclipperPurchase() {
    gainExperience(2);
  }

  void addUpgradePurchase(int upgradeLevel) {
    gainExperience(1.0 * upgradeLevel);
  }

  // Méthode de gain d'expérience
  void gainExperience(double amount) {
    // Réduction significative des gains
    double adjustedAmount = amount * (1 - (_level * 0.05));
    _experience += max(adjustedAmount, 0.1);
    _checkLevelUp();
  }

  void _checkLevelUp() {
    double requiredExperience = calculateExperienceRequirement(_level);

    while (_experience >= requiredExperience) {
      _level++;
      _experience -= requiredExperience;

      // Notification de level up plus significative
      _triggerLevelUpEvent(_level);

      // Recalculer pour le prochain niveau
      requiredExperience = calculateExperienceRequirement(_level);
    }
  }
  void _triggerLevelUpEvent(int newLevel) {
    EventManager.addEvent(
        EventType.LEVEL_UP,
        "Niveau $newLevel atteint !",
        description: "De nouvelles capacités sont maintenant disponibles.",
        importance: EventImportance.HIGH
    );

    // Ajouter un événement global pour déclencher l'affichage
    EventManager.triggerNotificationPopup(
      title: "Niveau $newLevel débloqué !",
      description: "De nouvelles fonctionnalités sont maintenant disponibles.",
      icon: Icons.stars,
    );
  }

  // Calcul du nouveau niveau
  int _calculateNewLevel() {
    return (pow(_experience, 0.7) / 10).floor();
  }

  // Sérialisation
  Map<String, dynamic> toJson() => {
    'experience': _experience,
    'level': _level,
    'currentPath': _currentPath.index,
  };

  // Désérialisation
  void loadFromJson(Map<String, dynamic> json) {
    _experience = (json['experience'] as num?)?.toDouble() ?? 0;
    _level = (json['level'] as num?)?.toInt() ?? 1;
    _currentPath = ProgressionPath.values[json['currentPath'] ?? 0];
    _checkLevelUp();
  }
  Map<int, String> get levelUnlocks {
    return _levelUnlocks.map((key, value) => MapEntry(key, value.description));
  }
}


// Classes de support
class PathOption {
  final ProgressionPath path;
  final double probability;

  PathOption(this.path, this.probability);
}

class LevelUnlock {
  final String description;
  final List<String> unlockedFeatures;
  final List<PathOption>? pathOptions;
  final double initialExperienceRequirement;

  LevelUnlock({
    required this.description,
    this.unlockedFeatures = const [],
    this.pathOptions,
    required this.initialExperienceRequirement
  });
}