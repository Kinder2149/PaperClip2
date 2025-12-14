import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameEvent pipeline', () {
    test('purchaseUpgrade émet un event consommé par stats et progression', () {
      final gameState = GameState();
      gameState.initialize();

      gameState.levelSystem.fromJson({
        'experience': 0,
        'level': 7,
        'currentPath': 0,
        'xpMultiplier': 1.0,
        'comboCount': 0,
        'dailyBonusClaimed': false,
        'pathProgress': <String, dynamic>{},
        'unlockedMilestones': <String, dynamic>{},
        'pendingPathChoiceLevel': null,
        'pendingPathOptions': <dynamic>[],
      });

      gameState.playerManager.updateMoney(100000.0);

      final statsBefore = gameState.statistics.totalUpgradesBought;
      final moneySpentBefore = gameState.statistics.totalMoneySpent;
      final xpBefore = gameState.levelSystem.experience;

      final ok = gameState.purchaseUpgrade('speed');

      expect(ok, isTrue);
      expect(gameState.statistics.totalUpgradesBought, statsBefore + 1);
      expect(gameState.statistics.totalMoneySpent, greaterThan(moneySpentBefore));
      expect(gameState.levelSystem.experience, greaterThan(xpBefore));

      gameState.dispose();
    });
  });
}
