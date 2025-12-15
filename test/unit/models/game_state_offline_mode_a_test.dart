import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameState - offline Mode A', () {
    test('applyOfflineModeAOnResume produit des trombones et consomme du métal', () {
      final gameState = GameState();
      gameState.initialize();

      gameState.playerManager.updateAutoclippers(1);
      gameState.playerManager.updateMetal(10000.0);

      final paperclipsBefore = gameState.playerManager.paperclips;
      final metalBefore = gameState.playerManager.metal;

      gameState.markLastActiveAt(DateTime.now().subtract(const Duration(minutes: 10)));
      gameState.applyOfflineModeAOnResume();

      final paperclipsAfter = gameState.playerManager.paperclips;
      final metalAfter = gameState.playerManager.metal;

      expect(paperclipsAfter, greaterThan(paperclipsBefore));
      expect(metalAfter, lessThan(metalBefore));

      // 1 autoclipper = 0.1 clips/sec => 60 clips en 10 min.
      expect(paperclipsAfter - paperclipsBefore, closeTo(60.0, 0.0001));

      gameState.dispose();
    });

    test('applyOfflineModeAOnResume clamp la durée offline à OFFLINE_MAX_DURATION', () {
      final gameState = GameState();
      gameState.initialize();

      gameState.playerManager.updateAutoclippers(1);
      gameState.playerManager.updateMetal(1000000.0);

      final paperclipsBefore = gameState.playerManager.paperclips;

      gameState.markLastActiveAt(DateTime.now().subtract(const Duration(days: 2)));
      gameState.applyOfflineModeAOnResume();

      final produced = gameState.playerManager.paperclips - paperclipsBefore;

      // Clamp à 8h: 0.1 clips/sec * 8h
      const expectedMax = GameConstants.BASE_AUTOCLIPPER_PRODUCTION * 60.0 * 60.0 * 8.0;
      expect(produced, closeTo(expectedMax, 0.0001));

      gameState.dispose();
    });

    test('applyOfflineModeAOnResume ne double-crédite pas si appelé deux fois de suite', () {
      final gameState = GameState();
      gameState.initialize();

      gameState.playerManager.updateAutoclippers(1);
      gameState.playerManager.updateMetal(10000.0);

      gameState.markLastActiveAt(DateTime.now().subtract(const Duration(minutes: 10)));
      gameState.applyOfflineModeAOnResume();

      final paperclipsAfterFirst = gameState.playerManager.paperclips;

      gameState.applyOfflineModeAOnResume();
      final paperclipsAfterSecond = gameState.playerManager.paperclips;

      expect(paperclipsAfterSecond, closeTo(paperclipsAfterFirst, 0.0001));

      gameState.dispose();
    });
  });
}
