import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/managers/player_manager.dart';
import 'package:paperclip2/models/statistics_manager.dart';
import 'package:paperclip2/models/progression_system.dart';
import 'package:paperclip2/managers/production_manager.dart';

void main() {
  group('ProductionManager.processProduction', () {
    late PlayerManager player;
    late StatisticsManager stats;
    late LevelSystem level;
    late ProductionManager production;

    setUp(() {
      player = PlayerManager();
      stats = StatisticsManager();
      level = LevelSystem();
      production = ProductionManager(
        playerManager: player,
        statistics: stats,
        levelSystem: level,
      );

      // Reset state
      player.resetPlayerState();
      // Ensure known baseline: no autoclippers, some metal, base upgrades
      player.updateAutoclippers(0);
      player.updateMetal(GameConstants.INITIAL_METAL);
      player.upgrades['speed']?.level = 0;
      player.upgrades['bulk']?.level = 0;
      player.upgrades['efficiency']?.level = 0;
    });

    test('no autoclippers -> no production and no metal consumption', () {
      final metalBefore = player.metal;
      final clipsBefore = player.paperclips;

      production.processProduction(elapsedSeconds: 1.0);

      expect(player.paperclips, closeTo(clipsBefore, 1e-9));
      expect(player.metal, closeTo(metalBefore, 1e-9));
      expect(stats.totalPaperclipsProduced, 0);
    });

    test('produces expected clips with sufficient metal (1s, base multipliers)', () {
      // 2 autoclippers, base production 1 per second each => 2 per second
      player.updateAutoclippers(2);
      // Ensure plenty of metal
      player.updateMetal(1000.0);

      production.processProduction(elapsedSeconds: 1.0);

      // Produced 2 units, metal cost per clip = METAL_PER_PAPERCLIP at efficiency level 0
      final expectedProduced = 2;
      final expectedMetalUsed = expectedProduced * GameConstants.METAL_PER_PAPERCLIP;

      expect(player.paperclips, closeTo(expectedProduced.toDouble(), 1e-9));
      expect(player.metal, closeTo(1000.0 - expectedMetalUsed, 1e-9));
      expect(stats.totalPaperclipsProduced, expectedProduced);
      expect(stats.totalMetalUsed, closeTo(expectedMetalUsed, 1e-9));
    });

    test('respects speed/bulk multipliers and floors to integer units', () {
      // 3 autoclippers, base 1/s => 3/s
      player.updateAutoclippers(3);
      // Upgrades
      player.upgrades['speed']?.level = 2; // +2 * SPEED_BONUS_PER_LEVEL
      player.upgrades['bulk']?.level = 1;  // +1 * BULK_BONUS_PER_LEVEL
      player.upgrades['efficiency']?.level = 0;
      player.updateMetal(1000.0);

      // Compute expected double production rate
      final speed = 1.0 + 2 * GameConstants.SPEED_BONUS_PER_LEVEL;
      final bulk = 1.0 + 1 * GameConstants.BULK_BONUS_PER_LEVEL;
      final rate = 3 * GameConstants.BASE_AUTOCLIPPER_PRODUCTION * speed * bulk; // per second
      final desired = rate * 1.0; // elapsedSeconds=1.0
      final produced = desired.floor();

      production.processProduction(elapsedSeconds: 1.0);

      expect(player.paperclips, closeTo(produced.toDouble(), 1e-9));
    });

    test('if metal insufficient, produce fewer clips and do not go negative', () {
      player.updateAutoclippers(10); // high demand
      // Very little metal available
      player.updateMetal(0.5);
      final metalPerClip = GameConstants.METAL_PER_PAPERCLIP; // efficiency 0
      final maxByMetal = (0.5 / metalPerClip).floor();

      production.processProduction(elapsedSeconds: 1.0);

      expect(player.paperclips, closeTo(maxByMetal.toDouble(), 1e-9));
      // Remaining metal is initial - used
      final expectedMetal = 0.5 - maxByMetal * metalPerClip;
      expect(player.metal, closeTo(expectedMetal, 1e-9));
    });
  });
}
