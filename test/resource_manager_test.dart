import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/managers/market_manager.dart';
import 'package:paperclip2/managers/player_manager.dart';
import 'package:paperclip2/managers/resource_manager.dart';
import 'package:paperclip2/models/statistics_manager.dart';

void main() {
  group('ResourceManager.purchaseMetal', () {
    late PlayerManager player;
    late MarketManager market;
    late ResourceManager resources;
    late StatisticsManager stats;

    setUp(() {
      player = PlayerManager();
      market = MarketManager();
      stats = StatisticsManager();
      resources = ResourceManager()
        ..setPlayerManager(player)
        ..setMarketManager(market)
        ..setStatisticsManager(stats);

      // Reset state to known values
      player.resetPlayerState();
      market.reset();

      // Ensure market has stock and define a predictable metal price
      market.marketMetalPrice = 0.20; // 0.20 per unit
      market.updateMarketStock(GameConstants.METAL_PACK_AMOUNT * 10); // enough stock

      // Give the player some money and empty metal to observe changes
      player.updateMoney(100.0);
      player.updateMetal(0.0);
      // Set storage capacity large enough initially
      player.updateMaxMetalStorage(GameConstants.METAL_PACK_AMOUNT * 20);
    });

    test('returns false when not enough money', () {
      player.updateMoney(0.0);
      final ok = resources.purchaseMetal();
      expect(ok, isFalse);
    });

    test('returns false when storage capacity would be exceeded', () {
      // Fill storage near capacity
      player.updateMetal(player.maxMetalStorage - (GameConstants.METAL_PACK_AMOUNT / 2));
      final ok = resources.purchaseMetal();
      expect(ok, isFalse);
    });

    test('returns false when market stock is insufficient', () {
      market.updateMarketStock(GameConstants.METAL_PACK_AMOUNT - 1); // less than a pack
      final ok = resources.purchaseMetal();
      expect(ok, isFalse);
    });

    test('successful purchase updates money, metal, market stock and statistics', () {
      final unitPrice = market.marketMetalPrice; // 0.20
      final pack = GameConstants.METAL_PACK_AMOUNT; // 100.0 by default
      final expectedCost = pack * unitPrice;

      final ok = resources.purchaseMetal();

      expect(ok, isTrue);
      // Player money decreased by expected cost
      expect(player.money, closeTo(100.0 - expectedCost, 1e-9));
      // Player metal increased by pack amount
      expect(player.metal, closeTo(pack, 1e-9));
      // Market stock decreased
      expect(market.marketMetalStock, closeTo((pack * 10) - pack, 1e-9));
      // Statistics updated
      expect(stats.totalMoneySpent, closeTo(expectedCost, 1e-9));
      expect(stats.totalMetalPurchased, closeTo(pack, 1e-9));
    });
  });
}
