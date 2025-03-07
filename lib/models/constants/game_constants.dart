class GameConstants {
  // Version et configuration
  static const String gameVersion = '1.0.0';
  static const int maxSaveSlots = 5;
  static const Duration autoSaveInterval = Duration(minutes: 5);
  static const Duration cloudSyncInterval = Duration(minutes: 15);
  static const Duration sessionTimeout = Duration(hours: 24);

  // Production
  static const double baseProductionRate = 1.0;
  static const double baseProductionMultiplier = 1.0;
  static const double autoProductionBaseRate = 0.1;
  static const double productionMultiplierPerLevel = 0.1;
  static const int maxProductionMultiplier = 100;
  static const double METAL_PER_PAPERCLIP = 1.0;

  // Marché et prix
  static const double basePrice = 1.0;
  static const double minPrice = 0.01;
  static const double maxPrice = 100.0;
  static const double priceVolatility = 0.1;
  static const double demandVolatility = 0.05;
  static const double marketEventChance = 0.05;
  static const Duration marketEventDuration = Duration(minutes: 5);
  static const double baseDemand = 100.0;
  static const double maxDemand = 1000.0;
  static const double minDemand = 10.0;
  static const double demandDecayRate = 0.1;
  static const double priceSensitivity = 0.5;
  static const double reputationImpact = 0.2;
  static const double marketingImpact = 0.3;
  static const double baseMetalPrice = 0.5;

  // Progression et niveaux
  static const int baseExperience = 100;
  static const double experienceMultiplier = 1.5;
  static const int maxLevel = 100;
  static const int experiencePerPaperclip = 1;
  static const int experiencePerSale = 5;
  static const double expPerPaperclip = 0.1;
  static const double expMultiplierPerLevel = 1.2;

  // Améliorations
  static const double upgradeCostMultiplier = 1.5;
  static const int maxUpgradeLevel = 100;
  static const int baseUpgradeCost = 10;
  static const double upgradeEffectivenessMultiplier = 0.1;
  static const double baseAutoclipperCost = 5.0;
  static const double autoclipperCostMultiplier = 1.5;
  static const double speedUpgradeMultiplier = 0.20;
  static const double bulkUpgradeMultiplier = 0.35;
  static const double efficiencyUpgradeMultiplier = 0.15;
  static const double efficiencyMaxReduction = 0.85;
  static const double qualityUpgradeMultiplier = 0.10;
  static const double marketingUpgradeMultiplier = 0.30;

  // Succès et classements
  static const int paperclipMasterThreshold = 1000;
  static const int millionaireThreshold = 1000000;
  static const int marketMasterThreshold = 10000;
  static const int speedRunnerThreshold = 3600; // 1 heure en secondes
  static const int maxLeaderboardEntries = 100;
  static const Duration leaderboardUpdateInterval = Duration(minutes: 30);
  static const int minScoreForLeaderboard = 1000;

  // Réputation et événements
  static const double maxReputation = 2.0;
  static const double minReputation = 0.1;
  static const double reputationBonusRate = 1.1;
  static const double reputationPenaltyRate = 0.9;
  static const double eventTriggerChance = 0.01;
  static const Duration eventDuration = Duration(minutes: 10);
  static const double eventImpactMultiplier = 2.0;

  // Difficulté et progression
  static const double baseDifficulty = 1.0;
  static const double difficultyIncreasePerMonth = 0.1;
  static const double maxDifficulty = 5.0;

  // Stockage et ressources
  static const double baseMetalStorage = 1000.0;
  static const double maxMetalStorage = 1000000.0;
  static const double metalStorageUpgradeCost = 1000.0;
  static const double metalStorageUpgradeMultiplier = 2.0;
  static const double storageUpgradeAmount = 100.0;

  // Sauvegarde et données
  static const String saveFileExtension = '.save';
  static const String backupFileExtension = '.backup';
  static const int maxBackupFiles = 3;
  static const Duration backupInterval = Duration(hours: 1);
  static const int maxSaveSize = 1024 * 1024; // 1MB

  // Analytique et monitoring
  static const Duration analyticsFlushInterval = Duration(minutes: 30);
  static const int maxAnalyticsEvents = 1000;
  static const int updateIntervalMs = 1000;

  // Validation et sécurité
  static const int minNameLength = 3;
  static const int maxNameLength = 20;
  static const RegExp validNamePattern = RegExp(r'^[a-zA-Z0-9_]+$');
} 