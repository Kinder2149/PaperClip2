// lib/screens/save_load_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../controllers/game_session_controller.dart';
import '../constants/game_config.dart';
import '../screens/main_screen.dart';
import '../services/save_system/save_manager_adapter.dart';
import '../services/save_migration_service.dart';
import '../widgets/cards/info_card.dart';
import '../widgets/indicators/stat_indicator.dart';
import '../widgets/dialogs/info_dialog.dart';
import '../services/notification_storage_service.dart';
import '../widgets/resources/resource_widgets.dart';
import '../services/save_game.dart' show SaveGameInfo; // Importer la classe unifiée SaveGameInfo
import '../widgets/save_button.dart';
import '../services/notification_manager.dart'; // Ajout de l'import pour NotificationManager

// La classe SaveGameInfo est maintenant importée depuis save_game.dart

/// Écran de gestion des sauvegardes
class SaveLoadScreen extends StatefulWidget {
  final bool isStartScreen;

  const SaveLoadScreen({Key? key, this.isStartScreen = false}) : super(key: key);

  @override
  _SaveLoadScreenState createState() => _SaveLoadScreenState();
}

class _SaveLoadScreenState extends State<SaveLoadScreen> {
  List<SaveGameInfo> _saves = [];
  bool _loading = true;
  bool _isMigrating = false;
  int _migrationMigrated = 0;
  int _migrationTotal = 0;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSaves();
  }

  Future<void> _loadSaves() async {
    setState(() => _loading = true);
    
    try {
      if (kDebugMode) {
        print('SaveLoadScreen._loadSaves: Chargement des sauvegardes...');
      }

      // Migration lazy: exécuter une migration progressive uniquement au moment où
      // l'utilisateur accède à l'écran des sauvegardes.
      final migrationSw = Stopwatch()..start();
      setState(() {
        _isMigrating = true;
        _migrationMigrated = 0;
        _migrationTotal = 0;
      });

      final migrationResult = await SaveMigrationService.migrateLegacySavesIfNeeded(
        maxToMigrate: 10,
        onProgress: (migrated, total) {
          if (!mounted) return;
          setState(() {
            _migrationMigrated = migrated;
            _migrationTotal = total;
          });
        },
      );
      migrationSw.stop();

      if (kDebugMode) {
        print(
          'SaveLoadScreen._loadSaves: Migration lazy terminée '
          '(scannées=${migrationResult.scannedCount}, ok=${migrationResult.successCount}, '
          'fail=${migrationResult.failureCount}, durée=${migrationSw.elapsed})',
        );
      }

      if (mounted) {
        setState(() {
          _isMigrating = false;
        });
      }
      
      // S'assurer que SaveManagerAdapter est correctement initialisé
      await SaveManagerAdapter.ensureInitialized();
      print('SaveLoadScreen._loadSaves: SaveManagerAdapter initialisé');
      
      // NOUVEAU: Vérifier l'état du cache dans LocalSaveGameManager
      print('DIAGNOSTIC SAVE SCREEN: Vérification directe du cache des métadonnées...');
      final sharedPrefs = await SharedPreferences.getInstance();
      final allKeys = sharedPrefs.getKeys();
      final metadataKeys = allKeys.where((key) => key.startsWith('save_metadata_')).toList();
      print('DIAGNOSTIC SAVE SCREEN: Nombre de métadonnées dans SharedPrefs: ${metadataKeys.length}');
      if (metadataKeys.isNotEmpty) {
        print('DIAGNOSTIC SAVE SCREEN: Premières clés trouvées: ${metadataKeys.take(3).join(", ")}');
      }
      
      // Vérifier s'il existe une dernière sauvegarde (pour diagnostic)
      final lastSave = await SaveManagerAdapter.getLastSave();
      if (kDebugMode) {
        if (lastSave != null) {
          print('DIAGNOSTIC SAVE SCREEN: getLastSave a trouvé une sauvegarde: "${lastSave.name}", ID: ${lastSave.id}');
        } else {
          print('DIAGNOSTIC SAVE SCREEN: getLastSave n\'a trouvé AUCUNE sauvegarde');
        }
      }
      
      // Récupérer les sauvegardes
      print('SaveLoadScreen._loadSaves: Appel de SaveManagerAdapter.listSaves()');
      final saves = await SaveManagerAdapter.listSaves();
      
      if (kDebugMode) {
        print('DIAGNOSTIC SAVE SCREEN: ${saves.length} sauvegardes récupérées de SaveManagerAdapter.listSaves()');
        if (saves.isEmpty) {
          print('DIAGNOSTIC SAVE SCREEN: La liste des sauvegardes est VIDE!');
          print('DIAGNOSTIC SAVE SCREEN: Détail complet du retour: $saves');
        } else {
          print('DIAGNOSTIC SAVE SCREEN: Détail des sauvegardes trouvées:');
          for (var save in saves) {
            print('  - Save: "${save.name}", ID: ${save.id}, date: ${save.lastModified}');
            print('    Type: ${save.runtimeType}, isBackup: ${save.isBackup}, money: ${save.money}, paperclips: ${save.paperclips}');
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _saves = saves;
          _loading = false;
        });
        // Nouveau log après setState pour confirmer que _saves a été mis à jour
        print('DIAGNOSTIC SAVE SCREEN: État mis à jour, _saves contient ${_saves.length} sauvegardes');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SaveLoadScreen._loadSaves: ERREUR: $e');
        print('DIAGNOSTIC Stack trace: $e\n${StackTrace.current}');
      }
      
      if (mounted) {
        setState(() {
          _loading = false;
          _isMigrating = false;
        });
        _showError('Erreur lors du chargement des sauvegardes: $e');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    NotificationManager.instance.showNotification(
      message: message,
      level: NotificationLevel.ERROR
    );
  }

  Future<void> _deleteSave(String saveId) async {
    try {
      await SaveManagerAdapter.deleteSaveByName(saveId);
      await _loadSaves();
      if (mounted) {
        NotificationManager.instance.showNotification(
          message: 'Sauvegarde supprimée',
          level: NotificationLevel.SUCCESS,
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur lors de la suppression: $e');
      }
    }
  }

  Future<void> _loadGame(BuildContext context, String name) async {
    try {
      final saveGame = await SaveManagerAdapter.loadGame(name);
      if (saveGame == null) {
        if (mounted) {
          _showError('Impossible de charger la sauvegarde');
        }
        return;
      }

      final gameState = context.read<GameState>();
      final gameSessionController = context.read<GameSessionController>();
      await gameState.loadGame(name); // Utiliser loadGame directement

      // Option A: démarrer la boucle de jeu uniquement quand une partie est active.
      gameSessionController.startSession();

      if (mounted) {
        // Notification de chargement réussi
        NotificationStorageService().addMessage(
          'Partie chargée: $name',
          EventType.INFO
        );
        
        // Navigation vers l'écran principal
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainScreen())
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur lors du chargement: $e');
      }
    }
  }

  Future<void> _restoreFromBackup(BuildContext context, String backupName) async {
    // Extraire le nom original de la sauvegarde à partir du nom du backup
    final parts = backupName.split(GameConstants.BACKUP_DELIMITER);
    if (parts.isEmpty) return;
    
    final originalSaveName = parts[0];
    final gameState = context.read<GameState>();
    
    try {
      final success = await SaveManagerAdapter.restoreFromBackup(backupName, gameState);
      
      if (success) {
        if (mounted) {
          NotificationStorageService().addMessage(
            'Sauvegarde restaurée depuis backup',
            EventType.INFO // EventType remplace MessageType pour le système de notifications
          );
          await _loadSaves();
        }
      } else {
        if (mounted) {
          _showError('Échec de la restauration');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur lors de la restauration: $e');
      }
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sauvegarder la partie'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nom de la sauvegarde'),
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('Sauvegarder'),
            onPressed: () async {
              if (_nameController.text.isEmpty) {
                _showError('Veuillez entrer un nom');
                return;
              }
              
              final gameState = context.read<GameState>();
              final saveName = _nameController.text;
              
              // Utiliser SaveButton pour effectuer la sauvegarde avec le nom spécifié
              final result = await SaveButton.saveGameWithName(context, saveName);
              
              if (result) {
                // En cas de succès
                if (mounted) {
                  Navigator.of(context).pop();
                  // Le SnackBar est déjà affiché par SaveButton
                  await _loadSaves(); // Actualiser la liste des sauvegardes
                }
              } else {
                // En cas d'erreur, SaveButton affiche déjà un message d'erreur
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sauvegardes'),
        actions: [
          if (!widget.isStartScreen)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _showSaveDialog,
              tooltip: 'Nouvelle sauvegarde',
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSaves,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12.0),
                  if (_isMigrating)
                    Text(
                      _migrationTotal > 0
                          ? 'Migration des sauvegardes… $_migrationMigrated/$_migrationTotal'
                          : 'Migration des sauvegardes…',
                    )
                  else
                    const Text('Chargement…'),
                ],
              ),
            )
          : _saves.isEmpty
              ? Center(child: Text('Aucune sauvegarde disponible'))
              : ListView.builder(
                  itemCount: _saves.length,
                  itemBuilder: (context, index) {
                    final save = _saves[index];
                    final isBackup = save.isBackup;
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isBackup 
                                            ? 'Backup: ${save.name.split(GameConstants.BACKUP_DELIMITER)[0]}' 
                                            : save.name,
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4.0),
                                      Text(
                                        // Vérification de nullité pour éviter les erreurs
                                        'Dernière modification: ${(save.lastModified ?? DateTime.now()).toLocal().toString().split('.')[0]}',
                                        style: TextStyle(fontSize: 12.0, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isBackup)
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteSave(save.name),
                                        tooltip: 'Supprimer',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.play_arrow, color: Colors.green),
                                        onPressed: () => _loadGame(context, save.name),
                                        tooltip: 'Charger',
                                      ),
                                    ],
                                  ),
                                if (isBackup)
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteSave(save.name),
                                        tooltip: 'Supprimer',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.restore, color: Colors.blue),
                                        onPressed: () => _restoreFromBackup(context, save.name),
                                        tooltip: 'Restaurer',
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            SizedBox(height: 16.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StatIndicator(
                                  icon: Icons.attach_money,
                                  value: save.money.toStringAsFixed(2),
                                  label: 'Argent',
                                ),
                                StatIndicator(
                                  icon: Icons.functions,
                                  value: save.paperclips.toString(),
                                  label: 'Trombones',
                                ),
                                StatIndicator(
                                  icon: Icons.point_of_sale,
                                  value: save.totalPaperclipsSold.toString(),
                                  label: 'Vendus',
                                ),
                              ],
                            ),
                            SizedBox(height: 8.0),
                            Divider(),
                            SizedBox(height: 8.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text(
                                    save.gameMode == GameMode.COMPETITIVE 
                                        ? 'Compétitif' 
                                        : 'Infini',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: save.gameMode == GameMode.COMPETITIVE 
                                      ? Colors.orange 
                                      : Colors.blue,
                                ),
                                if (save.isRestored)
                                  Chip(
                                    label: Text('Restauré', style: TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.purple,
                                  ),
                                Chip(
                                  label: Text('v${save.version}'),
                                  backgroundColor: Colors.grey[300],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
