import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameState - production manuelle', () {
    test('producePaperclip délègue à ProductionManager et met à jour stats/XP', () async {
      final gameState = GameState();
      gameState.initialize();

      final player = gameState.playerManager;
      final stats = gameState.statistics;
      final level = gameState.levelSystem;

      // Préparer un état où la production manuelle est possible
      player.updateMetal(GameConstants.METAL_PER_PAPERCLIP);

      final paperclipsBefore = player.paperclips;
      final metalBefore = player.metal;
      final producedBefore = stats.totalPaperclipsProduced;
      final xpBefore = level.experience;

      gameState.producePaperclip();

      expect(player.paperclips, paperclipsBefore + 1);
      expect(player.metal, closeTo(metalBefore - GameConstants.METAL_PER_PAPERCLIP, 0.0001));
      expect(stats.totalPaperclipsProduced, producedBefore + 1);
      expect(level.experience, greaterThanOrEqualTo(xpBefore));

      // Compat: compteur GameState miroir des stats
      expect(gameState.totalPaperclipsProduced, stats.totalPaperclipsProduced);

      gameState.dispose();
    });
  });
}
