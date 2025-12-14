import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/upgrades/upgrade_effects_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameState - upgrade storage', () {
    test('purchaseUpgrade(storage) applique maxMetalStorage via UpgradeEffectsCalculator', () {
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

      final player = gameState.playerManager;

      player.updateMoney(1e9);

      final beforeLevel = player.upgrades['storage']!.level;
      final ok = gameState.purchaseUpgrade('storage');

      expect(ok, isTrue);
      expect(player.upgrades['storage']!.level, beforeLevel + 1);

      final expectedCapacity = UpgradeEffectsCalculator.metalStorageCapacity(
        storageLevel: player.upgrades['storage']!.level,
      );
      expect(player.maxMetalStorage, expectedCapacity);

      gameState.dispose();
    });
  });
}
