import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import '../helpers/game_simulator.dart';

/// Test de production automatique avec autoclippers
void main() {
  group('Production Automatique', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      while (!gameState.isInitialized) {}
    });

    test('Production auto avec 10 autoclippers pendant 60 secondes', () {
      // Setup : Donner ressources initiales
      gameState.playerManager.updateMoney(10000);
      gameState.playerManager.updateMetal(1000);
      
      // Acheter 10 autoclippers
      for (int i = 0; i < 10; i++) {
        gameState.productionManager.buyAutoclipperOfficial();
      }
      
      expect(gameState.playerManager.autoClipperCount, equals(10));
      
      final paperclipsBefore = gameState.playerManager.paperclips;
      final autoPaperclipsBefore = gameState.statistics.autoPaperclipsProduced;
      
      // Simuler 60 secondes de production auto
      GameSimulator.simulateTimePassing(gameState, Duration(seconds: 60));
      
      final paperclipsAfter = gameState.playerManager.paperclips;
      final autoPaperclipsAfter = gameState.statistics.autoPaperclipsProduced;
      
      // Vérifications
      final produced = paperclipsAfter - paperclipsBefore;
      final autoProduced = autoPaperclipsAfter - autoPaperclipsBefore;
      
      print('📊 Résultats Production Auto :');
      print('   Autoclippers : 10');
      print('   Durée : 60 secondes');
      print('   Trombones produits : $produced');
      print('   Auto produits (stats) : $autoProduced');
      print('   Attendu : ~600 (10 autoclippers × 60 sec)');
      
      // 10 autoclippers × 60 secondes = 600 trombones attendus
      expect(produced, greaterThanOrEqualTo(500), 
          reason: 'Devrait produire au moins 500 trombones (marge pour achat métal)');
      expect(produced, lessThanOrEqualTo(700), 
          reason: 'Ne devrait pas dépasser 700 trombones');
    });

    test('Production auto s\'arrête si plus de métal ni d\'argent', () {
      // Setup : Peu de ressources
      gameState.playerManager.updateMoney(50); // Juste assez pour 1 pack métal
      gameState.playerManager.updateMetal(10); // 100 trombones max
      
      // Acheter 5 autoclippers
      for (int i = 0; i < 5; i++) {
        gameState.productionManager.buyAutoclipperOfficial();
      }
      
      final paperclipsBefore = gameState.playerManager.paperclips;
      
      // Simuler 60 secondes (devrait s'arrêter avant)
      GameSimulator.simulateTimePassing(gameState, Duration(seconds: 60));
      
      final paperclipsAfter = gameState.playerManager.paperclips;
      final produced = paperclipsAfter - paperclipsBefore;
      
      print('📊 Test Arrêt Production :');
      print('   Trombones produits : $produced');
      print('   Métal restant : ${gameState.playerManager.metal}');
      print('   Argent restant : ${gameState.playerManager.money}');
      
      // Devrait produire moins que 5 × 60 = 300 car manque de ressources
      expect(produced, lessThan(300), 
          reason: 'Production devrait s\'arrêter par manque de ressources');
    });

    test('Production auto avec 50 autoclippers pendant 5 minutes', () {
      // Setup : Beaucoup de ressources
      gameState.playerManager.updateMoney(100000);
      gameState.playerManager.updateMetal(5000);
      
      // Acheter 50 autoclippers
      for (int i = 0; i < 50; i++) {
        gameState.productionManager.buyAutoclipperOfficial();
      }
      
      final paperclipsBefore = gameState.playerManager.paperclips;
      
      // Simuler 5 minutes (300 secondes)
      GameSimulator.simulateTimePassing(gameState, Duration(minutes: 5));
      
      final paperclipsAfter = gameState.playerManager.paperclips;
      final produced = paperclipsAfter - paperclipsBefore;
      
      print('📊 Production Massive :');
      print('   Autoclippers : 50');
      print('   Durée : 5 minutes (300 sec)');
      print('   Trombones produits : $produced');
      print('   Attendu : ~15000 (50 × 300)');
      
      // 50 autoclippers × 300 secondes = 15000 trombones attendus
      expect(produced, greaterThanOrEqualTo(14000), 
          reason: 'Devrait produire au moins 14000 trombones');
    });

    test('Stats autoPaperclipsProduced vs manualPaperclipsProduced', () {
      gameState.playerManager.updateMoney(10000);
      gameState.playerManager.updateMetal(1000);
      
      // Production manuelle
      GameSimulator.simulateManualClicks(gameState, 100);
      
      // Acheter autoclippers
      for (int i = 0; i < 10; i++) {
        gameState.productionManager.buyAutoclipperOfficial();
      }
      
      // Production auto - appeler processProduction directement
      for (int i = 0; i < 30; i++) {
        gameState.productionManager.processProduction(elapsedSeconds: 1.0);
      }
      
      final manualStats = gameState.statistics.manualPaperclipsProduced;
      final autoStats = gameState.statistics.autoPaperclipsProduced;
      
      print('📊 Répartition Production :');
      print('   Manuel : $manualStats');
      print('   Auto : $autoStats');
      print('   Total : ${gameState.statistics.totalPaperclipsProduced}');
      
      expect(manualStats, greaterThanOrEqualTo(100), 
          reason: 'Stats manuelles devraient inclure les 100 clics');
      expect(autoStats, greaterThan(0), 
          reason: 'Stats auto devraient être > 0');
      expect(gameState.statistics.totalPaperclipsProduced, 
          equals(manualStats + autoStats),
          reason: 'Total devrait être la somme manuel + auto');
    });
  });
}
