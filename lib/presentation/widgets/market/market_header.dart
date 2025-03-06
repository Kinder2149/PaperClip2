import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/imports.dart';
import '../../domain/entities/market_state.dart';
import '../../domain/entities/player_state.dart';
import '../viewmodels/market_viewmodel.dart';
import '../viewmodels/production_viewmodel.dart';
import '../widgets/resource_widgets.dart';

class MarketHeader extends StatelessWidget {
  const MarketHeader({Key? key}) : super(key: key);

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
                  'État du Marché',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ResourceDisplay(
                        label: 'Trombones',
                        value: player.clips,
                        icon: Icons.inventory_2,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ResourceDisplay(
                        label: 'Argent',
                        value: player.money,
                        icon: Icons.attach_money,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prix actuel:',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    Text(
                      '${market.currentMetalPrice.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.headline6?.copyWith(
                        color: _getPriceColor(market.currentMetalPrice),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Demande: ${market.demand.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.subtitle2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getPriceColor(double price) {
    if (price > 1.5) return Colors.green;
    if (price < 0.5) return Colors.red;
    return Colors.orange;
  }
} 