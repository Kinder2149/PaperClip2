import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../services/save_manager.dart';
import '../models/game_config.dart';
import 'package:paperclip2/screens/main_screen.dart';

class SaveLoadScreen extends StatefulWidget {
  const SaveLoadScreen({Key? key}) : super(key: key);

  @override
  State<SaveLoadScreen> createState() => _SaveLoadScreenState();
}

class _SaveLoadScreenState extends State<SaveLoadScreen> {
  // Ajouter une clé pour forcer le rafraîchissement du FutureBuilder
  Key _futureBuilderKey = UniqueKey();
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  void _refreshSaves() {
    setState(() {
      _futureBuilderKey = UniqueKey(); // Créer une nouvelle clé force le rebuild
    });
  }
  Future<void> _createNewGame(BuildContext context, String gameName) async {
    try {
      print('Creating new game: $gameName');
      final gameState = context.read<GameState>();
      await gameState.startNewGame(gameName);
      print('Game created successfully');

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      print('Error creating game: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sauvegardes')),
      body: FutureBuilder<List<SaveGameInfo>>(
        future: SaveManager.listSaves(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          final saves = snapshot.data ?? [];
          if (saves.isEmpty) {
            return const Center(
              child: Text('Aucune sauvegarde'),
            );
          }

          return ListView.builder(
            itemCount: saves.length,
            itemBuilder: (context, index) {
              final save = saves[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(save.name),
                  subtitle: Text(
                      'Dernière sauvegarde: ${_formatDateTime(save.timestamp)}\n'
                          'Trombones: ${save.paperclips.toStringAsFixed(0)} | '
                          'Argent: ${save.money.toStringAsFixed(2)}€'
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _loadGame(context, save.name),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(context, save.name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewGameDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _loadGame(BuildContext context, String name) async {
    try {
      final gameState = Provider.of<GameState>(context, listen: false);
      await gameState.loadGame(name);

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context,
      String gameName,
      ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la partie ?'),
        content: Text('Voulez-vous vraiment supprimer la partie "$gameName" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await SaveManager.deleteSave(gameName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partie supprimée')),
        );
      }
    }
  }
  Future<void> _confirmDelete(BuildContext context, String gameName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la partie ?'),
        content: Text('Voulez-vous vraiment supprimer la partie "$gameName" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await SaveManager.deleteSave(gameName);
      _refreshSaves();
    }
  }


  Future<void> _showNewGameDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: 'Partie ${DateTime.now().day}/${DateTime.now().month}',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle partie'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom de la partie',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      await context.read<GameState>().startNewGame(result);
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }
}