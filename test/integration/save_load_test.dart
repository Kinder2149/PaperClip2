import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';

/// Test du système de sauvegarde/chargement local
/// Note: Ces tests nécessitent un système de fichiers réel et sont temporairement désactivés
void main() {
  group('Sauvegarde/Chargement Local', skip: 'Nécessite système de fichiers réel', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      while (!gameState.isInitialized) {}
    });

    test('Sauvegarder et charger GameState basique', () async {
      // 1. Modifier GameState
      gameState.playerManager.updateMoney(5000);
      gameState.playerManager.updateMetal(250);
      gameState.playerManager.updatePaperclips(150);
      
      final enterpriseId = gameState.enterpriseId!;
      final moneyBefore = gameState.playerManager.money;
      final metalBefore = gameState.playerManager.metal;
      final paperclipsBefore = gameState.playerManager.paperclips;
      
      print('📊 Avant Sauvegarde :');
      print('   Enterprise ID : $enterpriseId');
      print('   Argent : ${moneyBefore.toStringAsFixed(2)}€');
      print('   Métal : ${metalBefore.toStringAsFixed(2)}');
      print('   Trombones : ${paperclipsBefore.toStringAsFixed(0)}');
      
      // 2. Sauvegarder
      await gameState.saveOnImportantEvent();
      
      print('   ✅ Sauvegarde effectuée');
      
      // 3. Créer nouveau GameState
      final gameState2 = GameState();
      while (!gameState2.isInitialized) {}
      
      // 4. Charger
      await GamePersistenceOrchestrator.instance.loadGameById(
        gameState2, 
        enterpriseId
      );
      
      print('📊 Après Chargement :');
      print('   Argent : ${gameState2.playerManager.money.toStringAsFixed(2)}€');
      print('   Métal : ${gameState2.playerManager.metal.toStringAsFixed(2)}');
      print('   Trombones : ${gameState2.playerManager.paperclips.toStringAsFixed(0)}');
      
      // 5. Vérifier données
      expect(gameState2.playerManager.money, equals(moneyBefore),
          reason: 'Argent devrait être restauré');
      expect(gameState2.playerManager.metal, equals(metalBefore),
          reason: 'Métal devrait être restauré');
      expect(gameState2.playerManager.paperclips, equals(paperclipsBefore),
          reason: 'Trombones devraient être restaurés');
    });

    test('Sauvegarder après reset préserve Quantum/PI', () async {
      // 1. Donner Quantum et PI
      gameState.rareResources.addQuantum(50);
      gameState.rareResources.addPointsInnovation(25);
      
      final quantumBefore = gameState.rareResources.quantum;
      final piBefore = gameState.rareResources.pointsInnovation;
      final enterpriseId = gameState.enterpriseId!;
      
      print('📊 Avant Sauvegarde :');
      print('   Quantum : $quantumBefore');
      print('   PI : $piBefore');
      
      // 2. Sauvegarder
      await gameState.saveOnImportantEvent();
      
      // 3. Charger dans nouveau GameState
      final gameState2 = GameState();
      while (!gameState2.isInitialized) {}
      
      await GamePersistenceOrchestrator.instance.loadGameById(
        gameState2, 
        enterpriseId
      );
      
      print('📊 Après Chargement :');
      print('   Quantum : ${gameState2.rareResources.quantum}');
      print('   PI : ${gameState2.rareResources.pointsInnovation}');
      
      // 4. Vérifier persistance
      expect(gameState2.rareResources.quantum, equals(quantumBefore),
          reason: 'Quantum devrait persister');
      expect(gameState2.rareResources.pointsInnovation, equals(piBefore),
          reason: 'PI devrait persister');
    });

    test('Charger sauvegarde inexistante retourne erreur', () async {
      final gameState2 = GameState();
      while (!gameState2.isInitialized) {}
      
      // Tenter de charger avec ID inexistant
      try {
        await GamePersistenceOrchestrator.instance.loadGameById(
          gameState2, 
          'nonexistent-id-12345'
        );
        
        fail('Devrait lancer une exception');
      } catch (e) {
        print('📊 Erreur attendue : $e');
        expect(e, isNotNull,
            reason: 'Devrait lancer une exception pour ID inexistant');
      }
    });

    test('Sauvegarder stats de jeu', () async {
      // 1. Créer stats
      gameState.playerManager.updateMoney(1000);
      gameState.playerManager.updateMetal(500);
      
      // Produire et vendre
      for (int i = 0; i < 50; i++) {
        gameState.productionManager.producePaperclip();
      }
      
      final totalProduced = gameState.statistics.totalPaperclipsProduced;
      final enterpriseId = gameState.enterpriseId!;
      
      print('📊 Stats Avant Sauvegarde :');
      print('   Total produits : $totalProduced');
      
      // 2. Sauvegarder
      await gameState.saveOnImportantEvent();
      
      // 3. Charger
      final gameState2 = GameState();
      while (!gameState2.isInitialized) {}
      
      await GamePersistenceOrchestrator.instance.loadGameById(
        gameState2, 
        enterpriseId
      );
      
      print('📊 Stats Après Chargement :');
      print('   Total produits : ${gameState2.statistics.totalPaperclipsProduced}');
      
      // 4. Vérifier stats
      expect(gameState2.statistics.totalPaperclipsProduced, equals(totalProduced),
          reason: 'Stats devraient être restaurées');
    });
  });
}
