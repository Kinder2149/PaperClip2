import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/imports.dart';
import '../../domain/entities/player_state.dart';
import '../viewmodels/production_viewmodel.dart';
import '../widgets/production_button.dart';

class ProductionControls extends StatelessWidget {
  const ProductionControls({Key? key}) : super(key: key);

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
                  'Production',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ProductionButton(
                      onPressed: () => productionViewModel.produceClip(),
                      label: 'Produire',
                      icon: Icons.add_circle_outline,
                      color: Colors.blue,
                    ),
                    ProductionButton(
                      onPressed: () => productionViewModel.toggleAutoProduction(),
                      label: player.autoProduction ? 'Arrêter Auto' : 'Démarrer Auto',
                      icon: player.autoProduction ? Icons.stop : Icons.play_arrow,
                      color: player.autoProduction ? Colors.red : Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Production Automatique: ${player.autoclippers} trombones/s',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 