import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/save_migration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SaveMigrationService', () {
    test('migrateData 1.0 -> 1.5 ajoute id/timestamp et convertit wire->metal', () async {
      final old = <String, dynamic>{
        'version': '1.0',
        'playerManager': <String, dynamic>{
          'wire': 12.5,
        },
      };

      final migrated = await SaveMigrationService.migrateData(old, '1.0', '1.5');

      expect(migrated['version'], '1.5');
      expect(migrated['id'], isA<String>());
      expect(migrated['timestamp'], isA<String>());

      final player = migrated['playerManager'] as Map<String, dynamic>;
      expect(player['metal'], 12.5);
    });

    test('migrateData 1.5 -> 2.0 crée gameData et déplace les sections', () async {
      final old = <String, dynamic>{
        'version': '1.5',
        'timestamp': DateTime(2025, 1, 1).toIso8601String(),
        'id': 'abc',
        'playerManager': <String, dynamic>{'money': 1.0, 'metal': 0.0, 'paperclips': 0.0, 'sellPrice': 0.05},
        'marketManager': <String, dynamic>{'marketMetalStock': 100.0},
        'gameMode': 0,
        'totalTimePlayedInSeconds': 42,
      };

      final migrated = await SaveMigrationService.migrateData(old, '1.5', '2.0');

      expect(migrated['version'], '2.0');
      expect(migrated.containsKey('gameData'), isTrue);

      final gameData = migrated['gameData'] as Map<String, dynamic>;
      expect(gameData.containsKey('playerManager'), isTrue);
      expect(gameData.containsKey('marketManager'), isTrue);
      expect(gameData['gameMode'], 0);
      expect(gameData['totalTimePlayedInSeconds'], 42);

      // Les clés déplacées ne doivent plus être à la racine.
      expect(migrated.containsKey('playerManager'), isFalse);
      expect(migrated.containsKey('marketManager'), isFalse);
    });

    test('migrateData échoue si aucun chemin de migration', () async {
      final old = <String, dynamic>{'version': '0.9'};

      expect(
        () => SaveMigrationService.migrateData(old, '0.9', '2.0'),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
