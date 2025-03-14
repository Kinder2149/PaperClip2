// lib/models/game_config.dart
import 'package:flutter/material.dart';

class GameConstants {
  // Constantes de base
  static const double INITIAL_METAL = 100;
  static const double INITIAL_MONEY = 0;
  static const double INITIAL_PRICE = 0.25;
  static const double METAL_PER_PAPERCLIP = 0.15;
  static const double METAL_PACK_AMOUNT = 100.0;
  static const double MIN_METAL_PRICE = 14.0;
  static const double MAX_METAL_PRICE = 40.0;
  static const double INITIAL_STORAGE_CAPACITY = 1000.0;
  static const double BASE_EFFICIENCY = 1.0;
  static const double RESOURCE_DECAY_RATE = 0.01;
  static const String GAME_MODE_KEY = 'game_mode';

  static const double MAINTENANCE_EFFICIENCY_MULTIPLIER = 0.1;
  static const double EFFICIENCY_MAX_REDUCTION = 0.85;

  // Ajouter les constantes pour le mode crise
  static const Duration CRISIS_TRANSITION_DELAY = Duration(milliseconds: 300);
  static const int CRISIS_MODE_UNLOCK_LEVEL = 5;


  // Clés de sauvegarde
  static const String SAVE_KEY = 'paperclip_game_save';
  static const String SAVE_DIR_KEY = 'paperclip_save_directory';

  // Coûts et limites
  static const double BASE_AUTOCLIPPER_COST = 15.0;
  static const double MIN_PRICE = 0.01;
  static const double MAX_PRICE = 0.50;
  static const double INITIAL_MARKET_METAL = 80000.0; //80000
  static const int MAX_COMBO_COUNT = 5;
  static const double COMBO_MULTIPLIER = 0.1;  // Pour le calcul du multiplicateur de combo

  // Seuils de crise du métal
  static const double METAL_CRISIS_THRESHOLD_50 = INITIAL_MARKET_METAL * 0.50;  // 50%
  static const double METAL_CRISIS_THRESHOLD_25 = INITIAL_MARKET_METAL * 0.25;  // 25%
  static const double METAL_CRISIS_THRESHOLD_0 = 0.0;  // 0%


  // Durées
  static const Duration AUTO_SAVE_INTERVAL = Duration(minutes: 5);
  static const Duration MAINTENANCE_INTERVAL = Duration(minutes: 5);
  static const Duration MARKET_UPDATE_INTERVAL = Duration(milliseconds: 500);
  static const Duration PRODUCTION_INTERVAL = Duration(seconds: 1);
  static const Duration METAL_PRICE_UPDATE_INTERVAL = Duration(seconds: 6);
  static const Duration EVENT_MAX_AGE = Duration(days: 1);


  static const Duration GAME_LOOP_INTERVAL = Duration(milliseconds: 100);
  static const double TICKS_PER_SECOND = 10.0; // 1000ms / 100ms
  static const double BASE_PRODUCTION_PER_SECOND = 1.0; // 1 trombone par seconde
  static const double BASE_PRODUCTION_PER_TICK = BASE_PRODUCTION_PER_SECOND / TICKS_PER_SECOND; // 0.1 par tick




  //  "Expérience et progression"
  static const double MANUAL_PRODUCTION_XP = 1.5;
  static const double AUTO_PRODUCTION_XP = 0.2;
  static const double SALE_BASE_XP = 0.5;
  static const double AUTOCLIPPER_PURCHASE_XP = 3.0;
  static const double UPGRADE_XP_MULTIPLIER = 2.0;
  static const double XP_BOOST_MULTIPLIER = 2.0;
  // À ajouter dans une nouvelle section "Améliorations"
  static const double EFFICIENCY_UPGRADE_BASE = 45.0;





  // Limites système
  static const int MAX_STORED_EVENTS = 100;
  static const double MIN_MARKET_SATURATION = 50.0;
  static const double MAX_MARKET_SATURATION = 150.0;
  static const double COMPETITION_PRICE_VARIATION = 0.2;

  // Constantes pour les améliorations
  static const double STORAGE_UPGRADE_MULTIPLIER = 0.2;     // 20% par niveau
  static const double EFFICIENCY_UPGRADE_MULTIPLIER = 0.11; // 11% par niveau
  static const double BULK_UPGRADE_BASE = 0.25;            // 25% par niveau
  static const double MARKETING_UPGRADE_BASE = 0.1;        // 10% par niveau
  static const double QUALITY_UPGRADE_BASE = 0.1;          // 10% par niveau
  static const double SPEED_UPGRADE_BASE = 0.2;            // 20% par niveau
  static const double AUTOMATION_DISCOUNT_BASE = 0.1;      // 10% par niveau

  // Niveaux maximum des améliorations
  static const int MAX_STORAGE_LEVEL = 10;
  static const int MAX_EFFICIENCY_LEVEL = 8;
  static const int MAX_BULK_LEVEL = 10;
  static const int MAX_MARKETING_LEVEL = 10;



  // Bonus de progression
  static const double BASE_XP_MULTIPLIER = 1.0;
  static const double PATH_XP_MULTIPLIER = 0.2;
  static const double COMBO_XP_MULTIPLIER = 0.1;


  // Bonus quotidiens
  static const double DAILY_BONUS_AMOUNT = 10.0;
  static const double REPUTATION_BONUS_RATE = 1.01;

//Crise passagère
  static Color getCrisisColor(MarketEvent event) {
    switch (event) {
      case MarketEvent.MARKET_CRASH:
        return Colors.red.shade700;
      case MarketEvent.PRICE_WAR:
        return Colors.orange.shade800;
      case MarketEvent.DEMAND_SPIKE:
        return Colors.green.shade700;
      case MarketEvent.QUALITY_CONCERNS:
        return Colors.purple.shade700;
    }
  }


  // Intervalles de temps

  static const double BASE_AUTOCLIPPER_PRODUCTION = 1.0; // 1 trombone par seconde


  static const Duration AUTOSAVE_INTERVAL = Duration(minutes: 5);

  // Bonus des améliorations (en pourcentage)
  static const double SPEED_BONUS_PER_LEVEL = 0.20;    // +20% vitesse
  static const double BULK_BONUS_PER_LEVEL = 0.35;     // +35% quantité


  // Facteurs de réputation
  static const double REPUTATION_DECAY_RATE = 0.95;
  static const double REPUTATION_GROWTH_RATE = 1.01;
  static const double REPUTATION_PENALTY_RATE = 0.95;
  static const double MAX_REPUTATION = 2.0;
  static const double MIN_REPUTATION = 0.1;

  // Prix optimaux
  static const double OPTIMAL_PRICE_LOW = 0.25;
  static const double OPTIMAL_PRICE_HIGH = 0.35;
  // Niveaux de déblocage
  static const int MARKET_UNLOCK_LEVEL = 8;
  static const int UPGRADES_UNLOCK_LEVEL = 5;

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
  static const String VERSION = '1.0.3';
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
  XP_BOOST,
  INFO,
  CRISIS_MODE,
  UI_CHANGE,
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
enum GameMode {
  INFINITE,    // Mode infini, comme le jeu actuel
  COMPETITIVE  // Mode compétitif, avec focus sur les statistiques et scores
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
