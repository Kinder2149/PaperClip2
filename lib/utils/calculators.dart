import '../models/constants/game_constants.dart';

class GameCalculators {
  // Calculs de coûts
  static double calculateUpgradeCost(int currentLevel, double baseCost) {
    return baseCost * (GameConstants.upgradeCostMultiplier * currentLevel);
  }

  static double calculateAutoclipperCost(int currentCount) {
    return GameConstants.baseAutoclipperCost * 
           (GameConstants.autoclipperCostMultiplier * currentCount);
  }

  static double calculateStorageUpgradeCost(int currentLevel) {
    return GameConstants.metalStorageUpgradeCost * 
           (GameConstants.metalStorageUpgradeMultiplier * currentLevel);
  }

  // Calculs de production
  static double calculateProductionRate({
    required double baseRate,
    required int level,
    required double efficiency,
    required double quality,
    required int autoclipperCount,
  }) {
    final levelMultiplier = 1.0 + (level * GameConstants.productionMultiplierPerLevel);
    final efficiencyMultiplier = 1.0 + (efficiency * GameConstants.efficiencyUpgradeMultiplier);
    final qualityMultiplier = 1.0 + (quality * GameConstants.qualityUpgradeMultiplier);
    final autoclipperMultiplier = 1.0 + (autoclipperCount * GameConstants.autoProductionBaseRate);

    return baseRate * 
           levelMultiplier * 
           efficiencyMultiplier * 
           qualityMultiplier * 
           autoclipperMultiplier;
  }

  // Calculs d'expérience
  static int calculateExperienceForLevel(int level) {
    return (GameConstants.baseExperience * 
            (GameConstants.experienceMultiplier * (level - 1))).round();
  }

  static double calculateExperienceGain({
    required int paperclipCount,
    required double moneyEarned,
    required int level,
  }) {
    final paperclipExp = paperclipCount * GameConstants.experiencePerPaperclip;
    final moneyExp = (moneyEarned / 100).round() * GameConstants.experiencePerSale;
    final levelMultiplier = 1.0 + (level * GameConstants.expMultiplierPerLevel);

    return (paperclipExp + moneyExp) * levelMultiplier;
  }

  // Calculs de marché
  static double calculateMarketPrice({
    required double basePrice,
    required double demand,
    required double reputation,
    required double marketing,
  }) {
    final demandMultiplier = demand / GameConstants.baseDemand;
    final reputationMultiplier = 1.0 + (reputation * GameConstants.reputationImpact);
    final marketingMultiplier = 1.0 + (marketing * GameConstants.marketingImpact);

    return basePrice * 
           demandMultiplier * 
           reputationMultiplier * 
           marketingMultiplier;
  }

  static double calculateDemand({
    required double baseDemand,
    required double price,
    required double reputation,
    required double marketing,
  }) {
    final priceMultiplier = 1.0 - ((price - GameConstants.basePrice) * GameConstants.priceSensitivity);
    final reputationMultiplier = 1.0 + (reputation * GameConstants.reputationImpact);
    final marketingMultiplier = 1.0 + (marketing * GameConstants.marketingImpact);

    return baseDemand * 
           priceMultiplier * 
           reputationMultiplier * 
           marketingMultiplier;
  }

  // Calculs de difficulté
  static double calculateDifficulty(int monthsPlayed) {
    return GameConstants.baseDifficulty + 
           (monthsPlayed * GameConstants.difficultyIncreasePerMonth);
  }

  // Calculs de score
  static int calculateCompetitiveScore({
    required int paperclipCount,
    required double moneyEarned,
    required Duration playTime,
    required double efficiency,
    required double quality,
  }) {
    final paperclipScore = paperclipCount;
    final moneyScore = (moneyEarned / 100).round() * 10;
    final timeScore = playTime.inSeconds ~/ 60;
    final efficiencyScore = (efficiency * 1000).round();
    final qualityScore = (quality * 1000).round();

    return paperclipScore + 
           moneyScore + 
           timeScore + 
           efficiencyScore + 
           qualityScore;
  }

  // Calculs de progression
  static double calculateProgress({
    required double current,
    required double target,
  }) {
    return (current / target).clamp(0.0, 1.0);
  }

  static double calculateLevelProgress({
    required int currentExperience,
    required int level,
  }) {
    final experienceForNextLevel = calculateExperienceForLevel(level + 1);
    final experienceForCurrentLevel = calculateExperienceForLevel(level);
    final experienceInCurrentLevel = currentExperience - experienceForCurrentLevel;
    final experienceNeeded = experienceForNextLevel - experienceForCurrentLevel;

    return calculateProgress(
      current: experienceInCurrentLevel.toDouble(),
      target: experienceNeeded.toDouble(),
    );
  }

  // Calculs de réputation
  static double calculateReputationChange({
    required double currentReputation,
    required bool isPositive,
  }) {
    final changeRate = isPositive ? 
                      GameConstants.reputationBonusRate : 
                      GameConstants.reputationPenaltyRate;
    
    return (currentReputation * changeRate).clamp(
      GameConstants.minReputation,
      GameConstants.maxReputation,
    );
  }
} 