// lib/widgets/level_display.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

class LevelDisplay extends StatelessWidget {
  const LevelDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
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
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => _showLevelInfo(context, gameState),
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
                Text(
                  'XP: ${gameState.levelSystem.experience.floor()} / ${gameState.levelSystem.experienceForNextLevel.floor()}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLevelInfo(BuildContext context, GameState gameState) {
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
            Text('Bonus de production: +${(gameState.levelSystem.productionMultiplier - 1) * 100}%'),
            Text('Bonus de vente: +${(gameState.levelSystem.salesMultiplier - 1) * 100}%'),
            const SizedBox(height: 16),
            const Text(
              'Gains d\'expérience :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Production manuelle : 1 XP'),
            const Text('• Production auto : 0.5 XP'),
            const Text('• Vente : 2 XP × prix'),
            const Text('• Achat autoclipper : 50 XP'),
            const Text('• Amélioration : 100 XP × niveau'),
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