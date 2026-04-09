// test/local_save/local_load_enterprise_test.dart
// Test 2 : Chargement entreprise depuis sauvegarde locale

import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Test 2: Chargement Entreprise Locale', () {
    late GameState gameState;
    late LocalGamePersistenceService persistenceService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      gameState = GameState();
      persistenceService = const LocalGamePersistenceService();
    });

    test('Chargement entreprise depuis sauvegarde locale', () async {
      // Créer et sauvegarder une entreprise
      await gameState.createNewEnterprise('My Company');
      final originalId = gameState.enterpriseId!;
      final originalName = gameState.enterpriseName;
      
      gameState.playerManager.addPaperclips(250);
      gameState.playerManager.addMoney(125.5);
      
      final snapshot = gameState.toSnapshot();
      await persistenceService.saveSnapshotById(
        snapshot,
        enterpriseId: originalId,
      );
      
      // Créer un nouveau GameState vierge
      final newGameState = GameState();
      expect(newGameState.enterpriseId, isNull);
      
      // Charger via loadSnapshotById
      final loadedSnapshot = await persistenceService.loadSnapshotById(
        enterpriseId: originalId,
      );
      
      expect(loadedSnapshot, isNotNull);
      
      // Appliquer le snapshot au nouveau GameState
      newGameState.applySnapshot(loadedSnapshot!);
      
      // Vérifier que les données sont correctes
      expect(newGameState.enterpriseId, equals(originalId));
      expect(newGameState.enterpriseName, equals(originalName));
      expect(newGameState.playerManager.paperclips, equals(250.0));
      expect(newGameState.playerManager.money, equals(125.5));
    });

    test('Chargement avec enterpriseId correct', () async {
      // Créer entreprise
      await gameState.createNewEnterprise('Test Corp');
      final enterpriseId = gameState.enterpriseId!;
      
      // Sauvegarder
      final snapshot = gameState.toSnapshot();
      await persistenceService.saveSnapshotById(
        snapshot,
        enterpriseId: enterpriseId,
      );
      
      // Charger avec le bon ID
      final loaded = await persistenceService.loadSnapshotById(
        enterpriseId: enterpriseId,
      );
      
      expect(loaded, isNotNull);
      expect(loaded!.metadata['enterpriseId'], equals(enterpriseId));
    });

    test('Chargement retourne null si entreprise inexistante', () async {
      // Tenter de charger une entreprise qui n'existe pas
      final loaded = await persistenceService.loadSnapshotById(
        enterpriseId: 'non-existent-id-12345',
      );
      
      expect(loaded, isNull);
    });

    test('Chargement via GamePersistenceOrchestrator', () async {
      // Créer et sauvegarder
      await gameState.createNewEnterprise('Orchestrator Test');
      final enterpriseId = gameState.enterpriseId!;
      
      await GamePersistenceOrchestrator.instance.saveGameById(gameState);
      
      // Nouveau GameState
      final newGameState = GameState();
      
      // Charger via orchestrator
      await GamePersistenceOrchestrator.instance.loadGameById(
        newGameState,
        enterpriseId,
      );
      
      expect(newGameState.enterpriseId, equals(enterpriseId));
      expect(newGameState.enterpriseName, equals('Orchestrator Test'));
    });
  });
}
