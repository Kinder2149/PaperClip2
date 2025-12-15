// lib/widgets/appbar/appbar_progress_indicator.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import '../../constants/game_config.dart'; // Importé depuis constants au lieu de models

class AppBarProgressIndicator extends StatelessWidget {
  const AppBarProgressIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, int>(
      selector: (context, gameState) => gameState.totalPaperclipsProduced,
      builder: (context, totalPaperclipsProduced, _) {
        final double progressValue =
            (totalPaperclipsProduced.toDouble() / GameConstants.GLOBAL_PROGRESS_TARGET)
                .clamp(0.0, 1.0);

        return GestureDetector(
          onTap: () => _showProgressDetails(context, context.read<GameState>()),
          child: Container(
            width: 45,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue.shade900
                  : Colors.blue.shade700,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    value: progressValue,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(
                          progressValue, Theme.of(context).brightness),
                    ),
                    strokeWidth: 3,
                  ),
                ),
                Text(
                  '${(progressValue * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Calcul de la progression globale du jeu
  double _calculateGlobalProgress(GameState gameState) {
    // Version simple: basée sur le nombre de trombones produits par rapport à un objectif
    double maxPaperclips = GameConstants.GLOBAL_PROGRESS_TARGET;
    double currentPaperclips = gameState.totalPaperclipsProduced.toDouble();
    
    // Limiter à 1.0 (100%)
    return (currentPaperclips / maxPaperclips).clamp(0.0, 1.0);
  }

  // Couleurs selon le pourcentage de progression
  Color _getProgressColor(double progress, Brightness brightness) {
    if (progress < 0.3) {
      return brightness == Brightness.dark ? Colors.redAccent : Colors.red;
    } else if (progress < 0.6) {
      return brightness == Brightness.dark ? Colors.amberAccent : Colors.amber;
    } else {
      return brightness == Brightness.dark ? Colors.greenAccent : Colors.green;
    }
  }

  // Affichage des détails de progression
  void _showProgressDetails(BuildContext context, GameState gameState) {
    final progress = _calculateGlobalProgress(gameState);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.insights),
            SizedBox(width: 8),
            Text('Progression Globale'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progression: ${(progress * 100).toInt()}%'),
            const SizedBox(height: 8),
            Text(
              'Trombones produits: ${gameState.totalPaperclipsProduced} / ${GameConstants.GLOBAL_PROGRESS_TARGET.toStringAsFixed(0)}'
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(progress, Theme.of(context).brightness)
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Continuez à produire des trombones pour progresser dans le jeu!',
              style: TextStyle(fontStyle: FontStyle.italic),
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
}
