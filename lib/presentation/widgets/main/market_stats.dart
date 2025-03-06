import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/market_viewmodel.dart';
import '../widgets/chart_widgets.dart';

class MarketStats extends StatelessWidget {
  const MarketStats({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketViewModel>(
      builder: (context, marketViewModel, child) {
        final marketState = marketViewModel.marketState;

        if (marketState == null) {
          return const SizedBox.shrink();
        }

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
                      marketState.totalSales.toString(),
                      Icons.shopping_bag,
                    ),
                    _buildStatItem(
                      context,
                      'Prix Moyen',
                      '${marketState.averagePrice.toStringAsFixed(2)}€',
                      Icons.attach_money,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (marketState.priceHistory.isNotEmpty) ...[
                  const MarketPriceChart(),
                  const SizedBox(height: 16),
                  _buildMarketTrends(marketState),
                ],
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

  Widget _buildMarketTrends(MarketState marketState) {
    final priceChange = marketState.priceChange;
    final demandChange = marketState.demandChange;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTrendItem(
          'Prix',
          priceChange,
          Icons.trending_up,
          Icons.trending_down,
        ),
        _buildTrendItem(
          'Demande',
          demandChange,
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
} 