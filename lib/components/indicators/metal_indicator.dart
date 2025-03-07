import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import 'resource_indicator.dart';

class MetalIndicator extends StatelessWidget {
  const MetalIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return ResourceIndicator(
          icon: Icons.straighten,
          color: Colors.grey,
          label: 'Métal',
          value: gameState.player.metal,
          maxValue: gameState.player.maxMetalStorage,
          showProgress: true,
        );
      },
    );
  }
} 