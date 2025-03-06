import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/market_viewmodel.dart';
import '../viewmodels/player_viewmodel.dart';

class MarketControls extends StatelessWidget {
  const MarketControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<MarketViewModel, PlayerViewModel>(
      builder: (context, marketViewModel, playerViewModel, child) {
        final marketState = marketViewModel.marketState;
        final playerState = playerViewModel.playerState;

        if (marketState == null || playerState == null) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marché',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prix: ${marketState.currentPrice.toStringAsFixed(2)}€',
                      style: TextStyle(
                        color: _getPriceColor(marketState.currentPrice),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Stock: ${playerState.clips}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMarketButton(
                      context,
                      'Vendre 1',
                      Icons.sell,
                      Colors.red,
                      () => marketViewModel.sellClips(1),
                      playerState.clips >= 1,
                    ),
                    _buildMarketButton(
                      context,
                      'Vendre 10',
                      Icons.sell,
                      Colors.red,
                      () => marketViewModel.sellClips(10),
                      playerState.clips >= 10,
                    ),
                    _buildMarketButton(
                      context,
                      'Vendre Tout',
                      Icons.sell,
                      Colors.red,
                      () => marketViewModel.sellAllClips(),
                      playerState.clips > 0,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Métal: ${playerState.metal}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Argent: ${playerState.money.toStringAsFixed(2)}€',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMarketButton(
                      context,
                      'Acheter 1',
                      Icons.shopping_cart,
                      Colors.green,
                      () => marketViewModel.buyMetal(1),
                      playerState.money >= marketState.currentPrice,
                    ),
                    _buildMarketButton(
                      context,
                      'Acheter 10',
                      Icons.shopping_cart,
                      Colors.green,
                      () => marketViewModel.buyMetal(10),
                      playerState.money >= marketState.currentPrice * 10,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarketButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    bool enabled,
  ) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        primary: color,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Color _getPriceColor(double price) {
    if (price > 1.0) {
      return Colors.green;
    } else if (price < 0.5) {
      return Colors.red;
    }
    return Colors.orange;
  }
} 