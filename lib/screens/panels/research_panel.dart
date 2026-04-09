import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/research_node.dart';
import 'package:paperclip2/widgets/design_system/design_system.dart';

/// Panel recherche - Arbre de recherche avec Points Innovation
class ResearchPanel extends StatefulWidget {
  const ResearchPanel({Key? key}) : super(key: key);

  @override
  State<ResearchPanel> createState() => _ResearchPanelState();
}

class _ResearchPanelState extends State<ResearchPanel> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(gameState),
              DesignTokens.sectionGap,
              _buildResearchTree(gameState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(GameState gameState) {
    return PanelHeader(
      emoji: '🔬',
      title: 'Recherche',
      metrics: [
        MetricData(
          label: 'Argent',
          value: '\$${gameState.playerManager.money.toStringAsFixed(0)}',
          color: Colors.green,
        ),
        MetricData(
          label: 'Points Innovation',
          value: '${gameState.rareResources.pointsInnovation} PI',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildResearchTree(GameState gameState) {
    final allNodes = gameState.research.allNodes;
    
    // Grouper par catégorie
    final nodesByCategory = <ResearchCategory, List<ResearchNode>>{};
    for (var category in ResearchCategory.values) {
      nodesByCategory[category] = allNodes
          .where((node) => node.category == category && node.id != 'root')
          .toList();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: ResearchCategory.values.map((category) {
        final nodes = nodesByCategory[category] ?? [];
        if (nodes.isEmpty) return const SizedBox.shrink();
        
        // Regrouper les recherches multi-niveaux
        final groupedNodes = _groupMultiLevelResearches(nodes);
        
        return _buildCategorySection(gameState, category, groupedNodes);
      }).toList(),
    );
  }

  List<_ResearchGroup> _groupMultiLevelResearches(List<ResearchNode> nodes) {
    final groups = <_ResearchGroup>[];
    final processedIds = <String>{};
    
    // Définir les familles de recherches multi-niveaux
    final families = {
      'Efficacité Métal': ['prod_efficiency_1', 'prod_efficiency_2'],
      'Vitesse Production': ['prod_speed_1', 'prod_speed_2'],
      'Marketing': ['market_marketing_1', 'market_marketing_2'],
      'Qualité': ['market_quality_1', 'market_quality_2'],
      'Stockage': ['resource_storage_1', 'resource_storage_2'],
      'Approvisionnement': ['resource_procurement_1', 'resource_procurement_2'],
      'Formation Agents': ['agent_training_1', 'agent_training_2'],
      'Expansion RH': ['agent_slot_2', 'agent_slot_3', 'agent_slot_4'],
      'Reset Optimisé': ['reset_bonus_1', 'reset_bonus_2'],
      'Innovation': ['innovation_bonus_1', 'innovation_bonus_2'],
    };
    
    // Créer les groupes pour les familles
    for (var entry in families.entries) {
      final familyNodes = <ResearchNode>[];
      for (var id in entry.value) {
        try {
          final node = nodes.firstWhere((n) => n.id == id);
          familyNodes.add(node);
        } catch (_) {
          // Node not found, skip
        }
      }
      
      if (familyNodes.isNotEmpty) {
        groups.add(_ResearchGroup(
          familyName: entry.key,
          nodes: familyNodes,
          isMultiLevel: true,
        ));
        processedIds.addAll(entry.value);
      }
    }
    
    // Ajouter les recherches individuelles
    for (var node in nodes) {
      if (!processedIds.contains(node.id)) {
        groups.add(_ResearchGroup(
          familyName: node.name,
          nodes: [node],
          isMultiLevel: false,
        ));
      }
    }
    
    return groups;
  }

  Widget _buildCategorySection(GameState gameState, ResearchCategory category, List<_ResearchGroup> groups) {
    final categoryData = _getCategoryData(category);
    final allNodes = groups.expand((g) => g.nodes).toList();
    final researchedCount = allNodes.where((n) => n.isResearched).length;
    final availableCount = allNodes.where((n) => n.isAvailable).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: categoryData.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: categoryData.color,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                categoryData.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryData.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: categoryData.color,
                      ),
                    ),
                    Text(
                      '$researchedCount/${allNodes.length} recherchés • $availableCount disponibles',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: groups.map((group) {
                return SizedBox(
                  width: cardWidth,
                  child: group.isMultiLevel
                      ? _buildMultiLevelResearchCard(gameState, group, categoryData)
                      : _buildResearchCard(gameState, group.nodes.first, categoryData),
                );
              }).toList(),
            );
          },
        ),
        DesignTokens.sectionGap,
      ],
    );
  }

  _CategoryData _getCategoryData(ResearchCategory category) {
    switch (category) {
      case ResearchCategory.PRODUCTION:
        return _CategoryData(
          emoji: '🏭',
          name: 'Production',
          color: Colors.blue,
        );
      case ResearchCategory.MARKET:
        return _CategoryData(
          emoji: '💰',
          name: 'Marché',
          color: Colors.green,
        );
      case ResearchCategory.RESOURCES:
        return _CategoryData(
          emoji: '📦',
          name: 'Ressources',
          color: Colors.orange,
        );
      case ResearchCategory.AGENTS:
        return _CategoryData(
          emoji: '🤖',
          name: 'Agents IA',
          color: Colors.purple,
        );
      case ResearchCategory.META:
        return _CategoryData(
          emoji: '⚙️',
          name: 'Méta-jeu',
          color: Colors.amber,
        );
    }
  }

  String _getResearchEmoji(ResearchNode node) {
    // Emojis spécifiques par recherche basés sur le nom
    if (node.name.contains('Efficacité')) return '⚡';
    if (node.name.contains('Vitesse')) return '🚀';
    if (node.name.contains('Prix')) return '💵';
    if (node.name.contains('Demande')) return '📈';
    if (node.name.contains('Métal')) return '⚙️';
    if (node.name.contains('Quantum')) return '🔮';
    if (node.name.contains('Agent')) return '🤖';
    if (node.name.contains('Slot')) return '📍';
    if (node.name.contains('Reset')) return '🔄';
    if (node.name.contains('Innovation')) return '💡';
    
    // Par catégorie par défaut
    switch (node.category) {
      case ResearchCategory.PRODUCTION:
        return '🏭';
      case ResearchCategory.MARKET:
        return '💰';
      case ResearchCategory.RESOURCES:
        return '📦';
      case ResearchCategory.AGENTS:
        return '🤖';
      case ResearchCategory.META:
        return '⭐';
    }
  }

  Widget _buildResearchCard(GameState gameState, ResearchNode node, _CategoryData categoryData) {
    bool canAfford = true;
    if (node.moneyCost > 0) {
      canAfford = gameState.playerManager.money >= node.moneyCost;
    } else if (node.innovationPointsCost > 0) {
      canAfford = gameState.rareResources.pointsInnovation >= node.innovationPointsCost;
    }
    if (node.quantumCost > 0) {
      canAfford = canAfford && gameState.rareResources.quantum >= node.quantumCost;
    }
    
    final isAvailable = node.isAvailable;
    final isResearched = node.isResearched;
    final isLocked = !node.isUnlocked;
    
    Color cardColor;
    if (isResearched) {
      cardColor = categoryData.color.withOpacity(0.2);
    } else if (isAvailable && canAfford) {
      cardColor = categoryData.color.withOpacity(0.1);
    } else if (isLocked) {
      cardColor = Colors.grey.shade200;
    } else {
      cardColor = Colors.white;
    }
    
    return Card(
      elevation: isResearched ? 4 : 2,
      color: cardColor,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: (isAvailable && canAfford) 
            ? () => gameState.research.research(node.id)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    _getResearchEmoji(node),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      node.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isLocked ? Colors.grey : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isResearched ? Icons.check_circle : (isLocked ? Icons.lock : Icons.radio_button_unchecked),
                    size: 12,
                    color: isResearched ? Colors.green.shade700 : (isLocked ? Colors.grey.shade600 : categoryData.color),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isResearched ? 'Recherché' : (isLocked ? 'Verrouillé' : 'Disponible'),
                    style: TextStyle(
                      fontSize: 10,
                      color: isResearched ? Colors.green.shade700 : (isLocked ? Colors.grey.shade600 : Colors.black87),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                node.description,
                style: TextStyle(
                  fontSize: 10,
                  color: isLocked ? Colors.grey : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: canAfford ? Colors.white : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: canAfford ? categoryData.color : Colors.grey,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        node.moneyCost > 0 ? Icons.attach_money : Icons.lightbulb,
                        size: 14,
                        color: canAfford ? categoryData.color : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        node.moneyCost > 0 
                            ? '\$${node.moneyCost}'
                            : '${node.innovationPointsCost} PI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: canAfford ? Colors.black87 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isResearched)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check, size: 12, color: Colors.green),
                      SizedBox(width: 3),
                      Text(
                        'Actif',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiLevelResearchCard(GameState gameState, _ResearchGroup group, _CategoryData categoryData) {
    // Trouver le niveau actuel et le prochain
    ResearchNode? currentNode;
    int currentLevel = 0;
    
    for (int i = 0; i < group.nodes.length; i++) {
      if (group.nodes[i].isResearched) {
        currentLevel = i + 1;
      } else if (currentNode == null && !group.nodes[i].isResearched) {
        currentNode = group.nodes[i];
      }
    }
    
    final isCompleted = currentLevel == group.nodes.length;
    final displayNode = currentNode ?? group.nodes.last;
    
    bool canAfford = true;
    if (currentNode != null) {
      if (currentNode.moneyCost > 0) {
        canAfford = gameState.playerManager.money >= currentNode.moneyCost;
      } else if (currentNode.innovationPointsCost > 0) {
        canAfford = gameState.rareResources.pointsInnovation >= currentNode.innovationPointsCost;
      }
      if (currentNode.quantumCost > 0) {
        canAfford = canAfford && gameState.rareResources.quantum >= currentNode.quantumCost;
      }
    }
    
    final isAvailable = currentNode != null && currentNode.isAvailable;
    final isLocked = currentNode != null && !currentNode.isUnlocked;
    
    Color cardColor;
    if (isCompleted) {
      cardColor = categoryData.color.withOpacity(0.2);
    } else if (isAvailable && canAfford) {
      cardColor = categoryData.color.withOpacity(0.1);
    } else if (isLocked) {
      cardColor = Colors.grey.shade200;
    } else {
      cardColor = Colors.white;
    }
    
    return Card(
      elevation: isCompleted ? 4 : 2,
      color: cardColor,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: (isAvailable && canAfford && currentNode != null) 
            ? () => gameState.research.research(currentNode!.id)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    _getResearchEmoji(displayNode),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      group.familyName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isLocked ? Colors.grey : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : (isLocked ? Icons.lock : Icons.radio_button_unchecked),
                    size: 12,
                    color: isCompleted ? Colors.green.shade700 : (isLocked ? Colors.grey.shade600 : categoryData.color),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Niveau $currentLevel/${group.nodes.length}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isCompleted ? Colors.green.shade700 : (isLocked ? Colors.grey.shade600 : Colors.black87),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isCompleted && !isLocked) ...[
                    const SizedBox(width: 4),
                    Text(
                      '• ${isAvailable ? "Disponible" : "Verrouillé"}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                displayNode.description,
                style: TextStyle(
                  fontSize: 10,
                  color: isLocked ? Colors.grey : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: canAfford ? Colors.white : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: canAfford ? categoryData.color : Colors.grey,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentNode.moneyCost > 0 ? Icons.attach_money : Icons.lightbulb,
                        size: 14,
                        color: canAfford ? categoryData.color : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentNode.moneyCost > 0 
                            ? '\$${currentNode.moneyCost}'
                            : '${currentNode.innovationPointsCost} PI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: canAfford ? Colors.black87 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check, size: 12, color: Colors.green),
                      SizedBox(width: 3),
                      Text(
                        'Complété',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryData {
  final String emoji;
  final String name;
  final Color color;
  
  _CategoryData({
    required this.emoji,
    required this.name,
    required this.color,
  });
}

class _ResearchGroup {
  final String familyName;
  final List<ResearchNode> nodes;
  final bool isMultiLevel;
  
  _ResearchGroup({
    required this.familyName,
    required this.nodes,
    required this.isMultiLevel,
  });
}
