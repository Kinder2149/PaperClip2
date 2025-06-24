import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/market.dart';
import '../widgets/cards/stats_panel.dart';
import '../widgets/indicators/stat_indicator.dart';
import '../widgets/cards/info_card.dart';

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Ventes'),
        elevation: 0,
      ),
      body: Consumer<GameState>(
        builder: (context, gameState, child) {
          final sales = gameState.market.salesHistory;

          if (sales.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune vente enregistrée',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
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
                _buildSummaryCard(gameState),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Dernières Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: sales.length,
                    itemBuilder: (context, index) {
                      final sale = sales[sales.length - 1 - index];
                      return _buildSaleCard(sale);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  Widget _buildSummaryCard(GameState gameState) {
    double totalRevenue = gameState.market.salesHistory
        .fold(0.0, (sum, sale) => sum + sale.revenue);
        
    List<Widget> statItems = [
      _buildSummaryItem(
        'Revenus Session',
        '${totalRevenue.toStringAsFixed(2)} €',
        Icons.euro,
        Colors.green,
      ),
      _buildSummaryItem(
        'Prix Actuel',
        '${gameState.player.sellPrice.toStringAsFixed(2)} €',
        Icons.price_check,
        Colors.blue,
      ),
      _buildSummaryItem(
        'Total Vendu',
        _formatQuantity(gameState.totalPaperclipsProduced),
        Icons.shopping_cart,
        Colors.orange,
      ),
    ];

    return StatsPanel(
      title: 'Résumé des Ventes',
      titleIcon: Icons.analytics,
      titleStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(16),
      direction: Axis.horizontal,
      children: statItems,
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return StatIndicator(
      label: label,
      value: value,
      icon: icon,
      layout: StatIndicatorLayout.vertical,
      iconColor: color,
      valueStyle: TextStyle(color: color, fontSize: 16.0, fontWeight: FontWeight.bold),
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12.0),
      iconSize: 24.0,
      spaceBetween: 8.0,
    );
  }

  Widget _buildSaleCard(SaleRecord sale) {
    Map<String, String> details = {
      'Prix unitaire': '${sale.price.toStringAsFixed(2)} €',
      'Heure': _formatTimestamp(sale.timestamp),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InfoCard(
        title: '${sale.quantity} unités vendues',
        value: '${sale.revenue.toStringAsFixed(2)} €',
        icon: Icons.sell,
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: details.entries.map((entry) => Text('${entry.key}: ${entry.value}', style: TextStyle(fontSize: 12))).toList(),
        ),
        iconColor: Colors.green,
        backgroundColor: Colors.white,
      ),
    );
  }

  String _formatQuantity(int quantity) {
    if (quantity >= 1000000) {
      return '${(quantity / 1000000).toStringAsFixed(1)}M';
    } else if (quantity >= 1000) {
      return '${(quantity / 1000).toStringAsFixed(1)}K';
    }
    return quantity.toString();
  }
}