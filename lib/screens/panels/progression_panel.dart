import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/dialogs/reset_progression_dialog.dart';
import 'package:paperclip2/widgets/design_system/design_system.dart';

/// Panel progression - Système de reset et méta-progression
class ProgressionPanel extends StatefulWidget {
  const ProgressionPanel({Key? key}) : super(key: key);

  @override
  State<ProgressionPanel> createState() => _ProgressionPanelState();
}

class _ProgressionPanelState extends State<ProgressionPanel> with AutomaticKeepAliveClientMixin {
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
              _buildLifetimeStats(gameState),
              DesignTokens.sectionGap,
              _buildResetSection(gameState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(GameState gameState) {
    return PanelHeader(
      emoji: '📈',
      title: 'Progression',
      metrics: [
        MetricData(
          label: 'Quantum',
          value: '${gameState.rareResources.quantum}',
          color: Colors.cyan,
        ),
        MetricData(
          label: 'Points Innovation',
          value: '${gameState.rareResources.pointsInnovation}',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildLifetimeStats(GameState gameState) {
    return Card(
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              emoji: '📊',
              title: 'Statistiques Lifetime',
            ),
            DesignTokens.sectionGap,
            _buildStatRow(
              'Resets effectués',
              '${gameState.rareResources.totalResets}',
              Icons.refresh,
            ),
            _buildStatRow(
              'Quantum total',
              gameState.rareResources.quantumLifetime.toString(),
              Icons.flash_on,
            ),
            _buildStatRow(
              'PI total',
              gameState.rareResources.innovationPointsLifetime.toString(),
              Icons.lightbulb,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Trombones (total)',
              _formatNumber(gameState.statistics.totalPaperclipsProduced.toDouble()),
              Icons.attach_file,
            ),
            _buildStatRow(
              'Temps de jeu',
              _formatDuration(Duration(seconds: gameState.statistics.totalGameTimeSec)),
              Icons.timer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetSection(GameState gameState) {
    final canReset = gameState.resetManager.canReset();
    final rewards = gameState.resetManager.calculatePotentialRewards();
    final quantumReward = rewards.quantum;
    final piReward = rewards.innovationPoints;
    
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Reset Progression',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Réinitialisez votre progression pour obtenir des ressources rares permanentes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'Récompenses du prochain reset',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Icon(Icons.flash_on, color: Colors.cyan, size: 32),
                          const SizedBox(height: 4),
                          Text(
                            '+$quantumReward',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyan,
                            ),
                          ),
                          const Text('Quantum'),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.purple, size: 32),
                          const SizedBox(height: 4),
                          Text(
                            '+$piReward',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const Text('Points Innovation'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: canReset
                  ? () => _showResetDialog(context, gameState)
                  : null,
              icon: const Icon(Icons.refresh),
              label: const Text('RESET PROGRESSION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(20),
              ),
            ),
            if (!canReset) ...[
              const SizedBox(height: 12),
              Text(
                'Conditions non remplies pour effectuer un reset',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => const ResetProgressionDialog(),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}
