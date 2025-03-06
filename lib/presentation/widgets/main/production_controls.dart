import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/production_viewmodel.dart';

class ProductionControls extends StatelessWidget {
  const ProductionControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductionViewModel>(
      builder: (context, productionViewModel, child) {
        final playerState = productionViewModel.playerState;

        if (playerState == null) {
          return const SizedBox.shrink();
        }

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Autoclippers: ${playerState.autoclippers}',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    Text(
                      'Production/s: ${playerState.clipsPerSecond.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildProductionButton(
                      context,
                      'Produire',
                      Icons.add_circle,
                      Colors.green,
                      () => productionViewModel.produceClip(),
                    ),
                    _buildProductionButton(
                      context,
                      'Acheter Autoclipper',
                      Icons.shopping_cart,
                      Colors.blue,
                      () => productionViewModel.buyAutoclipper(),
                    ),
                    _buildProductionButton(
                      context,
                      playerState.isAutoProductionEnabled ? 'Désactiver Auto' : 'Activer Auto',
                      playerState.isAutoProductionEnabled ? Icons.pause : Icons.play_arrow,
                      Colors.orange,
                      () => productionViewModel.toggleAutoProduction(),
                    ),
                  ],
                ),
                if (playerState.isAutoProductionEnabled) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: productionViewModel.autoProductionProgress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
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
} 