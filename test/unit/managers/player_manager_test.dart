import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/managers/player_manager.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/services/units/value_objects.dart';

void main() {
  group('PlayerManager', () {
    test('updateMoney clamp à 0 si valeur négative', () {
      final player = PlayerManager();

      player.updateMoney(-10);

      expect(player.money, 0);
    }, skip: true);

    test('updateMetal clamp à maxMetalStorage', () {
      final player = PlayerManager();

      player.updateMaxMetalStorage(50);
      player.updateMetal(999);

      expect(player.metal, 50);
    });

    test('setSellPrice applique un minimum à 0.01', () {
      final player = PlayerManager();

      player.setSellPrice(0);

      expect(player.sellPrice, 0.01);
    });

    test('consumeMetal échoue si amount <= 0 ou > metal', () {
      final player = PlayerManager();

      final initialMetal = player.metal;

      expect(player.consumeMetal(0), false);
      expect(player.metal, initialMetal);

      expect(player.consumeMetal(initialMetal + 1), false);
      expect(player.metal, initialMetal);
    });

    test('purchaseUpgrade échoue si argent insuffisant (level inchangé)', () {
      final player = PlayerManager();

      player.updateMoney(0);

      final before = player.upgrades['storage']!.level;

      final success = player.purchaseUpgrade('storage');

      expect(success, false);
      expect(player.upgrades['storage']!.level, before);
    });

    test('purchaseUpgrade storage: level++ et storageUpgradeLevel miroir', () {
      final player = PlayerManager();

      player.updateMoney(1e9);

      final before = player.upgrades['storage']!.level;

      final success = player.purchaseUpgrade('storage');

      expect(success, true);
      expect(player.upgrades['storage']!.level, before + 1);
      expect(player.storageUpgradeLevel, player.upgrades['storage']!.level);
    });

    test('purchaseUpgrade efficiency: level++ et efficiencyUpgradeLevel miroir', () {
      final player = PlayerManager();

      player.updateMoney(1e9);

      final before = player.upgrades['efficiency']!.level;

      final success = player.purchaseUpgrade('efficiency');

      expect(success, true);
      expect(player.upgrades['efficiency']!.level, before + 1);
      expect(player.efficiencyUpgradeLevel, player.upgrades['efficiency']!.level);
    });

    test('fromJson fusionne wire vers metal (compat)', () {
      final player = PlayerManager();

      player.fromJson({
        'metal': 10,
        'wire': 5,
      });

      expect(player.metal, 15);
    });

    test('fromJson fallback legacy: storageUpgradeLevel/efficiencyUpgradeLevel -> upgrades', () {
      final player = PlayerManager();

      player.fromJson({
        'storageUpgradeLevel': 2,
        'efficiencyUpgradeLevel': 3,
      });

      expect(player.upgrades['storage']!.level, 2);
      expect(player.upgrades['efficiency']!.level, 3);
    });

    test('calculateAutoclipperROI matches expected formula (per minute conversion)', () {
      final player = PlayerManager();

      player.updateMoney(1e9);
      player.setSellPrice(0.2);
      expect(player.purchaseAutoClipper(), isTrue);

      final cost = player.calculateAutoclipperCost();
      final productionPerMinute = UnitsPerSecond(
        player.autoClipperCount * GameConstants.BASE_AUTOCLIPPER_PRODUCTION,
      ).toPerMinute().value;

      final expectedRoi = (productionPerMinute * player.sellPrice) / cost * 100;
      final roi = player.calculateAutoclipperROI();

      expect(roi.isFinite, isTrue);
      expect(roi, closeTo(expectedRoi, 1e-9));
    });
  });
}
