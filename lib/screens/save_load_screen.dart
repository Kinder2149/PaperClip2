// lib/screens/save_load_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../services/save_manager.dart';
import '../main.dart';

class SaveLoadScreen extends StatelessWidget {
  const SaveLoadScreen({Key? key}) : super(key: key);

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parties sauvegardées'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: context.read<GameState>().listGames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final games = snapshot.data ?? [];

          if (games.isEmpty) {
            return const Center(child: Text('Aucune partie sauvegardée'));
          }

          return ListView.builder(
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              final lastSaveTime = game['lastSaveTime'] as DateTime;

              return ListTile(
                title: Text(game['name'] as String),
                subtitle: Text('Dernière sauvegarde: ${_formatDateTime(lastSaveTime)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () async {
                        await context.read<GameState>().loadGame(game['id'] as String);
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const MainGame()),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _showDeleteConfirmation(
                        context,
                        game['id'] as String,
                        game['name'] as String,
                      ),
                    ),
                  ],
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

  Future<void> _showDeleteConfirmation(
      BuildContext context,
      String gameId,
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
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await context.read<GameState>().deleteGame(gameId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partie supprimée')),
        );
      }
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
          MaterialPageRoute(builder: (context) => const MainGame()),
        );
      }
    }
  }
}