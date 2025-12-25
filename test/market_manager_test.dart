import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/managers/market_manager.dart';

void main() {
  group('MarketManager.updateMarketStock & metal price', () {
    test('metal price increases when stock decreases, clamped to bounds', () {
      final market = MarketManager();
      market.resetMarketState();

      // At full initial stock => price near MIN
      market.updateMarketStock(GameConstants.INITIAL_MARKET_METAL);
      final pFull = market.marketMetalPrice;
      expect(pFull, closeTo(GameConstants.MIN_METAL_PRICE, 1e-9));

      // At zero stock => price should be MAX
      market.updateMarketStock(0);
      final pZero = market.marketMetalPrice;
      expect(pZero, closeTo(GameConstants.MAX_METAL_PRICE, 1e-9));

      // Mid stock => price between min and max
      final mid = GameConstants.INITIAL_MARKET_METAL / 2;
      market.updateMarketStock(mid);
      final pMid = market.marketMetalPrice;
      expect(pMid, greaterThan(GameConstants.MIN_METAL_PRICE));
      expect(pMid, lessThan(GameConstants.MAX_METAL_PRICE));
    });
  });
}
