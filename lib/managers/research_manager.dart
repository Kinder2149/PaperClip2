// lib/managers/research_manager.dart
import 'package:flutter/foundation.dart';
import '../models/research_node.dart';
import '../managers/rare_resources_manager.dart';
import '../managers/player_manager.dart';
import '../models/progression_system.dart';
import '../constants/game_config.dart';

/// Manager pour l'arbre de recherche
/// 
/// Gère les recherches technologiques achetées avec Points Innovation.
/// Remplace le système d'upgrades (€) par un arbre avec choix exclusifs.
class ResearchManager extends ChangeNotifier {
  final RareResourcesManager _rareResourcesManager;
  final PlayerManager _playerManager;
  LevelSystem? _levelSystem;
  
  // Tous les nœuds de recherche
  final Map<String, ResearchNode> _nodes = {};
  
  // Nœuds recherchés (IDs)
  final List<String> _researchedIds = [];
  
  ResearchManager(this._rareResourcesManager, this._playerManager) {
    _initializeResearchTree();
  }
  
  /// Configure le LevelSystem pour les gains XP
  void setLevelSystem(LevelSystem levelSystem) {
    _levelSystem = levelSystem;
  }
  
  void _initializeResearchTree() {
    // ROOT
    _nodes['root'] = ResearchNode(
      id: 'root',
      name: 'Fondations',
      description: 'Point de départ de l\'arbre de recherche',
      category: ResearchCategory.META,
      innovationPointsCost: 0,
      effect: ResearchEffect(
        type: ResearchEffectType.UNLOCK_FEATURE,
        params: {'feature': 'research_tree'},
      ),
      isUnlocked: true,
      isResearched: true,
    );
    _researchedIds.add('root');
    
    // ========================================================================
    // BRANCHE PRODUCTION (8 nœuds)
    // ========================================================================
    
    // P1: Efficacité Métal I
    _nodes['prod_efficiency_1'] = ResearchNode(
      id: 'prod_efficiency_1',
      name: 'Efficacité Métal I',
      description: 'Réduit consommation métal de 10%',
      category: ResearchCategory.PRODUCTION,
      innovationPointsCost: 0,
      moneyCost: 500,
      prerequisites: ['root'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'metalEfficiency', 'value': 0.10},
      ),
    );
    
    // P2: Vitesse Production I
    _nodes['prod_speed_1'] = ResearchNode(
      id: 'prod_speed_1',
      name: 'Vitesse Production I',
      description: 'Augmente vitesse autoclippers de 15%',
      category: ResearchCategory.PRODUCTION,
      innovationPointsCost: 0,
      moneyCost: 500,
      prerequisites: ['root'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'productionSpeed', 'value': 0.15},
      ),
    );
    
    // P3: Efficacité Métal II
    _nodes['prod_efficiency_2'] = ResearchNode(
      id: 'prod_efficiency_2',
      name: 'Efficacité Métal II',
      description: 'Réduit consommation métal de 20% supplémentaires',
      category: ResearchCategory.PRODUCTION,
      innovationPointsCost: 0,
      moneyCost: 1000,
      prerequisites: ['prod_efficiency_1'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'metalEfficiency', 'value': 0.20},
      ),
    );
    
    // P4: Vitesse Production II
    _nodes['prod_speed_2'] = ResearchNode(
      id: 'prod_speed_2',
      name: 'Vitesse Production II',
      description: 'Augmente vitesse autoclippers de 30% supplémentaires',
      category: ResearchCategory.PRODUCTION,
      innovationPointsCost: 0,
      moneyCost: 1000,
      prerequisites: ['prod_speed_1'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'productionSpeed', 'value': 0.30},
      ),
    );
    
    // P5: Production de Masse (EXCLUSIF avec P6)
    _nodes['prod_mass'] = ResearchNode(
      id: 'prod_mass',
      name: 'Production de Masse',
      description: '+30% production, -15% efficacité métal',
      category: ResearchCategory.PRODUCTION,
      innovationPointsCost: 0,
      moneyCost: 2500,
      prerequisites: ['prod_efficiency_2', 'prod_speed_2'],
      exclusiveWith: ['prod_precise'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {
          'bonuses': [
            {'stat': 'productionSpeed', 'value': 0.30},
            {'stat': 'metalEfficiency', 'value': -0.15},
          ],
        },
      ),
    );
    
    // P6: Production Précise (EXCLUSIF avec P5)
    _nodes['prod_precise'] = ResearchNode(
      id: 'prod_precise',
      name: 'Production Précise',
      description: '+20% efficacité métal, -10% vitesse',
      category: ResearchCategory.PRODUCTION,
      innovationPointsCost: 0,
      moneyCost: 2500,
      prerequisites: ['prod_efficiency_2', 'prod_speed_2'],
      exclusiveWith: ['prod_mass'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {
          'bonuses': [
            {'stat': 'metalEfficiency', 'value': 0.20},
            {'stat': 'productionSpeed', 'value': -0.10},
          ],
        },
      ),
    );
    
    // P7: Débloquer Agent Production
    _nodes['unlock_agent_production'] = ResearchNode(
      id: 'unlock_agent_production',
      name: 'Agent Production',
      description: 'Débloque l\'Optimiseur Production',
      category: ResearchCategory.AGENTS,
      innovationPointsCost: 40,
      prerequisites: ['prod_mass'], // OU prod_precise (géré dans canResearch)
      effect: ResearchEffect(
        type: ResearchEffectType.UNLOCK_AGENT,
        params: {'agentId': 'production_optimizer'},
      ),
    );
    
    // P8: Production Bulk
    _nodes['prod_bulk'] = ResearchNode(
      id: 'prod_bulk',
      name: 'Production en Masse',
      description: 'Augmente quantité produite de 35%',
      category: ResearchCategory.PRODUCTION,
      innovationPointsCost: 0,
      moneyCost: 1500,
      prerequisites: ['prod_speed_1'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'productionBulk', 'value': 0.35},
      ),
    );
    
    // ========================================================================
    // BRANCHE MARCHÉ (9 nœuds)
    // ========================================================================
    
    // M1: Marketing I
    _nodes['market_marketing_1'] = ResearchNode(
      id: 'market_marketing_1',
      name: 'Marketing I',
      description: '+15% demande marché',
      category: ResearchCategory.MARKET,
      innovationPointsCost: 0,
      moneyCost: 800,
      prerequisites: ['root'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'marketDemand', 'value': 0.15},
      ),
    );
    
    // M2: Qualité I
    _nodes['market_quality_1'] = ResearchNode(
      id: 'market_quality_1',
      name: 'Qualité I',
      description: '+10% prix vente effectif',
      category: ResearchCategory.MARKET,
      innovationPointsCost: 0,
      moneyCost: 800,
      prerequisites: ['root'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'salePrice', 'value': 0.10},
      ),
    );
    
    // M3: Marketing II
    _nodes['market_marketing_2'] = ResearchNode(
      id: 'market_marketing_2',
      name: 'Marketing II',
      description: '+30% demande marché supplémentaires',
      category: ResearchCategory.MARKET,
      innovationPointsCost: 0,
      moneyCost: 1200,
      prerequisites: ['market_marketing_1'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'marketDemand', 'value': 0.30},
      ),
    );
    
    // M4: Qualité II
    _nodes['market_quality_2'] = ResearchNode(
      id: 'market_quality_2',
      name: 'Qualité II',
      description: '+20% prix vente effectif supplémentaires',
      category: ResearchCategory.MARKET,
      innovationPointsCost: 0,
      moneyCost: 1200,
      prerequisites: ['market_quality_1'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'salePrice', 'value': 0.20},
      ),
    );
    
    // M5: Domination Marché (EXCLUSIF avec M6)
    _nodes['market_domination'] = ResearchNode(
      id: 'market_domination',
      name: 'Domination Marché',
      description: '+40% demande, augmente saturation marché (risque crises)',
      category: ResearchCategory.MARKET,
      innovationPointsCost: 0,
      moneyCost: 3000,
      prerequisites: ['market_marketing_2', 'market_quality_2'],
      exclusiveWith: ['market_niche'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {
          'bonuses': [
            {'stat': 'marketDemand', 'value': 0.40},
            {'stat': 'marketSaturation', 'value': 0.25},
          ],
        },
      ),
    );
    
    // M6: Marché de Niche (EXCLUSIF avec M5)
    _nodes['market_niche'] = ResearchNode(
      id: 'market_niche',
      name: 'Marché de Niche',
      description: '+60% plafond prix de vente, -35% demande',
      category: ResearchCategory.MARKET,
      innovationPointsCost: 0,
      moneyCost: 3000,
      prerequisites: ['market_marketing_2', 'market_quality_2'],
      exclusiveWith: ['market_domination'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {
          'bonuses': [
            {'stat': 'maxSalePrice', 'value': 0.60},
            {'stat': 'marketDemand', 'value': -0.35},
          ],
        },
      ),
    );
    
    // M7: Débloquer Agent Marché
    _nodes['unlock_agent_market'] = ResearchNode(
      id: 'unlock_agent_market',
      name: 'Agent Marché',
      description: 'Débloque le Gestionnaire Marché',
      category: ResearchCategory.AGENTS,
      innovationPointsCost: 30,
      prerequisites: ['market_domination'], // OU market_niche
      effect: ResearchEffect(
        type: ResearchEffectType.UNLOCK_AGENT,
        params: {'agentId': 'market_manager'},
      ),
    );
    
    // M8: Étude de Marché
    _nodes['market_research'] = ResearchNode(
      id: 'market_research',
      name: 'Étude de Marché',
      description: 'Réduit volatilité du marché de 20%',
      category: ResearchCategory.MARKET,
      innovationPointsCost: 0,
      moneyCost: 1500,
      prerequisites: ['market_marketing_1'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'volatilityReduction', 'value': 0.20},
      ),
    );
    
    // M9: Négociation - SUPPRIMÉ (doublon avec R2/R4 Approvisionnement)
    
    // ========================================================================
    // BRANCHE RESSOURCES (6 nœuds)
    // ========================================================================
    
    // R1: Stockage I
    _nodes['resource_storage_1'] = ResearchNode(
      id: 'resource_storage_1',
      name: 'Stockage I',
      description: '+50% capacité métal',
      category: ResearchCategory.RESOURCES,
      innovationPointsCost: 0,
      moneyCost: 600,
      prerequisites: ['root'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'metalStorage', 'value': 0.50},
      ),
    );
    
    // R2: Approvisionnement I
    _nodes['resource_procurement_1'] = ResearchNode(
      id: 'resource_procurement_1',
      name: 'Approvisionnement I',
      description: 'Réduit prix achat métal de 10%',
      category: ResearchCategory.RESOURCES,
      innovationPointsCost: 0,
      moneyCost: 1000,
      prerequisites: ['root'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'metalPurchaseDiscount', 'value': 0.10},
      ),
    );
    
    // R3: Stockage II
    _nodes['resource_storage_2'] = ResearchNode(
      id: 'resource_storage_2',
      name: 'Stockage II',
      description: '+100% capacité métal supplémentaires',
      category: ResearchCategory.RESOURCES,
      innovationPointsCost: 0,
      moneyCost: 1500,
      prerequisites: ['resource_storage_1'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'metalStorage', 'value': 1.00},
      ),
    );
    
    // R4: Approvisionnement II
    _nodes['resource_procurement_2'] = ResearchNode(
      id: 'resource_procurement_2',
      name: 'Approvisionnement II',
      description: 'Réduit prix achat métal de 20% supplémentaires',
      category: ResearchCategory.RESOURCES,
      innovationPointsCost: 0,
      moneyCost: 1500,
      prerequisites: ['resource_procurement_1'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'metalPurchaseDiscount', 'value': 0.20},
      ),
    );
    
    // R5: Débloquer Agent Métal
    _nodes['unlock_agent_metal'] = ResearchNode(
      id: 'unlock_agent_metal',
      name: 'Agent Métal',
      description: 'Débloque l\'Acheteur Métal',
      category: ResearchCategory.AGENTS,
      innovationPointsCost: 35,
      prerequisites: ['resource_storage_2', 'resource_procurement_2'],
      effect: ResearchEffect(
        type: ResearchEffectType.UNLOCK_AGENT,
        params: {'agentId': 'metal_buyer'},
      ),
    );
    
    // R6: Automatisation Achat
    _nodes['resource_auto_buy'] = ResearchNode(
      id: 'resource_auto_buy',
      name: 'Automatisation Achat',
      description: 'Active l\'achat automatique de métal',
      category: ResearchCategory.RESOURCES,
      innovationPointsCost: 0,
      moneyCost: 2000,
      prerequisites: ['unlock_agent_metal'],
      effect: ResearchEffect(
        type: ResearchEffectType.UNLOCK_FEATURE,
        params: {'feature': 'auto_metal_purchase'},
      ),
    );
    
    // ========================================================================
    // BRANCHE AGENTS (5 nœuds)
    // ========================================================================
    
    // A1: Expansion RH I
    _nodes['agent_slot_2'] = ResearchNode(
      id: 'agent_slot_2',
      name: 'Expansion RH I',
      description: 'Débloque 2ème slot agent',
      category: ResearchCategory.META,
      innovationPointsCost: 0,
      moneyCost: 1500,
      prerequisites: ['root'],
      effect: ResearchEffect(
        type: ResearchEffectType.UNLOCK_SLOT,
        params: {'slotNumber': 2},
      ),
    );
    
    // A2: Expansion RH II
    _nodes['agent_slot_3'] = ResearchNode(
      id: 'agent_slot_3',
      name: 'Expansion RH II',
      description: 'Débloque 3ème slot agent',
      category: ResearchCategory.META,
      innovationPointsCost: 0,
      moneyCost: 3500,
      prerequisites: ['agent_slot_2'],
      effect: ResearchEffect(
        type: ResearchEffectType.UNLOCK_SLOT,
        params: {'slotNumber': 3},
      ),
    );
    
    // A3: Formation Agents I
    _nodes['agent_training_1'] = ResearchNode(
      id: 'agent_training_1',
      name: 'Formation Agents I',
      description: '+15% efficacité de tous les agents',
      category: ResearchCategory.AGENTS,
      innovationPointsCost: 20,
      prerequisites: ['agent_slot_2'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'agentEfficiency', 'value': 0.15},
      ),
    );
    
    // A4: Formation Agents II
    _nodes['agent_training_2'] = ResearchNode(
      id: 'agent_training_2',
      name: 'Formation Agents II',
      description: '+30% efficacité de tous les agents supplémentaires',
      category: ResearchCategory.AGENTS,
      innovationPointsCost: 25,
      prerequisites: ['agent_training_1'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'agentEfficiency', 'value': 0.30},
      ),
    );
    
    // A5: Expansion RH III
    _nodes['agent_slot_4'] = ResearchNode(
      id: 'agent_slot_4',
      name: 'Expansion RH III',
      description: 'Débloque 4ème slot agent',
      category: ResearchCategory.META,
      innovationPointsCost: 0,
      moneyCost: 5000,
      prerequisites: ['agent_slot_3'],
      effect: ResearchEffect(
        type: ResearchEffectType.UNLOCK_SLOT,
        params: {'slotNumber': 4},
      ),
    );
    
    // A6: Débloquer Agent Innovation
    _nodes['unlock_agent_innovation'] = ResearchNode(
      id: 'unlock_agent_innovation',
      name: 'Agent Innovation',
      description: 'Débloque le Chercheur Innovation',
      category: ResearchCategory.AGENTS,
      innovationPointsCost: 50,
      prerequisites: ['agent_slot_3'],
      effect: ResearchEffect(
        type: ResearchEffectType.UNLOCK_AGENT,
        params: {'agentId': 'innovation_researcher'},
      ),
    );
    
    // ========================================================================
    // BRANCHE MÉTA (7 nœuds)
    // ========================================================================
    
    // META1: Reset Optimisé I
    _nodes['reset_bonus_1'] = ResearchNode(
      id: 'reset_bonus_1',
      name: 'Reset Optimisé I',
      description: '+15% gains Quantum au reset',
      category: ResearchCategory.META,
      innovationPointsCost: 0,
      moneyCost: 3000,
      prerequisites: ['root'],
      effect: ResearchEffect(
        type: ResearchEffectType.MODIFY_RESET,
        params: {'quantumBonus': 0.15},
      ),
    );
    
    // META2: Reset Optimisé II
    _nodes['reset_bonus_2'] = ResearchNode(
      id: 'reset_bonus_2',
      name: 'Reset Optimisé II',
      description: '+30% gains Quantum au reset supplémentaires',
      category: ResearchCategory.META,
      innovationPointsCost: 0,
      moneyCost: 5000,
      prerequisites: ['reset_bonus_1'],
      effect: ResearchEffect(
        type: ResearchEffectType.MODIFY_RESET,
        params: {'quantumBonus': 0.30},
      ),
    );
    
    // META3: Innovation I
    _nodes['innovation_bonus_1'] = ResearchNode(
      id: 'innovation_bonus_1',
      name: 'Innovation I',
      description: '+10% Points Innovation au reset',
      category: ResearchCategory.META,
      innovationPointsCost: 0,
      moneyCost: 2000,
      prerequisites: ['root'],
      effect: ResearchEffect(
        type: ResearchEffectType.MODIFY_RESET,
        params: {'innovationBonus': 0.10},
      ),
    );
    
    // META4: Innovation II
    _nodes['innovation_bonus_2'] = ResearchNode(
      id: 'innovation_bonus_2',
      name: 'Innovation II',
      description: '+20% Points Innovation au reset supplémentaires',
      category: ResearchCategory.META,
      innovationPointsCost: 0,
      moneyCost: 3500,
      prerequisites: ['innovation_bonus_1'],
      effect: ResearchEffect(
        type: ResearchEffectType.MODIFY_RESET,
        params: {'innovationBonus': 0.20},
      ),
    );
    
    // META5: Autoclippers Avancés
    _nodes['autoclipper_discount'] = ResearchNode(
      id: 'autoclipper_discount',
      name: 'Autoclippers Avancés',
      description: 'Réduit coût autoclippers de 20%',
      category: ResearchCategory.META,
      innovationPointsCost: 0,
      moneyCost: 2500,
      prerequisites: ['root'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'autoclipperDiscount', 'value': 0.20},
      ),
    );
    
    // META6: Production Passive
    _nodes['offline_production'] = ResearchNode(
      id: 'offline_production',
      name: 'Production Passive',
      description: '+50% production autoclippers offline',
      category: ResearchCategory.META,
      innovationPointsCost: 0,
      moneyCost: 3000,
      prerequisites: ['autoclipper_discount'],
      effect: ResearchEffect(
        type: ResearchEffectType.PASSIVE_BONUS,
        params: {'stat': 'offlineProduction', 'value': 0.50},
      ),
    );
    
    // ========================================================================
    // CHANTIER-06 : Recherches META avancées (coût Quantum/PI)
    // ========================================================================
    
    // META7: Quantum Amplifier
    _nodes['quantum_amplifier'] = ResearchNode(
      id: 'quantum_amplifier',
      name: 'Quantum Amplifier',
      description: '+10% gains Quantum lors des resets',
      category: ResearchCategory.META,
      innovationPointsCost: 0,
      quantumCost: 5,
      prerequisites: ['root'],
      effect: ResearchEffect(
        type: ResearchEffectType.MODIFY_RESET,
        params: {'quantumBonus': 0.10},
      ),
    );
    
    // META8: Innovation Catalyst
    _nodes['innovation_catalyst'] = ResearchNode(
      id: 'innovation_catalyst',
      name: 'Innovation Catalyst',
      description: '+10% gains Points Innovation lors des resets',
      category: ResearchCategory.META,
      innovationPointsCost: 0,
      moneyCost: 500,
      prerequisites: ['root'],
      effect: ResearchEffect(
        type: ResearchEffectType.MODIFY_RESET,
        params: {'innovationBonus': 0.10},
      ),
    );
    
    // META9: Quantum Researcher (débloque agent)
    _nodes['meta_researcher'] = ResearchNode(
      id: 'meta_researcher',
      name: 'Quantum Researcher',
      description: 'Débloque l\'agent Quantum Researcher',
      category: ResearchCategory.META,
      innovationPointsCost: 0,
      moneyCost: 1000,
      quantumCost: 10,
      prerequisites: ['quantum_amplifier', 'innovation_catalyst'],
      effect: ResearchEffect(
        type: ResearchEffectType.UNLOCK_AGENT,
        params: {'agentId': 'quantum_researcher'},
      ),
    );
    
    // META10: Quantum Efficiency
    _nodes['quantum_efficiency'] = ResearchNode(
      id: 'quantum_efficiency',
      name: 'Quantum Efficiency',
      description: '+15% gains Quantum lors des resets',
      category: ResearchCategory.META,
      innovationPointsCost: 0,
      quantumCost: 15,
      prerequisites: ['quantum_amplifier'],
      effect: ResearchEffect(
        type: ResearchEffectType.MODIFY_RESET,
        params: {'quantumBonus': 0.15},
      ),
    );
    
    // META11: Innovation Mastery
    _nodes['innovation_mastery'] = ResearchNode(
      id: 'innovation_mastery',
      name: 'Innovation Mastery',
      description: '+15% gains Points Innovation lors des resets',
      category: ResearchCategory.META,
      innovationPointsCost: 0,
      moneyCost: 1500,
      prerequisites: ['innovation_catalyst'],
      effect: ResearchEffect(
        type: ResearchEffectType.MODIFY_RESET,
        params: {'innovationBonus': 0.15},
      ),
    );
    
    // Débloquer nœuds accessibles depuis ROOT
    _updateUnlockedNodes();
  }
  
  // Getters
  List<ResearchNode> get allNodes => _nodes.values.toList();
  List<ResearchNode> get researchedNodes => 
      _researchedIds.map((id) => _nodes[id]!).toList();
  List<ResearchNode> get availableNodes => 
      _nodes.values.where((n) => n.isAvailable).toList();
  int get completedResearchCount => _researchedIds.length;
  
  /// Vérifier si recherche possible
  bool canResearch(String nodeId) {
    final node = _nodes[nodeId];
    if (node == null || node.isResearched || !node.isUnlocked) return false;
    
    // Vérifier coût argent
    if (node.moneyCost > 0) {
      if (_playerManager.money < node.moneyCost) {
        return false;
      }
    }
    
    // Vérifier coût Points Innovation
    if (node.innovationPointsCost > 0) {
      if (_rareResourcesManager.pointsInnovation < node.innovationPointsCost) {
        return false;
      }
    }
    
    // Vérifier coût Quantum
    if (node.quantumCost > 0) {
      if (_rareResourcesManager.quantum < node.quantumCost) {
        return false;
      }
    }
    
    // Vérifier prérequis (au moins un doit être satisfait pour les OU)
    if (node.prerequisites.isNotEmpty) {
      // Cas spécial : unlock_agent_production nécessite prod_mass OU prod_precise
      if (nodeId == 'unlock_agent_production') {
        final hasMass = _researchedIds.contains('prod_mass');
        final hasPrecise = _researchedIds.contains('prod_precise');
        if (!hasMass && !hasPrecise) return false;
      }
      // Cas spécial : unlock_agent_market nécessite market_domination OU market_niche
      else if (nodeId == 'unlock_agent_market') {
        final hasDomination = _researchedIds.contains('market_domination');
        final hasNiche = _researchedIds.contains('market_niche');
        if (!hasDomination && !hasNiche) return false;
      }
      // Cas normal : tous les prérequis doivent être satisfaits
      else {
        for (var prereqId in node.prerequisites) {
          if (!_researchedIds.contains(prereqId)) {
            return false;
          }
        }
      }
    }
    
    // Vérifier exclusivités
    for (var exclusiveId in node.exclusiveWith) {
      if (_researchedIds.contains(exclusiveId)) {
        return false; // Un choix exclusif a déjà été fait
      }
    }
    
    return true;
  }
  
  /// Rechercher un nœud
  bool research(String nodeId) {
    if (!canResearch(nodeId)) return false;
    
    final node = _nodes[nodeId]!;
    
    // Dépenser argent si nécessaire
    if (node.moneyCost > 0) {
      if (!_playerManager.spendMoney(node.moneyCost.toDouble())) {
        return false;
      }
    }
    
    // Dépenser Points Innovation si nécessaire
    if (node.innovationPointsCost > 0) {
      if (!_rareResourcesManager.spendPointsInnovation(
        node.innovationPointsCost,
        purpose: 'Research ${node.name}',
      )) {
        return false;
      }
    }
    
    // Dépenser Quantum si nécessaire
    if (node.quantumCost > 0) {
      if (!_rareResourcesManager.spendQuantum(
        node.quantumCost,
        purpose: 'Research ${node.name}',
      )) {
        return false;
      }
    }
    
    // Marquer comme recherché
    node.isResearched = true;
    node.researchedAt = DateTime.now();
    _researchedIds.add(nodeId);
    
    // Appliquer effet
    _applyResearchEffect(node);
    
    // Gain XP basé sur le coût total de la recherche
    _grantResearchExperience(node);
    
    // Mettre à jour nœuds débloqués
    _updateUnlockedNodes();
    
    notifyListeners();
    return true;
  }
  
  /// Calcule et attribue l'XP pour une recherche achetée
  void _grantResearchExperience(ResearchNode node) {
    if (_levelSystem == null) return;
    
    // Calcul XP basé sur les coûts
    double xp = 0.0;
    
    // XP pour coût en argent (1€ = 0.5 XP)
    if (node.moneyCost > 0) {
      xp += node.moneyCost * 0.5;
    }
    
    // XP pour coût en Points Innovation (1 PI = 10 XP)
    if (node.innovationPointsCost > 0) {
      xp += node.innovationPointsCost * 10.0;
    }
    
    // XP pour coût en Quantum (1 Quantum = 15 XP)
    if (node.quantumCost > 0) {
      xp += node.quantumCost * 15.0;
    }
    
    // Minimum 5 XP par recherche
    if (xp < 5.0) xp = 5.0;
    
    _levelSystem!.addExperience(xp, ExperienceType.UPGRADE);
    
    if (kDebugMode) {
      print('[ResearchManager] Recherche "${node.name}" : +${xp.toStringAsFixed(1)} XP');
    }
  }
  
  void _applyResearchEffect(ResearchNode node) {
    switch (node.effect.type) {
      case ResearchEffectType.UNLOCK_AGENT:
        // CHANTIER-04 : Déblocage agents
        if (kDebugMode) {
          print('[ResearchManager] Agent unlocked: ${node.effect.params['agentId']}');
        }
        break;
        
      case ResearchEffectType.UNLOCK_SLOT:
        // CHANTIER-04 : Déblocage slots agents
        if (kDebugMode) {
          print('[ResearchManager] Slot unlocked: ${node.effect.params['slotNumber']}');
        }
        break;
        
      case ResearchEffectType.PASSIVE_BONUS:
        // Bonus appliqués via getters dans managers
        if (kDebugMode) {
          print('[ResearchManager] Passive bonus applied: ${node.effect.params}');
        }
        break;
        
      case ResearchEffectType.MODIFY_RESET:
        // CHANTIER-05 : Bonus appliqué dans WorldResetManager.calculateRewards()
        if (kDebugMode) {
          print('[ResearchManager] Reset modifier applied: ${node.effect.params}');
        }
        break;
        
      case ResearchEffectType.UNLOCK_FEATURE:
        // Feature flags
        if (kDebugMode) {
          print('[ResearchManager] Feature unlocked: ${node.effect.params['feature']}');
        }
        break;
    }
  }
  
  void _updateUnlockedNodes() {
    for (var node in _nodes.values) {
      if (node.isResearched) continue;
      
      // Vérifier si tous les prérequis sont recherchés
      bool allPrereqsMet = node.prerequisites.isEmpty || 
        node.prerequisites.every(
          (prereqId) => _researchedIds.contains(prereqId)
        );
      
      // Cas spéciaux pour les OU
      if (node.id == 'unlock_agent_production') {
        allPrereqsMet = _researchedIds.contains('prod_mass') || 
                       _researchedIds.contains('prod_precise');
      } else if (node.id == 'unlock_agent_market') {
        allPrereqsMet = _researchedIds.contains('market_domination') || 
                       _researchedIds.contains('market_niche');
      }
      
      // Vérifier qu'aucun exclusif n'est recherché
      bool noExclusiveResearched = !node.exclusiveWith.any(
        (exclusiveId) => _researchedIds.contains(exclusiveId)
      );
      
      node.isUnlocked = allPrereqsMet && noExclusiveResearched;
    }
  }
  
  /// Obtenir bonus total d'un stat
  double getResearchBonus(String stat) {
    double total = 0.0;
    
    for (var nodeId in _researchedIds) {
      final node = _nodes[nodeId]!;
      
      if (node.effect.type == ResearchEffectType.PASSIVE_BONUS) {
        // Bonus simple
        if (node.effect.params['stat'] == stat) {
          total += (node.effect.params['value'] as num).toDouble();
        }
        
        // Bonus multiples
        if (node.effect.params.containsKey('bonuses')) {
          final bonuses = node.effect.params['bonuses'] as List;
          for (var bonus in bonuses) {
            if (bonus['stat'] == stat) {
              total += (bonus['value'] as num).toDouble();
            }
          }
        }
      }
    }
    
    return total;
  }
  
  /// Obtenir bonus reset (Quantum ou Innovation)
  double getResetBonus(String type) {
    double total = 0.0;
    
    for (var nodeId in _researchedIds) {
      final node = _nodes[nodeId]!;
      
      if (node.effect.type == ResearchEffectType.MODIFY_RESET) {
        if (type == 'quantum' && node.effect.params.containsKey('quantumBonus')) {
          total += (node.effect.params['quantumBonus'] as num).toDouble();
        } else if (type == 'innovation' && node.effect.params.containsKey('innovationBonus')) {
          total += (node.effect.params['innovationBonus'] as num).toDouble();
        }
      }
    }
    
    return total;
  }
  
  /// Vérifier si un agent est débloqué
  bool isAgentUnlocked(String agentId) {
    for (var nodeId in _researchedIds) {
      final node = _nodes[nodeId]!;
      if (node.effect.type == ResearchEffectType.UNLOCK_AGENT &&
          node.effect.params['agentId'] == agentId) {
        return true;
      }
    }
    return false;
  }
  
  /// Vérifier si une feature est débloquée
  bool isFeatureUnlocked(String feature) {
    for (var nodeId in _researchedIds) {
      final node = _nodes[nodeId]!;
      if (node.effect.type == ResearchEffectType.UNLOCK_FEATURE &&
          node.effect.params['feature'] == feature) {
        return true;
      }
    }
    return false;
  }
  
  /// Reset pour progression : conserve uniquement les recherches META
  /// 
  /// CHANTIER-06 : Les recherches META sont conservées lors du reset progression
  /// car elles sont achetées avec Quantum/PI (ressources rares conservées)
  void resetForProgression() {
    if (kDebugMode) {
      print('[ResearchManager] Reset progression - Conservation recherches META');
    }
    
    // Sauvegarder les recherches META
    final metaResearchIds = <String>[];
    for (var nodeId in _researchedIds) {
      final node = _nodes[nodeId];
      if (node != null && node.category == ResearchCategory.META) {
        metaResearchIds.add(nodeId);
      }
    }
    
    // Réinitialiser tous les nœuds
    for (var node in _nodes.values) {
      if (node.id != 'root' && !metaResearchIds.contains(node.id)) {
        node.isResearched = false;
        node.researchedAt = null;
        node.isUnlocked = false;
      }
    }
    
    // Conserver uniquement root + recherches META
    _researchedIds.clear();
    _researchedIds.add('root');
    _researchedIds.addAll(metaResearchIds);
    
    // Mettre à jour les nœuds débloqués
    _updateUnlockedNodes();
    
    if (kDebugMode) {
      print('[ResearchManager] ${metaResearchIds.length} recherches META conservées');
    }
    
    notifyListeners();
  }
  
  // Sérialisation
  Map<String, dynamic> toJson() => {
    'nodes': _nodes.map((id, node) => MapEntry(id, node.toJson())),
    'researchedIds': _researchedIds,
  };
  
  void fromJson(Map<String, dynamic> json) {
    _nodes.clear();
    _researchedIds.clear();
    
    final nodesData = json['nodes'] as Map<String, dynamic>;
    nodesData.forEach((id, data) {
      _nodes[id] = ResearchNode.fromJson(data);
    });
    
    _researchedIds.addAll(List<String>.from(json['researchedIds'] ?? []));
    
    _updateUnlockedNodes();
    notifyListeners();
  }
}
