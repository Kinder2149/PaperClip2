// lib/agents/production_optimizer_agent.dart

import 'package:flutter/foundation.dart';
import 'base_agent_executor.dart';
import '../models/agent.dart';
import '../models/game_state.dart';

/// Agent Production Optimizer
/// 
/// Applique un bonus passif de +25% à la vitesse de production des autoclippers.
/// Cet agent n'a pas d'action périodique, son effet est continu pendant qu'il est actif.
class ProductionOptimizerAgent implements BaseAgentExecutor {
  static const double PRODUCTION_BONUS = 0.25; // +25%
  
  @override
  bool execute(Agent agent, GameState gameState) {
    // Cet agent est passif, pas d'action périodique à exécuter
    // Le bonus est appliqué via AgentManager.getProductionSpeedBonus()
    if (kDebugMode) {
      print('[ProductionOptimizer] Bonus passif actif: +${(PRODUCTION_BONUS * 100).toInt()}%');
    }
    return true;
  }
  
  @override
  bool canExecute(Agent agent, GameState gameState) {
    // Toujours vrai car c'est un bonus passif
    return agent.isActive;
  }
  
  @override
  String getActionDescription(Agent agent) {
    return 'Bonus production +${(PRODUCTION_BONUS * 100).toInt()}% actif';
  }
}
