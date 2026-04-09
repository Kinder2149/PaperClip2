// lib/agents/innovation_researcher_agent.dart

import 'package:flutter/foundation.dart';
import 'base_agent_executor.dart';
import '../models/agent.dart';
import '../models/game_state.dart';

/// Agent Innovation Researcher
/// 
/// Génère automatiquement des Points Innovation.
/// Action exécutée toutes les 10 minutes.
/// 
/// Effet : +1 Point Innovation par action
class InnovationResearcherAgent implements BaseAgentExecutor {
  static const int INNOVATION_POINTS_PER_ACTION = 1;
  
  @override
  bool execute(Agent agent, GameState gameState) {
    if (!canExecute(agent, gameState)) {
      return false;
    }
    
    gameState.rareResources.addPointsInnovation(
      INNOVATION_POINTS_PER_ACTION,
      source: 'Innovation Researcher Agent',
    );
    
    if (kDebugMode) {
      print('[InnovationResearcher] +$INNOVATION_POINTS_PER_ACTION PI généré');
      print('[InnovationResearcher] Total PI: ${gameState.pointsInnovation}');
    }
    
    return true;
  }
  
  @override
  bool canExecute(Agent agent, GameState gameState) {
    return agent.isActive;
  }
  
  @override
  String getActionDescription(Agent agent) {
    return 'Génération de +$INNOVATION_POINTS_PER_ACTION Point Innovation';
  }
}
