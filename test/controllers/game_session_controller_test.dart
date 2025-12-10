import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/controllers/game_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameSessionController', () {
    test('peut être instancié avec un GameState initialisé', () {
      final gameState = GameState();
      gameState.initialize();

      final controller = GameSessionController(gameState);

      expect(controller.gameState, same(gameState));

      // Nettoyage
      controller.dispose();
      gameState.dispose();
    });
  });
}
