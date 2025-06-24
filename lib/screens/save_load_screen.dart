// Continuation de lib/screens/save_load_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import 'package:paperclip2/screens/main_screen.dart';
import 'package:paperclip2/services/save_manager.dart';
import '../widgets/cards/info_card.dart';
import '../widgets/indicators/stat_indicator.dart';
import '../widgets/dialogs/info_dialog.dart';

class SaveLoadScreen extends StatefulWidget {
  const SaveLoadScreen({Key? key}) : super(key: key);

  @override
  State<SaveLoadScreen> createState() => _SaveLoadScreenState();
}

enum SaveFilter {
  ALL,
  COMPETITIVE,
  INFINITE
}

class _SaveLoadScreenState extends State<SaveLoadScreen> {
  // Ajouter une clé pour forcer le rafraîchissement du FutureBuilder
  Key _futureBuilderKey = UniqueKey();
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  // Variables d'état
  SaveFilter _currentFilter = SaveFilter.ALL;

  List<SaveGameInfo> _filterSaves(List<SaveGameInfo> saves) {
    switch (_currentFilter) {
      case SaveFilter.COMPETITIVE:
        return saves.where((save) => save.gameMode == GameMode.COMPETITIVE).toList();
      case SaveFilter.INFINITE:
        return saves.where((save) => save.gameMode == GameMode.INFINITE).toList();
      case SaveFilter.ALL:
      default:
        return saves;
    }
  }

  // Méthode pour charger une sauvegarde
  Future<void> _loadGame(BuildContext context, SaveGameInfo saveInfo) async {
    try {
      final gameState = Provider.of<GameState>(context, listen: false);

      // Chargement normal
      await gameState.loadGame(saveInfo.name);

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
        title: const Text('Sauvegardes'),
        elevation: 0,
        actions: [
          // Menu de filtres
          PopupMenuButton<SaveFilter>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrer les sauvegardes',
            onSelected: (filter) {
              setState(() {
                _currentFilter = filter;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SaveFilter.ALL,
                child: Text('Toutes les sauvegardes'),
              ),
              const PopupMenuItem(
                value: SaveFilter.COMPETITIVE,
                child: Text('Mode Compétitif'),
              ),
              const PopupMenuItem(
                value: SaveFilter.INFINITE,
                child: Text('Mode Infini'),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<SaveGameInfo>>(
        key: _futureBuilderKey,
        future: SaveManager.listSaves(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ],
              ),
            );
          }

          final allSaves = snapshot.data ?? [];
          final filteredSaves = _filterSaves(allSaves);

          if (filteredSaves.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _currentFilter == SaveFilter.ALL
                        ? 'Aucune sauvegarde'
                        : 'Aucune sauvegarde correspondant au filtre',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Afficher le filtre actif
              if (_currentFilter != SaveFilter.ALL)
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.filter_list, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Filtre: ${_currentFilter.toString().split('.').last}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _currentFilter = SaveFilter.ALL;
                          });
                        },
                        child: const Icon(Icons.close, size: 16),
                      ),
                    ],
                  ),
                ),

              // Liste des sauvegardes
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredSaves.length,
                  itemBuilder: (context, index) {
                    final save = filteredSaves[index];
                    return _buildSaveCard(save, context);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewGameDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Partie'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  Widget _buildSaveCard(SaveGameInfo save, BuildContext context) {
    final bool isCompetitive = save.gameMode == GameMode.COMPETITIVE;

    Map<String, String> details = {
      'Dernière sauvegarde': _formatDateTime(save.timestamp),
      'Trombones': save.paperclips.toStringAsFixed(0),
      'Argent': '${save.money.toStringAsFixed(2)}€',
    };

    List<Widget> actions = [
      TextButton.icon(
        onPressed: () => _loadGame(context, save),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Charger'),
      ),
      TextButton.icon(
        onPressed: () => _confirmDelete(context, save.name),
        icon: Icon(Icons.delete, color: Colors.red[400]),
        label: Text('Supprimer', style: TextStyle(color: Colors.red[400])),
      ),
    ];

    // Créer une carte avec Padding pour les marges
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InfoCard(
        title: save.name,
        tooltip: isCompetitive ? 'Mode Compétitif' : 'Mode Infini',
        icon: isCompetitive ? Icons.emoji_events : Icons.save,
        // Utiliser le contenu personnalisé pour les détails
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: details.entries.map((entry) => Text('${entry.key}: ${entry.value}', style: TextStyle(fontSize: 12))).toList(),
            ),
            const SizedBox(width: 12),
            // Ajouter les actions comme partie du trailing widget
            Column(
              mainAxisSize: MainAxisSize.min,
              children: actions,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        value: '${save.paperclips.toStringAsFixed(0)} clips',  // Utiliser une valeur significative
        iconColor: isCompetitive ? Colors.amber.shade800 : Colors.blue,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: StatIndicator(
        label: label,
        value: value,
        icon: icon,
        layout: StatIndicatorLayout.horizontal,
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14.0),
        valueStyle: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
        iconColor: Colors.grey[600],
        iconSize: 16.0,
        spaceBetween: 8.0,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String gameName) async {
    final result = await InfoDialog.show(
      context,
      title: 'Supprimer la partie ?',
      message: 'Voulez-vous vraiment supprimer la partie "$gameName" ?',
      closeButtonLabel: 'CONFIRMER',
      additionalActions: [TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('ANNULER'),
      )],
      content: Icon(Icons.delete, color: Colors.red, size: 48),
      onClose: null, // On supprime le onClose car on va gérer la suppression après la vérification du résultat
    );
    
    // Si l'utilisateur a confirmé la suppression
    if (result) {
      await SaveManager.deleteSave(gameName);
      _refreshSaves();
    }
  }

  Future<void> _showNewGameDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: 'Partie ${DateTime.now().day}/${DateTime.now().month}',
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: Colors.deepPurple[400]),
            const SizedBox(width: 8),
            const Text('Nouvelle Partie'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nom de la partie',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.drive_file_rename_outline),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Donnez un nom à votre nouvelle partie',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    ).then((result) async {
      if (result != null && result.isNotEmpty && context.mounted) {
        await context.read<GameState>().startNewGame(result);
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      }
    });
  }
}