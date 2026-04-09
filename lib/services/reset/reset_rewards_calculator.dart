import 'dart:math';

/// Calculateur de récompenses pour le système de reset progression
/// 
/// Calcule les gains en Quantum et Points Innovation basés sur la progression
/// du joueur au moment du reset.
class ResetRewardsCalculator {
  // Constantes formule Quantum
  static const double QUANTUM_BASE = 20.0;
  static const double QUANTUM_PRODUCTION_MULTIPLIER = 15.0;
  static const double QUANTUM_REVENUE_MULTIPLIER = 8.0;
  static const double QUANTUM_AUTOCLIPPER_MULTIPLIER = 0.8;
  static const double QUANTUM_LEVEL_MULTIPLIER = 12.0;
  static const double QUANTUM_TIME_MULTIPLIER = 2.0;
  static const double QUANTUM_TIME_CAP = 50.0;
  static const double QUANTUM_FIRST_RESET_BONUS = 1.5;
  static const double QUANTUM_MAX_CAP = 500.0;
  
  // Constantes formule Points Innovation
  static const double INNOVATION_BASE = 10.0;
  static const double INNOVATION_RESEARCH_MULTIPLIER = 2.0;
  static const double INNOVATION_LEVEL_MULTIPLIER = 0.5;
  static const double INNOVATION_QUANTUM_DIVISOR = 10.0;
  static const double INNOVATION_MAX_CAP = 100.0;
  
  /// Calcule le gain de Quantum au reset
  /// 
  /// Formule : BASE + PRODUCTION + REVENUS + AUTOCLIPPERS + NIVEAU + TEMPS
  /// Avec bonus premier reset (×1.5) et bonus recherches META
  static int calculateQuantumReward({
    required double totalPaperclipsProduced,
    required double totalMoneyEarned,
    required int autoClipperCount,
    required int playerLevel,
    required double playTimeHours,
    required int resetCount,
    required double researchBonus, // Bonus des recherches META (0.0 à 1.0+)
  }) {
    // Composantes de base
    double base = QUANTUM_BASE;
    
    // Production : log10(totalPaperclips / 1_000_000) × 15
    double production = 0.0;
    if (totalPaperclipsProduced >= 1000000) {
      production = log(totalPaperclipsProduced / 1000000) / ln10 * QUANTUM_PRODUCTION_MULTIPLIER;
    }
    
    // Revenus : sqrt(totalMoney / 10_000) × 8
    double revenue = 0.0;
    if (totalMoneyEarned >= 10000) {
      revenue = sqrt(totalMoneyEarned / 10000) * QUANTUM_REVENUE_MULTIPLIER;
    }
    
    // Autoclippers : count × 0.8
    double autoclippers = autoClipperCount * QUANTUM_AUTOCLIPPER_MULTIPLIER;
    
    // Niveau : (level / 10)^1.5 × 12
    double level = pow(playerLevel / 10.0, 1.5).toDouble() * QUANTUM_LEVEL_MULTIPLIER;
    
    // Temps : min(playTimeHours × 2, 50)
    double time = min(playTimeHours * QUANTUM_TIME_MULTIPLIER, QUANTUM_TIME_CAP);
    
    // Total avant bonus
    double total = base + production + revenue + autoclippers + level + time;
    
    // Bonus premier reset (×1.5)
    if (resetCount == 0) {
      total *= QUANTUM_FIRST_RESET_BONUS;
    }
    
    // Bonus recherches META (additive)
    total *= (1.0 + researchBonus);
    
    // Plafond maximum
    total = min(total, QUANTUM_MAX_CAP);
    
    return max(0, total.round());
  }
  
  /// Calcule le gain de Points Innovation au reset
  /// 
  /// Formule : BASE + RECHERCHES + NIVEAU + BONUS_QUANTUM
  static int calculateInnovationPointsReward({
    required int researchesCompleted,
    required int playerLevel,
    required int quantumGained,
    required double researchBonus, // Bonus des recherches META (0.0 à 1.0+)
  }) {
    // Composantes de base
    double base = INNOVATION_BASE;
    
    // Recherches : count × 2
    double researches = researchesCompleted * INNOVATION_RESEARCH_MULTIPLIER;
    
    // Niveau : level × 0.5
    double level = playerLevel * INNOVATION_LEVEL_MULTIPLIER;
    
    // Bonus Quantum : quantumGained / 10
    double quantumBonus = quantumGained / INNOVATION_QUANTUM_DIVISOR;
    
    // Total avant bonus
    double total = base + researches + level + quantumBonus;
    
    // Bonus recherches META (additive)
    total *= (1.0 + researchBonus);
    
    // Plafond maximum
    total = min(total, INNOVATION_MAX_CAP);
    
    return max(0, total.round());
  }
  
  /// Calcule les deux récompenses en une seule passe
  static ResetRewards calculateRewards({
    required double totalPaperclipsProduced,
    required double totalMoneyEarned,
    required int autoClipperCount,
    required int playerLevel,
    required double playTimeHours,
    required int resetCount,
    required int researchesCompleted,
    required double quantumResearchBonus,
    required double innovationResearchBonus,
  }) {
    final quantum = calculateQuantumReward(
      totalPaperclipsProduced: totalPaperclipsProduced,
      totalMoneyEarned: totalMoneyEarned,
      autoClipperCount: autoClipperCount,
      playerLevel: playerLevel,
      playTimeHours: playTimeHours,
      resetCount: resetCount,
      researchBonus: quantumResearchBonus,
    );
    
    final innovationPoints = calculateInnovationPointsReward(
      researchesCompleted: researchesCompleted,
      playerLevel: playerLevel,
      quantumGained: quantum,
      researchBonus: innovationResearchBonus,
    );
    
    return ResetRewards(
      quantum: quantum,
      innovationPoints: innovationPoints,
    );
  }
}

/// Résultat du calcul de récompenses
class ResetRewards {
  final int quantum;
  final int innovationPoints;
  
  const ResetRewards({
    required this.quantum,
    required this.innovationPoints,
  });
  
  @override
  String toString() => 'ResetRewards(quantum: $quantum, innovationPoints: $innovationPoints)';
}
