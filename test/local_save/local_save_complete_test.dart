// test/local_save/local_save_complete_test.dart
// Test 1 : Sauvegarde locale complète d'une entreprise

import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Test 1: Sauvegarde Locale Complète', () {
    late GameState gameState;
    late LocalGamePersistenceService persistenceService;

    setUp(() async {
      // Initialiser SharedPreferences en mode test
      SharedPreferences.setMockInitialValues({});
      
      // Créer un GameState avec une entreprise
      gameState = GameState();
      
      // Créer une entreprise
      await gameState.createNewEnterprise('Test Enterprise');
      
      // Vérifier que l'entreprise a bien un ID
      expect(gameState.enterpriseId, isNotNull);
      expect(gameState.enterpriseId, isNotEmpty);
      
      persistenceService = const LocalGamePersistenceService();
    });

    test('Sauvegarde locale d\'une entreprise avec snapshot', () async {
      // Créer un snapshot depuis le GameState
      final snapshot = gameState.toSnapshot();
      
      // Vérifier que le snapshot contient l'enterpriseId
      expect(snapshot.metadata['enterpriseId'], equals(gameState.enterpriseId));
      expect(snapshot.metadata['enterpriseName'], equals('Test Enterprise'));
      
      // Sauvegarder via LocalGamePersistenceService
      await persistenceService.saveSnapshotById(
        snapshot,
        enterpriseId: gameState.enterpriseId!,
      );
      
      // Vérifier présence dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // Doit contenir une clé de sauvegarde avec l'enterpriseId
      final saveDataKey = 'save_data_${gameState.enterpriseId}';
      expect(keys.contains(saveDataKey), isTrue, 
        reason: 'La sauvegarde doit être présente dans SharedPreferences');
      
      // Charger et vérifier les données
      final mgr = await LocalSaveGameManager.getInstance();
      final loadedSave = await mgr.loadSave(gameState.enterpriseId!);
      
      expect(loadedSave, isNotNull);
      expect(loadedSave!.id, equals(gameState.enterpriseId));
      expect(loadedSave.gameData, isNotNull);
      expect(loadedSave.gameData.containsKey('gameSnapshot'), isTrue);
    });

    test('Intégrité des données sauvegardées', () async {
      // Modifier le GameState via playerManager
      gameState.playerManager.addPaperclips(100);
      gameState.playerManager.addMoney(50.0);
      
      // Sauvegarder
      final snapshot = gameState.toSnapshot();
      await persistenceService.saveSnapshotById(
        snapshot,
        enterpriseId: gameState.enterpriseId!,
      );
      
      // Charger et vérifier
      final loadedSnapshot = await persistenceService.loadSnapshotById(
        enterpriseId: gameState.enterpriseId!,
      );
      
      expect(loadedSnapshot, isNotNull);
      // Vérifier via playerManager dans le snapshot
      final playerData = loadedSnapshot!.core['playerManager'] as Map<String, dynamic>;
      expect(playerData['paperclips'], equals(100.0));
      expect(playerData['money'], equals(50.0));
    });

    test('Validation snapshot avant sauvegarde', () async {
      final snapshot = gameState.toSnapshot();
      
      // Le snapshot doit être valide
      expect(snapshot.metadata, isNotEmpty);
      expect(snapshot.core, isNotEmpty);
      expect(snapshot.metadata['enterpriseId'], isNotNull);
      expect(snapshot.metadata['enterpriseName'], isNotNull);
      
      // Sauvegarder ne doit pas lever d'exception
      await expectLater(
        persistenceService.saveSnapshotById(
          snapshot,
          enterpriseId: gameState.enterpriseId!,
        ),
        completes,
      );
    });
  });
}
