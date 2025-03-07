import 'package:flutter/material.dart';

class GameConstants {
  // Version du jeu
  static const String VERSION = '1.0.3';
  static const String SAVE_KEY = 'paperclip_game_save';

  // Ressources initiales
  static const double INITIAL_MONEY = 10.0;
  static const double INITIAL_METAL = 5.0;
  static const double INITIAL_PRICE = 0.25;
  static const double METAL_PER_PAPERCLIP = 0.1;
  static const double METAL_PACK_AMOUNT = 10.0;

  // Limites de marché
  static const double MIN_PRICE = 0.01;
  static const double MAX_PRICE = 1.0;
  static const double BASE_METAL_PRICE = 0.5;
  static const double MIN_METAL_PRICE = 0.1;
  static const double MAX_METAL_PRICE = 2.0;
  static const double INITIAL_MARKET_STOCK = 1000.0;
  static const double MIN_MARKET_STOCK = 100.0;
  static const double MAX_MARKET_STOCK = 10000.0;

  // Paramètres de crise
  static const double CRISIS_TRIGGER_PRICE = 1.5;
  static const double CRISIS_TRIGGER_STOCK = 200.0;
  static const double CRISIS_END_PRICE = 0.8;
  static const double CRISIS_END_STOCK = 500.0;

  // Paramètres de progression
  static const int MARKET_UNLOCK_LEVEL = 2;
  static const int UPGRADES_UNLOCK_LEVEL = 3;
  static const int AUTOMATION_UNLOCK_LEVEL = 4;
  static const double BASE_XP_REQUIREMENT = 100.0;
  static const double XP_MULTIPLIER = 1.5;
  static const double MANUAL_PRODUCTION_XP = 1.0;
  static const double AUTO_PRODUCTION_XP = 0.5;
  static const double SALE_BASE_XP = 0.2;
  static const double UPGRADE_XP_MULTIPLIER = 10.0;

  // Paramètres de combo
  static const int MAX_COMBO_COUNT = 10;
  static const double COMBO_MULTIPLIER = 0.1;
  static const Duration COMBO_TIMEOUT = Duration(seconds: 1);

  // Paramètres d'automation
  static const double BASE_AUTOCLIPPER_COST = 100.0;
  static const double AUTOCLIPPER_COST_MULTIPLIER = 1.5;
  static const double AUTO_PRODUCTION_INTERVAL = 1.0;

  // Paramètres de stockage
  static const double BASE_STORAGE_CAPACITY = 100.0;
  static const double STORAGE_UPGRADE_MULTIPLIER = 2.0;
  static const double STORAGE_EFFICIENCY_DECAY = 0.01;
  static const double MIN_STORAGE_EFFICIENCY = 0.5;

  // Paramètres de marché
  static const double MARKET_VOLATILITY = 0.1;
  static const double MARKET_TREND_STRENGTH = 0.05;
  static const double REPUTATION_DECAY = 0.01;
  static const double MAX_REPUTATION = 2.0;
  static const double MIN_REPUTATION = 0.5;

  // Paramètres de sauvegarde
  static const Duration AUTO_SAVE_INTERVAL = Duration(minutes: 5);
  static const int MAX_SAVE_COUNT = 10;
  static const Duration BACKUP_RETENTION = Duration(days: 7);

  // Paramètres de mode compétitif
  static const Duration COMPETITIVE_TIME_LIMIT = Duration(hours: 1);
  static const double COMPETITIVE_SCORE_MULTIPLIER = 1.5;
  static const double TIME_BONUS_MULTIPLIER = 0.5;
  static const double EFFICIENCY_BONUS_MULTIPLIER = 0.3;

  // Constantes de base
  static const double INITIAL_STORAGE_CAPACITY = 1000.0;
  static const double BASE_EFFICIENCY = 1.0;
  static const double RESOURCE_DECAY_RATE = 0.01;
  static const String GAME_MODE_KEY = 'game_mode';

  static const double MAINTENANCE_EFFICIENCY_MULTIPLIER = 0.1;
  static const double EFFICIENCY_MAX_REDUCTION = 0.85;

  // Constantes pour le mode crise
  static const Duration CRISIS_TRANSITION_DELAY = Duration(milliseconds: 300);
  static const int CRISIS_MODE_UNLOCK_LEVEL = 5;

  // Clés de sauvegarde
  static const String SAVE_DIR_KEY = 'paperclip_save_directory';

  // Coûts et limites
  static const double INITIAL_MARKET_METAL = 80000.0;
  static const double COMPETITION_PRICE_VARIATION = 0.2;

  // Seuils de crise du métal
  static const double METAL_CRISIS_THRESHOLD_50 = INITIAL_MARKET_METAL * 0.50;
  static const double METAL_CRISIS_THRESHOLD_25 = INITIAL_MARKET_METAL * 0.25;
  static const double METAL_CRISIS_THRESHOLD_0 = 0.0;

  // Durées
  static const Duration MAINTENANCE_INTERVAL = Duration(minutes: 5);
  static const Duration MARKET_UPDATE_INTERVAL = Duration(milliseconds: 500);
  static const Duration PRODUCTION_INTERVAL = Duration(seconds: 1);
  static const Duration METAL_PRICE_UPDATE_INTERVAL = Duration(seconds: 6);
  static const Duration EVENT_MAX_AGE = Duration(days: 1);

  static const Duration GAME_LOOP_INTERVAL = Duration(milliseconds: 100);
  static const double TICKS_PER_SECOND = 10.0;
  static const double BASE_PRODUCTION_PER_SECOND = 1.0;
  static const double BASE_PRODUCTION_PER_TICK = BASE_PRODUCTION_PER_SECOND / TICKS_PER_SECOND;

  // Expérience et progression
  static const double AUTOCLIPPER_PURCHASE_XP = 3.0;
  static const double XP_BOOST_MULTIPLIER = 2.0;
  static const double EFFICIENCY_UPGRADE_BASE = 45.0;

  // Limites système
  static const int MAX_STORED_EVENTS = 100;
  static const double MIN_MARKET_SATURATION = 50.0;
  static const double MAX_MARKET_SATURATION = 150.0;

  // Facteurs de réputation
  static const double REPUTATION_GROWTH_RATE = 1.01;
  static const double REPUTATION_PENALTY_RATE = 0.95;

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
  static const double MARKET_DEPLETION_THRESHOLD = 750.0;
  static const double DEFAULT_MARKET_SATURATION = 100.0;
  static const int MAX_SALES_HISTORY = 100;
  static const double MARKET_EVENT_CHANCE = 0.05;

  // Information de version
  static const String AUTHOR = 'Kinder2149';
  static const String LAST_UPDATE = '25/02/2025';
  static const String APP_NAME = 'PaperClip2';

  static const String DEFAULT_GAME_NAME_PREFIX = 'Partie';
  static const String APP_TITLE = 'ClipFactory Empire';
  static const String INTRO_TITLE_1 = "INITIALISATION";
  static const String INTRO_TITLE_2 = "PRODUCTION";
  static const String INTRO_TITLE_3 = "OPTIMISATION";
  static const String INTRO_AUDIO_PATH = "assets/audio/intro.mp3";
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

enum GameMode {
  INFINITE,
  COMPETITIVE
}

enum EventType {
  RESOURCE_DEPLETION,
  MARKET_CHANGE,
  ACHIEVEMENT,
  MILESTONE,
  CRISIS,
  INTERFACE_TRANSITION
}

enum EventImportance {
  LOW,
  MEDIUM,
  HIGH,
  CRITICAL
}

enum NotificationPriority {
  LOW,
  MEDIUM,
  HIGH,
  URGENT
}

enum UpgradeType {
  PRODUCTION,
  EFFICIENCY,
  MARKETING,
  STORAGE,
  AUTOMATION
}

enum FeatureType {
  MARKET,
  UPGRADES,
  AUTOMATION,
  STORAGE,
  MARKETING
}

class UnlockableFeature {
  final String name;
  final String description;
  final FeatureType type;

  UnlockableFeature(this.name, this.description, this.type);
}

class MarketEvent {
  final MarketEventType type;
  final double value;
  final DateTime timestamp;

  MarketEvent(this.type, this.value) : timestamp = DateTime.now();
}

enum MarketEventType {
  PRICE_SPIKE,
  PRICE_CRASH,
  STOCK_SHORTAGE,
  STOCK_SURPLUS
}

enum AchievementType {
  PAPERCLIPS_PRODUCED,
  MONEY_EARNED,
  UPGRADES_BOUGHT,
  LEVEL_REACHED,
  EFFICIENCY_REACHED,
  COMBO_ACHIEVED,
  TIME_PLAYED
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final int requiredValue;
  final AchievementType type;
  bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredValue,
    required this.type,
    this.isUnlocked = false,
  });
}

class GameError implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  GameError(this.message, {this.code, this.details});

  @override
  String toString() => 'GameError: $message${code != null ? ' (Code: $code)' : ''}';
} 