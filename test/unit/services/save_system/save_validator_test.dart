import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/save_system/save_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> baseV2Data({
    Map<String, dynamic>? playerManager,
    Map<String, dynamic>? marketManager,
    Map<String, dynamic>? levelSystem,
  }) {
    return <String, dynamic>{
      'version': '2.0',
      'timestamp': DateTime(2025, 1, 1).toIso8601String(),
      'gameData': <String, dynamic>{
        'playerManager': <String, dynamic>{
          'money': 10.0,
          'metal': 1.0,
          'paperclips': 0.0,
          'sellPrice': 0.05,
          ...?playerManager,
        },
        'marketManager': <String, dynamic>{
          'marketMetalStock': 100.0,
          ...?marketManager,
        },
        'levelSystem': <String, dynamic>{
          'experience': 0.0,
          'level': 1,
          ...?levelSystem,
        },
      },
    };
  }

  group('SaveValidator', () {
    test('quickValidate échoue si metadata version/timestamp manquantes', () {
      final result = SaveValidator.quickValidate({
        'gameData': {
          'playerManager': {'money': 0.0, 'metal': 0.0, 'paperclips': 0.0},
          'marketManager': {'marketMetalStock': 100.0},
        },
      });

      expect(result.isValid, isFalse);
      expect(result.severity, ValidationSeverity.critical);
      expect(result.errors.join(' '), contains('version'));
    });

    test('validate complète les sections manquantes et garde severity moderate', () {
      final data = <String, dynamic>{
        'version': '2.0',
        'timestamp': DateTime(2025, 1, 1).toIso8601String(),
        'gameData': <String, dynamic>{
          // missing marketManager
          'playerManager': <String, dynamic>{
            'money': 10.0,
            'metal': 1.0,
            'paperclips': 0.0,
            'sellPrice': 0.05,
          },
        },
      };

      final result = SaveValidator.validate(data);

      expect(result.isValid, isTrue); // moderate != critical
      expect(result.severity, isNot(ValidationSeverity.critical));
      expect(result.errors, isNotEmpty);

      final fixed = result.validatedData!;
      final fixedGameData = fixed['gameData'] as Map<String, dynamic>;
      expect(fixedGameData.containsKey('marketManager'), isTrue);
      expect(fixedGameData['marketManager'], isA<Map>());
    });

    test('validate remonte une erreur si type invalide sur playerManager.paperclips', () {
      final data = <String, dynamic>{
        'version': '2.0',
        'timestamp': DateTime(2025, 1, 1).toIso8601String(),
        'gameData': <String, dynamic>{
          'playerManager': <String, dynamic>{
            'money': 10.0,
            'metal': 1.0,
            'paperclips': 'not-a-number',
            'sellPrice': 0.05,
          },
          'marketManager': <String, dynamic>{
            'marketMetalStock': 100.0,
          },
        },
      };

      final result = SaveValidator.validate(data);

      expect(result.isValid, isTrue); // moderate errors tolerated
      expect(result.errors.any((e) => e.contains('playerManager.paperclips')), isTrue);
    });

    test('validate remonte une erreur si playerManager.sellPrice < min', () {
      final data = baseV2Data(playerManager: {'sellPrice': 0.0});
      final result = SaveValidator.validate(data);

      expect(result.isValid, isTrue);
      expect(result.errors.any((e) => e.contains('playerManager.sellPrice')), isTrue);
      expect(result.errors.any((e) => e.contains('trop petite')), isTrue);
    });

    test('validate remonte une erreur si playerManager.sellPrice > max', () {
      final data = baseV2Data(playerManager: {'sellPrice': 2.0});
      final result = SaveValidator.validate(data);

      expect(result.isValid, isTrue);
      expect(result.errors.any((e) => e.contains('playerManager.sellPrice')), isTrue);
      expect(result.errors.any((e) => e.contains('trop grande')), isTrue);
    });

    test('validate remonte une erreur si playerManager.money est négatif', () {
      final data = baseV2Data(playerManager: {'money': -1.0});
      final result = SaveValidator.validate(data);

      expect(result.isValid, isTrue);
      expect(result.errors.any((e) => e.contains('playerManager.money')), isTrue);
      expect(result.errors.any((e) => e.contains('trop petite')), isTrue);
    });

    test('validate remonte une erreur si marketManager.reputation > max', () {
      final data = baseV2Data(marketManager: {'reputation': 3.0});
      final result = SaveValidator.validate(data);

      expect(result.isValid, isTrue);
      expect(result.errors.any((e) => e.contains('marketManager.reputation')), isTrue);
      expect(result.errors.any((e) => e.contains('trop grande')), isTrue);
    });

    test('validate remonte une erreur si levelSystem.level < 1', () {
      final data = baseV2Data(levelSystem: {'level': 0});
      final result = SaveValidator.validate(data);

      expect(result.isValid, isTrue);
      expect(result.errors.any((e) => e.contains('levelSystem.level')), isTrue);
      expect(result.errors.any((e) => e.contains('trop petite')), isTrue);
    });

    test('validate remonte une erreur si levelSystem.xpMultiplier < 1.0', () {
      final data = baseV2Data(levelSystem: {'xpMultiplier': 0.5});
      final result = SaveValidator.validate(data);

      expect(result.isValid, isTrue);
      expect(result.errors.any((e) => e.contains('levelSystem.xpMultiplier')), isTrue);
      expect(result.errors.any((e) => e.contains('trop petite')), isTrue);
    });

    test('validate remonte une erreur si playerManager.autoClipperCount est négatif', () {
      final data = baseV2Data(playerManager: {'autoClipperCount': -1});
      final result = SaveValidator.validate(data);

      expect(result.isValid, isTrue);
      expect(
        result.errors.any((e) => e.contains('playerManager.autoClipperCount')),
        isTrue,
      );
      expect(result.errors.any((e) => e.contains('trop petite')), isTrue);
    });

    test(
        'validate ne crash pas si playerManager.paperclips est un int (cast gameSpecificRules)',
        () {
      final data = <String, dynamic>{
        'version': '2.0',
        'timestamp': DateTime(2025, 1, 1).toIso8601String(),
        'gameData': <String, dynamic>{
          'playerManager': <String, dynamic>{
            'money': 10.0,
            'metal': 1.0,
            // OK pour _validateAllSections (num), mais peut casser le cast as double?
            'paperclips': 120,
            'sellPrice': 0.05,
          },
          'marketManager': <String, dynamic>{
            'marketMetalStock': 100.0,
          },
        },
      };

      final result = SaveValidator.validate(data);
      expect(result.errors, isA<List<String>>());
      expect(result.severity, isNotNull);
    });

    test(
        'validate ne crash pas si playerManager.money/sellPrice sont des String (cast gameSpecificRules)',
        () {
      final data = <String, dynamic>{
        'version': '2.0',
        'timestamp': DateTime(2025, 1, 1).toIso8601String(),
        'gameData': <String, dynamic>{
          'playerManager': <String, dynamic>{
            // Ces valeurs vont générer des erreurs de type via _validateAllSections
            // et peuvent provoquer l’exception de cast dans _validateGameSpecificRules.
            'money': '10.0',
            'metal': 1.0,
            'paperclips': 200.0,
            'sellPrice': '0.05',
          },
          'marketManager': <String, dynamic>{
            'marketMetalStock': 100.0,
          },
        },
      };

      final result = SaveValidator.validate(data);
      // Non-régression: validate doit retourner un résultat (pas throw)
      expect(result.errors, isNotNull);
      expect(result.isValid, isTrue); // errors moderate tolérées
      expect(result.errors.any((e) => e.contains('playerManager.money')), isTrue);
      expect(result.errors.any((e) => e.contains('playerManager.sellPrice')), isTrue);
    });

    test('validate remonte une erreur si gameMode est un type invalide', () {
      final data = <String, dynamic>{
        'version': '2.0',
        'timestamp': DateTime(2025, 1, 1).toIso8601String(),
        'gameData': <String, dynamic>{
          'gameMode': 'not-an-int',
          'playerManager': <String, dynamic>{
            'money': 10.0,
            'metal': 1.0,
            'paperclips': 0.0,
            'sellPrice': 0.05,
          },
          'marketManager': <String, dynamic>{
            'marketMetalStock': 100.0,
          },
        },
      };

      final result = SaveValidator.validate(data);
      expect(result.isValid, isTrue);
      expect(result.errors.any((e) => e.contains('mode de jeu')), isTrue);
    });
  });
}
