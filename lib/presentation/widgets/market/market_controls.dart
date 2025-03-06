import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/imports.dart';
import '../../domain/entities/market_state.dart';
import '../../domain/entities/player_state.dart';
import '../viewmodels/market_viewmodel.dart';
import '../viewmodels/production_viewmodel.dart';

class MarketControls extends StatelessWidget {
  const MarketControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<MarketViewModel, ProductionViewModel>(
      builder: (context, marketViewModel, productionViewModel, child) {
        final market = marketViewModel.marketState;
        final player = productionViewModel.playerState;
        
        if (market == null || player == null) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actions',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      context,
                      'Vendre',
                      Icons.sell,
                      Colors.green,
                      () => marketViewModel.sellClips(1),
                      player.clips > 0,
                    ),
                    _buildActionButton(
                      context,
                      'Vendre x10',
                      Icons.sell,
                      Colors.green,
                      () => marketViewModel.sellClips(10),
                      player.clips >= 10,
                    ),
                    _buildActionButton(
                      context,
                      'Vendre Tout',
                      Icons.sell,
                      Colors.green,
                      () => marketViewModel.sellAllClips(),
                      player.clips > 0,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      context,
                      'Acheter Métal',
                      Icons.shopping_cart,
                      Colors.blue,
                      () => marketViewModel.buyMetal(1),
                      player.money >= market.currentMetalPrice,
                    ),
                    _buildActionButton(
                      context,
                      'Acheter x10',
                      Icons.shopping_cart,
                      Colors.blue,
                      () => marketViewModel.buyMetal(10),
                      player.money >= market.currentMetalPrice * 10,
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

  Widget _buildActionButton(
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
        onSurface: color.withOpacity(0.5),
      ),
    );
  }
} 