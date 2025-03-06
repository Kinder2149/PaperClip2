import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/production_viewmodel.dart';
import '../viewmodels/game_viewmodel.dart';
import '../widgets/chart_widgets.dart';

class ProductionStats extends StatelessWidget {
  const ProductionStats({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProductionViewModel, GameViewModel>(
      builder: (context, productionViewModel, gameViewModel, child) {
        final playerState = productionViewModel.playerState;
        final gameState = gameViewModel.gameState;

        if (playerState == null || gameState == null) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiques de Production',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      context,
                      'Production Totale',
                      gameState.totalPaperclipsProduced.toString(),
                      Icons.attachment,
                    ),
                    _buildStatItem(
                      context,
                      'Production/s',
                      '${playerState.clipsPerSecond.toStringAsFixed(1)}',
                      Icons.speed,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (gameState.productionHistory.isNotEmpty) ...[
                  const ProductionChart(),
                  const SizedBox(height: 16),
                  _buildProductionTrends(gameState),
                ],
                const SizedBox(height: 16),
                _buildStatRow(
                  context,
                  'Efficacité de production',
                  '${_calculateEfficiency(playerState).toStringAsFixed(1)}%',
                  Icons.efficiency,
                ),
                _buildStatRow(
                  context,
                  'Temps moyen de production',
                  '${_calculateAverageProductionTime(playerState).toStringAsFixed(2)}s',
                  Icons.timer,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headline6,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.caption,
        ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionTrends(GameState gameState) {
    final productionChange = gameState.productionChange;
    final efficiencyChange = gameState.efficiencyChange;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTrendItem(
          'Production',
          productionChange,
          Icons.trending_up,
          Icons.trending_down,
        ),
        _buildTrendItem(
          'Efficacité',
          efficiencyChange,
          Icons.trending_up,
          Icons.trending_down,
        ),
      ],
    );
  }

  Widget _buildTrendItem(
    String label,
    double change,
    IconData upIcon,
    IconData downIcon,
  ) {
    final isPositive = change > 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? upIcon : downIcon;

    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ${change.abs().toStringAsFixed(1)}%',
          style: TextStyle(color: color),
        ),
      ],
    );
  }

  double _calculateEfficiency(PlayerState playerState) {
    if (playerState.clipsPerSecond == 0) return 0;
    return (playerState.clipsPerSecond / playerState.autoclippers) * 100;
  }

  double _calculateAverageProductionTime(PlayerState playerState) {
    if (playerState.clipsPerSecond == 0) return 0;
    return 1 / playerState.clipsPerSecond;
  }
} 