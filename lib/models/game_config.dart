// lib/models/game_config.dart
class GameConstants {
  // Constantes de base
  static const double INITIAL_METAL = 100;
  static const double INITIAL_MONEY = 0;
  static const double INITIAL_PRICE = 0.25;
  static const double METAL_PER_PAPERCLIP = 0.15;
  static const double METAL_PACK_AMOUNT = 100.0;
  static const double MIN_METAL_PRICE = 14.0;
  static const double MAX_METAL_PRICE = 39.0;

  // Clés de sauvegarde
  static const String SAVE_KEY = 'paperclip_game_save';
  static const String SAVE_DIR_KEY = 'paperclip_save_directory';

  // Coûts et limites
  static const double BASE_AUTOCLIPPER_COST = 15.0;
  static const double MIN_PRICE = 0.01;
  static const double MAX_PRICE = 0.50;
  static const double INITIAL_MARKET_METAL = 1500.0;

  // Durées
  static const Duration NOTIFICATION_DURATION = Duration(seconds: 5);
  static const Duration EVENT_MAX_AGE = Duration(days: 1);

  // Limites système
  static const int MAX_STORED_EVENTS = 100;
  static const double MIN_MARKET_SATURATION = 50.0;
  static const double MAX_MARKET_SATURATION = 150.0;
  static const double COMPETITION_PRICE_VARIATION = 0.2;

  // Facteurs de réputation
  static const double REPUTATION_DECAY_RATE = 0.95;
  static const double REPUTATION_GROWTH_RATE = 1.01;
  static const double REPUTATION_PENALTY_RATE = 0.95;
  static const double REPUTATION_BONUS_RATE = 1.01;
  static const double MAX_REPUTATION = 2.0;
  static const double MIN_REPUTATION = 0.1;

  // Prix optimaux
  static const double OPTIMAL_PRICE_LOW = 0.25;
  static const double OPTIMAL_PRICE_HIGH = 0.35;

  // Difficultés et multiplicateurs
  static const double BASE_DIFFICULTY = 1.0;
  static const double DIFFICULTY_INCREASE_PER_MONTH = 0.1;

  // Maintenance et stockage
  static const double STORAGE_MAINTENANCE_RATE = 0.01;
  static const double MIN_METAL_CONSUMPTION = 0.1;

  // Seuils de ressources
  static const double WARNING_THRESHOLD = 1000.0;
  static const double CRITICAL_THRESHOLD = 500.0;

  // Information de version
  static const String VERSION = '1.0.0';
  static const String DEVELOPER = 'Kinder2149';
  static const String LAST_UPDATE = '23/01/2025';
}

/// Énumérations de jeu
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

enum MissionType {
  PRODUCE_PAPERCLIPS,
  SELL_PAPERCLIPS,
  BUY_AUTOCLIPPERS,
  UPGRADE_PURCHASE,
  EARN_MONEY
}

enum MarketEvent {
  PRICE_WAR,
  DEMAND_SPIKE,
  MARKET_CRASH,
  QUALITY_CONCERNS
}

enum EventType {
  LEVEL_UP,
  MARKET_CHANGE,
  RESOURCE_DEPLETION,
  UPGRADE_AVAILABLE,
  SPECIAL_ACHIEVEMENT,
  XP_BOOST
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

enum UnlockableFeature {
  MANUAL_PRODUCTION,
  METAL_PURCHASE,
  MARKET_SALES,
  MARKET_SCREEN,
  AUTOCLIPPERS,
  UPGRADES,
}

/// Classes de configuration
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