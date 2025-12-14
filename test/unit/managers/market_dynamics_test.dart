import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/managers/market_manager.dart';

void main() {
  group('MarketDynamics', () {
    test('getMarketConditionMultiplier applique la formule volatility*(1+trend)*pressure', () {
      final d = MarketDynamics()
        ..marketVolatility = 1.2
        ..marketTrend = 0.1
        ..competitorPressure = 0.9;

      final expected = 1.2 * (1 + 0.1) * 0.9;
      expect(d.getMarketConditionMultiplier(), closeTo(expected, 1e-9));
    });

    test('toJson/fromJson roundtrip conserve les valeurs', () {
      final d1 = MarketDynamics()
        ..marketVolatility = 0.95
        ..marketTrend = -0.05
        ..competitorPressure = 1.05;

      final json = d1.toJson();

      final d2 = MarketDynamics()..fromJson(json);

      expect(d2.marketVolatility, closeTo(0.95, 1e-9));
      expect(d2.marketTrend, closeTo(-0.05, 1e-9));
      expect(d2.competitorPressure, closeTo(1.05, 1e-9));
    });

    test('fromJson applique des valeurs par défaut si champs manquants', () {
      final d = MarketDynamics()..fromJson({});

      expect(d.marketVolatility, 1.0);
      expect(d.marketTrend, 0.0);
      expect(d.competitorPressure, 1.0);
    });

    test('updateMarketConditions garde des valeurs dans les bornes attendues', () {
      final d = MarketDynamics();
      d.updateMarketConditions();

      // Ces bornes proviennent directement de l’implémentation (Random) :
      // volatility = 0.8..1.2 ; trend = -0.2..0.2 ; pressure = 0.9..1.1
      expect(d.marketVolatility, inInclusiveRange(0.8, 1.2));
      expect(d.marketTrend, inInclusiveRange(-0.2, 0.2));
      expect(d.competitorPressure, inInclusiveRange(0.9, 1.1));
    });
  });

  group('MarketManager.calculateDemand (dépendance MarketDynamics)', () {
    test('par défaut la demande vaut BASE_DEMAND à prix=0, marketing=0, saturation=DEFAULT', () {
      final manager = MarketManager();

      // _currentMarketSaturation est initialisé à DEFAULT_MARKET_SATURATION.
      final demand = manager.calculateDemand(0.0, 0);

      // priceMultiplier = 1.0 ; marketingMultiplier = 1.0 ; saturationFactor = 1.0
      // _marketDynamics multiplier = 1.0 (defaults)
      expect(demand, closeTo(GameConstants.BASE_DEMAND, 1e-9));
    });

    test('la demande augmente avec le marketing (marketingLevel * MARKETING_BOOST_PER_LEVEL)', () {
      final manager = MarketManager();

      final d0 = manager.calculateDemand(0.0, 0);
      final d2 = manager.calculateDemand(0.0, 2);

      final expectedMultiplier = 1.0 + (2 * GameConstants.MARKETING_BOOST_PER_LEVEL);
      expect(d2, closeTo(d0 * expectedMultiplier, 1e-9));
    });

    test('fromJson: marketDynamics impacte calculateDemand via getMarketConditionMultiplier', () {
      final manager = MarketManager();

      // Force un multiplicateur de marché x2 via _marketDynamics
      manager.fromJson({
        'currentMarketSaturation': GameConstants.DEFAULT_MARKET_SATURATION,
        'marketDynamics': {
          'marketVolatility': 2.0,
          'marketTrend': 0.0,
          'competitorPressure': 1.0,
        },
      });

      final base = MarketManager().calculateDemand(0.0, 0);
      final boosted = manager.calculateDemand(0.0, 0);

      expect(boosted, closeTo(base * 2.0, 1e-9));
    });
  });
}
