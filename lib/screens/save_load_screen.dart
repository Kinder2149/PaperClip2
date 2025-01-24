import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../services/save_manager.dart';
import '../models/game_config.dart';
import 'package:paperclip2/screens/main_screen.dart';

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
      body: Consumer<GameState>(
        builder: (context, gameState, child) {
          return FutureBuilder<List<SaveGame>>(
            future: SaveManager.getAllSaves(),
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
                  // Récupération des données de sauvegarde
                  final paperclips = game.gameData['paperclips'] ?? 0;
                  final money = game.gameData['money'] ?? 0;
                  final metal = game.gameData['metal'] ?? 0;
                  final autoclippers = game.gameData['autoclippers'] ?? 0;
                  final level = (game.gameData['levelSystem'] as Map<String, dynamic>?)?['level'] ?? 1;
                  final totalPaperclips = game.gameData['totalPaperclipsProduced'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ExpansionTile(
                      title: Text(game.name),
                      subtitle: Text('Niveau ${level.toString()} - ${_formatDateTime(game.lastSaveTime)}'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Trombones', paperclips.toStringAsFixed(0)),
                              _buildInfoRow('Argent', '${money.toStringAsFixed(2)} €'),
                              _buildInfoRow('Métal', '${metal.toStringAsFixed(1)} unités'),
                              _buildInfoRow('Autoclippeuses', autoclippers.toString()),
                              _buildInfoRow('Production totale', totalPaperclips.toString()),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Charger'),
                                    onPressed: () async {
                                      try {
                                        await gameState.loadGame(game.name);
                                        if (context.mounted) {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (context) => const MainScreen()),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Erreur: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Supprimer'),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    onPressed: () => _showDeleteConfirmation(context, game.name),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
      await SaveManager.deleteGame(gameName);
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
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }
}