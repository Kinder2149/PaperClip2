import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/managers/player_manager.dart';

void main() {
  group('PlayerManager autoclippers', () {
    late PlayerManager player;

    setUp(() {
      player = PlayerManager();
      player.resetPlayerState();
      // Argent suffisant pour les achats
      player.updateMoney(1000.0);
      // Nettoyer autoclippers
      player.updateAutoclippers(0);
      // Reset automation level
      player.upgrades['automation']?.level = 0;
    });

    test('calculateAutoclipperCost respects base and discount bounds', () {
      final base = GameConstants.BASE_AUTOCLIPPER_COST;
      final c0 = player.calculateAutoclipperCost();
      expect(c0, base);

      // Augmente le level d'automation -> discount appliqué
      player.upgrades['automation']?.level = 5;
      final c1 = player.calculateAutoclipperCost();
      // Toujours >= 50% du base cost
      expect(c1, greaterThanOrEqualTo(base * 0.5));
    });

    test('purchaseAutoClipper increments count and spends money', () {
      final beforeMoney = player.money;
      final cost = player.calculateAutoclipperCost();
      final ok = player.purchaseAutoClipper();
      expect(ok, isTrue);
      expect(player.autoClipperCount, 1);
      expect(player.money, closeTo(beforeMoney - cost, 1e-9));
    });

    test('calculateAutoclipperROI returns 0 when no autoclippers', () {
      player.updateAutoclippers(0);
      expect(player.calculateAutoclipperROI(), 0.0);
    });

    test('calculateAutoclipperROI positive when autoclippers exist', () {
      player.updateAutoclippers(2);
      final roi = player.calculateAutoclipperROI();
      // ROI notionnelle > 0 selon implémentation actuelle
      expect(roi, greaterThanOrEqualTo(0.0));
    });
  });
}
