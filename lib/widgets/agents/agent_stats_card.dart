// lib/widgets/agents/agent_stats_card.dart

import 'package:flutter/material.dart';
import '../../models/agent.dart';

/// Widget affichant les statistiques d'un agent
class AgentStatsCard extends StatelessWidget {
  final Agent agent;

  const AgentStatsCard({
    Key? key,
    required this.agent,
  }) : super(key: key);

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Jamais';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: Colors.blue[700], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${agent.totalActions} action${agent.totalActions > 1 ? 's' : ''} effectuée${agent.totalActions > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (agent.lastActionAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Dernière: ${_formatTimeAgo(agent.lastActionAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
