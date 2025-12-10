import 'package:flutter/material.dart';
import 'package:paperclip2/constants/game_config.dart'; // Importé depuis constants au lieu de models
import 'package:paperclip2/models/game_state.dart';
import 'package:provider/provider.dart';

class MetalCrisisDialog extends StatelessWidget {
  const MetalCrisisDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final isCompetitiveMode = gameState.gameMode == GameMode.COMPETITIVE;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context, gameState, isCompetitiveMode),
    );
  }

  Widget _buildDialogContent(BuildContext context, GameState gameState, bool isCompetitiveMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            isCompetitiveMode ? 'Fin de partie!' : 'Crise de métal!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isCompetitiveMode
                ? 'Vous avez atteint la fin de votre partie compétitive. Votre score final est calculé en fonction de votre production de trombones et du temps mis.'
                : 'Vous avez épuisé vos réserves de métal et n\'avez plus d\'argent pour en acheter. Que souhaitez-vous faire?',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (isCompetitiveMode) ...[
            _buildCompetitiveActions(context, gameState),
          ] else ...[
            _buildCrisisActions(context, gameState),
          ],
        ],
      ),
    );
  }

  Widget _buildCompetitiveActions(BuildContext context, GameState gameState) {
    return Column(
      children: [
        Text(
          'Score: ${gameState.calculateCompetitiveScore()}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {
            gameState.handleCompetitiveGameEnd();
            Navigator.of(context).pop();
          },
          child: const Text('Terminer la partie'),
        ),
      ],
    );
  }

  Widget _buildCrisisActions(BuildContext context, GameState gameState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red.shade800,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () {
            // Fermer le dialogue et continuer la partie
            Navigator.of(context).pop();
          },
          child: const Text('Continuer'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () {
            // Vendre tous les trombones pour récupérer de l'argent
            // Puis fermer le dialogue
            //gameState.sellAllPaperclips();
            Navigator.of(context).pop();
          },
          child: const Text('Vendre tout'),
        ),
      ],
    );
  }
}
