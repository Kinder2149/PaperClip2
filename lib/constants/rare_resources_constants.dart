/// Constantes pour le système de ressources rares (Quantum & Points Innovation)
/// 
/// Ces constantes définissent les paramètres de calcul des récompenses au reset
/// et les plafonds maximaux pour chaque ressource rare.
class RareResourcesConstants {
  // ============================================================================
  // QUANTUM - Calcul au reset
  // ============================================================================
  
  /// Quantum de base garanti à chaque reset (minimum)
  static const int QUANTUM_BASE_RESET = 20;
  
  /// Plafond maximum de Quantum pouvant être gagné en un reset
  static const int QUANTUM_MAX_CAP = 500;
  
  /// Multiplicateur appliqué au premier reset (bonus débutant)
  static const double QUANTUM_FIRST_RESET_MULTIPLIER = 1.5;
  
  // Composant PRODUCTION (échelle logarithmique)
  /// Multiplicateur pour le composant production
  static const double QUANTUM_PRODUCTION_MULTIPLIER = 15.0;
  
  /// Seuil minimum de trombones pour commencer à gagner du Quantum via production
  static const int QUANTUM_PRODUCTION_THRESHOLD = 1000000; // 1M trombones
  
  // Composant REVENUS (échelle racine carrée)
  /// Multiplicateur pour le composant revenus
  static const double QUANTUM_REVENUE_MULTIPLIER = 8.0;
  
  /// Seuil minimum d'argent pour commencer à gagner du Quantum via revenus
  static const int QUANTUM_REVENUE_THRESHOLD = 10000; // 10k€
  
  // Composant AUTOCLIPPERS (linéaire)
  /// Multiplicateur pour le composant autoclippers
  static const double QUANTUM_AUTOCLIPPER_MULTIPLIER = 0.8;
  
  // Composant NIVEAU (exponentiel léger)
  /// Multiplicateur pour le composant niveau
  static const double QUANTUM_LEVEL_MULTIPLIER = 12.0;
  
  /// Diviseur pour normaliser le niveau avant calcul exponentiel
  static const int QUANTUM_LEVEL_DIVIDER = 10;
  
  /// Exposant pour le calcul du niveau (progression exponentielle légère)
  static const double QUANTUM_LEVEL_EXPONENT = 1.5;
  
  // Composant TEMPS (plafonné)
  /// Multiplicateur pour le composant temps de jeu
  static const double QUANTUM_TIME_MULTIPLIER = 2.0;
  
  /// Plafond maximum pour le composant temps (en heures)
  static const int QUANTUM_TIME_CAP = 50;
  
  // ============================================================================
  // POINTS INNOVATION - Calcul au reset
  // ============================================================================
  
  /// Points Innovation de base garantis à chaque reset (minimum)
  static const int INNOVATION_BASE_RESET = 10;
  
  /// Plafond maximum de Points Innovation pouvant être gagnés en un reset
  static const int INNOVATION_MAX_CAP = 100;
  
  // Composants du calcul
  /// Multiplicateur pour le nombre de recherches complétées
  static const int INNOVATION_RESEARCH_MULTIPLIER = 2;
  
  /// Multiplicateur pour le niveau du joueur
  static const double INNOVATION_LEVEL_MULTIPLIER = 0.5;
  
  /// Diviseur pour le bonus basé sur le Quantum gagné
  static const int INNOVATION_QUANTUM_BONUS_DIVIDER = 10;
}
