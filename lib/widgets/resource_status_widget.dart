import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/resource_manager.dart';

class ResourceStatusWidget extends StatelessWidget {
  const ResourceStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final metalStock = gameState.resourceManager.marketMetalStock;
        final warningLevel = metalStock <= ResourceManager.WARNING_THRESHOLD;
        final criticalLevel = metalStock <= ResourceManager.CRITICAL_THRESHOLD;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  'Stock de métal mondial',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: criticalLevel
                        ? Colors.red
                        : warningLevel
                        ? Colors.orange
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: metalStock / ResourceManager.INITIAL_MARKET_METAL,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    criticalLevel
                        ? Colors.red
                        : warningLevel
                        ? Colors.orange
                        : Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${metalStock.toStringAsFixed(1)} unités',
                  style: TextStyle(
                    fontSize: 12,
                    color: criticalLevel
                        ? Colors.red
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}