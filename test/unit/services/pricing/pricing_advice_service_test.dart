import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/pricing/pricing_advice_service.dart';
import 'package:paperclip2/managers/market_manager.dart';

void main() {
  group('PricingAdviceService.handleSetSellPrice', () {
    test('warns when price excessive and calls onAccept', () {
      final market = MarketManager();
      int warnings = 0;
      int accepted = 0;

      PricingAdviceService.handleSetSellPrice(
        market: market,
        newPrice: 1e9, // surely excessive
        onAccept: () => accepted++,
        onWarning: ({required String title, required String description, String? detailedDescription}) {
          warnings++;
        },
      );

      expect(warnings, 1);
      expect(accepted, 1);
    });

    test('does not warn when price is normal and calls onAccept', () {
      final market = MarketManager();
      int warnings = 0;
      int accepted = 0;

      PricingAdviceService.handleSetSellPrice(
        market: market,
        newPrice: 1.0,
        onAccept: () => accepted++,
        onWarning: ({required String title, required String description, String? detailedDescription}) {
          warnings++;
        },
      );

      expect(warnings, 0);
      expect(accepted, 1);
    });
  });
}
