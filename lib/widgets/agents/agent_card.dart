// lib/widgets/agents/agent_card.dart

import 'package:flutter/material.dart';
import '../../models/agent.dart';
import 'agent_timer_display.dart';
import 'agent_stats_card.dart';

/// Carte affichant un agent IA avec son état et ses actions
class AgentCard extends StatelessWidget {
  final Agent agent;
  final VoidCallback? onActivate;
  final VoidCallback? onDeactivate;
  final bool canActivate;

  const AgentCard({
    Key? key,
    required this.agent,
    this.onActivate,
    this.onDeactivate,
    required this.canActivate,
  }) : super(key: key);

  Color _getTypeColor() {
    switch (agent.type) {
      case AgentType.PRODUCTION:
        return Colors.blue;
      case AgentType.MARKET:
        return Colors.green;
      case AgentType.RESOURCE:
        return Colors.amber;
      case AgentType.INNOVATION:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon() {
    switch (agent.type) {
      case AgentType.PRODUCTION:
        return Icons.precision_manufacturing;
      case AgentType.MARKET:
        return Icons.trending_up;
      case AgentType.RESOURCE:
        return Icons.inventory_2;
      case AgentType.INNOVATION:
        return Icons.lightbulb;
    }
  }

  String _getStatusLabel() {
    switch (agent.status) {
      case AgentStatus.LOCKED:
        return 'Verrouillé';
      case AgentStatus.UNLOCKED:
        return 'Disponible';
      case AgentStatus.ACTIVE:
        return 'Actif';
    }
  }

  Color _getStatusColor() {
    switch (agent.status) {
      case AgentStatus.LOCKED:
        return Colors.grey;
      case AgentStatus.UNLOCKED:
        return _getTypeColor();
      case AgentStatus.ACTIVE:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = agent.status == AgentStatus.LOCKED;
    final isActive = agent.isActive;

    return Card(
      elevation: isActive ? 4 : 2,
      color: isLocked 
          ? Colors.grey[200]
          : isActive
              ? _getTypeColor().withOpacity(0.1)
              : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header : Icône + Nom + Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        agent.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(), width: 1),
                  ),
                  child: Text(
                    _getStatusLabel(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
            
            if (!isLocked) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Infos coût et durée
              Row(
                children: [
                  Icon(Icons.diamond, color: Colors.purple, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Coût: ${agent.activationCost} Quantum',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.timer, color: Colors.blue, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    'Durée: 1h',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              
              // Timer si actif
              if (isActive && agent.expiresAt != null) ...[
                const SizedBox(height: 12),
                AgentTimerDisplay(
                  expiresAt: agent.expiresAt!,
                  compact: true,
                ),
              ],
              
              // Stats
              if (agent.totalActions > 0) ...[
                const SizedBox(height: 12),
                AgentStatsCard(agent: agent),
              ],
              
              const SizedBox(height: 12),
              
              // Bouton d'action
              SizedBox(
                width: double.infinity,
                child: isActive
                    ? ElevatedButton.icon(
                        onPressed: onDeactivate,
                        icon: const Icon(Icons.stop),
                        label: const Text('Désactiver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: canActivate ? onActivate : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Activer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getTypeColor(),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                      ),
              ),
              
              // Message si ne peut pas activer
              if (!isActive && !canActivate && onActivate != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Quantum insuffisant ou slots pleins',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recherche requise pour débloquer cet agent',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
