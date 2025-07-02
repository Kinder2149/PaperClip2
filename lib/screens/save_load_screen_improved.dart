// lib/screens/save_load_screen_improved.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../screens/main_screen.dart';
import '../services/save_manager_improved.dart';
import '../widgets/cards/info_card.dart';
import '../widgets/indicators/stat_indicator.dart';
import '../widgets/dialogs/info_dialog.dart';
import '../services/notification_storage_service.dart';
import '../widgets/resources/resource_widgets.dart';

/// Écran de gestion des sauvegardes avec logique UI/métier séparée
class SaveLoadScreen extends StatefulWidget {
  const SaveLoadScreen({Key? key}) : super(key: key);

  @override
  State<SaveLoadScreen> createState() => _SaveLoadScreenState();
}

/// Filtre pour les sauvegardes
enum SaveFilter {
  ALL,
  COMPETITIVE,
  INFINITE
}

/// État de l'écran de sauvegarde/chargement
class _SaveLoadScreenState extends State<SaveLoadScreen> {
  // Clé pour forcer le rafraîchissement du FutureBuilder
  Key _futureBuilderKey = UniqueKey();
  
  // État du filtre
  SaveFilter _currentFilter = SaveFilter.ALL;

  @override
  void initState() {
    super.initState();
    // Initialisation si nécessaire
  }

  // Formater une date pour l'affichage
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
  
  // Utilisez la méthode de formatage existante de MoneyDisplay

  // Filtrer les sauvegardes selon le filtre actif
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

  // Rafraîchir la liste des sauvegardes
  void _refreshSaves() {
    setState(() {
      _futureBuilderKey = UniqueKey(); // Force le rebuild
    });
  }

  // INTERFACE DE SERVICE : Actions sur les sauvegardes (logique métier)
  // Ces méthodes servent d'interface entre l'UI et le SaveManager

  /// Charge une sauvegarde et navigue vers l'écran principal
  Future<void> _handleLoadGame(BuildContext context, SaveGameInfo saveInfo) async {
    try {
      // Afficher un indicateur de chargement
      _showLoadingDialog(context, 'Chargement de la partie...');

      // Obtenir l'état du jeu
      final gameState = Provider.of<GameState>(context, listen: false);
      
      // Charger la sauvegarde (opération potentiellement longue)
      await gameState.loadGame(saveInfo.name);

      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.of(context).pop(); // Fermer le dialogue de chargement
      }

      // Naviguer vers l'écran principal
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Afficher l'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Crée une nouvelle partie et navigue vers l'écran principal
  Future<void> _handleCreateNewGame(BuildContext context, String gameName) async {
    try {
      // Afficher un indicateur de chargement
      _showLoadingDialog(context, 'Création de la partie...');

      // Obtenir l'état du jeu
      final gameState = context.read<GameState>();
      
      // Créer une nouvelle partie
      await gameState.startNewGame(gameName);

      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.of(context).pop(); // Fermer le dialogue de chargement
      }

      // Naviguer vers l'écran principal
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Afficher l'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Supprime une sauvegarde après confirmation
  Future<void> _handleDeleteSave(BuildContext context, String gameName) async {
    final confirmed = await _showDeleteConfirmDialog(context, gameName);
    
    if (confirmed) {
      try {
        await SaveManager.deleteSave(gameName);
        _refreshSaves();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // DIALOGS ET UI HELPERS : Composants réutilisables pour l'UI
  
  /// Affiche un dialogue de confirmation pour la suppression
  Future<bool> _showDeleteConfirmDialog(BuildContext context, String gameName) async {
    final result = await InfoDialog.show(
      context,
      title: 'Supprimer la partie ?',
      message: 'Voulez-vous vraiment supprimer la partie "$gameName" ?',
      closeButtonLabel: 'CONFIRMER',
      additionalActions: [TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('ANNULER'),
      )],
      content: const Icon(Icons.delete, color: Colors.red, size: 48),
    );
    
    return result ?? false;
  }

  /// Affiche un dialogue pour créer une nouvelle partie
  Future<void> _showNewGameDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: 'Partie ${DateTime.now().day}/${DateTime.now().month}',
    );

    final result = await showDialog<String>(
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
    );

    // Si un nom a été saisi, créer la partie
    if (result != null && result.isNotEmpty && context.mounted) {
      await _handleCreateNewGame(context, result);
    }
  }

  /// Affiche un dialogue de chargement
  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  // CONSTRUCTION DES WIDGETS : Construction de l'UI

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
      body: Column(
        children: [
          Expanded(
            child: _buildSavesList(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewGameDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle partie'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  /// Construit la liste des sauvegardes
  Widget _buildSavesList(BuildContext context) {
    return FutureBuilder<List<SaveGameInfo>>(
      key: _futureBuilderKey,
      future: SaveManager.listSaves(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshSaves,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final saves = snapshot.data ?? [];
        final filteredSaves = _filterSaves(saves);

        if (filteredSaves.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_open, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Aucune sauvegarde trouvée',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                if (_currentFilter != SaveFilter.ALL) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentFilter = SaveFilter.ALL;
                      });
                    },
                    child: const Text('Afficher toutes les sauvegardes'),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _refreshSaves();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: filteredSaves.length,
            itemBuilder: (context, index) {
              final save = filteredSaves[index];
              return _buildSaveCard(save, context);
            },
          ),
        );
      },
    );
  }

  /// Construit une carte pour une sauvegarde
  Widget _buildSaveCard(SaveGameInfo save, BuildContext context) {
    // Déterminer la couleur en fonction du mode de jeu
    final Color cardColor = save.gameMode == GameMode.COMPETITIVE
        ? Colors.orange.withOpacity(0.1)
        : Colors.blue.withOpacity(0.1);

    // Vérifier si c'est une sauvegarde de backup
    final bool isBackup = save.name.contains('_backup_');
    final String displayName = isBackup
        ? '${save.name.split('_backup_')[0]} (Backup)'
        : save.name;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: save.gameMode == GameMode.COMPETITIVE
              ? Colors.orange.withOpacity(0.5)
              : Colors.blue.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _handleLoadGame(context, save),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom et date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          save.gameMode == GameMode.COMPETITIVE
                              ? Icons.timer
                              : Icons.repeat,
                          color: save.gameMode == GameMode.COMPETITIVE
                              ? Colors.orange[700]
                              : Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDateTime(save.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              
              // Statistiques (mise à jour pour afficher les ventes et autoclippers)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoRow(
                    'Vendus',
                    MoneyDisplay.formatNumber(save.totalPaperclipsSold.toDouble(), isInteger: true).replaceAll(' €', ''),
                    Icons.shopping_cart,
                  ),
                  _buildInfoRow(
                    'Autoclippers',
                    '${save.autoclippers}',
                    Icons.smart_toy,
                  ),
                ],
              ),
              
              // Version et boutons
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'v${save.version}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                    Row(
                      children: [
                        if (!isBackup) IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Supprimer',
                          onPressed: () => _handleDeleteSave(context, save.name),
                          iconSize: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          tooltip: 'Charger',
                          onPressed: () => _handleLoadGame(context, save),
                          color: Colors.green,
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit une ligne d'information
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: StatIndicator(
        label: label,
        value: value,
        icon: icon,
        layout: StatIndicatorLayout.horizontal,
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14.0),
        valueStyle: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
        iconColor: Colors.grey[600],
        iconSize: 16.0,
        spaceBetween: 8.0,
      ),
    );
  }
}
