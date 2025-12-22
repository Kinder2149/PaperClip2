// lib/screens/save_load_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../constants/game_config.dart';
import '../screens/main_screen.dart';
import '../screens/backups_history_screen.dart';
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
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import 'package:paperclip2/models/save_metadata.dart';
import '../services/google/google_bootstrap.dart';
import '../services/google/snapshots/snapshots_cloud_save.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:flutter/services.dart';

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
  // gameId présent dans le slot cloud (si disponible)
  String? _cloudGameIdAvailable;
  // date savedAt du cloud si disponible
  DateTime? _cloudSavedAt;
  // Messages diagnostics (debug)
  List<String> _diagnostics = [];
  List<Map<String, dynamic>> _dupGroups = [];
  bool _loading = true;
  bool _isMigrating = false;
  int _migrationMigrated = 0;
  int _migrationTotal = 0;
  final _nameController = TextEditingController();
  Timer? _cloudProbeTimer;

  @override
  void initState() {
    super.initState();
    _loadSaves();
    // Auto-refresh périodique: permet de refléter un upload cloud initié ailleurs
    _cloudProbeTimer?.cancel();
    _cloudProbeTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      try {
        await _loadSaves();
      } catch (_) {}
    });
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
                      return ListTile(
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

  Future<void> _createLocalFromCloud(Map<String, dynamic> json, {String? preferredName}) async {
    try {
      final snapshot = json['snapshot'];
      if (snapshot == null || snapshot is! Map) {
        _showError('Snapshot cloud absent ou invalide');
        return;
      }
      final meta = (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final version = (meta['gameVersion']?.toString()) ?? '1.0.0';
      final gm = (meta['gameMode']?.toString() ?? 'INFINITE').toUpperCase();
      final gameMode = gm == 'COMPETITIVE' ? GameMode.COMPETITIVE : GameMode.INFINITE;
      final name = preferredName ?? 'Partie (cloud)';

      final local = SaveGame(
        name: name,
        lastSaveTime: DateTime.now(),
        gameData: { 'gameSnapshot': Map<String, dynamic>.from(snapshot as Map) },
        version: version,
        gameMode: gameMode,
      );
      final ok = await SaveManagerAdapter.saveGame(local);
      if (!ok) {
        _showError('Création locale depuis cloud échouée');
        return;
      }
      await _loadSaves();
      if (mounted) {
        NotificationManager.instance.showNotification(
          message: 'Partie locale créée depuis le cloud',
          level: NotificationLevel.SUCCESS,
        );
      }
    } catch (e) {
      if (mounted) _showError('Erreur création locale depuis cloud: $e');
    }
  }

  Future<void> _restoreLatestBackupFor(BuildContext context, String baseName) async {
    final latest = _latestBackups[baseName];
    if (latest == null) {
      _showError('Aucun backup disponible pour "$baseName"');
      return;
    }
    await _restoreFromBackup(context, latest.name);
  }

  Future<void> _uploadPartyToCloud(SaveEntry save) async {
    try {
      final enableGpg = (dotenv.env['FEATURE_CLOUD_SAVES_GPG'] ?? 'false').toLowerCase() == 'true';
      if (!enableGpg) {
        _showError('Cloud désactivé');
        return;
      }
      final google = context.read<GoogleServicesBundle>();
      if (google.identity.status.name != 'signedIn') {
        _showError('Connexion Google requise');
        return;
      }

      final loaded = await GamePersistenceOrchestrator.instance.loadSaveById(save.id);
      if (loaded == null) {
        _showError('Partie introuvable localement');
        return;
      }

      final Map<String, dynamic> data = loaded.gameData;
      Map<String, dynamic>? snapshot;
      if (data.containsKey('gameSnapshot')) {
        final raw = data['gameSnapshot'];
        if (raw is Map) {
          snapshot = Map<String, dynamic>.from(raw as Map);
        } else if (raw is String) {
          try {
            snapshot = Map<String, dynamic>.from(jsonDecode(raw) as Map);
          } catch (_) {}
        }
      }

      if (snapshot == null) {
        _showError('Aucun snapshot à envoyer');
        return;
      }

      // Extraire sections utiles pour l’aperçu cloud
      Map<String, dynamic> core = {};
      Map<String, dynamic> stats = {};
      if (snapshot['core'] is Map) core = Map<String, dynamic>.from(snapshot['core'] as Map);
      if (snapshot['stats'] is Map) stats = Map<String, dynamic>.from(snapshot['stats'] as Map);

      final svc = createSnapshotsCloudSave(identity: google.identity);
      final payload = <String, dynamic>{
        'metadata': {
          'gameId': save.id,
          'savedAt': DateTime.now().toIso8601String(),
          'gameMode': save.gameMode == GameMode.COMPETITIVE ? 'COMPETITIVE' : 'INFINITE',
          'gameVersion': save.version,
        },
        'core': core,
        'stats': stats,
        'snapshot': snapshot,
      };

      await svc.saveJson(payload);
      // Recharger le slot cloud et rafraîchir l'UI (badge/état)
      try {
        if (kDebugMode) {
          print('[GPG] saveJson() terminé. Relecture du slot via loadJson()...');
        }
        final __t0 = DateTime.now();
        final back = await svc.loadJson();
        final __dt = DateTime.now().difference(__t0).inMilliseconds;
        if (kDebugMode) {
          print('[GPG] loadJson() après upload: ${back != null ? 'OK' : 'null'} (' + __dt.toString() + 'ms)');
        }
        if (back != null) {
          final meta = (back['metadata'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
          final cloudGameId = meta['gameId'] as String?;
          final savedAtStr = meta['savedAt'] as String?;
          setState(() {
            _cloudGameIdAvailable = cloudGameId;
            _cloudSavedAt = savedAtStr != null ? DateTime.tryParse(savedAtStr) : null;
          });
        }
      } catch (e) {
        if (kDebugMode) {
          print('[GPG] Erreur lors de la relecture du slot après upload: ' + e.toString());
        }
      }
      await _loadSaves();
      if (mounted) {
        NotificationManager.instance.showNotification(
          message: 'Partie envoyée au cloud',
          level: NotificationLevel.SUCCESS,
        );
      }
    } catch (e) {
      if (mounted) _showError('Erreur upload cloud: $e');
    }
  }

  Future<void> _restorePartyFromCloud(SaveEntry save) async {
    try {
      final enableGpg = (dotenv.env['FEATURE_CLOUD_SAVES_GPG'] ?? 'false').toLowerCase() == 'true';
      if (!enableGpg) {
        _showError('Cloud désactivé');
        return;
      }
      final google = context.read<GoogleServicesBundle>();
      if (google.identity.status.name != 'signedIn') {
        _showError('Connexion Google requise');
        return;
      }

      final svc = createSnapshotsCloudSave(identity: google.identity);
      final json = await svc.loadJson();
      if (json == null) {
        _showError('Aucune sauvegarde cloud');
        return;
      }
      final meta = (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final cloudGameId = meta['gameId'] as String?;
      if (cloudGameId == null || cloudGameId != save.id) {
        _showError('Le cloud ne correspond pas à cette partie');
        return;
      }
      // Alerte si cloud plus ancien que local
      try {
        final savedAtStr = meta['savedAt'] as String?;
        if (savedAtStr != null) {
          final cloudAt = DateTime.parse(savedAtStr);
          final localAt = save.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
          final older = localAt.difference(cloudAt).inSeconds;
          if (older > 60) {
            final proceed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Restauration cloud plus ancien'),
                content: Text('Le cloud (${cloudAt.toIso8601String()}) est plus ancien que votre sauvegarde locale (${localAt.toIso8601String()}).\nVoulez-vous vraiment écraser le local ?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
                  ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Continuer')),
                ],
              ),
            );
            if (proceed != true) {
              return;
            }
          }
        }
      } catch (_) {}
      final snapshot = json['snapshot'];
      if (snapshot == null || snapshot is! Map) {
        _showError('Snapshot cloud absent ou invalide');
        return;
      }

      final restored = SaveGame(
        id: save.id,
        name: save.name,
        lastSaveTime: DateTime.now(),
        gameData: { 'gameSnapshot': Map<String, dynamic>.from(snapshot as Map) },
        version: save.version,
        gameMode: save.gameMode,
      );
      final ok = await SaveManagerAdapter.saveGame(restored);
      if (!ok) {
        _showError('Échec de la restauration cloud');
        return;
      }
      await _loadSaves();
      if (mounted) {
        NotificationManager.instance.showNotification(
          message: 'Restauration cloud appliquée',
          level: NotificationLevel.SUCCESS,
        );
      }
    } catch (e) {
      if (mounted) _showError('Erreur restauration cloud: $e');
    }
  }

  Future<void> _renameSave(SaveEntry save) async {
    final controller = TextEditingController(text: save.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renommer la sauvegarde'),
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

      // Détecter la présence d'une sauvegarde cloud liée à un gameId
      _cloudGameIdAvailable = null;
      _cloudSavedAt = null;
      try {
        final enableGpg = (dotenv.env['FEATURE_CLOUD_SAVES_GPG'] ?? 'false').toLowerCase() == 'true';
        if (enableGpg) {
          final google = context.read<GoogleServicesBundle>();
          if (kDebugMode) {
            print('[GPG] Feature flag actif. Status=' + google.identity.status.name + ', playerId=' + (google.identity.playerId ?? '-'));
          }
          if (google.identity.status.name == 'signedIn') {
            final svc = createSnapshotsCloudSave(identity: google.identity);
            if (kDebugMode) {
              print('[GPG] _loadSaves: appel loadJson() pour sonder le slot cloud');
            }
            final __t1 = DateTime.now();
            final json = await svc.loadJson();
            final __dt1 = DateTime.now().difference(__t1).inMilliseconds;
            if (kDebugMode) {
              print('[GPG] _loadSaves: loadJson -> ' + (json != null ? 'OK' : 'null') + ' (' + __dt1.toString() + 'ms)');
            }
            if (json != null) {
              final meta = (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
              final cloudGameId = meta['gameId'] as String?;
              if (cloudGameId != null && cloudGameId.isNotEmpty) {
                _cloudGameIdAvailable = cloudGameId;
              }
              final savedAtStr = meta['savedAt'] as String?;
              if (savedAtStr != null) {
                try { _cloudSavedAt = DateTime.parse(savedAtStr); } catch (_) {}
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('[GPG] _loadSaves: erreur lors du sondage cloud: ' + e.toString());
        }
        // No-op: si indisponible, on n'affiche pas le badge cloud
      }

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

          // Cloud: état
          if (_cloudGameIdAvailable != null) {
            diag.add('Cloud: gameId=$_cloudGameIdAvailable, savedAt=${_cloudSavedAt?.toIso8601String() ?? 'n/a'}');
          } else {
            diag.add('Cloud: aucun gameId associé au slot courant');
          }
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
          if (!widget.isStartScreen)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _showSaveDialog,
              tooltip: 'Nouvelle sauvegarde',
            ),
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BackupsHistoryScreen()),
              );
            },
            tooltip: 'Historique Backups',
          ),
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
                  final enableGpg = (dotenv.env['FEATURE_CLOUD_SAVES_GPG'] ?? 'false').toLowerCase() == 'true';
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
                      if (enableGpg)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: FutureBuilder<Map<String, dynamic>?>(
                            future: () async {
                              final google = context.read<GoogleServicesBundle>();
                              final svc = createSnapshotsCloudSave(identity: google.identity);
                              try {
                                return await svc.loadJson().timeout(const Duration(seconds: 3));
                              } catch (_) {
                                return null;
                              }
                            }(),
                            builder: (ctx, snap) {
                              final hasCloud = snap.connectionState == ConnectionState.done && snap.data != null;
                              return Card(
                                color: Colors.lightBlue.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.cloud, color: Colors.blue),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  hasCloud ? 'Cloud: sauvegarde disponible' : 'Cloud: aucune sauvegarde',
                                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                                ),
                                                const SizedBox(height: 2),
                                                const Text('Slot: paperclip2_main_save (GPG)'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      OverflowBar(
                                        alignment: MainAxisAlignment.start,
                                        spacing: 8,
                                        overflowSpacing: 4,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () async {
                                              final google = context.read<GoogleServicesBundle>();
                                              final svc = createSnapshotsCloudSave(identity: google.identity);
                                              final data = await svc.loadJson();
                                              if (data == null) {
                                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune sauvegarde cloud')));
                                                return;
                                              }
                                              final meta = (data['metadata'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
                                              final cloudId = meta['gameId'] as String?;
                                              if (cloudId != null) {
                                                final idx = _saves.indexWhere((s) => s.id == cloudId);
                                                if (idx != -1) {
                                                  final match = _saves[idx];
                                                  await _restorePartyFromCloud(match);
                                                  return;
                                                }
                                              }
                                              // Orphelin: créer locale depuis cloud
                                              await _createLocalFromCloud(data);
                                            },
                                            icon: const Icon(Icons.download),
                                            label: const Text('Restaurer'),
                                          ),
                                          TextButton.icon(
                                            onPressed: () async {
                                              try {
                                                final google = context.read<GoogleServicesBundle>();
                                                final svc = createSnapshotsCloudSave(identity: google.identity);
                                                await svc.deleteCloudSlot();
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cloud supprimé')));
                                                  setState(() {});
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression cloud: $e')));
                                                }
                                              }
                                            },
                                            icon: const Icon(Icons.cloud_off),
                                            label: const Text('Supprimer'),
                                          ),
                                          if (hasCloud)
                                            Builder(builder: (ctx) {
                                              try {
                                                final meta = (snap.data?['metadata'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
                                                final cloudId = meta['gameId'] as String?;
                                                final orphan = cloudId == null || !_saves.any((s) => s.id == cloudId);
                                                if (orphan) {
                                                  return TextButton.icon(
                                                    onPressed: () async {
                                                      final data = snap.data!;
                                                      await _createLocalFromCloud(data);
                                                    },
                                                    icon: const Icon(Icons.add),
                                                    label: const Text('Créer locale depuis cloud'),
                                                  );
                                                }
                                              } catch (_) {}
                                              return const SizedBox.shrink();
                                            }),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _saves.length,
                          itemBuilder: (context, index) {
                            final save = _saves[index];
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
                                            ],
                                          ),
                                        ),
                                        if (!isBackup && !isCloud)
                                          Row(
                                            children: [
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
                                              // Cloud par partie (Option A) via orchestrateur
                                              if ((dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true') ...[
                                                IconButton(
                                                  icon: const Icon(Icons.cloud_upload, color: Colors.blue),
                                                  tooltip: 'Push (Cloud par partie)',
                                                  onPressed: () async {
                                                    try {
                                                      final gs = context.read<GameState>();
                                                      await GamePersistenceOrchestrator.instance.pushCloudById(partieId: save.id, state: gs);
                                                      if (mounted) {
                                                        NotificationManager.instance.showNotification(
                                                          message: 'Envoyé au cloud (par partie)',
                                                          level: NotificationLevel.SUCCESS,
                                                        );
                                                      }
                                                    } catch (e) {
                                                      if (mounted) _showError('Erreur push cloud: $e');
                                                    }
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.cloud_download, color: Colors.indigo),
                                                  tooltip: 'Pull (Cloud par partie)',
                                                  onPressed: () async {
                                                    try {
                                                      final data = await GamePersistenceOrchestrator.instance.pullCloudById(partieId: save.id);
                                                      if (data == null) {
                                                        if (mounted) _showError('Aucune donnée cloud pour cette partie');
                                                        return;
                                                      }
                                                      // data devrait contenir {'snapshot': ..., 'metadata': ...}
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
                                              if ((dotenv.env['FEATURE_CLOUD_SAVES_GPG'] ?? 'false').toLowerCase() == 'true' && context.read<GoogleServicesBundle>().identity.status.name == 'signedIn') ...[
                                                IconButton(
                                                  icon: const Icon(Icons.cloud_upload, color: Colors.blue),
                                                  onPressed: () => _uploadPartyToCloud(save),
                                                  tooltip: 'Sauver au cloud',
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.cloud_download, color: Colors.indigo),
                                                  onPressed: () => _restorePartyFromCloud(save),
                                                  tooltip: 'Restaurer du cloud',
                                                ),
                                              ],
                                              IconButton(
                                                icon: const Icon(Icons.restore, color: Colors.blue),
                                                onPressed: () => _restoreLatestBackupFor(context, save.name),
                                                tooltip: 'Restaurer dernier backup',
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _deleteSave(save.id),
                                                tooltip: 'Supprimer',
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.play_arrow, color: Colors.green),
                                                onPressed: () => _loadGame(context, save.id),
                                                tooltip: 'Charger',
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
                                        if (save.isRestored)
                                          Chip(
                                            label: Text('Restauré', style: TextStyle(color: Colors.white)),
                                            backgroundColor: Colors.purple,
                                          ),
                                        Chip(
                                          label: Text('v${save.version}'),
                                          backgroundColor: Colors.grey[300],
                                        ),
                                        const SizedBox(width: 8),
                                        // Badges de source: Local toujours, Cloud si le slot correspond à ce gameId
                                        Chip(
                                          label: const Text('Local'),
                                          backgroundColor: Colors.teal.shade50,
                                        ),
                                        // Badge Cloud (Option A) par partie — version minimale: présent si status disponible
                                        if ((dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true')
                                          FutureBuilder(
                                            future: GamePersistenceOrchestrator.instance.cloudStatusById(partieId: save.id),
                                            builder: (ctx, snap) {
                                              if (snap.connectionState != ConnectionState.done) {
                                                return const SizedBox.shrink();
                                              }
                                              final status = snap.data;
                                              if (status == null || status.remoteVersion == null) {
                                                return const SizedBox.shrink();
                                              }
                                              return Chip(
                                                label: const Text('Cloud'),
                                                backgroundColor: Colors.lightBlue.shade50,
                                              );
                                            },
                                          ),
                                        if (_cloudGameIdAvailable != null && _cloudGameIdAvailable == save.id)
                                          (() {
                                            final local = save.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
                                            final cloud = _cloudSavedAt;
                                            String label = 'Cloud';
                                            Color bg = Colors.lightBlue.shade50;
                                            if (cloud != null) {
                                              final diff = cloud.difference(local).inSeconds;
                                              if (diff > 60) {
                                                label = 'Cloud plus récent';
                                                bg = Colors.blue.shade100;
                                              } else if (diff.abs() <= 60) {
                                                label = 'Cloud à jour';
                                                bg = Colors.green.shade100;
                                              } else {
                                                label = 'Cloud ancien';
                                                bg = Colors.orange.shade100;
                                              }
                                            }
                                            final tooltip = cloud != null
                                                ? 'Cloud savedAt: ${cloud.toIso8601String()}\nLocal lastModified: ${local.toIso8601String()}'
                                                : 'Cloud présent (dates indisponibles)';
                                            return Tooltip(
                                              message: tooltip,
                                              child: Chip(
                                                label: Text(label),
                                                backgroundColor: bg,
                                              ),
                                            );
                                          }()),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }),
    );
  }
}
