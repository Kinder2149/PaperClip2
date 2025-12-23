import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/gameplay/events/game_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameState - événements UI via EventBus', () {
    test('setSellPrice émet un avertissement prix excessif', () async {
      final gameState = GameState();
      gameState.initialize();

      int warnings = 0;
      String? lastTitle;
      String? lastDescription;

      GameEventListener listener = (e) {
        if (e.data['reason'] == 'ui_price_excessive_warning') {
          warnings++;
          lastTitle = e.data['title'] as String?;
          lastDescription = e.data['description'] as String?;
        }
      };

      gameState.addEventListener(listener);

      gameState.setSellPrice(999999);

      expect(warnings, 1);
      expect(lastTitle, isNotNull);
      expect(lastDescription, isNotNull);

      gameState.removeEventListener(listener);
      gameState.dispose();
    });

    test('handleCompetitiveGameEnd émet un événement de résultat compétitif', () async {
      final gameState = GameState();
      gameState.initialize();

      int events = 0;
      Map<String, Object?>? lastData;

      GameEventListener listener = (e) {
        if (e.data['reason'] == 'ui_show_competitive_result') {
          events++;
          lastData = e.data;
        }
      };

      gameState.addEventListener(listener);

      await gameState.startNewGame('test_competitive', mode: GameMode.COMPETITIVE);
      gameState.playerManager.updateMoney(123.0);
      gameState.playerManager.updatePaperclips(100);
      gameState.playerManager.updateMetal(GameConstants.METAL_PER_PAPERCLIP);

      gameState.handleCompetitiveGameEnd();

      expect(events, 1);
      expect(lastData, isNotNull);
      expect(lastData!['score'], isA<int>());

      gameState.removeEventListener(listener);
      gameState.dispose();
    });
  });
}
