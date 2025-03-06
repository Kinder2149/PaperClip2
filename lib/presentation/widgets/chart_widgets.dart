// lib/presentation/widgets/chart_widgets.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/sale_record_entity.dart';
import '../../core/utils/game_utils.dart';

class ProfitLineChart extends StatelessWidget {
  final List<SaleRecordEntity> salesHistory;
  final String title;
  final int dataPoints;

  const ProfitLineChart({
    Key? key,
    required this.salesHistory,
    this.title = 'Historique des profits',
    this.dataPoints = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = _prepareData();
    final maxY = data.isEmpty ? 1.0 : data.map((point) => point.y).reduce((a, b) => a > b ? a : b) * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          height: 200,
          child: data.isEmpty
              ? const Center(child: Text('Aucune donnée disponible'))
              : LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: data.length > 1 ? (data.length / 5).ceil().toDouble() : 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= data.length || value.toInt() < 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          GameUtils.formatNumber(value),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              minX: 0,
              maxX: data.length.toDouble() - 1,
              minY: 0,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: data,
                  isCurved: true,
                  color: Colors.deepPurple,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.deepPurple.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _prepareData() {
    // Use most recent sales up to dataPoints
    final recentSales = salesHistory.length > dataPoints
        ? salesHistory.sublist(salesHistory.length - dataPoints)
        : salesHistory;

    // Create spots for the chart
    final spots = List<FlSpot>.generate(
      recentSales.length,
          (index) => FlSpot(index.toDouble(), recentSales[index].revenue),
    );

    return spots;
  }
}

class MetalPriceHistoryChart extends StatelessWidget {
  final List<double> priceHistory;
  final double currentPrice;

  const MetalPriceHistoryChart({
    Key? key,
    required this.priceHistory,
    required this.currentPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (priceHistory.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Aucun historique de prix disponible')),
      );
    }

    final data = _prepareData();
    final maxY = priceHistory.reduce((a, b) => a > b ? a : b) * 1.2;
    final minY = priceHistory.reduce((a, b) => a < b ? a : b) * 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prix du métal',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Actuel: ${currentPrice.toStringAsFixed(2)} €',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              minX: 0,
              maxX: data.length.toDouble() - 1,
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: data,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _prepareData() {
    return List<FlSpot>.generate(
      priceHistory.length,
          (index) => FlSpot(index.toDouble(), priceHistory[index]),
    );
  }
}

class ProductionStatsPieChart extends StatelessWidget {
  final int manualProduction;
  final int autoProduction;

  const ProductionStatsPieChart({
    Key? key,
    required this.manualProduction,
    required this.autoProduction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = manualProduction + autoProduction;

    if (total == 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Aucune production enregistrée')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Répartition de la production',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: Colors.blue,
                  value: manualProduction.toDouble(),
                  title: '${((manualProduction / total) * 100).toStringAsFixed(1)}%',
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.green,
                  value: autoProduction.toDouble(),
                  title: '${((autoProduction / total) * 100).toStringAsFixed(1)}%',
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Manuel', Colors.blue, manualProduction),
            const SizedBox(width: 24),
            _buildLegendItem('Automatique', Colors.green, autoProduction),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}