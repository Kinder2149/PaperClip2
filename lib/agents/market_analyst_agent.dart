// lib/agents/market_analyst_agent.dart

import 'package:flutter/foundation.dart';
import 'base_agent_executor.dart';
import '../models/agent.dart';
import '../models/game_state.dart';

/// Agent Market Analyst
/// 
/// Ajuste automatiquement le prix de vente selon la demande du marché.
/// Action exécutée toutes les 5 minutes.
/// 
/// Logique :
/// - Demande > 15 → Prix +3%
/// - Demande < 6 → Prix -3%
/// - Sinon → Prix stable
class MarketAnalystAgent implements BaseAgentExecutor {
  static const double PRICE_ADJUSTMENT = 0.03; // ±3%
  static const double HIGH_DEMAND_THRESHOLD = 15.0;
  static const double LOW_DEMAND_THRESHOLD = 6.0;
  
  @override
  bool execute(Agent agent, GameState gameState) {
    if (!canExecute(agent, gameState)) {
      return false;
    }
    
    final currentPrice = gameState.player.sellPrice;
    final marketingLevel = gameState.player.getMarketingLevel();
    final currentDemand = gameState.market.calculateDemand(currentPrice, marketingLevel);
    double newPrice = currentPrice;
    String action = 'stable';
    
    if (currentDemand > HIGH_DEMAND_THRESHOLD) {
      // Demande élevée → Augmenter prix
      newPrice = currentPrice * (1.0 + PRICE_ADJUSTMENT);
      action = 'augmentation';
    } else if (currentDemand < LOW_DEMAND_THRESHOLD) {
      // Demande faible → Baisser prix
      newPrice = currentPrice * (1.0 - PRICE_ADJUSTMENT);
      action = 'baisse';
    }
    
    if (newPrice != currentPrice) {
      gameState.player.setSellPrice(newPrice);
      
      if (kDebugMode) {
        print('[MarketAnalyst] Ajustement prix: $action (demande: ${currentDemand.toStringAsFixed(1)})');
        print('[MarketAnalyst] Prix: ${currentPrice.toStringAsFixed(2)}€ → ${newPrice.toStringAsFixed(2)}€');
      }
      
      return true;
    }
    
    if (kDebugMode) {
      print('[MarketAnalyst] Prix stable (demande: ${currentDemand.toStringAsFixed(1)})');
    }
    
    return true;
  }
  
  @override
  bool canExecute(Agent agent, GameState gameState) {
    return agent.isActive;
  }
  
  @override
  String getActionDescription(Agent agent) {
    return 'Analyse du marché et ajustement des prix';
  }
}
