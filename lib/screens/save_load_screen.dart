// lib/screens/save_load_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../constants/game_config.dart';
import '../screens/main_screen.dart';
// import '../screens/backups_history_screen.dart';
import '../services/persistence/game_persistence_orchestrator.dart';
import '../services/notification_manager.dart';
import '../services/navigation_service.dart';
import '../services/game_runtime_coordinator.dart';
import '../widgets/indicators/stat_indicator.dart';
import '../services/notification_storage_service.dart';
import '../services/save_game.dart' show SaveGameInfo; // legacy type (pour compat)
import '../services/persistence/save_aggregator.dart';
import '../widgets/save_button.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import 'package:paperclip2/models/save_metadata.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:flutter/services.dart';
import '../services/google/google_bootstrap.dart';

// La classe SaveGameInfo est maintenant importée depuis save_game.dart

/// Écran de gestion des sauvegardes
class SaveLoadScreen extends StatefulWidget {
  final bool isStartScreen;

  const SaveLoadScreen({Key? key, this.isStartScreen = false}) : super(key: key);

  @override
  _SaveLoadScreenState createState() => _SaveLoadScreenState();
}

class _SaveLoadScreenState extends State<SaveLoadScreen> {
  List<SaveEntry> _saves = [];
  // Index des derniers backups par baseName (invisible dans la liste principale)
  final Map<String, SaveEntry> _latestBackups = {};
  // Compteur de backups par partieId (ID-first)
  final Map<String, int> _backupCounts = {};
  // Messages diagnostics (debug)
  List<String> _diagnostics = [];
  List<Map<String, dynamic>> _dupGroups = [];
  bool _loading = true;
  bool _isMigrating = false;
  int _migrationMigrated = 0;
  int _migrationTotal = 0;
  final _nameController = TextEditingController();
  Timer? _cloudProbeTimer;
  bool _showTechnicalId = false;
  int _filterMode = 0; // 0=Tous, 1=Local, 2=Cloud
  // IDs marqués en attente de push cloud (pending)
  final Set<String> _pendingCloudPushIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadSaves();
    _maybeRunDailyRetention();
    // Mission 3: suppression du sondage cloud global (slot unique)
    _cloudProbeTimer?.cancel();
    // Charger la préférence d'affichage de l'ID technique
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _showTechnicalId = prefs.getBool('show_technical_id') ?? false;
        });
      } catch (_) {}
    }();
  }

  // Flux cloud global supprimé

  Future<void> _maybeRunDailyRetention() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'backup_retention_last_run';
      final last = prefs.getInt(key);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final oneDayMs = const Duration(days: 1).inMilliseconds;
      if (last == null || (nowMs - last) > oneDayMs) {
        await _applyRetentionAll();
        await prefs.setInt(key, nowMs);
      }
    } catch (_) {}
  }

  Future<void> _applyRetentionAll() async {
    try {
      // Récupère toutes les sauvegardes et identifie les partieId présents dans les backups
      final all = await SaveManagerAdapter.listSaves();
      final ids = <String>{};
      for (final s in all.where((e) => e.isBackup)) {
        final base = s.name.split(GameConstants.BACKUP_DELIMITER).first;
        if (base.isNotEmpty) ids.add(base);
      }
      int totalDeleted = 0;
      for (final id in ids) {
        totalDeleted += await SaveManagerAdapter.applyBackupRetention(partieId: id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rétention appliquée: $totalDeleted backups supprimés')),
        );
      }
      await _loadSaves();
    } catch (e) {
      _showError('Erreur rétention globale: $e');
    }
  }

  Future<void> _showBackupsFor(SaveEntry save) async {
    try {
      final backups = _saves.where((e) => e.isBackup && e.name.startsWith('${save.id}${GameConstants.BACKUP_DELIMITER}')).toList()
        ..sort((a, b) => (b.lastModified ?? DateTime(0)).compareTo(a.lastModified ?? DateTime(0)));
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Backups de cette partie'),
          content: SizedBox(
            width: double.maxFinite,
            child: backups.isEmpty
                ? const Text('Aucun backup disponible')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: backups.length,
                    itemBuilder: (ctx, i) {
                      final b = backups[i];
                      final ts = (b.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0)).toLocal().toString().split('.')[0];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListTile(
                            dense: true,
                            title: Text(b.name.split(GameConstants.BACKUP_DELIMITER).last),
                            subtitle: Text('Créé le: $ts'),
                            trailing: TextButton.icon(
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                await _restoreFromBackup(context, b.name);
                              },
                              icon: const Icon(Icons.restore),
                              label: const Text('Restaurer'),
                            ),
                          ),
                          // Barre d'options (afficher/masquer ID technique) — masquée sauf flag FEATURE_TECHNICAL_IDS
                          if ((dotenv.env['FEATURE_TECHNICAL_IDS'] ?? 'false').toLowerCase() == 'true')
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.badge_outlined, size: 18, color: Colors.grey.shade700),
                                  const SizedBox(width: 6),
                                  Text('Afficher ID technique', style: TextStyle(color: Colors.grey.shade800)),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: _showTechnicalId,
                                    onChanged: (val) async {
                                      setState(() { _showTechnicalId = val; });
                                      try {
                                        final prefs = await SharedPreferences.getInstance();
                                        await prefs.setBool('show_technical_id', val);
                                      } catch (_) {}
                                    },
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Erreur d\'affichage des backups: $e');
    }
  }

  // Mission 4: suppression du flux de création locale depuis le cloud

  Future<void> _restoreLatestBackupFor(BuildContext context, String baseName) async {
    final latest = _latestBackups[baseName];
    if (latest == null) {
      _showError('Aucun backup disponible pour "$baseName"');
      return;
    }
    await _restoreFromBackup(context, latest.name);
  }

  String _cloudLabel(String state) {
    switch (state) {
      case 'in_sync':
        return 'Cloud à jour';
      case 'ahead_local':
        return 'Local en avance';
      case 'ahead_remote':
        return 'Cloud en avance';
      case 'diverged':
        return 'Divergé';
      default:
        return 'Cloud';
    }
  }

  Color _cloudColor(String state) {
    switch (state) {
      case 'in_sync':
        return Colors.green.shade100;
      case 'ahead_local':
        return Colors.orange.shade100;
      case 'ahead_remote':
        return Colors.blue.shade100;
      case 'diverged':
        return Colors.red.shade100;
      default:
        return Colors.lightBlue.shade50;
    }
  }

  // Flux cloud global supprimé: upload/restore globaux retirés

  Future<void> _renameSave(SaveEntry save) async {
    final controller = TextEditingController(text: save.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renommer la partie'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nouveau nom'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == save.name) return;
    try {
      final mgr = await LocalSaveGameManager.getInstance();
      final meta = await mgr.getSaveMetadata(save.id);
      if (meta == null) {
        _showError('Métadonnées introuvables');
        return;
      }
      final updated = meta.copyWith(name: newName, lastModified: DateTime.now());
      final ok = await mgr.updateSaveMetadata(save.id, updated);
      if (!ok) {
        _showError('Échec du renommage');
        return;
      }
      await _loadSaves();
      // Mission 3: déclencher un push immédiat après renommage (cloud gagne sur le nom)
      try {
        final enableCloudPerPartie = (dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true';
        if (enableCloudPerPartie) {
          String? playerId;
          try {
            final google = context.read<GoogleServicesBundle>();
            playerId = google.identity.playerId;
          } catch (_) {}
          await GamePersistenceOrchestrator.instance.pushCloudFromSaveId(partieId: save.id, playerId: playerId);
        }
      } catch (_) {}
      if (mounted) {
        NotificationManager.instance.showNotification(
          message: 'Nom mis à jour',
          level: NotificationLevel.SUCCESS,
        );
      }
    } catch (e) {
      _showError('Erreur renommage: $e');
    }
  }

  Future<void> _loadSaves() async {
    setState(() => _loading = true);
    
    try {
      if (kDebugMode) {
        print('SaveLoadScreen._loadSaves: Chargement des sauvegardes...');
      }

      // Suppression de la migration legacy: aucune ancienne sauvegarde à transformer
      
      // Récupérer les sauvegardes via l'agrégateur (local + cloud)
      print('SaveLoadScreen._loadSaves: Appel de SaveAggregator.listAll()');
      final all = await SaveAggregator().listAll(context);
      if (kDebugMode) {
        await GamePersistenceOrchestrator.instance.runIntegrityChecks();
      }

      // Mission 3: suppression du sondage du slot cloud global

      // Construire un index des derniers backups par baseName
      _latestBackups.clear();
      _backupCounts.clear();
      for (final s in all.where((e) => e.isBackup)) {
        final base = s.name.split(GameConstants.BACKUP_DELIMITER).first;
        final existing = _latestBackups[base];
        if (existing == null || (s.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0)).isAfter(existing.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0))) {
          _latestBackups[base] = s;
        }
        _backupCounts.update(base, (v) => v + 1, ifAbsent: () => 1);
      }

      // Filtrer: n'afficher que les parties locales régulières (pas backups, pas cloud)
      final saves = all.where((e) => !e.isBackup && e.source != SaveSource.cloud).toList();

      // Charger les indicateurs de pending push (SharedPreferences)
      _pendingCloudPushIds.clear();
      try {
        final prefs = await SharedPreferences.getInstance();
        for (final s in saves) {
          final pending = prefs.getBool('pending_cloud_push_'+s.id) ?? false;
          if (pending) _pendingCloudPushIds.add(s.id);
        }
      } catch (_) {}
      
      if (kDebugMode) {
        print('DIAGNOSTIC SAVE SCREEN: ${saves.length} sauvegardes récupérées via GamePersistenceOrchestrator.listSaves()');
        if (saves.isEmpty) {
          print('DIAGNOSTIC SAVE SCREEN: La liste des sauvegardes est VIDE!');
          print('DIAGNOSTIC SAVE SCREEN: Détail complet du retour: $saves');
        } else {
          print('DIAGNOSTIC SAVE SCREEN: Détail des sauvegardes trouvées:');
          for (var save in saves) {
            print('  - ${save.source.name.toUpperCase()} Save: "${save.name}", ID: ${save.id}, date: ${save.lastModified}, playerId=${save.playerId ?? '-'}');
            print('    isBackup: ${save.isBackup}, money: ${save.money}, paperclips: ${save.paperclips}');
          }
        }
      }
      // Diagnostics détaillés (debug): doublons, backups, cloud
      if (kDebugMode) {
        final List<String> diag = [];
        try {
          // Doublons de noms sur des IDs différents
          final Map<String, Set<String>> nameToIds = {};
          for (final s in all.where((e) => !e.isBackup)) {
            nameToIds.putIfAbsent(s.name, () => <String>{}).add(s.id);
          }
          final dups = nameToIds.entries.where((e) => e.value.length > 1).toList()
            ..sort((a, b) => b.value.length.compareTo(a.value.length));
          if (dups.isNotEmpty) {
            diag.add('Doublons de noms: ${dups.length} groupe(s)');
            for (final d in dups.take(5)) {
              diag.add('  • "${d.key}": ${d.value.join(', ')}');
            }
            if (dups.length > 5) diag.add('  • …');
            _dupGroups = dups
                .map((e) => {
                      'name': e.key,
                      'ids': e.value.toList(),
                    })
                .toList();
          } else {
            diag.add('Aucun doublon de nom détecté');
            _dupGroups = [];
          }

          // Backups: compteur + derniers par base
          final backups = all.where((e) => e.isBackup).toList();
          diag.add('Backups présents: ${backups.length}');
          int listed = 0;
          final bases = _latestBackups.entries.toList()
            ..sort((a, b) => (b.value.lastModified ?? DateTime(0)).compareTo(a.value.lastModified ?? DateTime(0)));
          for (final entry in bases) {
            if (listed >= 5) { diag.add('  • …'); break; }
            final lm = entry.value.lastModified?.toIso8601String() ?? 'n/a';
            diag.add('  • ${entry.key} → dernier backup: ${entry.value.name} @ $lm');
            listed++;
          }

          // Mission 3: pas de diagnostic cloud global
        } catch (e) {
          diag.add('Erreur génération diagnostics: $e');
        }
        _diagnostics = diag;
      }
      
      if (mounted) {
        setState(() {
          _saves = saves;
          _loading = false;
        });
        // Nouveau log après setState pour confirmer que _saves a été mis à jour
        print('DIAGNOSTIC SAVE SCREEN: État mis à jour, _saves contient ${_saves.length} sauvegardes');

        // Retry automatique: push cloud pour les parties marquées pending si identité disponible
        try {
          final enableCloudPerPartie = (dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true';
          if (enableCloudPerPartie) {
            String? playerId;
            try {
              final google = context.read<GoogleServicesBundle>();
              playerId = google.identity.playerId;
            } catch (_) {}
            if (playerId != null && playerId.isNotEmpty) {
              final prefs = await SharedPreferences.getInstance();
              for (final s in _saves) {
                final key = 'pending_cloud_push_'+s.id;
                final pending = prefs.getBool(key) ?? false;
                if (pending) {
                  try {
                    await GamePersistenceOrchestrator.instance.pushCloudFromSaveId(partieId: s.id, playerId: playerId);
                    await prefs.remove(key);
                    NotificationManager.instance.showNotification(
                      message: 'Synchronisation cloud effectuée pour "${s.name}"',
                      level: NotificationLevel.SUCCESS,
                      duration: const Duration(seconds: 2),
                    );
                  } catch (e) {
                    // conserver le flag pending; signaler clairement l'échec
                    NotificationManager.instance.showNotification(
                      message: 'Échec de la synchronisation cloud pour "${s.name}" — une resynchronisation est nécessaire',
                      level: NotificationLevel.ERROR,
                      duration: const Duration(seconds: 3),
                    );
                  }
                }
              }
            }
          }
        } catch (_) {}
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
      await GamePersistenceOrchestrator.instance.deleteSaveById(saveId);
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

  Future<void> _loadGame(BuildContext context, String id) async {
    try {
      await context.read<GameRuntimeCoordinator>().loadGameByIdAndStartAutoSave(id);

      // Boucle de jeu pilotée par le runtime coordinator.
      context.read<GameRuntimeCoordinator>().startSession();

      if (mounted) {
        // Notification de chargement réussi
        NotificationStorageService().addMessage(
          'Partie chargée',
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
      final success = await GamePersistenceOrchestrator.instance.restoreFromBackup(gameState, backupName);
      
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
    _cloudProbeTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sauvegardes'),
        actions: [
          if ((dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true')
            PopupMenuButton<int>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtrer',
              onSelected: (v) => setState(() => _filterMode = v),
              itemBuilder: (ctx) => [
                CheckedPopupMenuItem<int>(
                  value: 0,
                  checked: _filterMode == 0,
                  child: const Text('Tous'),
                ),
                CheckedPopupMenuItem<int>(
                  value: 1,
                  checked: _filterMode == 1,
                  child: const Text('Local'),
                ),
                CheckedPopupMenuItem<int>(
                  value: 2,
                  checked: _filterMode == 2,
                  child: const Text('Cloud'),
                ),
              ],
            ),
          if (!widget.isStartScreen)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _showSaveDialog,
              tooltip: 'Nouvelle sauvegarde',
            ),
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              onPressed: _applyRetentionAll,
              tooltip: 'Nettoyer (rétention N=10, TTL=30j)',
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
              : Builder(builder: (context) {
                  return Column(
                    children: [
                      if (kDebugMode)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Card(
                            color: Colors.grey.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.bug_report, color: Colors.grey),
                                          SizedBox(width: 8),
                                          Text('Diagnostics (debug)', style: TextStyle(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      TextButton.icon(
                                        onPressed: _loadSaves,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Rerun checks'),
                                      ),
                                      TextButton.icon(
                                        onPressed: () async {
                                          final text = _diagnostics.join('\n');
                                          await Clipboard.setData(ClipboardData(text: text));
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diagnostics copiés')));
                                          }
                                        },
                                        icon: const Icon(Icons.copy),
                                        label: const Text('Copier'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (_diagnostics.isEmpty)
                                    const Text('Aucun message.'),
                                  if (_diagnostics.isNotEmpty)
                                    ..._diagnostics.take(10).map((m) => Text(m)).toList(),
                                  if (_diagnostics.length > 10)
                                    const Text('…'),
                                  const SizedBox(height: 8),
                                  if (_dupGroups.isNotEmpty) ...[
                                    const Divider(),
                                    const Text('Résoudre les doublons', style: TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    ..._dupGroups.take(5).map((g) {
                                      final name = g['name'] as String;
                                      final ids = (g['ids'] as List).cast<String>();
                                      final Map<String, SaveEntry> idMap = {for (final s in _saves) s.id: s};
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: Text('• "$name" — ${ids.length} ID(s)')),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: ids.where((id) => idMap.containsKey(id)).map((id) {
                                                final s = idMap[id]!;
                                                final shortId = id.length > 6 ? id.substring(0, 6) : id;
                                                return OutlinedButton(
                                                  onPressed: () => _renameSave(s),
                                                  child: Text('Renommer ($shortId)'),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    if (_dupGroups.length > 5) const Text('…'),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Bloc GPG cloud global supprimé
                      Expanded(
                        child: Builder(builder: (context) {
                          final enableCloud = (dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true';
                          List<SaveEntry> visible = _saves;
                          if (enableCloud) {
                            if (_filterMode == 1) {
                              visible = _saves.where((s) => s.source != SaveSource.cloud).toList();
                            } else if (_filterMode == 2) {
                              visible = _saves.where((s) => s.source == SaveSource.cloud).toList();
                            }
                          }
                          return ListView.builder(
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final save = visible[index];
                            final isBackup = save.isBackup;
                            final isCloud = save.source == SaveSource.cloud;
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
                                                'Dernière modification: ${(save.lastModified ?? DateTime.now()).toLocal().toString().split('.')[0]}',
                                                style: TextStyle(fontSize: 12.0, color: Colors.grey),
                                              ),
                                              if ((dotenv.env['FEATURE_TECHNICAL_IDS'] ?? 'false').toLowerCase() == 'true' && _showTechnicalId) ...[
                                                SizedBox(height: 2.0),
                                                Text(
                                                  'ID: ${save.id}',
                                                  style: TextStyle(fontSize: 11.0, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (!isBackup && !isCloud)
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              if ((dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true' && (dotenv.env['FEATURE_ADVANCED_CLOUD_UI'] ?? 'false').toLowerCase() == 'true' && !kReleaseMode && save.cloudSyncState != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 8.0),
                                                  child: Chip(
                                                    avatar: const Icon(Icons.cloud, size: 16),
                                                    label: Text(_cloudLabel(save.cloudSyncState!)),
                                                    backgroundColor: _cloudColor(save.cloudSyncState!),
                                                  ),
                                                ),
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                                onPressed: () => _renameSave(save),
                                                tooltip: 'Renommer',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.history, color: Colors.brown),
                                                onPressed: () => _showBackupsFor(save),
                                                tooltip: 'Backups de cette partie',
                                              ),
                                              // Cloud par partie (Option A) via orchestrateur — UI avancée uniquement
                                              if ((dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true' && (dotenv.env['FEATURE_ADVANCED_CLOUD_UI'] ?? 'false').toLowerCase() == 'true' && !kReleaseMode) ...[
                                                IconButton(
                                                  icon: const Icon(Icons.cloud_upload, color: Colors.blue),
                                                  tooltip: 'Push (Cloud par partie)',
                                                  onPressed: () async {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        title: const Text('Envoyer au cloud ?'),
                                                        content: Text('Cette action publiera l\'état courant de "${save.name}" (ID: ${save.id}) vers le cloud.'),
                                                        actions: [
                                                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
                                                          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirmer')),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm != true) return;
                                                    try {
                                                      String? playerId;
                                                      try {
                                                        final google = context.read<GoogleServicesBundle>();
                                                        playerId = google.identity.playerId;
                                                      } catch (_) {}
                                                      await GamePersistenceOrchestrator.instance.pushCloudFromSaveId(partieId: save.id, playerId: playerId);
                                                      if (mounted) {
                                                        NotificationManager.instance.showNotification(
                                                          message: 'Envoyé au cloud (par partie)',
                                                          level: NotificationLevel.SUCCESS,
                                                        );
                                                        await _loadSaves();
                                                      }
                                                    } catch (e) {
                                                      if (mounted) _showError('Erreur push cloud: $e');
                                                    }
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.cloud_download, color: Colors.indigo),
                                                  tooltip: 'Pull (Cloud par partie)',
                                                  onPressed: (save.remoteVersion == null)
                                                      ? null
                                                      : () async {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        title: const Text('Remplacer depuis le cloud ?'),
                                                        content: Text('Cette action écrasera la sauvegarde locale de "${save.name}" avec la version cloud.'),
                                                        actions: [
                                                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
                                                          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remplacer')),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm != true) return;
                                                    try {
                                                      final data = await GamePersistenceOrchestrator.instance.pullCloudById(partieId: save.id);
                                                      if (data == null) {
                                                        if (mounted) _showError('Aucune donnée cloud pour cette partie');
                                                        return;
                                                      }
                                                      final snap = data['snapshot'];
                                                      if (snap is! Map) {
                                                        if (mounted) _showError('Snapshot cloud invalide');
                                                        return;
                                                      }
                                                      final restored = SaveGame(
                                                        id: save.id,
                                                        name: save.name,
                                                        lastSaveTime: DateTime.now(),
                                                        gameData: {'gameSnapshot': Map<String, dynamic>.from(snap as Map)},
                                                        version: save.version,
                                                        gameMode: save.gameMode,
                                                      );
                                                      final ok = await SaveManagerAdapter.saveGame(restored);
                                                      if (!ok) {
                                                        if (mounted) _showError('Échec de l\'application du pull cloud');
                                                        return;
                                                      }
                                                      await _loadSaves();
                                                      if (mounted) {
                                                        NotificationManager.instance.showNotification(
                                                          message: 'Récupération cloud appliquée',
                                                          level: NotificationLevel.SUCCESS,
                                                        );
                                                      }
                                                    } catch (e) {
                                                      if (mounted) _showError('Erreur pull cloud: $e');
                                                    }
                                                  },
                                                ),
                                              ],
                                              // Mission 3: suppression des contrôles GPG cloud globaux
                                              IconButton(
                                                icon: const Icon(Icons.restore, color: Colors.blue),
                                                onPressed: () => _restoreLatestBackupFor(context, save.id),
                                                tooltip: 'Restaurer dernier backup',
                                              ),
                                              if (_backupCounts.containsKey(save.id))
                                                Chip(
                                                  label: Text('Backups: ${_backupCounts[save.id]}'),
                                                  avatar: const Icon(Icons.inventory_2, size: 16),
                                                ),
                                              IconButton(
                                                icon: Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _deleteSave(save.id),
                                                tooltip: 'Supprimer',
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.play_arrow, color: Colors.green),
                                                onPressed: save.canLoad ? () => _loadGame(context, save.id) : null,
                                                tooltip: save.canLoad ? 'Charger' : 'Indisponible (restaurer un backup)',
                                              ),
                                            ],
                                          ),
                                        if (!isBackup && isCloud)
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              if ((dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true')
                                                IconButton(
                                                  icon: const Icon(Icons.cloud_download, color: Colors.indigo),
                                                  tooltip: 'Matérialiser depuis le cloud',
                                                  onPressed: () async {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        title: const Text('Créer cette partie en local ?'),
                                                        content: Text('Cette action créera localement la partie "${save.name}" (ID: ${save.id}) à partir du cloud.'),
                                                        actions: [
                                                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
                                                          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Créer')),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm != true) return;
                                                    try {
                                                      final ok = await GamePersistenceOrchestrator.instance.materializeFromCloud(partieId: save.id);
                                                      if (!ok) {
                                                        if (mounted) _showError('Échec de création locale');
                                                        return;
                                                      }
                                                      await _loadSaves();
                                                      if (mounted) {
                                                        NotificationManager.instance.showNotification(
                                                          message: 'Partie matérialisée depuis le cloud',
                                                          level: NotificationLevel.SUCCESS,
                                                        );
                                                      }
                                                    } catch (e) {
                                                      if (mounted) _showError('Erreur de matérialisation: $e');
                                                    }
                                                  },
                                                ),
                                              if ((dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true')
                                                IconButton(
                                                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                                                  tooltip: 'Supprimer du cloud',
                                                  onPressed: () async {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        title: const Text('Supprimer cette sauvegarde cloud ?'),
                                                        content: Text('Cette action supprimera définitivement l\'entrée cloud "${save.name}" (ID: ${save.id}). Les backups locaux ne sont pas affectés.'),
                                                        actions: [
                                                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
                                                          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Supprimer')),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm != true) return;
                                                    try {
                                                      await GamePersistenceOrchestrator.instance.deleteCloudById(partieId: save.id);
                                                      await _loadSaves();
                                                      if (mounted) {
                                                        NotificationManager.instance.showNotification(
                                                          message: 'Sauvegarde cloud supprimée',
                                                          level: NotificationLevel.SUCCESS,
                                                        );
                                                      }
                                                    } catch (e) {
                                                      if (mounted) _showError('Échec de la suppression cloud: $e');
                                                    }
                                                  },
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
                                          icon: Icons.precision_manufacturing,
                                          value: (save.paperclips + save.totalPaperclipsSold).toString(),
                                          label: 'Créés',
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
                                        // États globaux visibles pour le joueur (uniformisés)
                                        if (save.integrityStatus == GamePersistenceOrchestrator.integrityCorrupt)
                                          Chip(
                                            label: const Text('Erreur'),
                                            backgroundColor: Colors.red,
                                            labelStyle: const TextStyle(color: Colors.white),
                                          ),
                                        if (save.integrityStatus == GamePersistenceOrchestrator.integrityMigratable)
                                          Chip(
                                            label: const Text('À migrer'),
                                            backgroundColor: Colors.orange,
                                            labelStyle: const TextStyle(color: Colors.white),
                                          ),
                                        if (save.isRestored)
                                          Chip(
                                            label: const Text('Restauré'),
                                            backgroundColor: Colors.purple,
                                            labelStyle: const TextStyle(color: Colors.white),
                                          ),
                                        Chip(
                                          label: Text('v${save.version}'),
                                          backgroundColor: Colors.grey[300],
                                        ),
                                        const SizedBox(width: 8),
                                        // Visibilité source/statut
                                        if ((dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true') ...[
                                          Chip(
                                            label: const Text('Local'),
                                            backgroundColor: Colors.teal.shade50,
                                          ),
                                          if (_pendingCloudPushIds.contains(save.id))
                                            Chip(
                                              label: const Text('À synchroniser'),
                                              backgroundColor: Colors.orange.shade100,
                                            )
                                          else if (save.cloudSyncState != null) ...[
                                            if (save.cloudSyncState == 'in_sync')
                                              Chip(label: const Text('Synchronisée'), backgroundColor: Colors.green.shade100)
                                            else if (save.cloudSyncState == 'ahead_local')
                                              Chip(label: const Text('À synchroniser'), backgroundColor: Colors.orange.shade100)
                                            else if (save.cloudSyncState == 'ahead_remote')
                                              Chip(label: const Text('Mise à jour requise'), backgroundColor: Colors.blue.shade100)
                                            else if (save.cloudSyncState == 'diverged')
                                              Chip(label: const Text('Conflit'), backgroundColor: Colors.red.shade100),
                                          ]
                                          else
                                            Chip(
                                              label: const Text('Cloud uniquement'),
                                              backgroundColor: Colors.blueGrey.shade50,
                                            ),
                                        ] else ...[
                                          Chip(
                                            label: const Text('Local uniquement'),
                                            backgroundColor: Colors.teal.shade50,
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (!isBackup && !isCloud && save.cloudSyncState == 'diverged') ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Conflit détecté. Vous pouvez soit envoyer votre version locale au cloud (Push), soit importer la version cloud (Pull).',
                                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            );
                          },
                          );
                        }),
                      ),
                    ],
                  );
                }),
    );
  }
}
