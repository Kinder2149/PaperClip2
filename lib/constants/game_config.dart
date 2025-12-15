// lib/models/game_config.dart
import 'package:flutter/material.dart';

/// Classe centrale pour toutes les constantes du jeu
/// Toutes les constantes du projet doivent être définies ici pour éviter les duplications
class GameConstants {
  //======================================================================
  // SECTION: VERSION ET MÉTADONNÉES
  //======================================================================
  static const String VERSION = '1.0.3';
  static const String AUTHOR = 'Kinder2149';
  static const String LAST_UPDATE = '25/02/2025';
  static const String APP_NAME = 'PaperClip2';
  static const String APP_TITLE = 'ClipFactory Empire';
  static const int CURRENT_BUILD_NUMBER = 3;  // Ajouté depuis UpdateManager
  static const String GAME_MODE_KEY = 'game_mode';

  //======================================================================
  // SECTION: TEXTE D'INTERFACE
  //======================================================================
  static const String DEFAULT_GAME_NAME_PREFIX = 'Partie';
  static const String INTRO_TITLE_1 = "INITIALISATION";
  static const String INTRO_TITLE_2 = "PRODUCTION";
  static const String INTRO_TITLE_3 = "OPTIMISATION";
  static const String INTRO_AUDIO_PATH = "assets/audio/screenmusic.wav";

  //======================================================================
  // SECTION: SAUVEGARDE ET STOCKAGE
  //======================================================================
  // Clés de sauvegarde
  static const String SAVE_KEY = 'paperclip_game_save';
  static const String SAVE_DIR_KEY = 'paperclip_save_directory';
  static const String SAVE_PREFIX = 'paperclip_save_';      // Depuis StorageConstants
  static const String BACKUP_PREFIX = 'paperclip_backup_';   // Depuis StorageConstants
  static const String CURRENT_SAVE_FORMAT_VERSION = '2.0';  // Depuis StorageConstants
  static const int MAX_BACKUPS = 3;                        // Depuis StorageConstants
  static const String BACKUP_DELIMITER = '_backup_';        // Depuis StorageConstants
  static const int MAX_STORAGE_SIZE = 50 * 1024 * 1024;    // Depuis AutoSaveService
  static const Duration MAX_SAVE_AGE = Duration(days: 30); // Depuis AutoSaveService
  static const int MAX_TOTAL_SAVES = 10;                   // Depuis AutoSaveService
  static const int MAX_FAILED_ATTEMPTS = 3;                // Depuis AutoSaveService
  static const Duration CLEANUP_INTERVAL = Duration(hours: 24); // Depuis AutoSaveService
  //======================================================================
  static const Duration AUTO_SAVE_INTERVAL = Duration(minutes: 5);    // Unifié depuis AutoSaveService
  static const Duration MAINTENANCE_INTERVAL = Duration(minutes: 5);  // Unifié depuis GameState
  static const Duration MARKET_UPDATE_INTERVAL = Duration(seconds: 10); // Unifié depuis GameState
  static const Duration CRISIS_TRANSITION_DELAY = Duration(milliseconds: 300);
  
  //======================================================================
  // SECTION: MARCHÉ ET VENTE
  //======================================================================
  static const double SATURATION_DECAY_RATE = 0.01;     // Taux de décroissance naturelle de la saturation du marché
  static const double BASE_DEMAND = 10.0;              // Demande de base pour les trombones
  static const double MAX_PRICE_THRESHOLD = 0.50;      // Prix maximum (en euros) au-delà duquel la demande commence à chuter drastiquement
  static const double MARKETING_BOOST_PER_LEVEL = 0.15; // Boost de demande par niveau de marketing
  static const int MAX_SALES_HISTORY = 10;             // Nombre maximal d'entrées dans l'historique des ventes
  static const double SATURATION_IMPACT_PER_SALE = 0.005; // Impact d'une vente sur la saturation du marché
  static const double MIN_MARKET_SATURATION = 0.05;    // Saturation minimale du marché
  // Ces constantes sont déjà définies dans la section "DURÉES ET INTERVALLES DE TEMPS" ci-dessus
  // static const Duration PRODUCTION_INTERVAL = Duration(seconds: 1);
  // static const Duration METAL_PRICE_UPDATE_INTERVAL = Duration(seconds: 6);
  // static const Duration EVENT_MAX_AGE = Duration(days: 1);
  // static const Duration GAME_LOOP_INTERVAL = Duration(milliseconds: 100);

  //======================================================================
  // SECTION: CONSTANTES DE BASE ET RESSOURCES
  //======================================================================
  static const double INITIAL_METAL = 500.0;
  static const double INITIAL_MONEY = 0.0;
  static const double INITIAL_PRICE = 0.25;
  static const double METAL_PER_PAPERCLIP = 0.1;
  static const double METAL_PACK_AMOUNT = 10.0;
  static const double METAL_EFFICIENCY_BASE = 1.0;
  static const double METAL_EFFICIENCY_INCREMENT = 0.1;
  static const double INITIAL_STORAGE_CAPACITY = 1000.0;
  static const double BASE_EFFICIENCY = 1.0;
  static const double RESOURCE_DECAY_RATE = 0.01;
  
  // Maintenance et stockage des ressources
  static const double STORAGE_MAINTENANCE_RATE = 0.01;  // Unifié depuis GameStateResource
  static const double MIN_METAL_CONSUMPTION = 0.1;      // Unifié depuis GameStateResource
  
  // Ces constantes sont déjà définies ailleurs dans le fichier
  static const double MAINTENANCE_EFFICIENCY_MULTIPLIER = 0.1;
  static const double EFFICIENCY_MAX_REDUCTION = 0.85;
  static const double EFFICIENCY_UPGRADE_BASE = 45.0;
  static const double EFFICIENCY_UPGRADE_MULTIPLIER = 0.1;

  //======================================================================
  // SECTION: MODE CRISE
  //======================================================================
  static const int CRISIS_MODE_UNLOCK_LEVEL = 5;
  static const double INITIAL_MARKET_METAL = 80000.0;
  static const double METAL_CRISIS_THRESHOLD_50 = INITIAL_MARKET_METAL * 0.50;  // 50%
  static const double METAL_CRISIS_THRESHOLD_25 = INITIAL_MARKET_METAL * 0.25;  // 25%
  static const double METAL_CRISIS_THRESHOLD_0 = 0.0;  // 0%
  //======================================================================
  // SECTION: COÛTS ET LIMITES DU JEU
  //======================================================================
  // Coûts de production et limites
  static const double BASE_AUTOCLIPPER_COST = 15.0;
  static const double MIN_PRICE = 0.01;
  static const double MAX_PRICE = 0.50;
  
  static const int MAX_COMBO_COUNT = 5;
  static const double COMBO_MULTIPLIER = 0.1;  // Pour le calcul du multiplicateur de combo
  // Constantes de métal définies plus haut :
  // - METAL_PER_PAPERCLIP = 0.1
  // - METAL_PACK_AMOUNT = 10.0
  // - METAL_EFFICIENCY_BASE = 1.0
  // - METAL_EFFICIENCY_INCREMENT = 0.1
  static const double AUTOCLIPPER_COST_MULTIPLIER = 1.15; // Multiplicateur de coût pour les autoclippers
  static const double STORAGE_UPGRADE_MULTIPLIER = 0.5; // Multiplicateur pour l'amélioration de stockage
  static const double QUALITY_UPGRADE_BASE = 0.1; // Amélioration de base de la qualité
  static const double AUTOMATION_DISCOUNT_BASE = 0.1; // Réduction de base pour l'automatisation
  static const double STORAGE_MULTIPLIER = 1.2; // Multiplicateur pour l'amélioration de stockage
  static const double BASE_AUTOCLIPPER_PRODUCTION = 0.1; // Production de base des autoclippers
  static const int MAX_EFFICIENCY_LEVEL = 10; // Niveau maximal d'efficacité
  
  // Prix du métal sur le marché
  static const double MIN_METAL_PRICE = 10.0; // Prix minimum du métal
  static const double MAX_METAL_PRICE = 25.0; // Prix maximum du métal

  // Niveaux de déblocage
  static const int MARKET_UNLOCK_LEVEL = 5; // Niveau requis pour débloquer le marché
  static const int UPGRADES_UNLOCK_LEVEL = 7; // Niveau requis pour débloquer les améliorations
  
  // Marché et progression
  static const double DEFAULT_MARKET_SATURATION = 0.5; // Saturation de marché par défaut
  static const double BASE_DIFFICULTY = 1.0; // Difficulté de base
  static const double WARNING_THRESHOLD = 30.0; // Seuil d'avertissement pour les ressources
  static const double CRITICAL_THRESHOLD = 10.0; // Seuil critique pour les ressources
  static const double GLOBAL_PROGRESS_TARGET = 100000.0; // Objectif global de progression

  //======================================================================
  // SECTION: AMÉLIORATIONS ET BONUS
  //======================================================================
  static const double SPEED_BONUS_PER_LEVEL = 0.2; // Bonus de vitesse par niveau
  static const double BULK_BONUS_PER_LEVEL = 0.35; // Bonus de quantité par niveau
  
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
  // Durée déjà définie plus haut
  static const Duration PRODUCTION_INTERVAL = Duration(seconds: 1);
  static const Duration METAL_PRICE_UPDATE_INTERVAL = Duration(seconds: 6);
  static const Duration EVENT_MAX_AGE = Duration(days: 1);
  static const Duration OFFLINE_MAX_DURATION = Duration(hours: 8);
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

  // Limites système
  static const int MAX_STORED_EVENTS = 100;
  static const double MIN_MARKET_SATURATION_LEGACY = 50.0; // Renommé pour éviter le conflit avec la nouvelle constante
  static const double MAX_MARKET_SATURATION = 150.0;
  static const double COMPETITION_PRICE_VARIATION = 0.2;

  // Constantes pour les améliorations
  // STORAGE_UPGRADE_MULTIPLIER déjà défini plus haut (valeur 0.5)
  // EFFICIENCY_UPGRADE_MULTIPLIER déjà défini plus haut (valeur 0.1)
  // EFFICIENCY_UPGRADE_BASE déjà défini plus haut
  static const double BULK_UPGRADE_BASE = 0.25;            
  static const double MARKETING_UPGRADE_BASE = 0.1;        
  // QUALITY_UPGRADE_BASE déjà défini plus haut
  static const double SPEED_UPGRADE_BASE = 0.2;            
  // AUTOMATION_DISCOUNT_BASE déjà défini plus haut (valeur 0.05)

  // Niveaux maximum des améliorations
  static const int MAX_STORAGE_LEVEL = 20;
  // MAX_EFFICIENCY_LEVEL déjà défini plus haut
  static const int MAX_BULK_LEVEL = 20;
  static const int MAX_MARKETING_LEVEL = 20;

  // Bonus de progression
  static const double BASE_XP_MULTIPLIER = 1.0;
  static const double PATH_XP_MULTIPLIER = 0.2;
  static const double COMBO_XP_MULTIPLIER = 0.1;

  // Bonus quotidiens
  static const double DAILY_BONUS_AMOUNT = 10.0;
  // REPUTATION_BONUS_RATE déjà défini plus haut
  
  //======================================================================
  // SECTION: MÉTHODES D'UTILITAIRES
  //======================================================================
  
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
  SYSTEM,
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
