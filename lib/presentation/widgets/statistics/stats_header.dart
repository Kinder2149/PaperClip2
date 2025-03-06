import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/player_viewmodel.dart';
import '../viewmodels/game_viewmodel.dart';

class StatsHeader extends StatelessWidget {
  const StatsHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerViewModel, GameViewModel>(
      builder: (context, playerViewModel, gameViewModel, child) {
        final playerState = playerViewModel.playerState;
        final gameState = gameViewModel.gameState;

        if (playerState == null || gameState == null) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiques Générales',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  context,
                  'Niveau',
                  playerState.level.toString(),
                  Icons.star,
                ),
                _buildStatRow(
                  context,
                  'Temps de jeu',
                  gameState.formattedPlayTime,
                  Icons.timer,
                ),
                _buildStatRow(
                  context,
                  'Trombones produits',
                  gameState.totalPaperclipsProduced.toString(),
                  Icons.attachment,
                ),
                _buildStatRow(
                  context,
                  'Argent gagné',
                  '${gameState.totalMoneyEarned.toStringAsFixed(2)}€',
                  Icons.attach_money,
                ),
                _buildStatRow(
                  context,
                  'Autoclippers',
                  playerState.autoclippers.toString(),
                  Icons.precision_manufacturing,
                ),
                _buildStatRow(
                  context,
                  'Production/s',
                  '${playerState.clipsPerSecond.toStringAsFixed(1)}',
                  Icons.speed,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
} 