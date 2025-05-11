// Continuation de lib/screens/save_load_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import 'package:paperclip2/screens/main_screen.dart';
import 'package:paperclip2/services/games_services_controller.dart';
import '../services/save/save_system.dart';
import '../services/save/save_types.dart';
import 'package:uuid/uuid.dart';
import '../widgets/app_bar/widget_appbar_jeu.dart';
import 'package:provider/provider.dart';
import '../services/save/save_system.dart';

class SaveLoadScreen extends StatefulWidget {
  const SaveLoadScreen({Key? key}) : super(key: key);

  @override
  State<SaveLoadScreen> createState() => _SaveLoadScreenState();
}

enum SaveFilter {
  ALL,
  LOCAL,
  CLOUD,
  COMPETITIVE,
  INFINITE
}

class _SaveLoadScreenState extends State<SaveLoadScreen> {
  // Ajouter une clé pour forcer le rafraîchissement du FutureBuilder
  Key _futureBuilderKey = UniqueKey();
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
  late SaveSystem _saveSystem;
  // Variables d'état
  SaveFilter _currentFilter = SaveFilter.ALL;
  bool _isSyncing = false;
  bool _isLoading = false;

  List<SaveGameInfo> _filterSaves(List<SaveGameInfo> saves) {
    switch (_currentFilter) {
      case SaveFilter.LOCAL:
        return saves.where((save) => !save.isSyncedWithCloud).toList();
      case SaveFilter.CLOUD:
        return saves.where((save) => save.isSyncedWithCloud).toList();
      case SaveFilter.COMPETITIVE:
        return saves.where((save) => save.gameMode == GameMode.COMPETITIVE).toList();
      case SaveFilter.INFINITE:
        return saves.where((save) => save.gameMode == GameMode.INFINITE).toList();
      case SaveFilter.ALL:
      default:
        return saves;
    }
  }

  Future<void> _syncSaves() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final gamesServices = GamesServicesController();
      final isSignedIn = await gamesServices.isSignedIn();

      if (!isSignedIn) {
        await gamesServices.signIn();
      }

      final success = await gamesServices.syncSaves();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Sauvegardes synchronisées avec succès'
                : 'Échec de la synchronisation des sauvegardes'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        // Rafraîchir la liste
        _refreshSaves();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la synchronisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  // Méthode pour charger une sauvegarde
  Future<void> _loadGame(BuildContext context, SaveGameInfo saveInfo) async {
    try {
      final gameState = Provider.of<GameState>(context, listen: false);

      // Si c'est une sauvegarde cloud sans version locale, la télécharger d'abord
      if (saveInfo.isSyncedWithCloud && saveInfo.cloudId != null && !await _saveSystem.exists(saveInfo.name)) {
        final gamesServices = GamesServicesController();
        final cloudSave = await gamesServices.loadGameFromCloud(saveInfo.cloudId!);

        if (cloudSave != null) {
          await _saveSystem.saveGame(cloudSave);
        } else {
          throw SaveError('CLOUD_ERROR', 'Impossible de charger la sauvegarde depuis le cloud');
        }
      }

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
      // Utilisation du widget AppBar personnalisé
      appBar: WidgetAppBarJeu(
        title: 'Sauvegardes',
        elevation: 0,
        showLevelIndicator: false, // Pas besoin d'indicateur de niveau ici
        additionalActions: [
          // Bouton de synchronisation
          IconButton(
            icon: _isSyncing
                ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            )
                : const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _syncSaves,
            tooltip: 'Synchroniser avec le cloud',
          ),
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
                value: SaveFilter.LOCAL,
                child: Text('Sauvegardes locales'),
              ),
              const PopupMenuItem(
                value: SaveFilter.CLOUD,
                child: Text('Sauvegardes cloud'),
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
        showSettings: false, // On n'a pas besoin du bouton settings ici
      ),
      body: FutureBuilder<List<SaveGameInfo>>(
        key: _futureBuilderKey,
        future: _saveSystem.listSaves(),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCompetitive
            ? BorderSide(color: Colors.amber.shade700, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _loadGame(context, save),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icône différente selon le type de sauvegarde
                  Icon(
                    isCompetitive
                        ? Icons.emoji_events
                        : Icons.save,
                    color: isCompetitive
                        ? Colors.amber.shade700
                        : Colors.deepPurple[400],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      save.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Indicateur de synchronisation cloud
                  if (save.isSyncedWithCloud)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Tooltip(
                        message: 'Sauvegarde synchronisée avec le cloud',
                        child: Icon(
                          Icons.cloud_done,
                          color: Colors.blue[400],
                          size: 20,
                        ),
                      ),
                    ),

                  // Menu d'options
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'load',
                        child: Row(
                          children: const [
                            Icon(Icons.play_arrow),
                            SizedBox(width: 8),
                            Text('Charger'),
                          ],
                        ),
                      ),
                      // Option de synchronisation cloud pour les sauvegardes non synchronisées
                      if (!save.isSyncedWithCloud)
                        PopupMenuItem(
                          value: 'cloud_sync',
                          child: Row(
                            children: [
                              Icon(Icons.cloud_upload, color: Colors.blue[400]),
                              const SizedBox(width: 8),
                              const Text('Synchroniser'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red[400]),
                            const SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(color: Colors.red[400])),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'load') {
                        _loadGame(context, save);
                      } else if (value == 'cloud_sync') {
                        // Synchroniser avec le cloud
                        final gamesServices = GamesServicesController();
                        if (await gamesServices.isSignedIn()) {
                          // Charger la sauvegarde complète
                          final fullSave = await _saveSystem.loadGame(save.name);
                          if (fullSave != null) {
                            final success = await gamesServices.saveGameToCloud(fullSave);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? 'Sauvegarde synchronisée avec succès'
                                      : 'Échec de la synchronisation'),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );
                              _refreshSaves();
                            }
                          }
                        } else {
                          // Demander la connexion
                          await gamesServices.signIn();
                        }
                      } else if (value == 'delete') {
                        _confirmDelete(context, save.name);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Dernière sauvegarde',
                _formatDateTime(save.timestamp),
                Icons.access_time,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      'Trombones',
                      save.paperclips.toStringAsFixed(0),
                      Icons.shopping_cart,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoRow(
                      'Argent',
                      '${save.money.toStringAsFixed(2)}€',
                      Icons.euro,
                    ),
                  ),
                ],
              ),
              // Affichage du mode de jeu
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompetitive
                      ? Colors.amber.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isCompetitive
                        ? Colors.amber.shade300
                        : Colors.blue.shade300,
                    width: 1,
                  ),
                ),
                child: Text(
                  isCompetitive ? 'Mode Compétitif' : 'Mode Infini',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompetitive
                        ? Colors.amber.shade800
                        : Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
      await _saveSystem.deleteSave(gameName);
      _refreshSaves();
    }
  }

  void _showNewGameDialog(BuildContext context) {
    final controller = TextEditingController(
      text: 'Partie ${DateTime.now().day}/${DateTime.now().month}',
    );

    // Variable pour suivre le mode sélectionné
    GameMode selectedMode = GameMode.INFINITE;
    bool syncToCloud = false; // Valeur par défaut

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
          content: SingleChildScrollView(
            child: Column(
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

                // Option pour sélectionner le mode de jeu
                const Text(
                  'Mode de jeu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioListTile<GameMode>(
                  title: const Text('Mode Infini'),
                  subtitle: const Text('Jouez sans limite de temps'),
                  value: GameMode.INFINITE,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    setState(() => selectedMode = value!);
                  },
                ),
                RadioListTile<GameMode>(
                  title: const Text('Mode Compétitif'),
                  subtitle: const Text('Optimisez pour un meilleur score'),
                  value: GameMode.COMPETITIVE,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    setState(() => selectedMode = value!);
                  },
                ),

                // FutureBuilder pour vérifier si Google Play Games est connecté
                FutureBuilder<bool>(
                  future: GamesServicesController().isSignedIn(),
                  builder: (context, snapshot) {
                    final isSignedIn = snapshot.data ?? false;

                    if (isSignedIn) {
                      return SwitchListTile(
                        title: const Text('Synchroniser avec le cloud'),
                        value: syncToCloud,
                        onChanged: (value) {
                          setState(() => syncToCloud = value);
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                const SizedBox(height: 8),
                Text(
                  'Cette action créera une nouvelle sauvegarde',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final gameName = controller.text.trim();
                if (gameName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le nom ne peut pas être vide')),
                  );
                  return;
                }

                // Retourner un objet avec les informations de la nouvelle partie
                Navigator.pop(context, {
                  'name': gameName,
                  'mode': selectedMode,
                  'sync': syncToCloud,
                });
              },
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
      ),
    ).then((result) async {
      if (result != null && context.mounted) {
        try {
          final gameName = result['name'];
          final gameMode = result['mode'] as GameMode;
          final syncToCloud = result['sync'] as bool;

          // Vérifier si le profil peut créer une partie compétitive
          if (gameMode == GameMode.COMPETITIVE) {
            // TODO: Ajouter la vérification avec le UserManager
          }

          setState(() => _isLoading = true);

          await context.read<GameState>().startNewGame(
              gameName,
              mode: gameMode,
              syncToCloud: syncToCloud
          );

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
                content: Text('Erreur lors de la création: $e'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isLoading = false);
          }
        }
      }
    });
  }
}