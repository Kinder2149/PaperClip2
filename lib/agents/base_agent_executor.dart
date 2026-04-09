// lib/agents/base_agent_executor.dart

import '../models/agent.dart';
import '../models/game_state.dart';

/// Interface commune pour l'exécution des actions des agents
/// 
/// Chaque agent spécialisé implémente cette interface pour définir
/// sa logique métier spécifique.
abstract class BaseAgentExecutor {
  /// Exécute l'action de l'agent
  /// 
  /// Retourne true si l'action a été exécutée avec succès, false sinon.
  /// Les agents peuvent échouer si les conditions ne sont pas remplies
  /// (ex: pas assez d'argent, stock plein, etc.)
  bool execute(Agent agent, GameState gameState);
  
  /// Vérifie si l'agent peut exécuter son action
  /// 
  /// Permet de valider les conditions avant l'exécution.
  bool canExecute(Agent agent, GameState gameState);
  
  /// Description de l'action pour logs et debug
  String getActionDescription(Agent agent);
}
