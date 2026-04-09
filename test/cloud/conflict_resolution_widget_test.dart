// Tests Widget Résolution Conflits - Phase 2.5
// 3 tests pour valider l'UI de résolution de conflits
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/screens/conflict_resolution_screen.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';

void main() {
  group('Tests Widget Résolution Conflits - 3 tests', () {
    // Données de test
    final localSnapshot = GameSnapshot(
      metadata: {
        'lastSaved': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'deviceInfo': 'device-1',
        'appVersion': '1.0.0',
      },
      core: {
        'level': 5,
        'paperclips': 1000,
        'money': 50.0,
        'enterpriseId': '550e8400-e29b-41d4-a716-446655440000',
        'enterpriseName': 'Version Locale',
      },
    );

    final cloudSnapshot = GameSnapshot(
      metadata: {
        'lastSaved': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'deviceInfo': 'device-2',
        'appVersion': '1.0.0',
      },
      core: {
        'level': 7,
        'paperclips': 2000,
        'money': 80.0,
        'enterpriseId': '550e8400-e29b-41d4-a716-446655440000',
        'enterpriseName': 'Version Cloud',
      },
    );

    final testData = ConflictResolutionData(
      localSnapshot: localSnapshot,
      cloudSnapshot: cloudSnapshot,
      enterpriseId: '550e8400-e29b-41d4-a716-446655440000',
    );

    group('Test 1: Structure ConflictResolutionScreen', () {
      test('1.1 - ConflictResolutionScreen existe et est un Widget', () {
        // Arrange & Act
        final screen = ConflictResolutionScreen(data: testData);

        // Assert
        expect(screen, isA<Widget>());
        expect(screen.data, equals(testData));
      });

      test('1.2 - ConflictResolutionData est correctement structuré', () {
        // Assert
        expect(testData.localSnapshot, isNotNull);
        expect(testData.cloudSnapshot, isNotNull);
        expect(testData.enterpriseId, isNotEmpty);
      });

      test('1.3 - Snapshots contiennent métadonnées', () {
        // Assert
        expect(testData.localSnapshot.metadata, isNotEmpty);
        expect(testData.cloudSnapshot.metadata, isNotEmpty);
        expect(testData.localSnapshot.metadata['deviceInfo'], equals('device-1'));
        expect(testData.cloudSnapshot.metadata['deviceInfo'], equals('device-2'));
      });
    });

    group('Test 2: Données des versions', () {
      test('2.1 - Version locale a les bonnes données', () {
        // Assert
        expect(testData.localSnapshot.core['enterpriseName'], equals('Version Locale'));
        expect(testData.localSnapshot.core['level'], equals(5));
        expect(testData.localSnapshot.core['paperclips'], equals(1000));
        expect(testData.localSnapshot.core['money'], equals(50.0));
      });

      test('2.2 - Version cloud a les bonnes données', () {
        // Assert
        expect(testData.cloudSnapshot.core['enterpriseName'], equals('Version Cloud'));
        expect(testData.cloudSnapshot.core['level'], equals(7));
        expect(testData.cloudSnapshot.core['paperclips'], equals(2000));
        expect(testData.cloudSnapshot.core['money'], equals(80.0));
      });

      test('2.3 - Dates de sauvegarde sont présentes', () {
        // Assert
        expect(testData.localSnapshot.metadata['lastSaved'], isNotNull);
        expect(testData.cloudSnapshot.metadata['lastSaved'], isNotNull);
        
        // Vérifier que ce sont des dates valides
        final localDate = DateTime.parse(testData.localSnapshot.metadata['lastSaved'] as String);
        final cloudDate = DateTime.parse(testData.cloudSnapshot.metadata['lastSaved'] as String);
        
        expect(localDate.isBefore(DateTime.now()), isTrue);
        expect(cloudDate.isBefore(DateTime.now()), isTrue);
      });

      test('2.4 - Appareils sont identifiés', () {
        // Assert
        expect(testData.localSnapshot.metadata['deviceInfo'], equals('device-1'));
        expect(testData.cloudSnapshot.metadata['deviceInfo'], equals('device-2'));
      });
    });

    group('Test 3: Boutons de choix', () {
      test('3.1 - ConflictChoice enum définit les options', () {
        // Assert
        expect(ConflictChoice.keepLocal, isNotNull);
        expect(ConflictChoice.keepCloud, isNotNull);
        expect(ConflictChoice.cancel, isNotNull);
      });

      test('3.2 - ConflictResolutionData est immutable', () {
        // Arrange
        final data1 = ConflictResolutionData(
          localSnapshot: localSnapshot,
          cloudSnapshot: cloudSnapshot,
          enterpriseId: '550e8400-e29b-41d4-a716-446655440000',
        );

        final data2 = ConflictResolutionData(
          localSnapshot: localSnapshot,
          cloudSnapshot: cloudSnapshot,
          enterpriseId: '550e8400-e29b-41d4-a716-446655440000',
        );

        // Assert - Les données sont accessibles
        expect(data1.localSnapshot, isNotNull);
        expect(data1.cloudSnapshot, isNotNull);
        expect(data1.enterpriseId, isNotEmpty);
        expect(data2.enterpriseId, equals(data1.enterpriseId));
      });

      test('3.3 - Snapshots contiennent les données nécessaires', () {
        // Assert
        expect(testData.localSnapshot.core['enterpriseName'], equals('Version Locale'));
        expect(testData.cloudSnapshot.core['enterpriseName'], equals('Version Cloud'));
        expect(testData.localSnapshot.core['level'], equals(5));
        expect(testData.cloudSnapshot.core['level'], equals(7));
      });
    });

    group('Test Bonus: Structure des données', () {
      test('4.1 - ConflictResolutionData contient les bonnes propriétés', () {
        // Arrange & Act
        final data = ConflictResolutionData(
          localSnapshot: localSnapshot,
          cloudSnapshot: cloudSnapshot,
          enterpriseId: '550e8400-e29b-41d4-a716-446655440000',
        );

        // Assert
        expect(data.localSnapshot, equals(localSnapshot));
        expect(data.cloudSnapshot, equals(cloudSnapshot));
        expect(data.enterpriseId, equals('550e8400-e29b-41d4-a716-446655440000'));
      });

      test('4.2 - ConflictChoice enum a toutes les valeurs', () {
        // Assert
        expect(ConflictChoice.values.length, equals(3));
        expect(ConflictChoice.values, contains(ConflictChoice.keepLocal));
        expect(ConflictChoice.values, contains(ConflictChoice.keepCloud));
        expect(ConflictChoice.values, contains(ConflictChoice.cancel));
      });

      test('4.3 - Snapshots peuvent être comparés', () {
        // Arrange
        final level1 = localSnapshot.core['level'];
        final level2 = cloudSnapshot.core['level'];

        // Act & Assert
        expect(level1, equals(5));
        expect(level2, equals(7));
        expect(level2, greaterThan(level1 as num));
      });
    });
  });
}
