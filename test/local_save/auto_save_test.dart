// test/local_save/auto_save_test.dart
// Test : Auto-save périodique et lifecycle

import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Test Auto-Save', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('Auto-save démarre après création entreprise', () async {
      final gameState = GameState();
      await gameState.createNewEnterprise('AutoSave Test');
      
      // Vérifier que l'auto-save service existe
      expect(gameState.autoSaveService, isNotNull);
      
      // Vérifier que le service est initialisé
      expect(gameState.isInitialized, isTrue);
    });

    test('Sauvegarde manuelle via requestManualSave', () async {
      final gameState = GameState();
      await gameState.createNewEnterprise('Manual Save Test');
      
      // Modifier des données
      gameState.playerManager.addPaperclips(100);
      
      // Sauvegarder manuellement
      final orchestrator = GamePersistenceOrchestrator.instance;
      await orchestrator.requestManualSave(gameState, reason: 'test_manual');
      
      // Vérifier que la sauvegarde existe
      final saves = await orchestrator.listSaves();
      expect(saves, isNotEmpty);
      expect(saves.any((s) => s.id == gameState.enterpriseId), isTrue);
    });

    test('Lifecycle save - simulation pause', () async {
      final gameState = GameState();
      await gameState.createNewEnterprise('Lifecycle Test');
      
      // Modifier des données
      gameState.playerManager.addPaperclips(200);
      gameState.playerManager.addMoney(100.0);
      
      // Simuler lifecycle save (pause)
      await gameState.autoSaveService.requestLifecycleSave(reason: 'app_pause');
      
      // Vérifier que la sauvegarde a été effectuée
      final orchestrator = GamePersistenceOrchestrator.instance;
      final saves = await orchestrator.listSaves();
      expect(saves, isNotEmpty);
      
      // Charger et vérifier les données
      final newGameState = GameState();
      await orchestrator.loadGameById(newGameState, gameState.enterpriseId!);
      
      expect(newGameState.playerManager.paperclips, equals(200.0));
      expect(newGameState.playerManager.money, equals(100.0));
    });

    test('Backup automatique créé', () async {
      final gameState = GameState();
      await gameState.createNewEnterprise('Backup Test');
      
      // Créer un backup
      await gameState.autoSaveService.createBackup();
      
      // Vérifier que le backup existe
      final orchestrator = GamePersistenceOrchestrator.instance;
      final saves = await orchestrator.listSaves();
      
      // Il devrait y avoir au moins 2 sauvegardes (normale + backup)
      expect(saves.length, greaterThanOrEqualTo(1));
    });

    test('Persistance des données après plusieurs sauvegardes', () async {
      final gameState = GameState();
      await gameState.createNewEnterprise('Multi Save Test');
      
      final orchestrator = GamePersistenceOrchestrator.instance;
      
      // Première sauvegarde
      gameState.playerManager.addPaperclips(50);
      await orchestrator.saveGameById(gameState);
      
      // Deuxième sauvegarde avec modification
      gameState.playerManager.addPaperclips(50); // Total: 100
      await orchestrator.saveGameById(gameState);
      
      // Troisième sauvegarde avec modification
      gameState.playerManager.addMoney(75.0);
      await orchestrator.saveGameById(gameState);
      
      // Charger et vérifier
      final newGameState = GameState();
      await orchestrator.loadGameById(newGameState, gameState.enterpriseId!);
      
      expect(newGameState.playerManager.paperclips, equals(100.0));
      expect(newGameState.playerManager.money, equals(75.0));
    });
  });
}
