import 'package:paperclip2/managers/market_manager.dart';

class PricingAdviceService {
  static void handleSetSellPrice({
    required MarketManager market,
    required double newPrice,
    required void Function() onAccept,
    void Function({
      required String title,
      required String description,
      String? detailedDescription,
    })? onWarning,
  }) {
    if (market.isPriceExcessive(newPrice)) {
      onWarning?.call(
        title: 'Prix Excessif!',
        description: 'Ce prix pourrait affecter vos ventes',
        detailedDescription: market.getPriceRecommendation(),
      );
    }
    onAccept();
  }
}
