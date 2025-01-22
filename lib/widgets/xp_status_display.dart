// lib/widgets/xp_status_display.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'package:paperclip2/models/level_system.dart';

class XPStatusDisplay extends StatelessWidget {
  const XPStatusDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final comboMultiplier = gameState.levelSystem.currentComboMultiplier;
        final totalMultiplier = gameState.levelSystem.totalXpMultiplier;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                if (comboMultiplier > 1.0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_on, color: Colors.orange),
                      Text(
                        'Combo x${comboMultiplier.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
                Text(
                  'Multiplicateur XP total: x${totalMultiplier.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (!gameState.levelSystem.dailyBonus.claimed)
                  ElevatedButton.icon(
                    onPressed: () {
                      if (gameState.levelSystem.claimDailyBonus()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bonus quotidien réclamé !'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.stars),
                    label: const Text('Réclamer bonus quotidien'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}