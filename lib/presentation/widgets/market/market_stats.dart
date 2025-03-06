import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/imports.dart';
import '../../domain/entities/market_state.dart';
import '../viewmodels/market_viewmodel.dart';
import '../widgets/chart_widgets.dart';

class MarketStats extends StatelessWidget {
  const MarketStats({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketViewModel>(
      builder: (context, marketViewModel, child) {
        final market = marketViewModel.marketState;
        if (market == null) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiques du Marché',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      context,
                      'Ventes Totales',
                      market.totalSales.toString(),
                      Icons.shopping_cart,
                    ),
                    _buildStatItem(
                      context,
                      'Prix Moyen',
                      '${market.averagePrice.toStringAsFixed(2)} €',
                      Icons.attach_money,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (market.priceHistory.isNotEmpty)
                  MarketPriceChart(
                    priceHistory: market.priceHistory,
                  ),
                const SizedBox(height: 16),
                _buildMarketTrends(market),
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
          label,
          style: Theme.of(context).textTheme.subtitle2,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.headline6,
        ),
      ],
    );
  }

  Widget _buildMarketTrends(MarketState market) {
    final priceChange = market.priceHistory.length >= 2
        ? market.priceHistory.last - market.priceHistory[market.priceHistory.length - 2]
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tendances',
          style: Theme.of(context).textTheme.subtitle1,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              priceChange >= 0 ? Icons.trending_up : Icons.trending_down,
              color: priceChange >= 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              '${priceChange.abs().toStringAsFixed(2)} €',
              style: TextStyle(
                color: priceChange >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'depuis la dernière mise à jour',
              style: Theme.of(context).textTheme.caption,
            ),
          ],
        ),
      ],
    );
  }
} 