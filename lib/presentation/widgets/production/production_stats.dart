import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/imports.dart';
import '../../domain/entities/player_state.dart';
import '../viewmodels/production_viewmodel.dart';
import '../widgets/chart_widgets.dart';

class ProductionStats extends StatelessWidget {
  const ProductionStats({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductionViewModel>(
      builder: (context, productionViewModel, child) {
        final player = productionViewModel.playerState;
        if (player == null) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiques',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      context,
                      'Production Totale',
                      player.totalClipsProduced.toString(),
                      Icons.inventory_2,
                    ),
                    _buildStatItem(
                      context,
                      'Production Auto',
                      player.autoclippers.toString(),
                      Icons.auto_awesome,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (player.productionHistory.isNotEmpty)
                  ProductionHistoryChart(
                    history: player.productionHistory,
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
} 