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
      appBar: AppBar(
        title: const Text('Parties sauvegardées'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSaves,
          ),
          // Temporaire pour le débogage
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              final games = await SaveManager.getAllSaves();
              for (final game in games) {
                await SaveManager.debugSaveData(game.name);
              }
            },
          ),
        ],
      ),
      body: Consumer<GameState>(
        builder: (context, gameState, child) {
          return FutureBuilder<List<SaveGame>>(
            key: _futureBuilderKey, // Utiliser la clé ici
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
                  final playerManager = game.gameData['playerManager'] as Map<String, dynamic>? ?? {};

                  // Extraire les données avec sécurité
                  final paperclips = (playerManager['paperclips'] as num?)?.toDouble() ?? 0.0;
                  final money = (playerManager['money'] as num?)?.toDouble() ?? 0.0;
                  final metal = (playerManager['metal'] as num?)?.toDouble() ?? 0.0;
                  final autoclippers = playerManager['autoclippers'] as int? ?? 0;

                  // Récupérer le niveau
                  final levelSystem = game.gameData['levelSystem'] as Map<String, dynamic>? ?? {};
                  final level = levelSystem['level'] as int? ?? 1;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Theme(  // Ajoutez ce Theme pour s'assurer que l'ExpansionTile fonctionne
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: false,  // Assurez-vous que c'est initialement fermé
                        maintainState: true,       // Gardez l'état
                        title: Text(game.name),
                        subtitle: Text('${_formatDateTime(game.lastSaveTime)}'),
                        children: [_buildSaveDetails(game)],  // Extrayez les détails dans une méthode séparée
                      ),
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
  Widget _buildSaveDetails(SaveGame game) {
    // Accédez aux données de manière sécurisée
    final playerManager = game.gameData['gameData']?['playerManager'] as Map<String, dynamic>? ?? {};
    final paperclips = (playerManager['paperclips'] as num?)?.toDouble() ?? 0.0;
    final money = (playerManager['money'] as num?)?.toDouble() ?? 0.0;
    final metal = (playerManager['metal'] as num?)?.toDouble() ?? 0.0;
    final autoclippers = playerManager['autoclippers'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Trombones', paperclips.toStringAsFixed(0)),
          _buildInfoRow('Argent', '${money.toStringAsFixed(2)} €'),
          _buildInfoRow('Métal', '${metal.toStringAsFixed(1)} unités'),
          _buildInfoRow('Autoclippeuses', autoclippers.toString()),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Charger'),
                onPressed: () => _loadGame(game),
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
    );
  }
  Future<void> _loadGame(SaveGame game) async {
    try {
      final gameState = context.read<GameState>();
      await gameState.loadGame(game.name);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      print('Error loading game: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
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