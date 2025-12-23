import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameState - achat autoclipper', () {
    test('buyAutoclipper délègue à ProductionManager + met à jour stats et XP', () async {
      final gameState = GameState();
      gameState.initialize();

      final player = gameState.playerManager;
      final stats = gameState.statistics;
      final level = gameState.levelSystem;

      // Préparer un état achetable
      player.updateMoney(100000.0);

      final autoclippersBefore = player.autoClipperCount;
      final moneyBefore = player.money;
      final moneySpentBefore = stats.totalMoneySpent;
      final xpBefore = level.experience;

      final expectedCost = gameState.productionManager.calculateAutoclipperCost();

      gameState.buyAutoclipper();

      expect(player.autoClipperCount, autoclippersBefore + 1);
      expect(player.money, closeTo(moneyBefore - expectedCost, 0.0001));

      expect(stats.totalMoneySpent, closeTo(moneySpentBefore + expectedCost, 0.0001));
      expect(level.experience, greaterThan(xpBefore));

      gameState.dispose();
    });
  });
}
