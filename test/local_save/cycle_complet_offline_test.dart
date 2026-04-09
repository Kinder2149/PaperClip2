// test/local_save/cycle_complet_offline_test.dart
// Test 9 : Cycle complet sans connexion Google

import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Test 9: Cycle Complet Offline', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('Cycle complet: Créer → Jouer → Sauvegarder → Fermer → Rouvrir', () async {
      // === ÉTAPE 1: Créer entreprise ===
      final gameState = GameState();
      await gameState.createNewEnterprise('Offline Test Corp');
      
      expect(gameState.enterpriseId, isNotNull);
      expect(gameState.enterpriseName, equals('Offline Test Corp'));
      
      // === ÉTAPE 2: Jouer (modifier données) ===
      gameState.playerManager.addPaperclips(500);
      gameState.playerManager.addMoney(250.0);
      
      // === ÉTAPE 3: Sauvegarder ===
      final orchestrator = GamePersistenceOrchestrator.instance;
      await orchestrator.saveGameById(gameState);
      
      // Vérifier que la sauvegarde existe
      final saves = await orchestrator.listSaves();
      expect(saves, isNotEmpty);
      expect(saves.any((s) => s.id == gameState.enterpriseId), isTrue);
      
      // === ÉTAPE 4: Simuler fermeture app (sauvegarder l'ID) ===
      final savedEnterpriseId = gameState.enterpriseId!;
      
      // === ÉTAPE 5: Rouvrir app (nouveau GameState) ===
      final newGameState = GameState();
      
      // Charger l'entreprise
      await orchestrator.loadGameById(newGameState, savedEnterpriseId);
      
      // === ÉTAPE 6: Vérifier données restaurées ===
      expect(newGameState.enterpriseId, equals(savedEnterpriseId));
      expect(newGameState.enterpriseName, equals('Offline Test Corp'));
      expect(newGameState.playerManager.paperclips, equals(500.0));
      expect(newGameState.playerManager.money, equals(250.0));
    });

    test('Détection entreprise existante au redémarrage', () async {
      // Créer et sauvegarder une entreprise
      final gameState = GameState();
      await gameState.createNewEnterprise('Auto Nav Test');
      
      final orchestrator = GamePersistenceOrchestrator.instance;
      await orchestrator.saveGameById(gameState);
      
      // Simuler redémarrage
      final newGameState = GameState();
      
      // Charger l'entreprise
      final saves = await orchestrator.listSaves();
      expect(saves, isNotEmpty);
      
      final firstSave = saves.first;
      await orchestrator.loadGameById(newGameState, firstSave.id);
      
      // Vérifier que l'entreprise est chargée
      expect(newGameState.enterpriseId, isNotNull);
      expect(newGameState.enterpriseName, equals('Auto Nav Test'));
    });
  });
}
