import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/money_display.dart';
import '../models/upgrade.dart';
import 'package:paperclip2/models/level_system.dart';

class UpgradesScreen extends StatelessWidget {
  const UpgradesScreen({super.key});

  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours}h ${minutes}m ${remainingSeconds}s';
  }

  Widget _buildStatisticsCard(GameState gameState) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Niveau de Production',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Niveau ${gameState.levelSystem.level}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: gameState.levelSystem.experienceProgress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  Icons.precision_manufacturing,
                  'Production',
                  '${gameState.totalPaperclipsProduced}',
                ),
                _buildStatItem(
                  Icons.trending_up,
                  'Multiplicateur',
                  'x${gameState.levelSystem.productionMultiplier.toStringAsFixed(1)}',
                ),
                _buildStatItem(
                  Icons.timer,
                  'Temps de jeu',
                  _formatDuration(gameState.totalTimePlayed),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final visibleElements = gameState.getVisibleScreenElements();

        if (visibleElements['upgradesSection'] != true) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  size: 100,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Améliorations verrouillées',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Continuez à produire pour débloquer cette section.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MoneyDisplay(),
              const SizedBox(height: 16),
              _buildStatisticsCard(gameState),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: gameState.upgrades.entries
                      .map((entry) => _buildUpgradeCard(
                    context,
                    gameState,
                    entry.key,
                    entry.value,
                  ))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpgradeCard(
      BuildContext context,
      GameState gameState,
      String id,
      Upgrade upgrade,
      ) {
    bool canBuy = gameState.money >= upgrade.currentCost && upgrade.level < upgrade.maxLevel;
    bool isMaxed = upgrade.level >= upgrade.maxLevel;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: canBuy ? () => gameState.purchaseUpgrade(id) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getUpgradeIcon(id),
                    size: 24,
                    color: canBuy ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      upgrade.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: canBuy ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                  if (!isMaxed)
                    Text(
                      '${upgrade.currentCost.toStringAsFixed(1)} €',
                      style: TextStyle(
                        fontSize: 14,
                        color: canBuy ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                upgrade.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: upgrade.level / upgrade.maxLevel,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isMaxed ? Colors.green : Colors.blue,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Niveau ${upgrade.level}/${upgrade.maxLevel}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getUpgradeIcon(String upgradeId) {
    switch (upgradeId) {
      case 'efficiency':
        return Icons.eco;
      case 'marketing':
        return Icons.campaign;
      case 'bulk':
        return Icons.inventory;
      case 'speed':
        return Icons.speed;
      case 'storage':
        return Icons.warehouse;
      case 'automation':
        return Icons.precision_manufacturing;
      case 'quality':
        return Icons.grade;
      default:
        return Icons.extension;
    }
  }
}