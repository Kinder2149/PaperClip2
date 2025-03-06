import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/market_viewmodel.dart';
import '../viewmodels/game_viewmodel.dart';
import '../widgets/chart_widgets.dart';

class MarketStats extends StatelessWidget {
  const MarketStats({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<MarketViewModel, GameViewModel>(
      builder: (context, marketViewModel, gameViewModel, child) {
        final marketState = marketViewModel.marketState;
        final gameState = gameViewModel.gameState;

        if (marketState == null || gameState == null) {
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
                const SizedBox(height: 16),
                _buildStatRow(
                  context,
                  'Meilleur Prix',
                  '${marketState.highestPrice.toStringAsFixed(2)}€',
                  Icons.trending_up,
                ),
                _buildStatRow(
                  context,
                  'Pire Prix',
                  '${marketState.lowestPrice.toStringAsFixed(2)}€',
                  Icons.trending_down,
                ),
                _buildStatRow(
                  context,
                  'Volume Total',
                  marketState.totalVolume.toString(),
                  Icons.assessment,
                ),
                _buildStatRow(
                  context,
                  'Revenu Total',
                  '${marketState.totalRevenue.toStringAsFixed(2)}€',
                  Icons.account_balance_wallet,
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