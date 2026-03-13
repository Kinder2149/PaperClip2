// lib/widgets/indicators/competitive_mode_indicator.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import '../../constants/game_config.dart'; // Importé depuis constants au lieu de models

class _CompetitiveIndicatorView {
  final GameMode gameMode;
  final Duration playTime;

  const _CompetitiveIndicatorView({
    required this.gameMode,
    required this.playTime,
  });

  @override
  bool operator ==(Object other) {
    return other is _CompetitiveIndicatorView &&
        other.gameMode == gameMode &&
        other.playTime == playTime;
  }

  @override
  int get hashCode => Object.hash(gameMode, playTime);
}

class CompetitiveModeIndicator extends StatelessWidget {
  const CompetitiveModeIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, _CompetitiveIndicatorView>(
      selector: (context, gameState) => _CompetitiveIndicatorView(
        gameMode: gameState.gameMode,
        playTime: gameState.competitivePlayTime,
      ),
      builder: (context, view, child) {
        // Ne rien afficher si ce n'est pas le mode compétitif
        if (view.gameMode != GameMode.COMPETITIVE) {
          return const SizedBox.shrink();
        }

        final String formattedTime = _formatDuration(view.playTime);

        return GestureDetector(
          onTap: () => _showCompetitiveInfo(context, context.read<GameState>()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCompetitiveInfo(BuildContext context, GameState gameState) {
    // Calculer le score actuel
    final int currentScore = gameState.calculateCompetitiveScore();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: Colors.amber.shade700,
            ),
            const SizedBox(width: 8),
            const Text('Mode Compétitif'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score actuel: $currentScore'),
            const SizedBox(height: 8),
            Text('Temps écoulé: ${_formatDuration(gameState.competitivePlayTime)}'),
            const SizedBox(height: 16),
            const Text(
              'Objectif: Maximiser votre score avant l\'épuisement du métal mondial.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            Text(
              'Stock mondial restant: ${gameState.marketManager.marketMetalStock.toStringAsFixed(1)} / ${GameConstants.INITIAL_MARKET_METAL}',
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: gameState.marketManager.marketMetalStock / GameConstants.INITIAL_MARKET_METAL,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getColorForRemainingMetal(gameState.marketManager.marketMetalStock / GameConstants.INITIAL_MARKET_METAL),
              ),
            ),
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

  Color _getColorForRemainingMetal(double ratio) {
    if (ratio < 0.2) {
      return Colors.red;
    } else if (ratio < 0.5) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    int seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}