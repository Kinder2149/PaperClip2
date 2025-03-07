import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import 'resource_indicator.dart';

class MoneyIndicator extends StatelessWidget {
  const MoneyIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return ResourceIndicator(
          icon: Icons.euro,
          color: Colors.green,
          label: 'Argent',
          value: gameState.player.money,
          suffix: ' €',
        );
      },
    );
  }
} 