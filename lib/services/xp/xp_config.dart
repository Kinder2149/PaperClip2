// lib/services/xp/xp_config.dart

/// Configuration centralisée des valeurs d'XP pour toutes les sources
class XPConfig {
  // Production
  static const double MANUAL_PRODUCTION_BASE = 0.25;
  static const double AUTO_PRODUCTION_BASE = 0.10;
  
  // Ventes
  static const double SALE_BASE = 0.15;
  static const double SALE_QUALITY_MULTIPLIER = 0.5;
  
  // Achats et améliorations
  static const double AUTOCLIPPER_PURCHASE = 4.0;
  static const double UPGRADE_PURCHASE_BASE = 2.5;
  
  // Recherches
  static const double RESEARCH_MONEY_MULTIPLIER = 0.5;
  static const double RESEARCH_PI_MULTIPLIER = 10.0;
  static const double RESEARCH_QUANTUM_MULTIPLIER = 15.0;
  static const double RESEARCH_MIN_XP_MONEY = 5.0;
  static const double RESEARCH_MIN_XP_PI = 10.0;
  static const double RESEARCH_MIN_XP_QUANTUM = 15.0;
  
  // Missions
  static const double MISSION_DAILY_MIN = 50.0;
  static const double MISSION_DAILY_MAX = 200.0;
  static const double MISSION_WEEKLY_MIN = 300.0;
  static const double MISSION_WEEKLY_MAX = 800.0;
  static const double MISSION_DIFFICULTY_MULTIPLIER = 0.5;
  static const double MISSION_WEEKLY_TYPE_MULTIPLIER = 2.0;
  static const double MISSION_MILESTONE_TYPE_MULTIPLIER = 1.5;
  
  // Bonus
  static const double DAILY_BONUS_BASE = 10.0;
  
  // Multiplicateurs
  static const double PATH_MATCH_MULTIPLIER = 1.2;
  static const double PATH_MILESTONE_BONUS = 0.05;
  static const double COMBO_INCREMENT = 0.1;
  static const int COMBO_MAX = 10;
  
  // Reset progression
  static const double RESET_XP_BONUS_PER_RESET = 0.05;
  static const double RESET_XP_BONUS_MAX = 2.0;
  static const int RESET_XP_BONUS_MAX_RESETS = 20;
  
  // Scaling
  static const double LEVEL_SCALING_FACTOR = 0.04;
  static const double LOW_LEVEL_BONUS = 1.1;
  static const int LOW_LEVEL_THRESHOLD = 35;
}
