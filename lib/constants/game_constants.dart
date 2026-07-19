// lib/models/game_constants.dart

/// Types d'expérience pour la progression
enum LegacyExperienceType {
  PRODUCTION,
  SALES,
  MANAGEMENT,
  RESEARCH,
  SPECIAL_EVENT
}

/// Chemins de progression disponibles
enum LegacyProgressionPath {
  PRODUCTION,
  ECONOMY,
  RESEARCH
}

/// Niveaux de difficulté
enum LegacyDifficultyLevel {
  EASY,
  NORMAL,
  HARD
}

// Note: Types de missions (MissionType) désormais définis dans game_config.dart

/// Fonctionnalités débloquables du jeu
enum LegacyUnlockableFeature {
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
