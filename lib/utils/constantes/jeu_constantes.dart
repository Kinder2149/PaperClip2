import 'package:flutter/material.dart';

class JeuConstantes {
  // Constantes de base
  static const double METAL_INITIAL = 100.0;
  static const double ARGENT_INITIAL = 0.0;
  static const double PRIX_INITIAL = 0.25;
  static const double METAL_PAR_TROMBONE = 0.15;
  static const double QUANTITE_PACK_METAL = 100.0;
  static const double PRIX_METAL_MIN = 14.0;
  static const double PRIX_METAL_MAX = 40.0;
  static const double CAPACITE_STOCKAGE_INITIALE = 1000.0;
  static const double EFFICACITE_BASE = 1.0;
  static const double TAUX_DEGRADATION_RESSOURCES = 0.01;

  // Multiplicateurs de maintenance et efficacité
  static const double MULTIPLICATEUR_EFFICACITE_MAINTENANCE = 0.1;
  static const double REDUCTION_EFFICACITE_MAX = 0.85;

  // Mode crise
  static const Duration DELAI_TRANSITION_CRISE = Duration(milliseconds: 300);
  static const int NIVEAU_DEBLOCAGE_MODE_CRISE = 5;

  // Clés de sauvegarde
  static const String CLE_SAUVEGARDE = 'paperclip_game_save';
  static const String CLE_DOSSIER_SAUVEGARDE = 'paperclip_save_directory';

  // Coûts et limites
  static const double COUT_BASE_AUTOCLIP = 15.0;
  static const double PRIX_MIN = 0.01;
  static const double PRIX_MAX = 0.50;
  static const double METAL_MARCHE_INITIAL = 80000.0;
  static const int COMBO_MAX = 5;
  static const double MULTIPLICATEUR_COMBO = 0.1;

  // Seuils de crise du métal
  static const double SEUIL_CRISE_METAL_50 = METAL_MARCHE_INITIAL * 0.50;
  static const double SEUIL_CRISE_METAL_25 = METAL_MARCHE_INITIAL * 0.25;
  static const double SEUIL_CRISE_METAL_0 = 0.0;

  // Durées
  static const Duration INTERVALLE_SAUVEGARDE_AUTO = Duration(minutes: 5);
  static const Duration INTERVALLE_MAINTENANCE = Duration(minutes: 5);
  static const Duration INTERVALLE_MAJ_MARCHE = Duration(milliseconds: 500);
  static const Duration INTERVALLE_PRODUCTION = Duration(seconds: 1);
  static const Duration INTERVALLE_MAJ_PRIX_METAL = Duration(seconds: 6);
  static const Duration AGE_MAX_EVENEMENT = Duration(days: 1);

  // Production
  static const Duration INTERVALLE_BOUCLE_JEU = Duration(milliseconds: 100);
  static const double TICKS_PAR_SECONDE = 10.0;
  static const double PRODUCTION_BASE_PAR_SECONDE = 1.0;
  static const double PRODUCTION_BASE_PAR_TICK = PRODUCTION_BASE_PAR_SECONDE / TICKS_PAR_SECONDE;

  // Expérience et progression
  static const double XP_PRODUCTION_MANUELLE = 1.5;
  static const double XP_PRODUCTION_AUTO = 0.2;
  static const double XP_VENTE_BASE = 0.5;
  static const double XP_ACHAT_AUTOCLIP = 3.0;
  static const double MULTIPLICATEUR_XP_AMELIORATION = 2.0;
  static const double MULTIPLICATEUR_BOOST_XP = 2.0;
  static const double COUT_BASE_AMELIORATION = 45.0;

  // Limites système
  static const int MAX_EVENEMENTS_STOCKES = 100;
  static const double SATURATION_MARCHE_MIN = 50.0;
  static const double SATURATION_MARCHE_MAX = 150.0;
  static const double VARIATION_PRIX_COMPETITION = 0.2;

  // Améliorations
  static const double MULTIPLICATEUR_AMELIORATION_STOCKAGE = 0.2;
  static const double MULTIPLICATEUR_AMELIORATION_EFFICACITE = 0.11;
  static const double BASE_AMELIORATION_QUANTITE = 0.25;
  static const double BASE_AMELIORATION_MARKETING = 0.1;
  static const double BASE_AMELIORATION_QUALITE = 0.1;
  static const double BASE_AMELIORATION_VITESSE = 0.2;
  static const double BASE_REDUCTION_AUTOMATISATION = 0.1;

  // Niveaux maximum des améliorations
  static const int NIVEAU_MAX_STOCKAGE = 10;
  static const int NIVEAU_MAX_EFFICACITE = 8;
  static const int NIVEAU_MAX_QUANTITE = 10;
  static const int NIVEAU_MAX_MARKETING = 10;

  // Bonus de progression
  static const double MULTIPLICATEUR_XP_BASE = 1.0;
  static const double MULTIPLICATEUR_XP_CHEMIN = 0.2;
  static const double MULTIPLICATEUR_XP_COMBO = 0.1;

  // Bonus quotidiens
  static const double MONTANT_BONUS_QUOTIDIEN = 10.0;
  static const double TAUX_BONUS_REPUTATION = 1.01;

  // Facteurs de réputation
  static const double TAUX_DEGRADATION_REPUTATION = 0.95;
  static const double TAUX_CROISSANCE_REPUTATION = 1.01;
  static const double TAUX_PENALITE_REPUTATION = 0.95;
  static const double REPUTATION_MAX = 2.0;
  static const double REPUTATION_MIN = 0.1;

  // Prix optimaux
  static const double PRIX_OPTIMAL_BAS = 0.25;
  static const double PRIX_OPTIMAL_HAUT = 0.35;

  // Niveaux de déblocage
  static const int NIVEAU_DEBLOCAGE_MARCHE = 8;
  static const int NIVEAU_DEBLOCAGE_AMELIORATIONS = 5;

  // Difficultés et multiplicateurs
  static const double DIFFICULTE_BASE = 1.0;
  static const double AUGMENTATION_DIFFICULTE_PAR_MOIS = 0.1;

  // Maintenance et stockage
  static const double TAUX_MAINTENANCE_STOCKAGE = 0.01;
  static const double CONSOMMATION_METAL_MIN = 0.1;

  // Seuils de ressources
  static const double SEUIL_AVERTISSEMENT = 1000.0;
  static const double SEUIL_CRITIQUE = 500.0;
  static const double SEUIL_EPUISEMENT_MARCHE = 750.0;
  static const double SATURATION_MARCHE_DEFAUT = 100.0;
  static const int MAX_HISTORIQUE_VENTES = 100;
  static const double CHANCE_EVENEMENT_MARCHE = 0.05;

  // Information de version
  static const String VERSION = '1.0.3';
  static const String AUTEUR = 'Kinder2149';
  static const String DERNIERE_MAJ = '25/02/2025';
  static const String NOM_APP = 'PaperClip2';
  static const String PREFIXE_NOM_PARTIE_DEFAUT = 'Partie';
  static const String TITRE_APP = 'ClipFactory Empire';
  static const String TITRE_INTRO_1 = "INITIALISATION";
  static const String TITRE_INTRO_2 = "PRODUCTION";
  static const String TITRE_INTRO_3 = "OPTIMISATION";
  static const String CHEMIN_AUDIO_INTRO = "assets/audio/intro.mp3";

  // Couleurs pour les événements
  static Color getCouleurCrise(String typeEvenement) {
    switch (typeEvenement) {
      case 'KRACH_MARCHE':
        return Colors.red.shade700;
      case 'GUERRE_PRIX':
        return Colors.orange.shade800;
      case 'PIC_DEMANDE':
        return Colors.green.shade700;
      case 'PROBLEMES_QUALITE':
        return Colors.purple.shade700;
      default:
        return Colors.grey;
    }
  }

  // Couleurs pour les notifications
  static Color getCouleurNotification(String priorite) {
    switch (priorite) {
      case 'BASSE':
        return Colors.blue;
      case 'MOYENNE':
        return Colors.orange;
      case 'HAUTE':
        return Colors.deepOrange;
      case 'CRITIQUE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Énumérations
enum CheminProgression {
  PRODUCTION,
  MARKETING,
  EFFICACITE,
  INNOVATION
}

enum TypeExperience {
  GENERAL,
  PRODUCTION,
  VENTE,
  AMELIORATION,
  BONUS_QUOTIDIEN,
  BONUS_COMBO
}

enum TypeMission {
  PRODUIRE_TROMBONES,
  VENDRE_TROMBONES,
  ACHETER_AUTOCLIPS,
  ACHAT_AMELIORATION,
  GAGNER_ARGENT
}

enum EvenementMarche {
  GUERRE_PRIX,
  PIC_DEMANDE,
  KRACH_MARCHE,
  PROBLEMES_QUALITE
}

enum TypeEvenement {
  NIVEAU_SUP,
  CHANGEMENT_MARCHE,
  EPUISEMENT_RESSOURCES,
  AMELIORATION_DISPONIBLE,
  SUCCES_SPECIAL,
  BOOST_XP,
  INFO,
  MODE_CRISE,
  CHANGEMENT_UI,
}

enum ImportanceEvenement {
  BASSE,
  MOYENNE,
  HAUTE,
  CRITIQUE
}

enum ModeJeu {
  INFINI,
  COMPETITIF
}

enum FonctionnaliteDeblocable {
  PRODUCTION_MANUELLE,
  ACHAT_METAL,
  VENTES_MARCHE,
  ECRAN_MARCHE,
  AUTOCLIPS,
  AMELIORATIONS,
} 