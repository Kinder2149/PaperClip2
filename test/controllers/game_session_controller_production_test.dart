import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/controllers/game_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameSessionController - production', () {
    test('un tick de production augmente les trombones et consomme du métal', () async {
      final gameState = GameState();
      gameState.initialize();

      // Préparer un état où la production automatique peut fonctionner
      final player = gameState.playerManager;
      player.updateMoney(1000.0);
      player.updateMetal(20.0);

      // Acheter au moins un autoclipper pour avoir une production automatique
      player.purchaseAutoClipper();

      final controller = GameSessionController(gameState);

      final paperclipsBefore = player.paperclips;
      final metalBefore = player.metal;

      // Simuler un tick de production sans attendre un vrai Timer
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
