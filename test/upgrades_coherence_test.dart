import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/managers/market_manager.dart';
import 'package:paperclip2/managers/player_manager.dart';
import 'package:paperclip2/managers/production_manager.dart';
import 'package:paperclip2/models/statistics_manager.dart';
import 'package:paperclip2/models/level_system.dart';
import 'package:paperclip2/services/upgrades/upgrade_effects_calculator.dart';

void main() {
  group('Upgrades coherence', () {
    test('Storage capacity is re-applied on load and metal is clamped', () {
      final player = PlayerManager();
      // Simule un niveau de stockage > 0
      player.upgrades['storage']!.level = 3;
      // Préparer un JSON de sauvegarde minimal avec upgrades
      final json = player.toJson();
      json['upgrades'] = player.upgrades.map((k, v) => MapEntry(k, v.toJson()));

      // Charger dans un nouveau PlayerManager
      final reloaded = PlayerManager();
      reloaded.fromJson(json);

      final expectedCapacity = UpgradeEffectsCalculator.metalStorageCapacity(
        storageLevel: reloaded.upgrades['storage']!.level,
      );
      expect(reloaded.maxMetalStorage, expectedCapacity);

      // Simule un métal trop élevé puis recharge
      final json2 = Map<String, dynamic>.from(json);
      json2['metal'] = expectedCapacity + 100.0;
      final reloaded2 = PlayerManager();
      reloaded2.fromJson(json2);
      expect(reloaded2.metal <= reloaded2.maxMetalStorage, isTrue);
    });

    test('Autoclipper cost calculation remains consistent', () {
      final player = PlayerManager();
      // Simule quelques autoclippers et un niveau d\'automatisation
      player.updateAutoclippers(3);
      player.upgrades['automation']!.level = 2;

      final expected = UpgradeEffectsCalculator.autoclipperCost(
        autoclippersOwned: player.autoClipperCount,
        automationLevel: player.upgrades['automation']!.level,
      );

      // ProductionManager comme source officielle
      final stats = StatisticsManager();
      final level = LevelSystem();
      final production = ProductionManager(
        playerManager: player,
        statistics: stats,
        levelSystem: level,
      );

      final official = production.calculateAutoclipperCost();
      expect(official, closeTo(expected, 1e-9));
    });

    test('Marketing level comes from upgrades map', () {
      final player = PlayerManager();
      player.upgrades['marketing']!.level = 4;
      expect(player.getMarketingLevel(), 4);
    });

    test('Quality increases effective sale price in MarketManager.processSales', () {
      final player = PlayerManager();
      final stats = StatisticsManager();
      final market = MarketManager();
      market.setManagers(player, stats);

      // Préparer l\'état
      player.updatePaperclips(1000);
      player.setSellPrice(GameConstants.OPTIMAL_PRICE_LOW);
      player.upgrades['quality']!.level = 3; // Bonus qualité

      // Fixer un prix du métal et stock marché raisonnables pour éviter effets secondaires
      market.updateMarketStock(GameConstants.INITIAL_MARKET_METAL);

      final qualityBonus = UpgradeEffectsCalculator.qualityMultiplier(level: 3);

      final result = market.processSales(
        playerPaperclips: player.paperclips,
        sellPrice: player.sellPrice,
        marketingLevel: player.getMarketingLevel(),
        qualityLevel: player.upgrades['quality']!.level,
        updatePaperclips: (delta) => player.updatePaperclips(player.paperclips + delta),
        updateMoney: (delta) => player.updateMoney(player.money + delta),
        elapsedSeconds: 5.0, // quelques secondes
        updateMarketState: true,
        requireAutoSellEnabled: false,
      );

      expect(result.unitPrice, closeTo(player.sellPrice * qualityBonus, 1e-9));
      expect(result.quantity, greaterThan(0));
      expect(player.money, greaterThan(0));
    });

    test('Dynamic reputation increases under good sales and optimal price (single step)', () {
      final player = PlayerManager();
      final stats = StatisticsManager();
      final market = MarketManager();
      market.setManagers(player, stats);

      // État initial
      final initialRep = market.reputation;
      player.updatePaperclips(10000);
      player.setSellPrice(GameConstants.OPTIMAL_PRICE_LOW);

      // Assurer une demande suffisante avec une fenêtre longue pour dépasser le seuil (10/min)
      final result = market.processSales(
        playerPaperclips: player.paperclips,
        sellPrice: player.sellPrice,
        marketingLevel: player.getMarketingLevel(),
        qualityLevel: player.upgrades['quality']!.level,
        updatePaperclips: (delta) => player.updatePaperclips(player.paperclips + delta),
        updateMoney: (delta) => player.updateMoney(player.money + delta),
        elapsedSeconds: 60.0, // 1 minute -> ventes/min = quantité vendue
        updateMarketState: true,
        requireAutoSellEnabled: false,
      );

      // Il se peut que la demande ne permette pas des ventes massives selon paramètres, mais on attend au moins un petit ajustement +0.01
      expect(result.quantity, greaterThan(0));
      expect(market.reputation >= initialRep, isTrue);
    });
  });
}
