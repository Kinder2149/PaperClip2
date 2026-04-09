import 'dart:math';
import '../../constants/rare_resources_constants.dart';

/// Calculateur pour les récompenses de ressources rares au reset
/// 
/// Ce service contient les formules de calcul pour déterminer combien de
/// Quantum et de Points Innovation le joueur gagne lors d'un reset entreprise.
/// 
/// Les formules utilisent plusieurs composants de progression pour équilibrer
/// les gains et encourager différents styles de jeu.
class RareResourcesCalculator {
  // ============================================================================
  // Calcul Quantum
  // ============================================================================
  
  /// Calcule le Quantum gagné lors d'un reset entreprise
  /// 
  /// Formule : BASE + PRODUCTION + REVENUS + AUTOCLIPPERS + NIVEAU + TEMPS
  /// 
  /// Composants :
  /// - BASE : 20 Q minimum garanti
  /// - PRODUCTION : log10(trombones / 1M) × 15 (échelle logarithmique)
  /// - REVENUS : sqrt(argent / 10k) × 8 (échelle racine carrée)
  /// - AUTOCLIPPERS : nombre × 0.8 (linéaire)
  /// - NIVEAU : (niveau / 10)^1.5 × 12 (exponentiel léger)
  /// - TEMPS : min(heures × 2, 50) (plafonné)
  /// 
  /// Bonus premier reset : ×1.5
  /// Plafond maximum : 500 Q
  /// 
  /// [totalPaperclipsProduced] : Total de trombones produits durant la partie
  /// [totalMoneyEarned] : Total d'argent gagné durant la partie
  /// [autoClipperCount] : Nombre d'autoclippers possédés
  /// [playerLevel] : Niveau du joueur
  /// [playTimeHours] : Temps de jeu en heures
  /// [resetCount] : Nombre de resets déjà effectués (0 = premier reset)
  /// 
  /// Retourne le nombre de Quantum gagné (arrondi à l'entier inférieur)
  static int calculateQuantumReward({
    required int totalPaperclipsProduced,
    required double totalMoneyEarned,
    required int autoClipperCount,
    required int playerLevel,
    required double playTimeHours,
    required int resetCount,
  }) {
    int base = RareResourcesConstants.QUANTUM_BASE_RESET;
    
    // 1. Composant PRODUCTION (échelle logarithmique)
    // Récompense la production massive de trombones
    double production = 0.0;
    if (totalPaperclipsProduced >= RareResourcesConstants.QUANTUM_PRODUCTION_THRESHOLD) {
      production = log(totalPaperclipsProduced / RareResourcesConstants.QUANTUM_PRODUCTION_THRESHOLD) / 
                   ln10 * 
                   RareResourcesConstants.QUANTUM_PRODUCTION_MULTIPLIER;
    }
    
    // 2. Composant REVENUS (échelle racine carrée)
    // Récompense la génération d'argent
    double revenue = 0.0;
    if (totalMoneyEarned >= RareResourcesConstants.QUANTUM_REVENUE_THRESHOLD) {
      revenue = sqrt(totalMoneyEarned / RareResourcesConstants.QUANTUM_REVENUE_THRESHOLD) * 
                RareResourcesConstants.QUANTUM_REVENUE_MULTIPLIER;
    }
    
    // 3. Composant AUTOCLIPPERS (linéaire)
    // Récompense l'investissement dans l'automatisation
    double autoclippers = autoClipperCount * 
                          RareResourcesConstants.QUANTUM_AUTOCLIPPER_MULTIPLIER;
    
    // 4. Composant NIVEAU (exponentiel léger)
    // Récompense la progression du joueur
    double level = pow(
      playerLevel / RareResourcesConstants.QUANTUM_LEVEL_DIVIDER,
      RareResourcesConstants.QUANTUM_LEVEL_EXPONENT
    ).toDouble() * RareResourcesConstants.QUANTUM_LEVEL_MULTIPLIER;
    
    // 5. Composant TEMPS (plafonné)
    // Récompense le temps investi, mais plafonné pour éviter l'idle farming
    double time = min(
      playTimeHours * RareResourcesConstants.QUANTUM_TIME_MULTIPLIER,
      RareResourcesConstants.QUANTUM_TIME_CAP.toDouble()
    );
    
    // Somme de tous les composants
    double total = base + production + revenue + autoclippers + level + time;
    
    // Bonus premier reset (encouragement débutant)
    if (resetCount == 0) {
      total *= RareResourcesConstants.QUANTUM_FIRST_RESET_MULTIPLIER;
    }
    
    // Application du plafond maximum et arrondi
    return min(
      RareResourcesConstants.QUANTUM_MAX_CAP,
      max(base, total.floor())
    );
  }
  
  // ============================================================================
  // Calcul Points Innovation
  // ============================================================================
  
  /// Calcule les Points Innovation gagnés lors d'un reset entreprise
  /// 
  /// Formule : BASE + RECHERCHES + NIVEAU + BONUS_QUANTUM
  /// 
  /// Composants :
  /// - BASE : 10 PI minimum garanti
  /// - RECHERCHES : nombre × 2 (récompense exploration arbre)
  /// - NIVEAU : niveau × 0.5 (progression joueur)
  /// - BONUS_QUANTUM : quantum gagné / 10 (synergie avec Quantum)
  /// 
  /// Plafond maximum : 100 PI
  /// 
  /// [researchesCompleted] : Nombre de recherches complétées dans l'arbre
  /// [playerLevel] : Niveau du joueur
  /// [quantumGained] : Quantum gagné lors de ce reset
  /// 
  /// Retourne le nombre de Points Innovation gagnés (arrondi à l'entier inférieur)
  static int calculateInnovationPointsReward({
    required int researchesCompleted,
    required int playerLevel,
    required int quantumGained,
  }) {
    int base = RareResourcesConstants.INNOVATION_BASE_RESET;
    
    // 1. Composant RECHERCHES
    // Récompense l'exploration de l'arbre de recherche
    int research = researchesCompleted * 
                   RareResourcesConstants.INNOVATION_RESEARCH_MULTIPLIER;
    
    // 2. Composant NIVEAU
    // Récompense la progression du joueur
    double level = playerLevel * 
                   RareResourcesConstants.INNOVATION_LEVEL_MULTIPLIER;
    
    // 3. Composant BONUS_QUANTUM
    // Synergie avec le Quantum gagné (gros reset = plus de PI)
    double quantumBonus = quantumGained / 
                          RareResourcesConstants.INNOVATION_QUANTUM_BONUS_DIVIDER;
    
    // Somme de tous les composants
    double total = base + research + level + quantumBonus;
    
    // Application du plafond maximum et arrondi
    return min(
      RareResourcesConstants.INNOVATION_MAX_CAP,
      max(base, total.floor())
    );
  }
}
