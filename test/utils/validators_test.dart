import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/utils/validators.dart';
import 'package:paperclip2/models/constants/game_constants.dart';

void main() {
  group('GameValidators', () {
    group('isValidPrice', () {
      test('accepte un prix valide', () {
        expect(
          GameValidators.isValidPrice(GameConstants.basePrice),
          true,
        );
      });

      test('rejette un prix négatif', () {
        expect(
          GameValidators.isValidPrice(-1.0),
          false,
        );
      });

      test('rejette un prix nul', () {
        expect(
          GameValidators.isValidPrice(0.0),
          false,
        );
      });

      test('rejette un prix infini', () {
        expect(
          GameValidators.isValidPrice(double.infinity),
          false,
        );
      });
    });

    group('isValidDemand', () {
      test('accepte une demande valide', () {
        expect(
          GameValidators.isValidDemand(GameConstants.baseDemand),
          true,
        );
      });

      test('rejette une demande négative', () {
        expect(
          GameValidators.isValidDemand(-1.0),
          false,
        );
      });

      test('rejette une demande nulle', () {
        expect(
          GameValidators.isValidDemand(0.0),
          false,
        );
      });

      test('rejette une demande infinie', () {
        expect(
          GameValidators.isValidDemand(double.infinity),
          false,
        );
      });
    });

    group('isValidReputation', () {
      test('accepte une réputation valide', () {
        expect(
          GameValidators.isValidReputation(1.0),
          true,
        );
      });

      test('rejette une réputation inférieure au minimum', () {
        expect(
          GameValidators.isValidReputation(GameConstants.minReputation - 0.1),
          false,
        );
      });

      test('rejette une réputation supérieure au maximum', () {
        expect(
          GameValidators.isValidReputation(GameConstants.maxReputation + 0.1),
          false,
        );
      });
    });

    group('isValidLevel', () {
      test('accepte un niveau valide', () {
        expect(
          GameValidators.isValidLevel(1),
          true,
        );
      });

      test('rejette un niveau négatif', () {
        expect(
          GameValidators.isValidLevel(-1),
          false,
        );
      });

      test('rejette un niveau nul', () {
        expect(
          GameValidators.isValidLevel(0),
          false,
        );
      });
    });

    group('isValidExperience', () {
      test('accepte une expérience valide', () {
        expect(
          GameValidators.isValidExperience(100),
          true,
        );
      });

      test('rejette une expérience négative', () {
        expect(
          GameValidators.isValidExperience(-1),
          false,
        );
      });

      test('rejette une expérience nulle', () {
        expect(
          GameValidators.isValidExperience(0),
          false,
        );
      });
    });

    group('isValidMoney', () {
      test('accepte un montant valide', () {
        expect(
          GameValidators.isValidMoney(100.0),
          true,
        );
      });

      test('rejette un montant négatif', () {
        expect(
          GameValidators.isValidMoney(-1.0),
          false,
        );
      });

      test('rejette un montant infini', () {
        expect(
          GameValidators.isValidMoney(double.infinity),
          false,
        );
      });
    });

    group('isValidPaperclipCount', () {
      test('accepte un nombre valide', () {
        expect(
          GameValidators.isValidPaperclipCount(100),
          true,
        );
      });

      test('rejette un nombre négatif', () {
        expect(
          GameValidators.isValidPaperclipCount(-1),
          false,
        );
      });

      test('rejette un nombre infini', () {
        expect(
          GameValidators.isValidPaperclipCount(double.infinity.toInt()),
          false,
        );
      });
    });

    group('isValidStorageCapacity', () {
      test('accepte une capacité valide', () {
        expect(
          GameValidators.isValidStorageCapacity(1000),
          true,
        );
      });

      test('rejette une capacité négative', () {
        expect(
          GameValidators.isValidStorageCapacity(-1),
          false,
        );
      });

      test('rejette une capacité nulle', () {
        expect(
          GameValidators.isValidStorageCapacity(0),
          false,
        );
      });
    });

    group('isValidProductionRate', () {
      test('accepte un taux valide', () {
        expect(
          GameValidators.isValidProductionRate(1.0),
          true,
        );
      });

      test('rejette un taux négatif', () {
        expect(
          GameValidators.isValidProductionRate(-1.0),
          false,
        );
      });

      test('rejette un taux nul', () {
        expect(
          GameValidators.isValidProductionRate(0.0),
          false,
        );
      });

      test('rejette un taux infini', () {
        expect(
          GameValidators.isValidProductionRate(double.infinity),
          false,
        );
      });
    });

    group('isValidEfficiency', () {
      test('accepte une efficacité valide', () {
        expect(
          GameValidators.isValidEfficiency(0.5),
          true,
        );
      });

      test('rejette une efficacité négative', () {
        expect(
          GameValidators.isValidEfficiency(-1.0),
          false,
        );
      });

      test('rejette une efficacité supérieure à 1', () {
        expect(
          GameValidators.isValidEfficiency(1.1),
          false,
        );
      });
    });

    group('isValidQuality', () {
      test('accepte une qualité valide', () {
        expect(
          GameValidators.isValidQuality(0.5),
          true,
        );
      });

      test('rejette une qualité négative', () {
        expect(
          GameValidators.isValidQuality(-1.0),
          false,
        );
      });

      test('rejette une qualité supérieure à 1', () {
        expect(
          GameValidators.isValidQuality(1.1),
          false,
        );
      });
    });

    group('isValidAutoclipperCount', () {
      test('accepte un nombre valide', () {
        expect(
          GameValidators.isValidAutoclipperCount(5),
          true,
        );
      });

      test('rejette un nombre négatif', () {
        expect(
          GameValidators.isValidAutoclipperCount(-1),
          false,
        );
      });

      test('rejette un nombre supérieur à la limite', () {
        expect(
          GameValidators.isValidAutoclipperCount(GameConstants.maxAutoclippers + 1),
          false,
        );
      });
    });

    group('isValidMarketingLevel', () {
      test('accepte un niveau valide', () {
        expect(
          GameValidators.isValidMarketingLevel(1),
          true,
        );
      });

      test('rejette un niveau négatif', () {
        expect(
          GameValidators.isValidMarketingLevel(-1),
          false,
        );
      });

      test('rejette un niveau supérieur à la limite', () {
        expect(
          GameValidators.isValidMarketingLevel(GameConstants.maxMarketingLevel + 1),
          false,
        );
      });
    });

    group('isValidStorageUpgradeLevel', () {
      test('accepte un niveau valide', () {
        expect(
          GameValidators.isValidStorageUpgradeLevel(1),
          true,
        );
      });

      test('rejette un niveau négatif', () {
        expect(
          GameValidators.isValidStorageUpgradeLevel(-1),
          false,
        );
      });

      test('rejette un niveau supérieur à la limite', () {
        expect(
          GameValidators.isValidStorageUpgradeLevel(GameConstants.maxStorageUpgradeLevel + 1),
          false,
        );
      });
    });
  });
} 