import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/imports.dart';
import '../../domain/entities/player_state.dart';
import '../viewmodels/production_viewmodel.dart';
import '../widgets/resource_widgets.dart';

class ProductionHeader extends StatelessWidget {
  const ProductionHeader({Key? key}) : super(key: key);

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
                  'Vos Ressources',
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
                        label: 'Métal',
                        value: player.metal,
                        icon: Icons.metal,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ProgressBar(
                  progress: player.metal / player.maxMetalStorage,
                  color: Colors.grey,
                  label: 'Capacité de stockage: ${player.metal.toStringAsFixed(1)}/${player.maxMetalStorage.toStringAsFixed(1)}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 