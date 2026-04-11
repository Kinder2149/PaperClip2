// lib/agents/market_analyst_agent.dart

import 'package:flutter/foundation.dart';
import 'base_agent_executor.dart';
import '../models/agent.dart';
import '../models/game_state.dart';
import '../constants/game_config.dart';

/// Agent Market Analyst
///
/// Ajuste automatiquement le prix de vente pour maximiser le revenu par seconde.
/// Stratégie : tester 3 scénarios (stable / +3% / -3%) et appliquer la direction
/// la plus rentable, en tenant compte du prix concurrent et de la demande mondiale.
///
/// Activé : toutes les 5 minutes.
class MarketAnalystAgent implements BaseAgentExecutor {
  static const double PRICE_STEP = 0.03; // ±3% par cycle d'ajustement

  @override
  bool execute(Agent agent, GameState gameState) {
    if (!canExecute(agent, gameState)) return false;

    final market = gameState.market;
    final player = gameState.player;

    final currentPrice = player.sellPrice;
    final marketingLevel = player.getMarketingLevel();
    final competitorPrice = market.competitorPrice;

    // Calcul du revenu simulé pour 3 scénarios de prix
    final revStable = _simulateRevenue(currentPrice, marketingLevel, market);
    final revUp = _simulateRevenue(currentPrice * (1 + PRICE_STEP), marketingLevel, market);
    final revDown = _simulateRevenue(currentPrice * (1 - PRICE_STEP), marketingLevel, market);

    double newPrice = currentPrice;
    String action = 'stable';

    if (revUp > revStable && revUp >= revDown) {
      // Hausse de prix plus rentable
      newPrice = (currentPrice * (1 + PRICE_STEP))
          .clamp(GameConstants.MIN_PRICE, GameConstants.MAX_PRICE);
      action = 'hausse';
    } else if (revDown > revStable && revDown > revUp) {
      // Baisse de prix plus rentable
      newPrice = (currentPrice * (1 - PRICE_STEP))
          .clamp(GameConstants.MIN_PRICE, GameConstants.MAX_PRICE);
      action = 'baisse';
    }

    if (newPrice != currentPrice) {
      player.setSellPrice(newPrice);

      if (kDebugMode) {
        print('[MarketAnalyst] Ajustement: $action'
            ' | Prix: ${currentPrice.toStringAsFixed(3)}€ → ${newPrice.toStringAsFixed(3)}€'
            ' | Concurrent: ${competitorPrice.toStringAsFixed(3)}€'
            ' | Rev/s stable: ${revStable.toStringAsFixed(2)}'
            ' | +3%: ${revUp.toStringAsFixed(2)}'
            ' | -3%: ${revDown.toStringAsFixed(2)}');
      }
      return true;
    }

    if (kDebugMode) {
      print('[MarketAnalyst] Prix optimal conservé: ${currentPrice.toStringAsFixed(3)}€'
          ' | Concurrent: ${competitorPrice.toStringAsFixed(3)}€');
    }
    return true;
  }

  /// Calcule le revenu par seconde simulé pour un prix donné
  double _simulateRevenue(double price, int marketingLevel, dynamic market) {
    final clampedPrice = price.clamp(GameConstants.MIN_PRICE, GameConstants.MAX_PRICE);
    final demand = market.calculateDemand(clampedPrice, marketingLevel);
    return clampedPrice * demand;
  }

  @override
  bool canExecute(Agent agent, GameState gameState) => agent.isActive;

  @override
  String getActionDescription(Agent agent) =>
      'Analyse marché mondial et optimisation du prix de vente';
}
