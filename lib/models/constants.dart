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
  static const double MAX_PRICE = 1.0;
  static const double INITIAL_MARKET_METAL = 1500.0;
  static const Duration NOTIFICATION_DURATION = Duration(seconds: 5);
  static const Duration EVENT_MAX_AGE = Duration(days: 1);
  static const int MAX_STORED_EVENTS = 100;
}