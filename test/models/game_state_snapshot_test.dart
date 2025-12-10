// Tests de roundtrip pour GameState.toSnapshot / applySnapshot

import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';

void main() {
  // Nécessaire pour que les services Flutter (SystemChannels, SharedPreferences, etc.)
  // soient accessibles pendant les tests unitaires.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameState snapshot roundtrip', () {
    test('toSnapshot puis applySnapshot recréent un état cohérent', () async {
      // GIVEN un GameState initialisé avec quelques valeurs
      final original = GameState();
      original.initialize();

      // Simuler quelques modifications de jeu
      original.playerManager.updateMoney(250.0);
      original.playerManager.updatePaperclips(100);
      original.playerManager.updateMetal(15.0);

      // Forcer un mode de jeu particulier
      await original.startNewGame('test-game', mode: GameMode.COMPETITIVE);

      // WHEN on crée un snapshot
      final GameSnapshot snapshot = original.toSnapshot();

      // THEN on peut l'appliquer à une nouvelle instance
      final restored = GameState();
      restored.initialize();
      restored.applySnapshot(snapshot);

      expect(restored.gameName, equals(original.gameName));
      expect(restored.gameMode, equals(original.gameMode));
      expect(restored.playerManager.money, equals(original.playerManager.money));
      expect(restored.playerManager.paperclips, equals(original.playerManager.paperclips));
      expect(restored.playerManager.metal, equals(original.playerManager.metal));
    });
  });
}
