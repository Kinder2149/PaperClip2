import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import 'resource_indicator.dart';

class PaperclipIndicator extends StatelessWidget {
  const PaperclipIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return ResourceIndicator(
          icon: Icons.link,
          color: Colors.blue,
          label: 'Trombones',
          value: gameState.player.paperclips.toDouble(),
          isInteger: true,
        );
      },
    );
  }
} 