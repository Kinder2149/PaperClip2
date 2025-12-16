import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameState - offline Mode A', () {
    test('applyOfflineProgressV2 produit des trombones et consomme du métal', () {
      final gameState = GameState();
      gameState.initialize();

      // Offline v2 simule aussi les ventes auto; on désactive pour tester la production seule.
      gameState.setAutoSellEnabled(false);

      gameState.playerManager.updateAutoclippers(1);
      gameState.playerManager.updateMetal(10000.0);

      final paperclipsBefore = gameState.playerManager.paperclips;
      final metalBefore = gameState.playerManager.metal;

      gameState.markLastActiveAt(DateTime.now().subtract(const Duration(minutes: 10)));
      gameState.applyOfflineProgressV2();

      final paperclipsAfter = gameState.playerManager.paperclips;
      final metalAfter = gameState.playerManager.metal;

      expect(paperclipsAfter, greaterThan(paperclipsBefore));
      expect(metalAfter, lessThan(metalBefore));

      // 1 autoclipper = 0.1 clips/sec => 60 clips en 10 min.
      expect(paperclipsAfter - paperclipsBefore, closeTo(60.0, 0.0001));

      gameState.dispose();
    });

    test('applyOfflineProgressV2 clamp la durée offline à OFFLINE_MAX_DURATION', () {
      final gameState = GameState();
      gameState.initialize();

      // Offline v2 simule aussi les ventes auto; on désactive pour tester la production seule.
      gameState.setAutoSellEnabled(false);

      gameState.playerManager.updateAutoclippers(1);
      gameState.playerManager.updateMetal(1000000.0);

      final paperclipsBefore = gameState.playerManager.paperclips;

      gameState.markLastActiveAt(DateTime.now().subtract(const Duration(days: 2)));
      gameState.applyOfflineProgressV2();

      final produced = gameState.playerManager.paperclips - paperclipsBefore;

      // Clamp à 8h: 0.1 clips/sec * 8h
      const expectedMax = GameConstants.BASE_AUTOCLIPPER_PRODUCTION * 60.0 * 60.0 * 8.0;
      expect(produced, closeTo(expectedMax, 0.0001));

      gameState.dispose();
    });

    test('applyOfflineProgressV2 ne double-crédite pas si appelé deux fois de suite', () {
      final gameState = GameState();
      gameState.initialize();

      // Offline v2 simule aussi les ventes auto; on désactive pour tester la production seule.
      gameState.setAutoSellEnabled(false);

      gameState.playerManager.updateAutoclippers(1);
      gameState.playerManager.updateMetal(10000.0);

      gameState.markLastActiveAt(DateTime.now().subtract(const Duration(minutes: 10)));
      gameState.applyOfflineProgressV2();

      final paperclipsAfterFirst = gameState.playerManager.paperclips;

      gameState.applyOfflineProgressV2();
      final paperclipsAfterSecond = gameState.playerManager.paperclips;

      expect(paperclipsAfterSecond, closeTo(paperclipsAfterFirst, 0.0001));

      gameState.dispose();
    });
  });
}
