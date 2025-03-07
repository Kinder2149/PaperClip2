import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/utils/calculators.dart';
import 'package:paperclip2/models/constants/game_constants.dart';

void main() {
  group('GameCalculators', () {
    group('calculateUpgradeCost', () {
      test('calcule correctement le coût d\'une amélioration de niveau 1', () {
        expect(
          GameCalculators.calculateUpgradeCost(1, 10),
          closeTo(10 * GameConstants.upgradeCostMultiplier, 0.01),
        );
      });

      test('calcule correctement le coût d\'une amélioration de niveau 5', () {
        expect(
          GameCalculators.calculateUpgradeCost(5, 10),
          closeTo(10 * (GameConstants.upgradeCostMultiplier * 5), 0.01),
        );
      });
    });

    group('calculateAutoclipperCost', () {
      test('calcule correctement le coût du premier autoclipper', () {
        expect(
          GameCalculators.calculateAutoclipperCost(0),
          GameConstants.baseAutoclipperCost,
        );
      });

      test('calcule correctement le coût du cinquième autoclipper', () {
        expect(
          GameCalculators.calculateAutoclipperCost(4),
          closeTo(
            GameConstants.baseAutoclipperCost *
                (GameConstants.autoclipperCostMultiplier * 5),
            0.01,
          ),
        );
      });
    });

    group('calculateStorageUpgradeCost', () {
      test('calcule correctement le coût de la première amélioration', () {
        expect(
          GameCalculators.calculateStorageUpgradeCost(1),
          closeTo(
            GameConstants.metalStorageUpgradeCost *
                GameConstants.metalStorageUpgradeMultiplier,
            0.01,
          ),
        );
      });

      test('calcule correctement le coût de la cinquième amélioration', () {
        expect(
          GameCalculators.calculateStorageUpgradeCost(5),
          closeTo(
            GameConstants.metalStorageUpgradeCost *
                (GameConstants.metalStorageUpgradeMultiplier * 5),
            0.01,
          ),
        );
      });
    });

    group('calculateProductionRate', () {
      test('calcule correctement le taux de production de base', () {
        expect(
          GameCalculators.calculateProductionRate(
            baseRate: 1.0,
            level: 1,
            efficiency: 0.0,
            quality: 0.0,
            autoclipperCount: 0,
          ),
          closeTo(1.0, 0.01),
        );
      });

      test('calcule correctement le taux de production avec tous les bonus', () {
        expect(
          GameCalculators.calculateProductionRate(
            baseRate: 1.0,
            level: 5,
            efficiency: 0.5,
            quality: 0.5,
            autoclipperCount: 3,
          ),
          closeTo(
            1.0 *
                (1 + 5 * GameConstants.productionMultiplierPerLevel) *
                (1 + 0.5 * GameConstants.efficiencyUpgradeMultiplier) *
                (1 + 0.5 * GameConstants.qualityUpgradeMultiplier) *
                (1 + 3 * GameConstants.autoProductionBaseRate),
            0.01,
          ),
        );
      });
    });

    group('calculateExperienceForLevel', () {
      test('calcule correctement l\'expérience pour le niveau 1', () {
        expect(
          GameCalculators.calculateExperienceForLevel(1),
          GameConstants.baseExperience,
        );
      });

      test('calcule correctement l\'expérience pour le niveau 5', () {
        expect(
          GameCalculators.calculateExperienceForLevel(5),
          closeTo(
            GameConstants.baseExperience *
                (GameConstants.experienceMultiplier * 4),
            0.01,
          ),
        );
      });
    });

    group('calculateExperienceGain', () {
      test('calcule correctement le gain d\'expérience de base', () {
        expect(
          GameCalculators.calculateExperienceGain(
            paperclipCount: 10,
            moneyEarned: 100,
            level: 1,
          ),
          closeTo(
            (10 * GameConstants.experiencePerPaperclip +
                    1 * GameConstants.experiencePerSale) *
                (1 + GameConstants.expMultiplierPerLevel),
            0.01,
          ),
        );
      });
    });

    group('calculateMarketPrice', () {
      test('calcule correctement le prix de base', () {
        expect(
          GameCalculators.calculateMarketPrice(
            basePrice: 1.0,
            demand: GameConstants.baseDemand,
            reputation: 1.0,
            marketing: 0.0,
          ),
          closeTo(1.0, 0.01),
        );
      });

      test('calcule correctement le prix avec tous les bonus', () {
        expect(
          GameCalculators.calculateMarketPrice(
            basePrice: 1.0,
            demand: GameConstants.baseDemand * 2,
            reputation: 1.5,
            marketing: 0.5,
          ),
          closeTo(
            1.0 *
                2 *
                (1 + 0.5 * GameConstants.reputationImpact) *
                (1 + 0.5 * GameConstants.marketingImpact),
            0.01,
          ),
        );
      });
    });

    group('calculateDemand', () {
      test('calcule correctement la demande de base', () {
        expect(
          GameCalculators.calculateDemand(
            baseDemand: GameConstants.baseDemand,
            price: GameConstants.basePrice,
            reputation: 1.0,
            marketing: 0.0,
          ),
          closeTo(GameConstants.baseDemand, 0.01),
        );
      });

      test('calcule correctement la demande avec tous les bonus', () {
        expect(
          GameCalculators.calculateDemand(
            baseDemand: GameConstants.baseDemand,
            price: GameConstants.basePrice * 1.5,
            reputation: 1.5,
            marketing: 0.5,
          ),
          closeTo(
            GameConstants.baseDemand *
                (1 - 0.5 * GameConstants.priceSensitivity) *
                (1 + 0.5 * GameConstants.reputationImpact) *
                (1 + 0.5 * GameConstants.marketingImpact),
            0.01,
          ),
        );
      });
    });

    group('calculateDifficulty', () {
      test('calcule correctement la difficulté de base', () {
        expect(
          GameCalculators.calculateDifficulty(0),
          GameConstants.baseDifficulty,
        );
      });

      test('calcule correctement la difficulté après 5 mois', () {
        expect(
          GameCalculators.calculateDifficulty(5),
          closeTo(
            GameConstants.baseDifficulty +
                (5 * GameConstants.difficultyIncreasePerMonth),
            0.01,
          ),
        );
      });
    });

    group('calculateCompetitiveScore', () {
      test('calcule correctement le score de base', () {
        expect(
          GameCalculators.calculateCompetitiveScore(
            paperclipCount: 100,
            moneyEarned: 1000,
            playTime: const Duration(minutes: 5),
            efficiency: 0.5,
            quality: 0.5,
          ),
          100 + 100 + 300 + 500 + 500,
        );
      });
    });

    group('calculateProgress', () {
      test('calcule correctement une progression de 0%', () {
        expect(
          GameCalculators.calculateProgress(current: 0, target: 100),
          0.0,
        );
      });

      test('calcule correctement une progression de 50%', () {
        expect(
          GameCalculators.calculateProgress(current: 50, target: 100),
          0.5,
        );
      });

      test('calcule correctement une progression de 100%', () {
        expect(
          GameCalculators.calculateProgress(current: 100, target: 100),
          1.0,
        );
      });

      test('limite la progression à 100%', () {
        expect(
          GameCalculators.calculateProgress(current: 150, target: 100),
          1.0,
        );
      });
    });

    group('calculateLevelProgress', () {
      test('calcule correctement la progression au niveau 1', () {
        expect(
          GameCalculators.calculateLevelProgress(
            currentExperience: 50,
            level: 1,
          ),
          closeTo(0.5, 0.01),
        );
      });
    });

    group('calculateReputationChange', () {
      test('calcule correctement une amélioration de réputation', () {
        expect(
          GameCalculators.calculateReputationChange(
            currentReputation: 1.0,
            isPositive: true,
          ),
          closeTo(1.0 * GameConstants.reputationBonusRate, 0.01),
        );
      });

      test('calcule correctement une détérioration de réputation', () {
        expect(
          GameCalculators.calculateReputationChange(
            currentReputation: 1.0,
            isPositive: false,
          ),
          closeTo(1.0 * GameConstants.reputationPenaltyRate, 0.01),
        );
      });

      test('limite la réputation au minimum', () {
        expect(
          GameCalculators.calculateReputationChange(
            currentReputation: GameConstants.minReputation,
            isPositive: false,
          ),
          GameConstants.minReputation,
        );
      });

      test('limite la réputation au maximum', () {
        expect(
          GameCalculators.calculateReputationChange(
            currentReputation: GameConstants.maxReputation,
            isPositive: true,
          ),
          GameConstants.maxReputation,
        );
      });
    });
  });
} 