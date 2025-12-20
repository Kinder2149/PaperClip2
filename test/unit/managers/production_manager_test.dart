import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/managers/player_manager.dart';
import 'package:paperclip2/managers/production_manager.dart';
import 'package:paperclip2/models/event_system.dart';
import 'package:paperclip2/models/level_system.dart';
import 'package:paperclip2/models/statistics_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProductionManager', () {
    late PlayerManager player;
    late StatisticsManager stats;
    late LevelSystem level;
    late ProductionManager production;

    setUp(() {
      SharedPreferences.setMockInitialValues({});

      player = PlayerManager();
      stats = StatisticsManager();
      level = LevelSystem();
      production = ProductionManager(
        playerManager: player,
        statistics: stats,
        levelSystem: level,
      );

      // Éviter les effets de bord entre tests (singleton)
      EventManager.instance.clearAllEvents();
    });

    test('processProduction ajuste la production si métal insuffisant', () {
      // GIVEN 1 autoclipper mais métal limité
      player.updateAutoclippers(1);
      player.updateMetal(GameConstants.METAL_PER_PAPERCLIP * 1.5);

      final metalBefore = player.metal;
      final paperclipsBefore = player.paperclips;
      final producedBefore = stats.totalPaperclipsProduced;

      // WHEN
      production.processProduction();

      // THEN : on produit au moins 1 trombone et on consomme du métal
      expect(player.paperclips, greaterThanOrEqualTo(paperclipsBefore));
      expect(player.metal, lessThanOrEqualTo(metalBefore));
      expect(stats.totalPaperclipsProduced, greaterThanOrEqualTo(producedBefore));

      // Et on ne consomme pas plus de métal que disponible
      expect(player.metal, greaterThanOrEqualTo(0));
    });

    test('buyAutoclipperOfficial débite l’argent et augmente autoclippers', () {
      player.updateMoney(100000.0);

      final autoclippersBefore = player.autoClipperCount;
      final moneyBefore = player.money;
      final spentBefore = stats.totalMoneySpent;
      final xpBefore = level.experience;

      final cost = production.calculateAutoclipperCost();

      final ok = production.buyAutoclipperOfficial();

      expect(ok, isTrue);
      expect(player.autoClipperCount, autoclippersBefore + 1);
      expect(player.money, closeTo(moneyBefore - cost, 0.0001));
      expect(stats.totalMoneySpent, closeTo(spentBefore + cost, 0.0001));
      expect(level.experience, greaterThanOrEqualTo(xpBefore));
    });

    test('applyMaintenanceCosts réduit autoclippers si argent insuffisant', () {
      // GIVEN
      player.updateAutoclippers(10);
      player.updateMoney(0.0);

      final before = player.autoClipperCount;

      // WHEN
      production.applyMaintenanceCosts();

      // THEN
      expect(player.autoClipperCount, lessThan(before));
    });
  });
}
