import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperclip2/services/persistence/save_aggregator.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/persistence/sync_state.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import 'package:paperclip2/widgets/worlds/world_state_helper.dart';
import 'package:paperclip2/widgets/worlds/world_card.dart';
import 'package:paperclip2/widgets/worlds/world_actions_dialog.dart';
import 'package:paperclip2/services/runtime/runtime_actions.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/widgets/appbar/sections/google_account_action.dart';
import 'package:paperclip2/widgets/new_game/new_game_dialog.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/services/auth/firebase_auth_service.dart';
import 'package:paperclip2/screens/introduction_screen.dart';
import 'package:paperclip2/screens/main_screen.dart';
import 'package:paperclip2/widgets/common/empty_state.dart';
import 'package:paperclip2/widgets/layout/app_scaffold.dart';
import 'package:paperclip2/widgets/dialogs/offline_progress_dialog.dart';
import 'package:paperclip2/services/game_runtime_coordinator.dart';

class WorldsScreen extends StatefulWidget {
  final bool openCreateDialog;
  const WorldsScreen({super.key, this.openCreateDialog = false});

  @override
  State<WorldsScreen> createState() => _WorldsScreenState();
}

class _WorldsScreenState extends State<WorldsScreen> with WidgetsBindingObserver {
  bool _loading = true;
  bool _syncing = false; // NOUVEAU: indicateur sync en cours
  List<SaveEntry> _entries = [];
  final Map<String, String> _cloudStateById = {};
  final Map<String, String> _cloudLabelById = {};
  final Map<String, int> _backupCountById = {};
  int _sortMode = 0; // 0=date desc, 1=nom asc
  ValueListenable<SyncState>? _sync;
  VoidCallback? _syncListener;
  // _authSub supprimé - listener authStateChanges retiré (redondant)
  
  // CORRECTION AUDIT P0 #1: Cache pour pull-to-refresh manuel uniquement
  // La sync automatique au login est gérée par le listener Firebase dans main.dart
  DateTime? _lastCloudSyncAt;
  // Note: TTL non utilisé car sync uniquement sur action utilisateur (forceRefresh=true)
  
  // CORRECTION AUDIT P1 #3: Cache pour éviter refresh excessifs de la liste locale
  // Ce cache concerne uniquement le refresh de la liste locale (métadonnées)
  DateTime? _lastLocalRefreshAt;
  static const _localRefreshCooldown = Duration(seconds: 5); // Cooldown court pour UX réactive

  @override
  void initState() {
    super.initState();
    try { WidgetsBinding.instance.addObserver(this); } catch (_) {}
    
    // Configurer le callback pour afficher la notification offline
    try {
      final coordinator = context.read<GameRuntimeCoordinator>();
      coordinator.setOfflineProgressCallback((result) {
        if (!mounted) return;
        OfflineProgressDialog.show(context, result);
      });
    } catch (_) {}
    
    _sync = GamePersistenceOrchestrator.instance.syncState;
    _syncListener = () {
      if (!mounted) return;
      // NOUVEAU: Mettre à jour état syncing (inclut downloading)
      final v = _sync?.value ?? SyncState.ready;
      setState(() {
        _syncing = v.isActive;
      });
      
      // ZONE D'OMBRE #3: Message spécifique pour téléchargement
      if (v == SyncState.downloading) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📥 Téléchargement depuis le cloud...'),
              duration: Duration(seconds: 2),
            ),
          );
        } catch (_) {}
      }
      
      // Snackbar non silencieuse en cas d'erreur de sync
      if (v == SyncState.error) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec de synchronisation cloud — réessayez')),
          );
        } catch (_) {}
      }
      _load();
    };
    try { _sync?.addListener(_syncListener!); } catch (_) {}
    _load();
    // CORRECTION AUDIT P1 #4: Responsabilités clarifiées
    // 
    // SYNC CLOUD (automatique au login):
    //   → Gérée par listener Firebase dans main.dart:256-335
    //   → Appelle GamePersistenceOrchestrator.onPlayerConnected()
    //   → Déclenche syncAllWorldsFromCloud() + retryPendingCloudPushes()
    // 
    // SYNC CLOUD (manuelle pull-to-refresh):
    //   → Gérée par _load(forceRefresh: true) dans ce fichier
    //   → Appelle directement syncAllWorldsFromCloud()
    // 
    // REFRESH LOCAL (métadonnées):
    //   → Gérée par _load(forceRefresh: false) dans ce fichier
    //   → Charge uniquement SaveAggregator().listAll() (pas de requête cloud)
    //   → Cooldown de 5 secondes pour éviter refreshs excessifs
    // 
    // INDICATEURS UI (spinner, bandeaux):
    //   → Gérés par listener syncState (lignes 62-86)
    //   → Affiche état: 'syncing', 'downloading', 'error', 'ready'
    
    // Si demandé, ouvrir automatiquement le dialogue de création à l'arrivée
    if (widget.openCreateDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _createNewWorld();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // CORRECTION AUDIT P1 #3: Recharger uniquement si cooldown expiré
    // Évite les refreshs excessifs lors de navigation entre écrans
    final now = DateTime.now();
    final shouldRefresh = _lastLocalRefreshAt == null || 
                         now.difference(_lastLocalRefreshAt!) > _localRefreshCooldown;
    
    if (mounted && shouldRefresh) {
      _lastLocalRefreshAt = now;
      _load();
    }
  }

  Future<void> _createNewWorld() async {
    try {
      // Vérifier la limite de mondes avant d'ouvrir le dialogue
      final entries = await SaveAggregator().listAll(context);
      final worldCount = entries.where((e) => !e.isBackup).length;
      
      if (worldCount >= GameConstants.MAX_WORLDS) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Limite de ${GameConstants.MAX_WORLDS} mondes atteinte. '
              'Supprimez un monde existant pour en créer un nouveau.',
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
        return;
      }
      
      final result = await showNewGameDialog(context: context);
      if (result == null) return;
      final (name, mode) = result;
      await context.read<RuntimeActions>()
          .startNewGameAndStartAutoSave(name, mode: mode);
      context.read<RuntimeActions>().startSession();
      if (!mounted) return;
      // Afficher l'introduction puis lancer le jeu
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => IntroductionScreen(
            showSkipButton: true,
            isCompetitiveMode: mode == GameMode.COMPETITIVE,
            onStart: () {
              Navigator.of(ctx).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainScreen()),
              );
            },
          ),
        ),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de créer le monde: $err')),
      );
    }
  }

  @override
  void dispose() {
    try { WidgetsBinding.instance.removeObserver(this); } catch (_) {}
    try { if (_syncListener != null && _sync != null) { _sync!.removeListener(_syncListener!); } } catch (_) {}
    // _authSub?.cancel() supprimé - listener authStateChanges retiré
    super.dispose();
  }

  /// CORRECTION CRITIQUE 1.3: Attend que la synchronisation cloud se termine
  /// Timeout de 10 secondes pour ne pas bloquer l'UI indéfiniment
  Future<void> _waitForSyncCompletion({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final syncState = GamePersistenceOrchestrator.instance.syncState.value;
    
    // Si pas de sync en cours, retourner immédiatement
    if (!syncState.isActive) {
      return;
    }
    
    if (kDebugMode) {
      print('[WORLDS-SCREEN] Waiting for sync completion | currentState=$syncState');
    }
    
    final completer = Completer<void>();
    Timer? timeoutTimer;
    VoidCallback? listener;
    
    listener = () {
      final state = GamePersistenceOrchestrator.instance.syncState.value;
      if (!state.isActive) {
        if (kDebugMode) {
          print('[WORLDS-SCREEN] Sync completed | finalState=$state');
        }
        
        timeoutTimer?.cancel();
        GamePersistenceOrchestrator.instance.syncState.removeListener(listener!);
        if (!completer.isCompleted) completer.complete();
      }
    };
    
    GamePersistenceOrchestrator.instance.syncState.addListener(listener);
    
    // Timeout pour ne pas bloquer indéfiniment
    timeoutTimer = Timer(timeout, () {
      if (kDebugMode) {
        print('[WORLDS-SCREEN] Sync wait timeout');
      }
      
      GamePersistenceOrchestrator.instance.syncState.removeListener(listener!);
      if (!completer.isCompleted) completer.complete();
    });
    
    await completer.future;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // MISSION STABILISATION: Recharger la liste lors du retour en avant-plan
      Future.microtask(() async {
        if (mounted) { await _load(); }
      });
    }
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuthService.instance.currentUser;
      
      if (user != null) {
        // CORRECTION CRITIQUE 1.3: Attendre fin sync si en cours
        final syncState = GamePersistenceOrchestrator.instance.syncState.value;
        if (syncState.isActive) {
          if (kDebugMode) {
            print('[WORLDS-SCREEN] Sync in progress, waiting...');
          }
          
          await _waitForSyncCompletion();
        }
        
        // Si forceRefresh, déclencher sync manuelle (pull-to-refresh)
        if (forceRefresh) {
          if (kDebugMode) {
            print('[WORLDS-SCREEN] Force refresh requested');
          }
          
          final syncResult = await GamePersistenceOrchestrator.instance
              .syncAllWorldsFromCloud(playerId: user.uid);
          
          if (!syncResult.isSuccess && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(syncResult.userMessage)),
            );
          }
        }
      }
      
      // Charger la liste locale (mise à jour après sync cloud)
      final entries = await SaveAggregator().listAll(context);
      // compute cloud canonical state
      final Map<String, String> states = {};
      final Map<String, String> labels = {};
      // backups count (via listSaves bas niveau pour performance)
      final mgr = await LocalSaveGameManager.getInstance();
      final allSaves = await mgr.listSaves();
      final Map<String, int> backupCounts = {};
      for (final m in allSaves.where((e) => e.name.contains(GameConstants.BACKUP_DELIMITER))) {
        final base = m.name.split('|').first;
        if (base.isEmpty) continue;
        backupCounts.update(base, (v) => v + 1, ifAbsent: () => 1);
      }
      for (final e in entries.where((e) => !e.isBackup)) {
        final s = await WorldStateHelper.canonicalStateFor(e);
        states[e.id] = s;
        labels[e.id] = WorldStateHelper.canonicalLabel(s);
      }
      if (!mounted) return;
      setState(() {
        _entries = entries.where((e) => !e.isBackup).toList();
        _applySort();
        _cloudStateById
          ..clear()
          ..addAll(states);
        _cloudLabelById
          ..clear()
          ..addAll(labels);
        _backupCountById
          ..clear()
          ..addAll(backupCounts);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      // Erreurs silencieuses pour un premier squelette
    }
  }

  void _applySort() {
    if (_sortMode == 1) {
      _entries.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      _entries.sort((a, b) => (b.lastModified ?? DateTime(0)).compareTo(a.lastModified ?? DateTime(0)));
    }
  }

  Future<void> _play(SaveEntry e) async {
    try {
      await context.read<RuntimeActions>().loadGameByIdAndStartAutoSave(e.id);
      context.read<RuntimeActions>().startSession();
      if (!mounted) return;
      // Naviguer explicitement vers l'écran principal du jeu pour un flux uniforme
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir ce monde: $err')),
      );
    }
  }

  Future<void> _rename(SaveEntry e) async {
    final newName = await showRenameWorldDialog(context, initialName: e.name);
    if (newName == null || newName.isEmpty || newName == e.name) return;
    
    // Mise à jour métadonnées locales
    final mgr = await LocalSaveGameManager.getInstance();
    final meta = await mgr.getSaveMetadata(e.id);
    if (meta == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Échec du renommage')));
      return;
    }
    
    final updated = meta.copyWith(name: newName, lastModified: DateTime.now());
    final ok = await mgr.updateSaveMetadata(e.id, updated);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Échec du renommage')));
      return;
    }
    
    // Push cloud si activé
    try {
      final prefs = await SharedPreferences.getInstance();
      final cloudEnabled = prefs.getBool('cloud_enabled') ?? false;
      if (cloudEnabled) {
        final uid = FirebaseAuthService.instance.currentUser?.uid;
        if (uid != null && uid.isNotEmpty) {
          await GamePersistenceOrchestrator.instance.pushCloudFromSaveId(
            partieId: e.id,
            uid: uid,
          );
        }
      }
    } catch (_) {}
    
    if (!mounted) return;
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom mis à jour')));
  }

  Future<void> _delete(SaveEntry e) async {
    final confirm = await showConfirmDeleteWorldDialog(context);
    if (!confirm) return;
    
    // Suppression locale
    await GamePersistenceOrchestrator.instance.deleteSaveById(e.id);
    
    // Suppression cloud avec logs détaillés
    bool cloudDeleted = false;
    String? cloudError;
    try {
      if (kDebugMode) {
        print('[WORLDS-SCREEN] Suppression cloud | worldId=${e.id}');
      }
      await GamePersistenceOrchestrator.instance.deleteCloudById(partieId: e.id);
      cloudDeleted = true;
      if (kDebugMode) {
        print('[WORLDS-SCREEN] Suppression cloud réussie | worldId=${e.id}');
      }
    } catch (err) {
      cloudError = err.toString();
      if (kDebugMode) {
        print('[WORLDS-SCREEN] Échec suppression cloud | worldId=${e.id} error=$err');
      }
    }
    
    if (!mounted) return;
    await _load();
    
    // Message utilisateur adapté
    final message = cloudDeleted 
        ? 'Monde supprimé (local + cloud)'
        : cloudError != null
            ? 'Monde supprimé localement (échec cloud: ${cloudError.split(':').last.trim()})'
            : 'Monde supprimé localement';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: cloudDeleted ? null : Colors.orange,
        duration: Duration(seconds: cloudDeleted ? 2 : 4),
      ),
    );
  }

  Future<void> _restore(SaveEntry e) async {
    try {
      final mgr = await LocalSaveGameManager.getInstance();
      final all = await mgr.listSaves();
      final backups = all.where((s) => s.name.startsWith('${e.id}|')).toList()
        ..sort((a, b) => b.lastModified.compareTo(a.lastModified));
      if (!mounted) return;
      if (backups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun backup disponible pour ce monde')));
        return;
      }
      final items = backups.map((b) => buildRestoreItem(backupName: b.name, timestamp: b.timestamp)).toList();
      await showRestoreWorldDialog(
        context,
        items: items,
        onPick: (picked) async {
          final state = context.read<GameState>();
          final ok = await GamePersistenceOrchestrator.instance.restoreFromBackup(state, picked.id);
          if (!mounted) return;
          if (ok) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restauré')));
            await _load();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Échec de la restauration')));
          }
        },
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur restauration: $err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarActions: [
        // NOUVEAU: Indicateur sync en cours
        if (_syncing)
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          ),
        PopupMenuButton<int>(
          tooltip: 'Trier',
          onSelected: (v) { setState(() { _sortMode = v; _applySort(); }); },
          itemBuilder: (ctx) => [
            CheckedPopupMenuItem<int>(value: 0, checked: _sortMode==0, child: const Text('Par date (récent en premier)')),
            CheckedPopupMenuItem<int>(value: 1, checked: _sortMode==1, child: const Text('Par nom (A→Z)')),
          ],
          icon: const Icon(Icons.sort_rounded),
        ),
        const GoogleAccountAction(),
      ],
      body: Column(
        children: [
          // Bandeau informatif si certains mondes sont uniquement dans le cloud
          if (_entries.any((e) => !e.canLoad))
            Builder(builder: (context) {
              final cs = Theme.of(context).colorScheme;
              return Container(
                width: double.infinity,
                color: cs.primaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.cloud_download_rounded, color: cs.onPrimaryContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Certains mondes sont uniquement dans le cloud. Téléchargez-les pour y jouer sur cet appareil.',
                        style: TextStyle(color: cs.onPrimaryContainer),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          final toDownload = _entries.where((e) => !e.canLoad).toList();
                          for (final e in toDownload) {
                            try { await GamePersistenceOrchestrator.instance.materializeFromCloud(partieId: e.id); } catch (_) {}
                          }
                          if (!mounted) return;
                          await _load();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Téléchargement terminé')),
                          );
                        } catch (_) {}
                      },
                      child: const Text('Télécharger tout'),
                    ),
                  ],
                ),
              );
            }),
          if ((_sync?.value ?? SyncState.ready) == SyncState.pendingIdentity)
            Builder(builder: (context) {
              final cs = Theme.of(context).colorScheme;
              return Container(
                width: double.infinity,
                color: cs.secondaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Connectez-vous pour activer la synchronisation cloud.',
                  style: TextStyle(color: cs.onSecondaryContainer),
                ),
              );
            }),
          if ((_sync?.value ?? SyncState.ready) == SyncState.error)
            Builder(builder: (context) {
              final cs = Theme.of(context).colorScheme;
              return Container(
                width: double.infinity,
                color: cs.errorContainer,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Hors-ligne ou erreur réseau — certaines actions cloud sont indisponibles.',
                  style: TextStyle(color: cs.onErrorContainer),
                ),
              );
            }),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(forceRefresh: true), // CORRECTION #5: Forcer refresh au pull-to-refresh
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            EmptyState(
                              icon: Icons.travel_explore_outlined,
                              title: 'Aucun monde',
                              message: 'Créez votre premier monde pour commencer l\'aventure.',
                              actionLabel: 'Créer un monde',
                              onAction: _createNewWorld,
                            ),
                            const SizedBox(height: 24),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _entries.length,
                          itemBuilder: (ctx, i) {
                            final e = _entries[i];
                            final cloudState = _cloudStateById[e.id] ?? 'local_only';
                            final cloudLabel = _cloudLabelById[e.id] ?? 'Local uniquement';
                            final backups = _backupCountById[e.id] ?? 0;
                            return WorldCard(
                              entry: e,
                              cloudState: cloudState,
                              cloudLabel: cloudLabel,
                              backupCount: backups,
                              canLoad: e.canLoad,
                              // NOUVEAU: Désactiver actions pendant sync
                              onPlay: !_syncing ? () => _play(e) : () {},
                              onRename: !_syncing ? () => _rename(e) : () {},
                              onDelete: !_syncing ? () => _delete(e) : () {},
                              onRestore: (_syncing || backups == 0) ? null : () => _restore(e),
                              onRetry: (cloudState == 'cloud_error' || cloudState == 'cloud_pending')
                                  ? () async {
                                      try {
                                        final uid = FirebaseAuthService.instance.currentUser?.uid;
                                        if (uid != null && uid.isNotEmpty) {
                                          await GamePersistenceOrchestrator.instance.pushCloudFromSaveId(partieId: e.id, uid: uid);
                                        }
                                        if (!mounted) return;
                                        await _load();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('✅ Synchronisation cloud réussie')),
                                        );
                                      } catch (err) {
                                        if (!mounted) return;
                                        // CORRECTION AUDIT: Message d'erreur plus explicite
                                        final errorMsg = err.toString().contains('PLAYER_ID_REQUIRED')
                                            ? 'Connexion requise pour synchroniser'
                                            : 'Échec synchronisation: ${err.toString().split(':').last.trim()}';
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(errorMsg),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(seconds: 4),
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              onDownload: e.canLoad
                                  ? null
                                  : () async {
                                      try {
                                        await GamePersistenceOrchestrator.instance.materializeFromCloud(partieId: e.id);
                                        if (!mounted) return;
                                        await _load();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Monde téléchargé depuis le cloud')),
                                        );
                                      } catch (err) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Échec du téléchargement: $err')),
                                        );
                                      }
                                    },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        // NOUVEAU: Désactiver création pendant sync
        onPressed: _syncing ? null : _createNewWorld,
        tooltip: 'Nouveau monde',
        child: const Icon(Icons.add),
      ),
    );
  }
}
