import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/managers/market_manager.dart';
import 'package:paperclip2/managers/player_manager.dart';
import 'package:paperclip2/managers/resource_manager.dart';
import 'package:paperclip2/models/statistics_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ResourceManager', () {
    test('purchaseMetal retourne false si argent insuffisant', () {
      final player = PlayerManager();
      final market = MarketManager();
      final stats = StatisticsManager();
      market.setManagers(player, stats);

      final resources = ResourceManager()
        ..setPlayerManager(player)
        ..setMarketManager(market)
        ..setStatisticsManager(stats);

      // Prix élevé => achat impossible
      market.marketMetalPrice = 1000.0;
      player.updateMoney(0.0);
      player.updateMetal(0.0);
      player.updateMaxMetalStorage(100000.0);

      final ok = resources.purchaseMetal();

      expect(ok, isFalse);
      expect(player.metal, 0.0);
      expect(stats.totalMoneySpent, 0.0);
      expect(stats.totalMetalPurchased, 0.0);
    });

    test('purchaseMetal retourne false si stockage insuffisant', () {
      final player = PlayerManager();
      final market = MarketManager();
      final stats = StatisticsManager();
      market.setManagers(player, stats);

      final resources = ResourceManager()
        ..setPlayerManager(player)
        ..setMarketManager(market)
        ..setStatisticsManager(stats);

      market.marketMetalPrice = 1.0;
      player.updateMoney(999999.0);

      // Stockage trop petit
      player.updateMaxMetalStorage(GameConstants.METAL_PACK_AMOUNT - 0.0001);
      player.updateMetal(0.0);

      final ok = resources.purchaseMetal();

      expect(ok, isFalse);
      expect(player.metal, 0.0);
      expect(stats.totalMoneySpent, 0.0);
      expect(stats.totalMetalPurchased, 0.0);
    });

    test('purchaseMetal achète du métal, déduit l’argent et met à jour les stats', () {
      final player = PlayerManager();
      final market = MarketManager();
      final stats = StatisticsManager();
      market.setManagers(player, stats);

      final resources = ResourceManager()
        ..setPlayerManager(player)
        ..setMarketManager(market)
        ..setStatisticsManager(stats);

      market.marketMetalPrice = 2.0;
      player.updateMoney(100000.0);
      player.updateMetal(0.0);
      player.updateMaxMetalStorage(100000.0);

      final moneyBefore = player.money;
      final metalBefore = player.metal;
      final spentBefore = stats.totalMoneySpent;
      final purchasedBefore = stats.totalMetalPurchased;

      final ok = resources.purchaseMetal();

      expect(ok, isTrue);
      expect(player.metal, closeTo(metalBefore + GameConstants.METAL_PACK_AMOUNT, 0.0001));
      expect(
        player.money,
        closeTo(moneyBefore - (GameConstants.METAL_PACK_AMOUNT * market.marketMetalPrice), 0.0001),
      );
      expect(
        stats.totalMoneySpent,
        closeTo(spentBefore + (GameConstants.METAL_PACK_AMOUNT * market.marketMetalPrice), 0.0001),
      );
      expect(stats.totalMetalPurchased, closeTo(purchasedBefore + GameConstants.METAL_PACK_AMOUNT, 0.0001));
    });
  });
}
