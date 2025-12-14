import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameState - temps de jeu', () {
    test('incrementGameTime met à jour StatisticsManager et le compteur legacy', () async {
      final gameState = GameState();
      gameState.initialize();

      final stats = gameState.statistics;

      expect(stats.totalGameTimeSec, 0);
      expect(gameState.totalTimePlayedInSeconds, 0);

      gameState.incrementGameTime(3);

      expect(stats.totalGameTimeSec, 3);
      expect(gameState.totalTimePlayedInSeconds, 3);

      gameState.incrementGameTime(2);

      expect(stats.totalGameTimeSec, 5);
      expect(gameState.totalTimePlayedInSeconds, 5);

      gameState.dispose();
    });
  });
}
