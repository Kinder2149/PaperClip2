// lib/widgets/research/research_node_card.dart
import 'package:flutter/material.dart';
import '../../models/research_node.dart';
import '../../managers/research_manager.dart';

/// Carte affichant un nœud de recherche individuel
class ResearchNodeCard extends StatelessWidget {
  final ResearchNode node;
  final ResearchManager researchManager;
  final VoidCallback? onTap;
  final bool showConnections;

  const ResearchNodeCard({
    Key? key,
    required this.node,
    required this.researchManager,
    this.onTap,
    this.showConnections = false,
  }) : super(key: key);

  Color _getCategoryColor() {
    switch (node.category) {
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

  IconData _getStateIcon() {
    if (node.isResearched) {
      return Icons.check_circle;
    } else if (node.isUnlocked) {
      return Icons.radio_button_unchecked;
    } else {
      return Icons.lock;
    }
  }

  Color _getStateColor() {
    if (node.isResearched) {
      return Colors.green;
    } else if (node.isUnlocked) {
      return _getCategoryColor();
    } else {
      return Colors.grey;
    }
  }

  String _getStateLabel() {
    if (node.isResearched) {
      return 'Recherché';
    } else if (node.isUnlocked) {
      return 'Disponible';
    } else {
      return 'Verrouillé';
    }
  }

  Widget _buildEffectDescription() {
    final effect = node.effect;
    
    switch (effect.type) {
      case ResearchEffectType.PASSIVE_BONUS:
        if (effect.params.containsKey('bonuses')) {
          final bonuses = effect.params['bonuses'] as List;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: bonuses.map((bonus) {
              final value = (bonus['value'] as num).toDouble();
              final sign = value >= 0 ? '+' : '';
              return Text(
                '${bonus['stat']}: $sign${(value * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12),
              );
            }).toList(),
          );
        } else {
          final stat = effect.params['stat'] as String;
          final value = (effect.params['value'] as num).toDouble();
          final sign = value >= 0 ? '+' : '';
          return Text(
            '$stat: $sign${(value * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12),
          );
        }
        
      case ResearchEffectType.UNLOCK_AGENT:
        return Text(
          'Débloque: ${effect.params['agentId']}',
          style: const TextStyle(fontSize: 12),
        );
        
      case ResearchEffectType.UNLOCK_SLOT:
        return Text(
          'Slot agent #${effect.params['slotNumber']}',
          style: const TextStyle(fontSize: 12),
        );
        
      case ResearchEffectType.UNLOCK_FEATURE:
        return Text(
          'Feature: ${effect.params['feature']}',
          style: const TextStyle(fontSize: 12),
        );
        
      case ResearchEffectType.MODIFY_RESET:
        final parts = <String>[];
        if (effect.params.containsKey('quantumBonus')) {
          final value = (effect.params['quantumBonus'] as num).toDouble();
          parts.add('Quantum: +${(value * 100).toStringAsFixed(0)}%');
        }
        if (effect.params.containsKey('innovationBonus')) {
          final value = (effect.params['innovationBonus'] as num).toDouble();
          parts.add('PI: +${(value * 100).toStringAsFixed(0)}%');
        }
        return Text(
          parts.join(', '),
          style: const TextStyle(fontSize: 12),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResearch = researchManager.canResearch(node.id);
    final isClickable = node.isUnlocked && !node.isResearched && canResearch;

    return Card(
      elevation: node.isResearched ? 4 : 2,
      color: node.isResearched 
          ? _getCategoryColor().withOpacity(0.2)
          : node.isUnlocked 
              ? Colors.white 
              : Colors.grey[200],
      child: InkWell(
        onTap: isClickable ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    _getStateIcon(),
                    color: _getStateColor(),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      node.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: node.isUnlocked ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _getStateLabel(),
                style: TextStyle(
                  fontSize: 11,
                  color: _getStateColor(),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                node.description,
                style: TextStyle(
                  fontSize: 12,
                  color: node.isUnlocked ? Colors.black87 : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              if (node.isUnlocked && !node.isResearched) ...[
                _buildEffectDescription(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      size: 16,
                      color: canResearch ? Colors.amber : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${node.innovationPointsCost} PI',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: canResearch ? Colors.amber[800] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
              if (node.isResearched) ...[
                const Divider(height: 16),
                Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Actif',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              if (!node.isUnlocked && node.prerequisites.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Prérequis: ${node.prerequisites.join(", ")}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (node.exclusiveWith.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Exclusif avec: ${node.exclusiveWith.join(", ")}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red[900],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
