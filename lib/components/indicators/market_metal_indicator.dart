import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import '../../models/game_config.dart';
import 'resource_indicator.dart';

class MarketMetalIndicator extends StatelessWidget {
  const MarketMetalIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final metalStock = gameState.resources.marketMetalStock;
        final warningLevel = metalStock <= GameConstants.WARNING_THRESHOLD;
        final criticalLevel = metalStock <= GameConstants.CRITICAL_THRESHOLD;
        
        Color indicatorColor = Colors.blue;
        if (criticalLevel) {
          indicatorColor = Colors.red;
        } else if (warningLevel) {
          indicatorColor = Colors.orange;
        }

        return ResourceIndicator(
          icon: Icons.public,
          color: indicatorColor,
          label: 'Stock de métal mondial',
          value: metalStock,
          maxValue: GameConstants.INITIAL_MARKET_METAL,
          showProgress: true,
        );
      },
    );
  }
} 