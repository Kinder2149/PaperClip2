import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/game_viewmodel.dart';

class NewSave extends StatelessWidget {
  const NewSave({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nouvelle Sauvegarde',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showNewSaveDialog(context),
              icon: const Icon(Icons.save),
              label: const Text('Créer une nouvelle sauvegarde'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNewSaveDialog(BuildContext context) async {
    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle Sauvegarde'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nom de la sauvegarde',
            hintText: 'Entrez un nom pour votre sauvegarde',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.of(context).pop(nameController.text);
              }
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );

    if (result != null) {
      context.read<GameViewModel>().createNewSave(result);
    }
  }
} 