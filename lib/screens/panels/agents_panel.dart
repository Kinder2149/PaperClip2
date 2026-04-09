import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/widgets/design_system/design_system.dart';

/// Panel agents IA - Gestion des agents autonomes
class AgentsPanel extends StatefulWidget {
  const AgentsPanel({Key? key}) : super(key: key);

  @override
  State<AgentsPanel> createState() => _AgentsPanelState();
}

class _AgentsPanelState extends State<AgentsPanel> with AutomaticKeepAliveClientMixin {
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
              _buildSlotsInfo(gameState),
              DesignTokens.sectionGap,
              _buildAgentsList(gameState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(GameState gameState) {
    return PanelHeader(
      emoji: '🤖',
      title: 'Agents IA Autonomes',
      singleMetric: MetricData(
        label: 'Quantum',
        value: '${gameState.rareResources.quantum}',
        color: Colors.cyan,
      ),
    );
  }

  Widget _buildSlotsInfo(GameState gameState) {
    return Card(
      color: Colors.cyan.shade50,
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: MetricRow(
          metrics: [
            MetricData(
              label: 'Slots actifs',
              value: '${gameState.agents.activeCount}',
              color: Colors.cyan,
            ),
            MetricData(
              label: 'Slots max',
              value: '${gameState.agents.maxSlots}',
              color: Colors.cyan,
            ),
            MetricData(
              label: 'Agents débloqués',
              value: '${gameState.agents.allAgents.where((a) => a.isUnlocked).length}',
              color: Colors.cyan,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentsList(GameState gameState) {
    final allAgents = gameState.agents.allAgents;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: allAgents.map((agent) {
        final isLocked = !agent.isUnlocked;
        final isActive = agent.isActive;
        final canActivate = agent.isUnlocked && 
                           !agent.isActive && 
                           gameState.agents.availableSlots > 0;
        
        return Card(
          color: isActive 
              ? Colors.cyan.shade100 
              : (isLocked ? Colors.grey.shade200 : null),
          child: Padding(
            padding: DesignTokens.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isLocked ? Icons.lock : (isActive ? Icons.check_circle : Icons.smart_toy),
                      color: isLocked ? Colors.grey : (isActive ? Colors.green : Colors.cyan),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        agent.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isActive)
                      Chip(
                        label: const Text('ACTIF'),
                        backgroundColor: Colors.green,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                  ],
                ),
                DesignTokens.smallGap,
                Text(
                  agent.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (!isLocked) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.flash_on, size: 16, color: Colors.cyan),
                      const SizedBox(width: 4),
                      Text('Coût: ${agent.activationCost} Quantum'),
                      const SizedBox(width: 16),
                      Icon(Icons.timer, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Durée: 1h'),
                    ],
                  ),
                ],
                if (agent.totalActions > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Actions effectuées: ${agent.totalActions}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (canActivate) ...[
                  DesignTokens.mediumGap,
                  ActionButton(
                    emoji: '▶️',
                    label: 'Activer',
                    onPressed: () => gameState.agents.activateAgent(agent.id),
                    color: Colors.cyan,
                  ),
                ],
                if (isActive) ...[
                  DesignTokens.mediumGap,
                  ActionButton(
                    emoji: '⏹️',
                    label: 'Désactiver',
                    onPressed: () => gameState.agents.deactivateAgent(agent.id),
                    color: Colors.red,
                  ),
                ],
                if (isLocked) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Débloqué via recherche',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
