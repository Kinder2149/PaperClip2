import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/game_viewmodel.dart';

class StartActions extends StatelessWidget {
  const StartActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              () => _startNewGame(context),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              'Charger une Partie',
              Icons.folder_open,
              Colors.blue,
              () => _loadGame(context),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              'Paramètres',
              Icons.settings,
              Colors.orange,
              () => _openSettings(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        primary: color,
        onPrimary: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _startNewGame(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle Partie'),
        content: const Text('Êtes-vous sûr de vouloir commencer une nouvelle partie ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<GameViewModel>().startNewGame();
            },
            child: const Text('Commencer'),
          ),
        ],
      ),
    );
  }

  void _loadGame(BuildContext context) {
    Navigator.of(context).pushNamed('/save-load');
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/settings');
  }
} 