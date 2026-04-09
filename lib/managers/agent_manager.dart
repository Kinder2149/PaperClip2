// lib/managers/agent_manager.dart

import 'package:flutter/foundation.dart';
import '../models/agent.dart';
import '../managers/rare_resources_manager.dart';
import '../managers/research_manager.dart';
import '../managers/player_manager.dart';
import '../managers/market_manager.dart';
import '../managers/resource_manager.dart';
import '../agents/production_optimizer_agent.dart';
import '../agents/market_analyst_agent.dart';
import '../agents/metal_buyer_agent.dart';
import '../agents/innovation_researcher_agent.dart';
import '../agents/quantum_researcher_agent.dart';
import '../agents/base_agent_executor.dart';

/// Manager pour les agents IA autonomes
/// 
/// Gère l'activation, la désactivation et l'exécution des agents.
/// Les agents sont débloqués via ResearchManager et consomment du Quantum.
class AgentManager extends ChangeNotifier {
  final RareResourcesManager _rareResourcesManager;
  final ResearchManager _researchManager;
  final PlayerManager _playerManager;
  final MarketManager _marketManager;
  final ResourceManager _resourceManager;
  
  // Tous les agents disponibles
  final Map<String, Agent> _agents = {};
  
  // Exécuteurs d'actions agents
  late final Map<String, BaseAgentExecutor> _executors;
  
  // Nombre maximum de slots actifs (2 de base, extensible à 4)
  int _maxSlots = 2;
  
  AgentManager(
    this._rareResourcesManager,
    this._researchManager,
    this._playerManager,
    this._marketManager,
    this._resourceManager,
  ) {
    _initializeAgents();
    _initializeExecutors();
  }
  
  /// Initialise les exécuteurs d'actions pour chaque agent
  void _initializeExecutors() {
    _executors = {
      'production_optimizer': ProductionOptimizerAgent(),
      'market_analyst': MarketAnalystAgent(),
      'metal_buyer': MetalBuyerAgent(),
      'innovation_researcher': InnovationResearcherAgent(),
      'quantum_researcher': QuantumResearcherAgent(),
    };
  }
  
  /// Initialise les 4 agents du jeu
  void _initializeAgents() {
    _agents['production_optimizer'] = Agent(
      id: 'production_optimizer',
      name: 'Production Optimizer',
      description: '+25% vitesse autoclippers pendant 1h',
      type: AgentType.PRODUCTION,
      activationCost: 5,
      actionIntervalMinutes: 0, // Bonus passif continu
    );
    
    _agents['market_analyst'] = Agent(
      id: 'market_analyst',
      name: 'Market Analyst',
      description: 'Ajuste prix automatiquement selon demande',
      type: AgentType.MARKET,
      activationCost: 5,
      actionIntervalMinutes: 5,
    );
    
    _agents['metal_buyer'] = Agent(
      id: 'metal_buyer',
      name: 'Metal Buyer',
      description: 'Achète métal quand stock bas',
      type: AgentType.RESOURCE,
      activationCost: 5,
      actionIntervalMinutes: 10,
    );
    
    _agents['innovation_researcher'] = Agent(
      id: 'innovation_researcher',
      name: 'Innovation Researcher',
      description: '+1 PI toutes les 10 min',
      type: AgentType.INNOVATION,
      activationCost: 5,
      actionIntervalMinutes: 10,
    );
    
    _agents['quantum_researcher'] = Agent(
      id: 'quantum_researcher',
      name: 'Quantum Researcher',
      description: '+1 Quantum toutes les 15 min',
      type: AgentType.INNOVATION,
      activationCost: 5,
      actionIntervalMinutes: 15,
    );
  }
  
  // ============================================================================
  // Getters
  // ============================================================================
  
  /// Tous les agents
  List<Agent> get allAgents => _agents.values.toList();
  
  /// Agents actuellement actifs
  List<Agent> get activeAgents => 
      _agents.values.where((a) => a.isActive).toList();
  
  /// Nombre d'agents actifs
  int get activeCount => activeAgents.length;
  
  /// Nombre maximum de slots
  int get maxSlots => _maxSlots;
  
  /// Slots disponibles
  int get availableSlots => _maxSlots - activeCount;
  
  /// Récupère un agent par ID
  Agent? getAgent(String agentId) => _agents[agentId];
  
  // ============================================================================
  // Synchronisation avec ResearchManager
  // ============================================================================
  
  /// Synchronise les déblocages avec l'arbre de recherche
  void syncWithResearch() {
    for (var agent in _agents.values) {
      final agentId = agent.id;
      final isResearched = _researchManager.isAgentUnlocked(agentId);
      
      if (isResearched && agent.status == AgentStatus.LOCKED) {
        agent.status = AgentStatus.UNLOCKED;
        if (kDebugMode) {
          print('[AgentManager] Agent unlocked: ${agent.name}');
        }
      }
    }
    
    // Débloquer slots selon recherche
    int newMaxSlots = 2; // Base
    
    try {
      final slot3Node = _researchManager.allNodes.firstWhere(
        (n) => n.id == 'agent_slot_3',
      );
      if (slot3Node.isResearched) {
        newMaxSlots = 3;
      }
      
      final slot4Node = _researchManager.allNodes.firstWhere(
        (n) => n.id == 'agent_slot_4',
      );
      if (slot4Node.isResearched) {
        newMaxSlots = 4;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AgentManager] Research nodes not found yet: $e');
      }
      // Garder newMaxSlots = 2 par défaut
    }
    
    if (newMaxSlots != _maxSlots) {
      _maxSlots = newMaxSlots;
      if (kDebugMode) {
        print('[AgentManager] Max slots updated: $_maxSlots');
      }
    }
    
    notifyListeners();
  }
  
  // ============================================================================
  // Activation / Désactivation
  // ============================================================================
  
  /// Active un agent pour 1 heure
  bool activateAgent(String agentId) {
    final agent = _agents[agentId];
    if (agent == null) {
      if (kDebugMode) {
        print('[AgentManager] Agent not found: $agentId');
      }
      return false;
    }
    
    // Vérifications
    if (agent.status != AgentStatus.UNLOCKED) {
      if (kDebugMode) {
        print('[AgentManager] Agent not unlocked: ${agent.name}');
      }
      return false;
    }
    
    if (activeCount >= _maxSlots) {
      if (kDebugMode) {
        print('[AgentManager] No available slots ($activeCount/$_maxSlots)');
      }
      return false;
    }
    
    // Vérifier et dépenser Quantum
    if (!_rareResourcesManager.spendQuantum(
      agent.activationCost,
      purpose: 'Activate ${agent.name}',
    )) {
      if (kDebugMode) {
        print('[AgentManager] Insufficient Quantum for ${agent.name}');
      }
      return false;
    }
    
    // Activer pour 1 heure
    final now = DateTime.now();
    agent.status = AgentStatus.ACTIVE;
    agent.activatedAt = now;
    agent.expiresAt = now.add(const Duration(hours: 1));
    agent.lastActionAt = now;
    
    if (kDebugMode) {
      print('[AgentManager] Agent activated: ${agent.name} until ${agent.expiresAt}');
    }
    
    notifyListeners();
    return true;
  }
  
  /// Désactive un agent (manuel ou automatique)
  void deactivateAgent(String agentId) {
    final agent = _agents[agentId];
    if (agent == null) return;
    
    if (agent.status == AgentStatus.ACTIVE) {
      agent.status = AgentStatus.UNLOCKED;
      agent.activatedAt = null;
      agent.expiresAt = null;
      
      if (kDebugMode) {
        print('[AgentManager] Agent deactivated: ${agent.name}');
      }
      
      notifyListeners();
    }
  }
  
  // ============================================================================
  // Tick (appelé par GameEngine)
  // ============================================================================
  
  /// Vérifie et exécute les agents actifs
  /// 
  /// Appelé à chaque tick du GameEngine pour :
  /// - Vérifier les expirations
  /// - Exécuter les actions périodiques
  /// 
  /// Note: gameState est optionnel pour compatibilité, mais nécessaire pour actions réelles
  void tick(double elapsedSeconds, {dynamic gameState}) {
    final now = DateTime.now();
    bool hasChanges = false;
    
    for (var agent in activeAgents.toList()) {
      // Vérifier expiration
      if (agent.expiresAt != null && now.isAfter(agent.expiresAt!)) {
        deactivateAgent(agent.id);
        hasChanges = true;
        continue;
      }
      
      // Vérifier si action nécessaire (sauf agents passifs)
      if (agent.actionIntervalMinutes > 0) {
        final timeSinceLastAction = agent.lastActionAt != null
            ? now.difference(agent.lastActionAt!)
            : const Duration(hours: 1);
        
        if (timeSinceLastAction.inMinutes >= agent.actionIntervalMinutes) {
          if (gameState != null) {
            executeAgentActionWithGameState(agent, gameState);
          } else {
            _executeAgentAction(agent);
          }
          agent.lastActionAt = now;
          agent.totalActions++;
          hasChanges = true;
        }
      }
    }
    
    if (hasChanges) {
      notifyListeners();
    }
  }
  
  /// Exécute l'action d'un agent
  void _executeAgentAction(Agent agent) {
    final executor = _executors[agent.id];
    if (executor == null) {
      if (kDebugMode) {
        print('[AgentManager] No executor found for ${agent.id}');
      }
      return;
    }
    
    // Créer un GameState temporaire pour passer aux exécuteurs
    // Note: Cette approche sera améliorée lors de l'intégration GameState (Jour 3)
    // Pour l'instant, on ne peut pas exécuter les actions sans GameState
    if (kDebugMode) {
      print('[AgentManager] Action ${agent.name} nécessite GameState (intégration Jour 3)');
    }
  }
  
  /// Exécute l'action d'un agent avec GameState
  /// 
  /// Méthode publique appelée par GameEngine.tick() avec accès au GameState
  void executeAgentActionWithGameState(Agent agent, dynamic gameState) {
    final executor = _executors[agent.id];
    if (executor == null) {
      if (kDebugMode) {
        print('[AgentManager] No executor found for ${agent.id}');
      }
      return;
    }
    
    try {
      final success = executor.execute(agent, gameState);
      if (success && kDebugMode) {
        print('[AgentManager] ${agent.name}: ${executor.getActionDescription(agent)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AgentManager] Error executing ${agent.name}: $e');
      }
    }
  }
  
  // ============================================================================
  // Bonus et getters pour intégration
  // ============================================================================
  
  /// Retourne le bonus de vitesse de production (Production Optimizer)
  double getProductionSpeedBonus() {
    final agent = _agents['production_optimizer'];
    if (agent != null && agent.isActive) {
      return ProductionOptimizerAgent.PRODUCTION_BONUS;
    }
    return 0.0;
  }
  
  /// Vérifie si un agent spécifique est actif
  bool hasActiveAgent(String agentId) {
    final agent = _agents[agentId];
    return agent != null && agent.isActive;
  }
  
  // ============================================================================
  // Persistance
  // ============================================================================
  
  /// Sérialise l'état du manager en JSON
  Map<String, dynamic> toJson() => {
    'maxSlots': _maxSlots,
    'agents': _agents.map((id, agent) => MapEntry(id, agent.toJson())),
  };
  
  /// Restaure l'état depuis JSON
  void fromJson(Map<String, dynamic> json) {
    _maxSlots = json['maxSlots'] ?? 2;
    
    final agentsData = json['agents'] as Map<String, dynamic>?;
    if (agentsData != null) {
      agentsData.forEach((id, data) {
        final agent = _agents[id];
        if (agent != null) {
          agent.fromJson(data as Map<String, dynamic>);
        }
      });
    }
    
    notifyListeners();
  }
  
  /// Réinitialise tous les agents (pour reset progression)
  void reset() {
    for (var agent in _agents.values) {
      if (agent.status == AgentStatus.ACTIVE) {
        agent.status = AgentStatus.UNLOCKED;
      }
      agent.activatedAt = null;
      agent.expiresAt = null;
      agent.lastActionAt = null;
      // totalActions conservé pour statistiques lifetime
    }
    
    notifyListeners();
  }
  
  /// Désactive tous les agents (alias pour reset progression)
  void deactivateAll() {
    resetForProgression();
  }
  
  /// Reset pour progression (prestige)
  /// 
  /// Désactive tous les agents mais conserve les déblocages et slots
  void resetForProgression() {
    for (var agent in _agents.values) {
      // Désactiver tous les agents actifs
      if (agent.status == AgentStatus.ACTIVE) {
        agent.status = AgentStatus.UNLOCKED;
      }
      
      // Reset états temporaires
      agent.activatedAt = null;
      agent.expiresAt = null;
      agent.lastActionAt = null;
      
      // Conserver : status (LOCKED/UNLOCKED), totalActions (lifetime)
    }
    
    notifyListeners();
  }
}
