// lib/agents/quantum_researcher_agent.dart

import 'package:flutter/foundation.dart';
import 'base_agent_executor.dart';
import '../models/agent.dart';
import '../models/game_state.dart';

/// Agent Quantum Researcher
/// 
/// Génère automatiquement du Quantum.
/// Action exécutée toutes les 15 minutes.
/// 
/// Effet : +1 Quantum par action
class QuantumResearcherAgent implements BaseAgentExecutor {
  static const int QUANTUM_PER_ACTION = 1;
  
  @override
  bool execute(Agent agent, GameState gameState) {
    if (!canExecute(agent, gameState)) {
      return false;
    }
    
    gameState.rareResources.addQuantum(
      QUANTUM_PER_ACTION,
      source: 'Quantum Researcher Agent',
    );
    
    if (kDebugMode) {
      print('[QuantumResearcher] +$QUANTUM_PER_ACTION Quantum généré');
      print('[QuantumResearcher] Total Quantum: ${gameState.rareResources.quantum}');
    }
    
    return true;
  }
  
  @override
  bool canExecute(Agent agent, GameState gameState) {
    return agent.isActive;
  }
  
  @override
  String getActionDescription(Agent agent) {
    return 'Génération de +$QUANTUM_PER_ACTION Quantum';
  }
}
