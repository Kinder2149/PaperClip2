// lib/widgets/charts/chart_widgets.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import '../../managers/market_manager.dart';
import '../../constants/game_config.dart'; // Importé depuis constants au lieu de models

class SalesChart extends StatelessWidget {
  final List<SaleRecord> salesHistory;

  const SalesChart({super.key, required this.salesHistory});

  @override
  Widget build(BuildContext context) {
    if (salesHistory.isEmpty) {
      return const Center(
        child: Text('Pas encore de ventes'),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                const Text('Revenus'),
              ],
            ),
            const SizedBox(width: 20),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: Colors.blue,
                ),
                const SizedBox(width: 4),
                const Text('Quantité'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 1,
                verticalInterval: 1,
              ),
              titlesData: const FlTitlesData(
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d), width: 1),
              ),
              lineBarsData: [
                // Ligne des revenus
                LineChartBarData(
                  spots: List.generate(salesHistory.length, (index) {
                    return FlSpot(index.toDouble(), salesHistory[index].revenue);
                  }),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
                // Ligne des quantités
                LineChartBarData(
                  spots: List.generate(salesHistory.length, (index) {
                    return FlSpot(index.toDouble(), salesHistory[index].quantity.toDouble());
                  }),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
              minX: 0,
              maxX: (salesHistory.length - 1).toDouble(),
              minY: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class StatsOverview extends StatelessWidget {
  const StatsOverview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiques',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _StatRow(
                  label: 'Trombones produits',
                  value: gameState.totalPaperclipsProduced.toString(),
                  icon: Icons.link,
                ),
                _StatRow(
                  label: 'Temps de jeu',
                  value: _formatPlayTime(gameState.totalTimePlayed),
                  icon: Icons.timer,
                ),
                _StatRow(
                  label: 'Autoclippers',
                  value: gameState.playerManager.autoClipperCount.toString(),
                  icon: Icons.precision_manufacturing,
                ),
                _StatRow(
                  label: 'Prix de vente',
                  value: '${gameState.playerManager.sellPrice.toStringAsFixed(2)} €',
                  icon: Icons.euro,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatPlayTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}