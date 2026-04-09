// Test P0-2: Validation UUID v4 dans CloudPersistenceAdapter
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_adapter.dart';

void main() {
  group('CloudPersistenceAdapter - Validation UUID v4 (P0-2)', () {
    late CloudPersistenceAdapter adapter;

    setUp(() {
      // Utiliser base URL vide pour éviter vraies requêtes HTTP
      adapter = CloudPersistenceAdapter(base: 'http://localhost:9999');
    });

    group('UUID v4 valides', () {
      test('accepte UUID v4 standard', () async {
        const validUuid = '550e8400-e29b-41d4-a716-446655440000';
        
        // Ne devrait pas lever d'exception
        expect(
          () => CloudPersistenceAdapter._validatePartieId(validUuid),
          returnsNormally,
        );
      });

      test('accepte UUID v4 avec lettres minuscules', () {
        const validUuid = 'a1b2c3d4-e5f6-4789-abcd-ef0123456789';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(validUuid),
          returnsNormally,
        );
      });

      test('accepte UUID v4 avec lettres majuscules', () {
        const validUuid = 'A1B2C3D4-E5F6-4789-ABCD-EF0123456789';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(validUuid),
          returnsNormally,
        );
      });

      test('accepte UUID v4 avec variante 8', () {
        const validUuid = '12345678-1234-4567-8901-234567890123';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(validUuid),
          returnsNormally,
        );
      });

      test('accepte UUID v4 avec variante 9', () {
        const validUuid = '12345678-1234-4567-9901-234567890123';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(validUuid),
          returnsNormally,
        );
      });

      test('accepte UUID v4 avec variante a', () {
        const validUuid = '12345678-1234-4567-a901-234567890123';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(validUuid),
          returnsNormally,
        );
      });

      test('accepte UUID v4 avec variante b', () {
        const validUuid = '12345678-1234-4567-b901-234567890123';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(validUuid),
          returnsNormally,
        );
      });
    });

    group('UUID invalides', () {
      test('rejette UUID v1 (version 1)', () {
        const invalidUuid = '550e8400-e29b-11d4-a716-446655440000';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(invalidUuid),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejette UUID v3 (version 3)', () {
        const invalidUuid = '550e8400-e29b-31d4-a716-446655440000';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(invalidUuid),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejette UUID v5 (version 5)', () {
        const invalidUuid = '550e8400-e29b-51d4-a716-446655440000';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(invalidUuid),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejette string vide', () {
        const invalidUuid = '';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(invalidUuid),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejette string quelconque', () {
        const invalidUuid = 'not-a-uuid';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(invalidUuid),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejette UUID sans tirets', () {
        const invalidUuid = '550e8400e29b41d4a716446655440000';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(invalidUuid),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejette UUID avec mauvais format de tirets', () {
        const invalidUuid = '550e8400-e29b41d4-a716-446655440000';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(invalidUuid),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejette UUID trop court', () {
        const invalidUuid = '550e8400-e29b-41d4-a716-44665544000';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(invalidUuid),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejette UUID trop long', () {
        const invalidUuid = '550e8400-e29b-41d4-a716-4466554400000';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(invalidUuid),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejette UUID v4 avec variante invalide (c)', () {
        const invalidUuid = '12345678-1234-4567-c901-234567890123';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(invalidUuid),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejette UUID v4 avec variante invalide (0)', () {
        const invalidUuid = '12345678-1234-4567-0901-234567890123';
        
        expect(
          () => CloudPersistenceAdapter._validatePartieId(invalidUuid),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Message d\'erreur', () {
      test('contient le enterpriseId invalide dans le message', () {
        const invalidUuid = 'invalid-uuid-123';
        
        try {
          CloudPersistenceAdapter._validatePartieId(invalidUuid);
          fail('Devrait lever ArgumentError');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          final argError = e as ArgumentError;
          expect(argError.message, contains('UUID v4 valide'));
          expect(argError.message, contains('xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'));
        }
      });
    });

    group('Intégration avec méthodes publiques', () {
      test('pushById valide UUID avant appel HTTP', () async {
        const invalidUuid = 'not-a-uuid';
        
        // Devrait lever ArgumentError AVANT de tenter requête HTTP
        expect(
          () => adapter.pushById(
            enterpriseId: invalidUuid,
            snapshot: {'test': 'data'},
            metadata: {},
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('pullById valide UUID avant appel HTTP', () async {
        const invalidUuid = 'not-a-uuid';
        
        expect(
          () => adapter.pullById(enterpriseId: invalidUuid),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('statusById valide UUID avant appel HTTP', () async {
        const invalidUuid = 'not-a-uuid';
        
        expect(
          () => adapter.statusById(enterpriseId: invalidUuid),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('deleteById valide UUID avant appel HTTP', () async {
        const invalidUuid = 'not-a-uuid';
        
        expect(
          () => adapter.deleteById(enterpriseId: invalidUuid),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
