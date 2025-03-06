import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/game_viewmodel.dart';

class GameActions extends StatelessWidget {
  const GameActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameViewModel>(
      builder: (context, gameViewModel, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actions',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  context,
                  'Nouvelle Partie',
                  Icons.play_arrow,
                  Colors.green,
                  () => gameViewModel.startNewGame(),
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  context,
                  'Charger une Partie',
                  Icons.folder_open,
                  Colors.blue,
                  () => gameViewModel.loadRecentGame(),
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  context,
                  'Paramètres',
                  Icons.settings,
                  Colors.orange,
                  () => gameViewModel.openSettings(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          primary: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
} 