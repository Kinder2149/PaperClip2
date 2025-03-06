import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/game_viewmodel.dart';

class SaveList extends StatelessWidget {
  const SaveList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameViewModel>(
      builder: (context, gameViewModel, child) {
        final saves = gameViewModel.availableSaves;

        if (saves.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Aucune sauvegarde disponible',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sauvegardes Disponibles',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: saves.length,
                  itemBuilder: (context, index) {
                    final save = saves[index];
                    return _buildSaveItem(context, save, gameViewModel);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveItem(
    BuildContext context,
    GameSave save,
    GameViewModel gameViewModel,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.save),
        title: Text(save.name),
        subtitle: Text(
          'Dernière sauvegarde: ${_formatDate(save.lastSaveTime)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context, save, gameViewModel),
            ),
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: () => gameViewModel.loadSave(save.id),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    GameSave save,
    GameViewModel gameViewModel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer la sauvegarde "${save.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      gameViewModel.deleteSave(save.id);
    }
  }
} 