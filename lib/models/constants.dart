class GameConstants {
  static const double INITIAL_METAL = 100;
  static const double INITIAL_MONEY = 0;
  static const double INITIAL_PRICE = 0.25;
  static const double METAL_PER_PAPERCLIP = 0.15;
  static const double METAL_PACK_AMOUNT = 100.0;
  static const double MIN_METAL_PRICE = 14.0;
  static const double MAX_METAL_PRICE = 39.0;
  static const String SAVE_KEY = 'paperclip_game_save';
  static const String SAVE_DIR_KEY = 'paperclip_save_directory';
  static const double BASE_AUTOCLIPPER_COST = 15.0;
  static const double MIN_PRICE = 0.01;
  static const double MAX_PRICE = 0.50;
  static const double INITIAL_MARKET_METAL = 1500.0;
  static const Duration NOTIFICATION_DURATION = Duration(seconds: 5);
  static const Duration EVENT_MAX_AGE = Duration(days: 1);
  static const int MAX_STORED_EVENTS = 100;
  static const double MIN_MARKET_SATURATION = 50.0;
  static const double MAX_MARKET_SATURATION = 150.0;
  static const double COMPETITION_PRICE_VARIATION = 0.2;
  static const double REPUTATION_DECAY_RATE = 0.95;
  static const double REPUTATION_GROWTH_RATE = 1.01;


  // Prix et Marché

  static const double OPTIMAL_PRICE_LOW = 0.25;
  static const double OPTIMAL_PRICE_HIGH = 0.35;

  // Pénalités et Bonus
  static const double REPUTATION_PENALTY_RATE = 0.95;
  static const double REPUTATION_BONUS_RATE = 1.01;
  static const double MAX_REPUTATION = 2.0;
  static const double MIN_REPUTATION = 0.1;

  // Multiplicateurs de difficulté
  static const double BASE_DIFFICULTY = 1.0;
  static const double DIFFICULTY_INCREASE_PER_MONTH = 0.1;

  // Constantes de stockage
  static const double STORAGE_MAINTENANCE_RATE = 0.01;
  static const double MIN_METAL_CONSUMPTION = 0.1;

  // ... autres constantes ...
  static const String VERSION = '1.0.0';
  static const String DEVELOPER = 'Kinder2149';
  static const String LAST_UPDATE = '23/01/2025';
}