import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/controllers/game_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameState ↔ GameSessionController', () {
    test('GameSessionController pilote bien la production automatique', () async {
      final gameState = GameState();
      gameState.initialize();

      // Préparer un état propice à la production automatique
      final player = gameState.playerManager;
      player.updateMoney(1000.0);
      player.updateMetal(20.0);
      player.purchaseAutoClipper();

      final controller = GameSessionController(gameState);

      final paperclipsBefore = player.paperclips;
      final metalBefore = player.metal;

      // Démarrer la session (démarre le timer de production)
      controller.startSession();

      // Simuler un tick via le contrôleur sans attendre le Timer réel
      controller.runProductionTickForTest();

      final paperclipsAfter = player.paperclips;
      final metalAfter = player.metal;

      expect(paperclipsAfter, greaterThanOrEqualTo(paperclipsBefore));
      expect(metalAfter, lessThanOrEqualTo(metalBefore));

      controller.dispose();
      gameState.dispose();
    });
  });
}
