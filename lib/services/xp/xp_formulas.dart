// lib/services/xp/xp_formulas.dart

import 'xp_config.dart';

/// Formules de calcul d'XP centralisées
class XPFormulas {
  /// Calcule l'XP pour la production manuelle
  /// 
  /// Formule: BASE × bonus_niveau × combo
  static double calculateManualProductionXP() {
    return XPConfig.MANUAL_PRODUCTION_BASE;
  }
  
  /// Calcule l'XP pour la production automatique
  /// 
  /// Formule: BASE × quantité × bonus_niveau
  static double calculateAutoProductionXP(int amount) {
    return XPConfig.AUTO_PRODUCTION_BASE * amount;
  }
  
  /// Calcule l'XP pour les ventes
  /// 
  /// Formule: BASE × quantité × (1 + qualité × MULTIPLIER)
  /// - qualité = (prix - 0.25) normalisé
  static double calculateSaleXP(int quantity, double price) {
    final quality = (price - 0.25).clamp(0.0, 10.0);
    return XPConfig.SALE_BASE * quantity * (1 + quality * XPConfig.SALE_QUALITY_MULTIPLIER);
  }
  
  /// Calcule l'XP pour l'achat d'une autoclipper
  static double calculateAutoclipperPurchaseXP() {
    return XPConfig.AUTOCLIPPER_PURCHASE;
  }
  
  /// Calcule l'XP pour l'achat d'une amélioration
  /// 
  /// Formule: BASE × niveau_upgrade
  static double calculateUpgradePurchaseXP(int upgradeLevel) {
    return XPConfig.UPGRADE_PURCHASE_BASE * upgradeLevel;
  }
  
  /// Calcule l'XP pour une recherche
  /// 
  /// Formule: (coût€ × 0.5) + (coût_PI × 10) + (coût_Q × 15)
  /// Minimum selon la devise la plus élevée utilisée
  static double calculateResearchXP({
    double moneyCost = 0.0,
    double innovationPointsCost = 0.0,
    double quantumCost = 0.0,
  }) {
    double xp = 0.0;
    
    if (moneyCost > 0) {
      xp += moneyCost * XPConfig.RESEARCH_MONEY_MULTIPLIER;
    }
    
    if (innovationPointsCost > 0) {
      xp += innovationPointsCost * XPConfig.RESEARCH_PI_MULTIPLIER;
    }
    
    if (quantumCost > 0) {
      xp += quantumCost * XPConfig.RESEARCH_QUANTUM_MULTIPLIER;
    }
    
    // Minimum selon la ressource la plus rare utilisée
    double minXP = XPConfig.RESEARCH_MIN_XP_MONEY;
    if (quantumCost > 0) {
      minXP = XPConfig.RESEARCH_MIN_XP_QUANTUM;
    } else if (innovationPointsCost > 0) {
      minXP = XPConfig.RESEARCH_MIN_XP_PI;
    }
    
    return xp < minXP ? minXP : xp;
  }
  
  /// Calcule l'XP pour une mission
  /// 
  /// Formule: BASE × (1 + difficulté × 0.5) × multiplicateur_type
  static double calculateMissionXP({
    required double baseXP,
    required double difficulty, // 0.0 = facile, 0.5 = moyen, 1.0 = difficile
    required double typeMultiplier, // 1.0 = daily, 2.0 = weekly, 1.5 = milestone
  }) {
    return baseXP * (1 + difficulty * XPConfig.MISSION_DIFFICULTY_MULTIPLIER) * typeMultiplier;
  }
  
  /// Calcule le bonus quotidien d'XP
  static double calculateDailyBonusXP() {
    return XPConfig.DAILY_BONUS_BASE;
  }
}

/// Classe pour les bonus de progression par niveau (existant, conservé)
class ProgressionBonus {
  /// Calcule le bonus total basé sur le niveau
  /// 
  /// Paliers:
  /// - Niveau 1-14: 1.0 + (niveau × 0.03)
  /// - Niveau 15-24: 1.45 + ((niveau-15) × 0.04)
  /// - Niveau 25-34: 1.85 + ((niveau-25) × 0.05)
  /// - Niveau 35+: 2.35 + ((niveau-35) × 0.03)
  static double getTotalBonus(int level) {
    if (level < 15) {
      return 1.0 + (level * 0.03);
    } else if (level < 25) {
      return 1.45 + ((level - 15) * 0.04);
    } else if (level < 35) {
      return 1.85 + ((level - 25) * 0.05);
    } else {
      return 2.35 + ((level - 35) * 0.03);
    }
  }
  
  /// Calcule le bonus de niveau simple (pour compatibilité)
  static double calculateLevelBonus(int level) {
    return getTotalBonus(level);
  }
}
