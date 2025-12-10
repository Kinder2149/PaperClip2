import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/managers/player_manager.dart' as managers;
import 'package:paperclip2/managers/market_manager.dart';
import 'package:paperclip2/managers/production_manager.dart';
import 'package:paperclip2/managers/resource_manager.dart';
import 'package:paperclip2/models/game_core_state.dart';
import 'package:paperclip2/models/level_system.dart';
import 'package:paperclip2/models/statistics_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameCoreState', () {
    test('peut être instancié avec des managers valides', () {
      final player = managers.PlayerManager();
      final market = MarketManager();
      final resources = ResourceManager();
      final level = LevelSystem();
      final stats = StatisticsManager();
      final production = ProductionManager(
        playerManager: player,
        statistics: stats,
        levelSystem: level,
      );

      final core = GameCoreState(
        playerManager: player,
        marketManager: market,
        resourceManager: resources,
        levelSystem: level,
        productionManager: production,
        statistics: stats,
      );

      expect(core.playerManager, same(player));
      expect(core.marketManager, same(market));
      expect(core.productionManager, same(production));
    });
  });
}
