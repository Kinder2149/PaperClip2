import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/market.dart';

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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, size: 24, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Résumé des Ventes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSaleCard(SaleRecord sale) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.green.shade300,
              width: 4,
            ),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.sell, color: Colors.green),
          ),
          title: Row(
            children: [
              Text(
                '${sale.quantity} ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('unités vendues'),
            ],
          ),
          subtitle: Text(
            'Prix unitaire: ${sale.price.toStringAsFixed(2)} €',
            style: TextStyle(color: Colors.grey[600]),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${sale.revenue.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                _formatTimestamp(sale.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
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