// lib/widgets/charts/chart_widgets.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import '../../managers/market_manager.dart';
import '../../services/format/game_format.dart';

class _StatsOverviewView {
  final int totalPaperclipsProduced;
  final String totalTimePlayed;
  final int autoClipperCount;
  final String sellPrice;

  const _StatsOverviewView({
    required this.totalPaperclipsProduced,
    required this.totalTimePlayed,
    required this.autoClipperCount,
    required this.sellPrice,
  });

  @override
  bool operator ==(Object other) {
    return other is _StatsOverviewView &&
        other.totalPaperclipsProduced == totalPaperclipsProduced &&
        other.totalTimePlayed == totalTimePlayed &&
        other.autoClipperCount == autoClipperCount &&
        other.sellPrice == sellPrice;
  }

  @override
  int get hashCode => Object.hash(
        totalPaperclipsProduced,
        totalTimePlayed,
        autoClipperCount,
        sellPrice,
      );
}

class SalesChartOptimized extends StatefulWidget {
  final List<SaleRecord> salesHistory;

  const SalesChartOptimized({super.key, required this.salesHistory});

  @override
  State<SalesChartOptimized> createState() => _SalesChartOptimizedState();
}

class _SalesChartOptimizedState extends State<SalesChartOptimized> {
  List<FlSpot> _revenueSpots = const [];
  List<FlSpot> _quantitySpots = const [];
  double _maxX = 0;
  int _lastSaleTimestampMs = 0;
  int _lastLen = 0;

  @override
  void initState() {
    super.initState();
    _recomputeIfNeeded(widget.salesHistory);
  }

  @override
  void didUpdateWidget(covariant SalesChartOptimized oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recomputeIfNeeded(widget.salesHistory);
  }

  void _recomputeIfNeeded(List<SaleRecord> salesHistory) {
    final len = salesHistory.length;
    final lastTimestampMs = len == 0
        ? 0
        : salesHistory.last.timestamp.millisecondsSinceEpoch;

    if (len == _lastLen && lastTimestampMs == _lastSaleTimestampMs) {
      return;
    }

    _lastLen = len;
    _lastSaleTimestampMs = lastTimestampMs;

    _revenueSpots = List<FlSpot>.generate(
      len,
      (index) => FlSpot(index.toDouble(), salesHistory[index].revenue),
      growable: false,
    );
    _quantitySpots = List<FlSpot>.generate(
      len,
      (index) =>
          FlSpot(index.toDouble(), salesHistory[index].quantity.toDouble()),
      growable: false,
    );
    _maxX = len <= 1 ? 0 : (len - 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final salesHistory = widget.salesHistory;

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
                  spots: _revenueSpots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
                // Ligne des quantités
                LineChartBarData(
                  spots: _quantitySpots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
              minX: 0,
              maxX: _maxX,
              minY: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class StatsOverview extends StatelessWidget {
  const StatsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, _StatsOverviewView>(
      selector: (context, gameState) => _StatsOverviewView(
        totalPaperclipsProduced: gameState.totalPaperclipsProduced,
        totalTimePlayed: GameFormat.durationHms(gameState.totalTimePlayed),
        autoClipperCount: gameState.playerManager.autoClipperCount,
        sellPrice: GameFormat.money(gameState.playerManager.sellPrice, decimals: 2),
      ),
      builder: (context, view, child) {
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
                  value: GameFormat.intWithSeparators(view.totalPaperclipsProduced),
                  icon: Icons.link,
                ),
                _StatRow(
                  label: 'Temps de jeu',
                  value: view.totalTimePlayed,
                  icon: Icons.timer,
                ),
                _StatRow(
                  label: 'Autoclippers',
                  value: GameFormat.intWithSeparators(view.autoClipperCount),
                  icon: Icons.precision_manufacturing,
                ),
                _StatRow(
                  label: 'Prix de vente',
                  value: view.sellPrice,
                  icon: Icons.euro,
                ),
              ],
            ),
          ),
        );
      },
    );
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