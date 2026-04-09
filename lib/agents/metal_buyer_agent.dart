// lib/agents/metal_buyer_agent.dart

import 'package:flutter/foundation.dart';
import 'base_agent_executor.dart';
import '../models/agent.dart';
import '../models/game_state.dart';

/// Agent Metal Buyer
/// 
/// Achète automatiquement du métal quand le stock est bas.
/// Action exécutée toutes les 10 minutes.
/// 
/// Conditions d'achat :
/// - Stock métal < 30% de la capacité
/// - Argent disponible > 100€
/// - Prix métal < 0.40€
class MetalBuyerAgent implements BaseAgentExecutor {
  static const double STOCK_THRESHOLD = 0.30; // 30% capacité
  static const double MIN_MONEY = 100.0; // 100€
  static const double MAX_METAL_PRICE = 0.40; // 0.40€
  
  @override
  bool execute(Agent agent, GameState gameState) {
    if (!canExecute(agent, gameState)) {
      if (kDebugMode) {
        print('[MetalBuyer] Conditions non remplies pour achat');
      }
      return false;
    }
    
    final resourceManager = gameState.resources;
    final purchased = resourceManager.purchaseMetal();
    
    if (purchased) {
      if (kDebugMode) {
        print('[MetalBuyer] Achat métal effectué');
        print('[MetalBuyer] Stock: ${resourceManager.metal.toStringAsFixed(0)}/${resourceManager.maxStorageCapacity.toStringAsFixed(0)}');
      }
      return true;
    }
    
    if (kDebugMode) {
      print('[MetalBuyer] Échec achat métal');
    }
    
    return false;
  }
  
  @override
  bool canExecute(Agent agent, GameState gameState) {
    if (!agent.isActive) return false;
    
    final resourceManager = gameState.resources;
    final playerManager = gameState.player;
    final marketManager = gameState.market;
    
    // Vérifier stock < 30%
    final stockRatio = resourceManager.metal / resourceManager.maxStorageCapacity;
    if (stockRatio >= STOCK_THRESHOLD) {
      if (kDebugMode) {
        print('[MetalBuyer] Stock suffisant: ${(stockRatio * 100).toStringAsFixed(0)}%');
      }
      return false;
    }
    
    // Vérifier argent > 100€
    if (playerManager.money < MIN_MONEY) {
      if (kDebugMode) {
        print('[MetalBuyer] Argent insuffisant: ${playerManager.money.toStringAsFixed(2)}€');
      }
      return false;
    }
    
    // Vérifier prix métal < 0.40€
    final metalPrice = marketManager.marketMetalPrice;
    if (metalPrice >= MAX_METAL_PRICE) {
      if (kDebugMode) {
        print('[MetalBuyer] Prix métal trop élevé: ${metalPrice.toStringAsFixed(2)}€');
      }
      return false;
    }
    
    return true;
  }
  
  @override
  String getActionDescription(Agent agent) {
    return 'Achat automatique de métal si stock < 30%';
  }
}
