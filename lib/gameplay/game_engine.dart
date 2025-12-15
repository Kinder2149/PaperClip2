import 'dart:math';

import 'package:flutter/foundation.dart';

import 'events/bus/game_event_bus.dart';
import 'events/game_event.dart';
import '../constants/game_config.dart';
import '../managers/production_manager.dart';
import '../managers/player_manager.dart';
import '../managers/market_manager.dart';
import '../models/statistics_manager.dart';
import '../models/progression_system.dart';
import '../services/progression/progression_rules_service.dart';
import '../services/upgrades/upgrade_effects_calculator.dart';

class GameEngine {
  final PlayerManager player;
  final MarketManager market;
  final ProductionManager production;
  final LevelSystem level;
  final StatisticsManager statistics;
  final ProgressionRulesService progressionRules;
  final GameEventBus eventBus;

  GameEngine({
    required this.player,
    required this.market,
    required this.production,
    required this.level,
    required this.statistics,
    required this.progressionRules,
    required this.eventBus,
  });

  void tick({
    required double elapsedSeconds,
    required bool autoSellEnabled,
  }) {
    final int elapsedWholeSeconds = max(0, elapsedSeconds.round());
    if (elapsedWholeSeconds > 0) {
      statistics.updateGameTime(elapsedWholeSeconds);
    }

    production.processProduction(elapsedSeconds: elapsedSeconds);

    // Le marché doit continuer à évoluer (tendances/saturation/prix métal),
    // même si la vente automatique est désactivée.
    market.updateMarketState();

    if (autoSellEnabled) {
      _processAutoSales();
    }
  }

  void tickMarket() {
    // Maintien pour compatibilité: tickMarket force une mise à jour du marché
    // puis traite une vente automatique.
    market.updateMarketState();
    _processAutoSales();
  }

  void _processAutoSales() {
    final sale = market.processSales(
      playerPaperclips: player.paperclips,
      sellPrice: player.sellPrice,
      marketingLevel: player.getMarketingLevel(),
      qualityLevel: player.upgrades['quality']?.level ?? 0,
      updatePaperclips: (delta) {
        player.updatePaperclips(player.paperclips + delta);
      },
      updateMoney: (delta) {
        player.updateMoney(player.money + delta);
      },
      updateMarketState: false,
      requireAutoSellEnabled: true,
    );

    // 3) XP de vente
    if (sale.quantity > 0) {
      eventBus.emit(
        GameEvent(
          type: GameEventType.saleProcessed,
          data: {
            'quantity': sale.quantity,
            'unitPrice': sale.unitPrice,
          },
        ),
      );
    }
  }

  bool canPurchaseUpgrade(String upgradeId) {
    final upgrade = player.upgrades[upgradeId];
    if (upgrade == null) return false;
    if (upgrade.isMaxLevel) return false;
    if (level.level < upgrade.requiredLevel) return false;
    return player.canAffordUpgrade(upgradeId);
  }

  bool purchaseUpgrade(String upgradeId) {
    if (!canPurchaseUpgrade(upgradeId)) return false;

    final upgrade = player.upgrades[upgradeId];
    if (upgrade == null) return false;

    final double cost = upgrade.getCost();
    final bool success = player.purchaseUpgrade(upgradeId);

    if (!success) {
      return false;
    }

    _applyUpgradeEffects();

    eventBus.emit(
      GameEvent(
        type: GameEventType.upgradePurchased,
        data: {
          'upgradesBought': 1,
          'moneySpent': cost,
          'upgradeLevel': upgrade.level,
          'upgradeId': upgradeId,
        },
      ),
    );

    return true;
  }

  bool buyAutoclipper() {
    return production.buyAutoclipperOfficial();
  }

  void producePaperclip() {
    production.producePaperclip();
  }

  void chooseProgressionPath(ProgressionPath path) {
    level.chooseProgressionPath(path);
  }

  void _applyUpgradeEffects() {
    if (player.upgrades['storage'] != null) {
      final storageLevel = player.upgrades['storage']!.level;
      final newCapacity = UpgradeEffectsCalculator.metalStorageCapacity(
        storageLevel: storageLevel,
      );
      player.updateMaxMetalStorage(newCapacity);
    }

    if (kDebugMode) {
      // no-op: keep method lightweight; debug hook reserved.
    }
  }
}
