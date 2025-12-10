// lib/models/game_constants.dart

/// Constantes globales utilisées dans tout le jeu
class GameConstants {
  // Version du jeu
  static const String VERSION = '1.0.0';
  
  // Constantes de production
  static const double MANUAL_PRODUCTION_XP = 0.5;
  static const double AUTO_PRODUCTION_XP = 0.1;
  
  // Constantes d'économie
  static const double STARTING_MONEY = 5.0;
  static const double PAPERCLIP_BASE_VALUE = 0.25;
  static const double METAL_BASE_COST = 2.0;
  
  // Constantes de progression
  static const double XP_PER_LEVEL = 100.0;
  static const int MAX_LEVEL = 100;
  
  // Constantes de sauvegarde
  static const int MAX_AUTO_SAVES = 5;
  static const int AUTO_SAVE_INTERVAL_MINUTES = 5;
  
  // Constantes d'interface utilisateur
  static const double UI_UPDATE_INTERVAL_SECONDS = 0.5;
  
  // Constantes de mode compétitif
  static const int COMPETITIVE_TIME_LIMIT_MINUTES = 30;
  static const int COMPETITIVE_SCORE_MULTIPLIER = 10;
  
  // Constantes de performance
  static const double EFFICIENCY_UPGRADE_BONUS = 0.1;
  static const double BULK_PURCHASE_BONUS = 0.25;
  static const double STORAGE_UPGRADE_BONUS = 5.0;
  static const double AUTOMATION_UPGRADE_BONUS = 0.15;
  
  // Constantes pour les crises
  static const int CRISIS_WARNING_THRESHOLD = 3;
  
  // Fonctionnalité devises premiums
  static const bool PREMIUM_ENABLED = false;
  
  // Constantes pour les missions
  static const int MAX_DAILY_MISSIONS = 3;
  static const int MAX_WEEKLY_MISSIONS = 2;
}

/// Types d'expérience pour la progression
enum ExperienceType {
  PRODUCTION,
  SALES,
  MANAGEMENT,
  RESEARCH,
  SPECIAL_EVENT
}

/// Chemins de progression disponibles
enum ProgressionPath {
  PRODUCTION,
  ECONOMY,
  RESEARCH
}

/// Niveaux de difficulté
enum DifficultyLevel {
  EASY,
  NORMAL,
  HARD
}

// Note: Types de missions (MissionType) désormais définis dans game_config.dart

/// Fonctionnalités débloquables du jeu
enum UnlockableFeature {
  MANUAL_PRODUCTION,
  METAL_PURCHASE,
  AUTOCLIPPERS,
  MARKET_SCREEN,
  MARKET_SALES,
  UPGRADES,
  IRON_MINING,
  COAL_MINING,
  STEEL_PRODUCTION,
  ADVANCED_AUTOMATION,
  RESEARCH_LAB
}
