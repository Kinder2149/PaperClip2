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
    // Ne déclencher un avertissement que pour des valeurs manifestement absurdes
    if (newPrice > 1e8) {
      onWarning?.call(
        title: 'Prix Excessif!',
        description: 'Ce prix pourrait affecter vos ventes',
        detailedDescription: market.getPriceRecommendation(),
      );
    }
    onAccept();
  }
}
