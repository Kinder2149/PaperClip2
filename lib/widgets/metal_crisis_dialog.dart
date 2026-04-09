import 'package:flutter/material.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:provider/provider.dart';

class MetalCrisisDialog extends StatelessWidget {
  const MetalCrisisDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context, gameState),
    );
  }

  Widget _buildDialogContent(BuildContext context, GameState gameState) {
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
          const Text(
            'Crise de métal!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Vous avez épuisé vos réserves de métal et n\'avez plus d\'argent pour en acheter. Que souhaitez-vous faire?',
            style: TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildCrisisActions(context, gameState),
        ],
      ),
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
