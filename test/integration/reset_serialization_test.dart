import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/reset_history_entry.dart';

/// Tests de sérialisation/désérialisation de l'historique des resets
void main() {
  group('Reset Serialization', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      while (!gameState.isInitialized) {}
    });

    test('Sérialisation historique vide', () {
      // Setup: historique vide
      expect(gameState.resetHistory, isEmpty);
      expect(gameState.resetCount, equals(0));
      
      // Action: sérialiser
      final snapshot = gameState.toSnapshot();
      
      // Assert: snapshot contient historique vide
      expect(snapshot.core['resetHistory'], isA<List>());
      expect(snapshot.core['resetHistory'], isEmpty);
      expect(snapshot.core['resetCount'], equals(0));
    });

    test('Sérialisation avec 1 reset', () {
      // Setup: ajouter 1 reset
      final entry = ResetHistoryEntry(
        timestamp: DateTime.now(),
        levelBefore: 25,
        quantumGained: 10,
        innovationGained: 5,
      );
      gameState.addResetEntry(entry);
      
      // Action: sérialiser
      final snapshot = gameState.toSnapshot();
      
      // Assert: snapshot contient 1 reset
      expect(snapshot.core['resetHistory'], isA<List>());
      expect((snapshot.core['resetHistory'] as List).length, equals(1));
      expect(snapshot.core['resetCount'], equals(1));
    });

    test('Sérialisation avec 5 resets', () {
      // Setup: ajouter 5 resets
      for (int i = 0; i < 5; i++) {
        gameState.addResetEntry(ResetHistoryEntry(
          timestamp: DateTime.now(),
          levelBefore: 20 + i,
          quantumGained: 10 + i,
          innovationGained: 5 + i,
        ));
      }
      
      // Action: sérialiser
      final snapshot = gameState.toSnapshot();
      
      // Assert: snapshot contient 5 resets
      expect((snapshot.core['resetHistory'] as List).length, equals(5));
      expect(snapshot.core['resetCount'], equals(5));
    });

    test('Cycle toSnapshot → applySnapshot conserve resetHistory', () {
      // Setup: ajouter 3 resets
      for (int i = 0; i < 3; i++) {
        gameState.addResetEntry(ResetHistoryEntry(
          timestamp: DateTime.now(),
          levelBefore: 20 + i,
          quantumGained: 10 + i,
          innovationGained: 5 + i,
        ));
      }
      
      final historyBefore = gameState.resetHistory;
      final countBefore = gameState.resetCount;
      
      // Action: sérialiser puis désérialiser
      final snapshot = gameState.toSnapshot();
      
      final gameState2 = GameState();
      while (!gameState2.isInitialized) {}
      gameState2.applySnapshot(snapshot);
      
      // Assert: historique restauré
      expect(gameState2.resetHistory.length, equals(historyBefore.length));
      expect(gameState2.resetCount, equals(countBefore));
      expect(gameState2.resetHistory.length, equals(3));
      expect(gameState2.resetCount, equals(3));
    });

    test('Désérialisation resetCount correct', () {
      // Setup: ajouter 2 resets
      gameState.addResetEntry(ResetHistoryEntry(
        timestamp: DateTime.now(),
        levelBefore: 20,
        quantumGained: 10,
        innovationGained: 5,
      ));
      gameState.addResetEntry(ResetHistoryEntry(
        timestamp: DateTime.now(),
        levelBefore: 25,
        quantumGained: 15,
        innovationGained: 8,
      ));
      
      // Action: cycle complet
      final snapshot = gameState.toSnapshot();
      final gameState2 = GameState();
      while (!gameState2.isInitialized) {}
      gameState2.applySnapshot(snapshot);
      
      // Assert: compteur correct
      expect(gameState2.resetCount, equals(2));
    });

    test('Désérialisation restaure détails des resets', () {
      // Setup: ajouter reset avec données spécifiques
      final originalTimestamp = DateTime.now();
      gameState.addResetEntry(ResetHistoryEntry(
        timestamp: originalTimestamp,
        levelBefore: 30,
        quantumGained: 50,
        innovationGained: 25,
      ));
      
      // Action: cycle complet
      final snapshot = gameState.toSnapshot();
      final gameState2 = GameState();
      while (!gameState2.isInitialized) {}
      gameState2.applySnapshot(snapshot);
      
      // Assert: détails préservés
      expect(gameState2.resetHistory.length, equals(1));
      final restoredEntry = gameState2.resetHistory.first;
      expect(restoredEntry.levelBefore, equals(30));
      expect(restoredEntry.quantumGained, equals(50));
      expect(restoredEntry.innovationGained, equals(25));
      // Note: timestamp peut avoir une légère différence due à la sérialisation
    });
  });
}
