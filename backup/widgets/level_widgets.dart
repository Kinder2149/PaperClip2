// lib/widgets/level_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/progression_system.dart';
import '../models/game_config.dart';

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

class LevelDisplay extends StatelessWidget {
  const LevelDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final comboMultiplier = gameState.levelSystem.currentComboMultiplier;
        final totalMultiplier = gameState.levelSystem.totalXpMultiplier;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Niveau ${gameState.levelSystem.level}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (comboMultiplier > 1.0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.flash_on, color: Colors.orange, size: 16),
                            Text(
                              'x${comboMultiplier.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => showLevelInfo(context, gameState),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: gameState.levelSystem.experienceProgress,
                    minHeight: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'XP: ${gameState.levelSystem.experience.floor()} / ${gameState.levelSystem.experienceForNextLevel.floor()}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (totalMultiplier > 1.0)
                      Text(
                        'XP x${totalMultiplier.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                if (gameState.levelSystem.isDailyBonusAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton.icon(
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
                      label: const Text('Bonus quotidien disponible !'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showLevelInfo(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations de niveau'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Niveau actuel: ${gameState.levelSystem.level}'),
            const SizedBox(height: 8),
            Text('Bonus de production: +${((gameState.levelSystem.productionMultiplier - 1) * 100).toStringAsFixed(1)}%'),
            Text('Bonus de vente: +${((gameState.levelSystem.salesMultiplier - 1) * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 16),
            const Text(
              'Multiplicateurs actifs :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Combo: x${gameState.levelSystem.currentComboMultiplier.toStringAsFixed(1)}'),
            Text('• Total: x${gameState.levelSystem.totalXpMultiplier.toStringAsFixed(1)}'),
            const SizedBox(height: 16),
            const Text(
              'Gains d\'expérience :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Production manuelle : 2 XP'),
            const Text('• Production auto : 0.1 XP × quantité'),
            const Text('• Vente : 0.3 XP × quantité (max 8)'),
            const Text('• Achat autoclipper : 3 XP'),
            const Text('• Amélioration : 2 XP × niveau'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}