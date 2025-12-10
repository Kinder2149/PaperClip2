// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/save_metadata.dart';
import 'package:paperclip2/services/save_game.dart';

void main() {
  group('SaveGameInfo Tests', () {
    // Tester la conversion SaveMetadata → SaveGameInfo
    test('fromMetadata factory crée un SaveGameInfo valide', () {
      // Créer des données de test
      final testDate = DateTime(2023, 1, 15, 10, 30);
      final metadata = SaveMetadata(
        id: 'test-save-123',
        name: 'Test Save',
        creationDate: testDate,  // Ajout du champ requis
        lastModified: testDate,
        version: '1.0.0',
        gameMode: GameMode.INFINITE,
        isRestored: false,
      );

      final gameData = {
        'playerManager': {
          'paperclips': 1000,
          'money': 500,
          'totalPaperclipsSold': 2000,
          'autoClipperCount': 5,
        },
      };

      // Exécuter la conversion
      final saveInfo = SaveGameInfo.fromMetadata(
        metadata,
        gameData: gameData,
        isBackup: false,
      );

      // Vérifier que la conversion est correcte
      expect(saveInfo.id, equals(metadata.id));
      expect(saveInfo.name, equals(metadata.name));
      expect(saveInfo.timestamp, equals(metadata.lastModified));
      expect(saveInfo.lastModified, equals(metadata.lastModified));  // Tester le getter aussi
      expect(saveInfo.version, equals(metadata.version));
      expect(saveInfo.gameMode, equals(GameMode.INFINITE));
      expect(saveInfo.isBackup, isFalse);
      expect(saveInfo.isRestored, isFalse);

      // Vérifier les données de jeu
      expect(saveInfo.paperclips, equals(1000));
      expect(saveInfo.money, equals(500));
      expect(saveInfo.totalPaperclipsSold, equals(2000));
      expect(saveInfo.autoClipperCount, equals(5));
    });

    // Tester la robustesse avec des données incomplètes
    test('fromMetadata gère les données incomplètes', () {
      // Créer des métadonnées minimales
      final now = DateTime.now();
      final metadata = SaveMetadata(
        id: 'minimal-save',
        name: 'Minimal Save',
        creationDate: now,  // Ajout du champ requis
        lastModified: now,
        version: '1.0.0',
        gameMode: GameMode.INFINITE,
        isRestored: false,
      );

      // Cas 1: Aucune donnée de jeu
      final saveInfoEmpty = SaveGameInfo.fromMetadata(
        metadata, 
        gameData: <dynamic, dynamic>{},  // Utilisation d'un Map<dynamic, dynamic> explicite
        isBackup: false,
      );

      // Vérifier que les valeurs par défaut sont utilisées
      expect(saveInfoEmpty.id, equals(metadata.id));
      expect(saveInfoEmpty.paperclips, equals(0));
      expect(saveInfoEmpty.money, equals(0));
      expect(saveInfoEmpty.totalPaperclipsSold, equals(0));
      expect(saveInfoEmpty.autoClipperCount, equals(0));

      // Cas 2: playerManager vide
      final saveInfoPartial = SaveGameInfo.fromMetadata(
        metadata, 
        gameData: <dynamic, dynamic>{'playerManager': <dynamic, dynamic>{}},  // Typage explicite
        isBackup: false,
      );

      // Vérifier que les valeurs par défaut sont utilisées
      expect(saveInfoPartial.paperclips, equals(0));
      expect(saveInfoPartial.money, equals(0));
      expect(saveInfoPartial.totalPaperclipsSold, equals(0));
      expect(saveInfoPartial.autoClipperCount, equals(0));

      // Cas 3: playerManager avec données partielles
      final saveInfoMixed = SaveGameInfo.fromMetadata(
        metadata, 
        gameData: <dynamic, dynamic>{'playerManager': <dynamic, dynamic>{'paperclips': 50}},  // Typage explicite
        isBackup: false,
      );

      expect(saveInfoMixed.paperclips, equals(50));
      expect(saveInfoMixed.money, equals(0));  // Valeur par défaut
    });

    // Tester la création avec paramètres manuels
    test('Constructeur classique fonctionne correctement', () {
      final now = DateTime.now();
      final saveInfo = SaveGameInfo(
        id: 'manual-id',
        name: 'Manual Save',
        timestamp: now,
        version: '1.2.0',
        gameMode: GameMode.COMPETITIVE,
        paperclips: 123,
        money: 456,
        totalPaperclipsSold: 789,
        autoClipperCount: 3,
        isBackup: true,
        isRestored: true,
      );

      expect(saveInfo.id, equals('manual-id'));
      expect(saveInfo.name, equals('Manual Save'));
      expect(saveInfo.timestamp, equals(now));
      expect(saveInfo.lastModified, equals(now));  // Tester le getter
      expect(saveInfo.gameMode, equals(GameMode.COMPETITIVE));
      expect(saveInfo.isBackup, isTrue);
      expect(saveInfo.isRestored, isTrue);
      expect(saveInfo.paperclips, equals(123));
      expect(saveInfo.money, equals(456));
    });

    // Test de la méthode toString
    test('toString() fonctionne correctement', () {
      final now = DateTime(2023, 6, 15);
      final saveInfo = SaveGameInfo(
        id: 'id-123',
        name: 'Test Save',
        timestamp: now,
        version: '1.0.0',
        gameMode: GameMode.INFINITE,
      );

      final stringRepresentation = saveInfo.toString();
      expect(stringRepresentation, contains('id-123'));
      expect(stringRepresentation, contains('Test Save'));
      expect(stringRepresentation, contains(now.toString()));
    });
  });
}
