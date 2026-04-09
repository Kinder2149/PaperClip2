// lib/widgets/research/research_category_section.dart
import 'package:flutter/material.dart';
import '../../models/research_node.dart';
import '../../managers/research_manager.dart';
import 'research_node_card.dart';

/// Section affichant les nœuds d'une catégorie de recherche
class ResearchCategorySection extends StatelessWidget {
  final ResearchCategory category;
  final List<ResearchNode> nodes;
  final ResearchManager researchManager;
  final Function(ResearchNode) onNodeTap;

  const ResearchCategorySection({
    Key? key,
    required this.category,
    required this.nodes,
    required this.researchManager,
    required this.onNodeTap,
  }) : super(key: key);

  String _getCategoryName() {
    switch (category) {
      case ResearchCategory.PRODUCTION:
        return '🏭 Production';
      case ResearchCategory.MARKET:
        return '🏪 Marché';
      case ResearchCategory.RESOURCES:
        return '📦 Ressources';
      case ResearchCategory.AGENTS:
        return '🤖 Agents';
      case ResearchCategory.META:
        return '⚙️ Méta';
    }
  }

  IconData _getCategoryIcon() {
    switch (category) {
      case ResearchCategory.PRODUCTION:
        return Icons.precision_manufacturing;
      case ResearchCategory.MARKET:
        return Icons.store;
      case ResearchCategory.RESOURCES:
        return Icons.inventory_2;
      case ResearchCategory.AGENTS:
        return Icons.smart_toy;
      case ResearchCategory.META:
        return Icons.settings;
    }
  }

  Color _getCategoryColor() {
    switch (category) {
      case ResearchCategory.PRODUCTION:
        return Colors.blue;
      case ResearchCategory.MARKET:
        return Colors.green;
      case ResearchCategory.RESOURCES:
        return Colors.amber;
      case ResearchCategory.AGENTS:
        return Colors.purple;
      case ResearchCategory.META:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const SizedBox.shrink();
    }

    final researchedCount = nodes.where((n) => n.isResearched).length;
    final availableCount = nodes.where((n) => n.isAvailable).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _getCategoryColor().withOpacity(0.1),
            border: Border(
              left: BorderSide(
                color: _getCategoryColor(),
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(),
                color: _getCategoryColor(),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCategoryName(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getCategoryColor(),
                      ),
                    ),
                    Text(
                      '$researchedCount/${nodes.length} recherchés • $availableCount disponibles',
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
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: nodes.length,
            itemBuilder: (context, index) {
              final node = nodes[index];
              return ResearchNodeCard(
                node: node,
                researchManager: researchManager,
                onTap: () => onNodeTap(node),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
