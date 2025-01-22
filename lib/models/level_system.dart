import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'game_enums.dart';

enum ProgressionPath {
  PRODUCTION,
  MARKETING,
  EFFICIENCY,
  INNOVATION
}


enum ExperienceType {
  GENERAL,
  PRODUCTION,
  SALE,
  UPGRADE,
  DAILY_BONUS,
  COMBO_BONUS
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

class XPComboSystem {
  int _comboCount = 0;
  Timer? _comboTimer;

  int get comboCount => _comboCount;

  void setComboCount(int count) {
    _comboCount = count;
  }

  double getComboMultiplier() {
    return 1.0 + (_comboCount * 0.1); // +10% par combo
  }

  void incrementCombo() {
    _comboCount = min(_comboCount + 1, 5); // Max 5 combos
    _resetComboTimer();
  }

  void _resetComboTimer() {
    _comboTimer?.cancel();
    _comboTimer = Timer(const Duration(seconds: 5), () {
      _comboCount = 0;
    });
  }

  void dispose() {
    _comboTimer?.cancel();
  }
}

class DailyXPBonus {
  bool _claimed = false;
  final double _bonusAmount = 10.0;
  Timer? _resetTimer;

  bool get claimed => _claimed;

  void setClaimed(bool value) {
    _claimed = value;
    if (value) {
      _scheduleReset();
    }
  }

  bool claimDailyBonus(LevelSystem levelSystem) {
    if (!_claimed) {
      levelSystem.gainExperience(_bonusAmount);
      _claimed = true;
      _scheduleReset();
      return true;
    }
    return false;
  }

  void _scheduleReset() {
    _resetTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    _resetTimer = Timer(timeUntilMidnight, () {
      _claimed = false;
    });
  }

  void dispose() {
    _resetTimer?.cancel();
  }
}

class LevelSystem extends ChangeNotifier {
  double _experience = 0;
  int _level = 1;
  ProgressionPath _currentPath = ProgressionPath.PRODUCTION;
  final GameFeatureUnlocker featureUnlocker = GameFeatureUnlocker();

  // Nouveaux systèmes
  double _xpMultiplier = 1.0;
  final XPComboSystem comboSystem = XPComboSystem();
  final DailyXPBonus dailyBonus = DailyXPBonus();

  // Getters
  double get experience => _experience;
  int get level => _level;
  ProgressionPath get currentPath => _currentPath;
  double get currentComboMultiplier => comboSystem.getComboMultiplier();
  double get totalXpMultiplier => _xpMultiplier * currentComboMultiplier;
  bool get isDailyBonusAvailable => !dailyBonus.claimed;

  Function(int level, List<UnlockableFeature> newFeatures)? onLevelUp;

  // Multiplicateurs de base
  double get productionMultiplier => 1 + (_level * 0.01);
  double get salesMultiplier => 1 + (_level * 0.005);

  double get experienceForNextLevel => calculateExperienceRequirement(_level + 1);
  double get experienceProgress => _experience / experienceForNextLevel;

  // Nouveau calcul d'expérience requis
  @override
  double calculateExperienceRequirement(int level) {
    if (level <= 10) {
      return 50 * pow(1.3, level) + (level * level * 4);
    } else if (level <= 20) {
      return 50 * pow(1.5, level) + (level * level * 6);
    } else if (level <= 30) {
      return 50 * pow(1.7, level) + (level * level * 8);
    } else {
      return 50 * pow(2.0, level) + (level * level * 10);
    }
  }
  final Map<int, LevelUnlock> _levelUnlocks = {
    1: LevelUnlock(
        description: "Production manuelle débloquée",
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
        description: "Accès aux améliorations basiques",
        unlockedFeatures: ['basic_upgrades'],
        initialExperienceRequirement: 500
    ),
    8: LevelUnlock(
        description: "Marché débloqué",
        unlockedFeatures: ['market_access'],
        pathOptions: [
          PathOption(ProgressionPath.MARKETING, 0.3),
          PathOption(ProgressionPath.EFFICIENCY, 0.2)
        ],
        initialExperienceRequirement: 1000
    ),
    12: LevelUnlock(
        description: "Améliorations avancées",
        unlockedFeatures: ['advanced_upgrades'],
        initialExperienceRequirement: 2000
    ),
    15: LevelUnlock(
        description: "Marketing optimisé",
        unlockedFeatures: ['marketing_boost'],
        initialExperienceRequirement: 3000
    ),
    20: LevelUnlock(
        description: "Production de masse",
        unlockedFeatures: ['mass_production'],
        pathOptions: [
          PathOption(ProgressionPath.PRODUCTION, 0.4),
          PathOption(ProgressionPath.INNOVATION, 0.3)
        ],
        initialExperienceRequirement: 5000
    ),
    25: LevelUnlock(
        description: "Expertise commerciale",
        unlockedFeatures: ['trade_mastery'],
        initialExperienceRequirement: 8000
    ),
    30: LevelUnlock(
        description: "Optimisation ultime",
        unlockedFeatures: ['ultimate_optimization'],
        initialExperienceRequirement: 12000
    ),
    35: LevelUnlock(
        description: "Maîtrise totale",
        unlockedFeatures: ['complete_mastery'],
        pathOptions: [
          PathOption(ProgressionPath.INNOVATION, 0.5),
          PathOption(ProgressionPath.MARKETING, 0.4)
        ],
        initialExperienceRequirement: 20000
    )
  };

  Map<int, String> get levelUnlocks {
    return _levelUnlocks.map((key, value) => MapEntry(key, value.description));
  }
  void addExperience(double amount) {
    _experience += amount;
    _checkLevelUp();
    notifyListeners();
  }

  // Méthodes de gain d'XP améliorées
  void addManualProduction() {
    double baseXP = 2.0;
    double bonusXP = ProgressionBonus.getTotalBonus(level);
    addExperience(baseXP * bonusXP);
    comboSystem.incrementCombo();
  }

  void addAutomaticProduction(int amount) {
    double baseXP = 0.1 * amount;
    double bonusXP = ProgressionBonus.getTotalBonus(level);
    addExperience(baseXP * bonusXP);
  }

  void addSale(int quantity, double price) {
    double baseXP = 0.3 * quantity * (1 + (price - 0.25) * 2);
    double bonusXP = ProgressionBonus.getTotalBonus(level);
    addExperience(baseXP * bonusXP);
  }

  void addAutoclipperPurchase() {
    gainExperience(3);
  }

  void addUpgradePurchase(int upgradeLevel) {
    gainExperience(2.0 * upgradeLevel);
  }

  // Système de gain d'XP principal
  void gainExperience(double amount) {
    double baseAmount = amount * totalXpMultiplier;
    double levelPenalty = _level * 0.02; // Réduit à 2%
    double adjustedAmount = baseAmount * (1 - levelPenalty);

    // Bonus de progression pré-35
    if (_level < 35) {
      adjustedAmount *= 1.1;
    }

    _experience += max(adjustedAmount, 0.2);
    comboSystem.incrementCombo();
    _checkLevelUp();
    notifyListeners();
  }


  // Gestion des bonus temporaires
  void applyXPBoost(double multiplier, Duration duration) {
    _xpMultiplier = multiplier;
    EventManager.addEvent(
        EventType.XP_BOOST,
        "Bonus d'XP activé !",
        description: "Multiplicateur x$multiplier pendant ${duration.inMinutes} minutes",
        importance: EventImportance.MEDIUM
    );

    Future.delayed(duration, () {
      _xpMultiplier = 1.0;
      notifyListeners();
    });
  }

  // Bonus quotidien
  bool claimDailyBonus() {
    return dailyBonus.claimDailyBonus(this);
  }

  void _checkLevelUp() {
    double requiredExperience = calculateExperienceRequirement(_level);

    while (_experience >= requiredExperience) {
      _level++;
      _experience -= requiredExperience;

      // Vérifier les nouvelles fonctionnalités débloquées
      List<UnlockableFeature> newFeatures = featureUnlocker.getNewlyUnlockedFeatures(_level - 1, _level);

      // Notification de level up
      _triggerLevelUpEvent(_level, newFeatures);

      if (onLevelUp != null) {
        onLevelUp!(_level, newFeatures);
      }

      requiredExperience = calculateExperienceRequirement(_level);
      notifyListeners();
    }
  }

  void _triggerLevelUpEvent(int newLevel, List<UnlockableFeature> newFeatures) {
    String featuresDescription = newFeatures.isEmpty
        ? "Continuez votre progression !"
        : "Nouvelles fonctionnalités débloquées !";

    EventManager.addEvent(
        EventType.LEVEL_UP,
        "Niveau $newLevel atteint !",
        description: featuresDescription,
        importance: EventImportance.HIGH
    );

    EventManager.triggerNotificationPopup(
      title: "Niveau $newLevel débloqué !",
      description: featuresDescription,
      icon: Icons.stars,
    );
  }

  // Sérialisation
  Map<String, dynamic> toJson() => {
    'experience': _experience,
    'level': _level,
    'currentPath': _currentPath.index,
    'xpMultiplier': _xpMultiplier,
    'comboCount': comboSystem.comboCount,
    'dailyBonusClaimed': dailyBonus.claimed,
  };

  // Désérialisation
  void loadFromJson(Map<String, dynamic> json) {
    _experience = (json['experience'] as num?)?.toDouble() ?? 0;
    _level = (json['level'] as num?)?.toInt() ?? 1;
    _currentPath = ProgressionPath.values[json['currentPath'] ?? 0];
    _xpMultiplier = (json['xpMultiplier'] as num?)?.toDouble() ?? 1.0;
    comboSystem.setComboCount(json['comboCount'] ?? 0);
    dailyBonus.setClaimed(json['dailyBonusClaimed'] ?? false);

    _checkLevelUp();
  }

  // Nettoyage
  void dispose() {
    comboSystem.dispose();
    dailyBonus.dispose();
    super.dispose();
  }
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

  List<UnlockableFeature> getNewlyUnlockedFeatures(int previousLevel, int newLevel) {
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
class ProgressionBonus {
  static double calculateLevelBonus(int level) {
    if (level < 35) {
      return 1.0 + (level * 0.02);
    } else {
      return 1.7 + ((level - 35) * 0.01);
    }
  }

  static double getMilestoneBonus(int level) {
    Map<int, double> milestones = {
      10: 1.2,
      20: 1.3,
      30: 1.4,
    };
    return milestones[level] ?? 1.0;
  }

  static double getTotalBonus(int level) {
    return calculateLevelBonus(level) * getMilestoneBonus(level);
  }
}