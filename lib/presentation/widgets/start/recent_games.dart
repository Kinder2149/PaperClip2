import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/game_viewmodel.dart';

class RecentGames extends StatelessWidget {
  const RecentGames({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameViewModel>(
      builder: (context, gameViewModel, child) {
        final recentGames = gameViewModel.recentGames;

        if (recentGames.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parties Récentes',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentGames.length,
                  itemBuilder: (context, index) {
                    final game = recentGames[index];
                    return _buildGameItem(context, game, gameViewModel);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameItem(
    BuildContext context,
    GameSave game,
    GameViewModel gameViewModel,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.save),
        title: Text(game.name),
        subtitle: Text(
          'Dernière sauvegarde: ${_formatDate(game.lastSaveTime)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () => _loadGame(context, game, gameViewModel),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _loadGame(
    BuildContext context,
    GameSave game,
    GameViewModel gameViewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Charger la Partie'),
        content: Text('Voulez-vous charger la partie "${game.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              gameViewModel.loadSave(game.id);
            },
            child: const Text('Charger'),
          ),
        ],
      ),
    );
  }
} 