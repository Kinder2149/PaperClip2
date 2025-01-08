import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/game_state.dart';

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