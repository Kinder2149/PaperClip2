// lib/services/persistence/game_persistence_orchestrator.dart
import 'dart:async';
// Service d'orchestration de la persistance de l'état de jeu.
//
// Ce service centralise la logique de sauvegarde/chargement/backup
// et délègue au système existant (SaveManagerAdapter, GamePersistenceService),
// afin de garder GameState focalisé sur la logique métier et la sérialisation.

import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_adapter.dart';
import 'package:paperclip2/services/cloud/models/cloud_world_detail.dart';
import 'package:paperclip2/services/auth/firebase_auth_service.dart';
import 'package:paperclip2/services/persistence/game_persistence_service.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/persistence/snapshot_validator.dart';
import 'package:paperclip2/services/persistence/sync_result.dart';
import 'package:paperclip2/services/persistence/sync_state.dart';
import 'package:paperclip2/services/save_system/save_validator.dart';
import 'package:paperclip2/services/save_game.dart';
import 'package:paperclip2/models/save_metadata.dart';
import 'package:paperclip2/services/notification_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperclip2/utils/logger.dart';
import 'package:paperclip2/screens/conflict_resolution_screen.dart';

// CORRECTION AUDIT P2 #5: Timeouts standardisés et documentés
// 
// Ces timeouts sont différenciés selon le type d'opération pour optimiser
// le compromis entre UX (réactivité) et fiabilité (connexions lentes).

/// Timeout pour sauvegarde locale (écriture disque)
/// Valeur: 10 secondes
/// Justification: Écriture disque rapide, même sur appareils anciens
const Duration kLocalSaveTimeout = Duration(seconds: 10);

/// Timeout pour push cloud (requête HTTP PUT)
/// Valeur: 60 secondes
/// Justification: Connexion 3G lente possible, snapshots volumineux
const Duration kCloudPushTimeout = Duration(seconds: 60);

/// Timeout pour matérialisation cloud (requête HTTP GET + écriture locale)
/// Valeur: 30 secondes
/// Justification: Compromis entre UX (pas trop long) et fiabilité (connexion lente)
const Duration kCloudMaterializeTimeout = Duration(seconds: 30);

/// Timeout pour liste des mondes cloud (requête HTTP GET)
/// Valeur: 15 secondes
/// Justification: Requête légère, doit être rapide pour UX au login
const Duration kCloudListTimeout = Duration(seconds: 15);

enum SaveTrigger {
  autosave,
  importantEvent,
  manual,
  lifecycle,
  backup,
}

enum SavePriority {
  low,
  normal,
  high,
  critical,
}

class SaveRequest {
  final SaveTrigger trigger;
  final SavePriority priority;
  final String slotId;
  final bool isBackup;
  final DateTime requestedAt;
  final String? reason;

  const SaveRequest({
    required this.trigger,
    required this.priority,
    required this.slotId,
    required this.isBackup,
    required this.requestedAt,
    this.reason,
  });
}

const bool _isDebug = !bool.fromEnvironment('dart.vm.product');

/// Service d'orchestration de la persistance pour GameState.
class GamePersistenceOrchestrator {
  GamePersistenceOrchestrator._();

  static final GamePersistenceOrchestrator instance = GamePersistenceOrchestrator._();
  static final Logger _logger = Logger.forComponent('persist');

  final GamePersistenceService _persistence = const LocalGamePersistenceService();
  // Port cloud optionnel (injecté depuis le bootstrap ou un service)
  CloudPersistencePort? _cloudPort;
  // BuildContext optionnel pour afficher l'écran de résolution de conflits
  BuildContext? _navigationContext;
  
  /// IDENTITÉ CANONIQUE (CRITIQUE):
  /// - uid Firebase = identité technique backend (SOURCE DE VÉRITÉ)
  /// - playerId Google Play = identité cosmétique (affichage UI uniquement)
  /// - RÈGLE: Toute logique métier DOIT utiliser uid, JAMAIS playerId
  /// - Backend isole données par uid: players/{uid}/saves/{enterpriseId}
  /// 
  /// Utiliser FirebaseAuthService.instance.currentUser?.uid pour obtenir l'identité
  
  // Mission: mémoire de première sauvegarde par monde pour snapshot "après première save"
  final Set<String> _firstSaveLogged = <String>{};

  static const Duration _backupCooldown = Duration(minutes: 10);
  static const Duration _importantEventCoalesceWindow = Duration(seconds: 2);
  static const Duration _autoSaveDebounceWindow = Duration(seconds: 10);

  final List<SaveRequest> _queue = <SaveRequest>[];
  bool _isPumping = false;
  // ZONE D'OMBRE #4: Backup cooldown par enterpriseId au lieu de global
  final Map<String, DateTime> _lastBackupAtByPartie = <String, DateTime>{};
  DateTime? _lastImportantEventEnqueuedAt;
  final Map<String, DateTime> _lastAutoSaveAtBySlot = <String, DateTime>{};
  final Map<String, DateTime> _lastImportantEventAtBySlot = <String, DateTime>{};

  // Etat de synchronisation applicatif
  final ValueNotifier<SyncState> syncState = ValueNotifier<SyncState>(SyncState.ready);

  void resetForTesting() {
    _queue.clear();
    _isPumping = false;
    _lastBackupAtByPartie.clear();
    _lastImportantEventEnqueuedAt = null;
    _lastAutoSaveAtBySlot.clear();
    _lastImportantEventAtBySlot.clear();
  }

  // Assure les champs contractuels requis par le backend et le validateur
  GameSnapshot _normalizeSnapshotContract(GameSnapshot snapshot) {
    final meta = Map<String, dynamic>.from(snapshot.metadata);
    final nowIso = DateTime.now().toIso8601String();
    // createdAt: si absent/invalid → fallback savedAt → now
    final createdAtRaw = meta['createdAt'];
    if (createdAtRaw is! String || DateTime.tryParse(createdAtRaw) == null) {
      final savedAt = meta['savedAt'];
      meta['createdAt'] = (savedAt is String && DateTime.tryParse(savedAt) != null) ? savedAt : nowIso;
    }
    // lastModified: toujours présent
    meta['lastModified'] = nowIso;
    // version (contrat): int
    final contractVersion = meta['version'];
    if (contractVersion is! int) {
      // Fixer une valeur entière canonique pour le contrat de snapshot
      meta['version'] = 2;
    }
    return GameSnapshot(
      metadata: meta,
      core: snapshot.core,
      market: snapshot.market,
      production: snapshot.production,
      stats: snapshot.stats,
    );
  }
  /// Supprime l'entrée cloud pour une partie (cloud-only ou non)
  Future<void> deleteCloudById({
    required String partieId,
  }) async {
    final port = _cloudPort;
    if (port == null) {
      throw StateError('Cloud port not configured');
    }
    await port.deleteById(enterpriseId: partieId);
  }

  // Injection du port cloud (GPG, HTTP, etc.)
  void setCloudPort(CloudPersistencePort port) {
    final portType = port.runtimeType.toString();
    final isNoop = portType.contains('Noop');
    
    _logger.info('[cloud][config] setCloudPort', code: 'cloud_config', ctx: {
      'portType': portType,
      'isNoop': isNoop,
    });
    _cloudPort = port;
  }

  /// Définit le contexte de navigation pour afficher l'écran de résolution de conflits
  void setNavigationContext(BuildContext? context) {
    _navigationContext = context;
  }

  /// Affiche l'écran de résolution de conflits et retourne le choix de l'utilisateur
  Future<ConflictChoice?> _showConflictResolution({
    required GameSnapshot localSnapshot,
    required GameSnapshot cloudSnapshot,
    required String enterpriseId,
  }) async {
    final context = _navigationContext;
    if (context == null || !context.mounted) {
      _logger.warn('[CONFLICT] Pas de contexte de navigation', code: 'conflict_no_context');
      return null;
    }

    try {
      final choice = await Navigator.of(context).push<ConflictChoice>(
        MaterialPageRoute(
          builder: (context) => ConflictResolutionScreen(
            data: ConflictResolutionData(
              localSnapshot: localSnapshot,
              cloudSnapshot: cloudSnapshot,
              enterpriseId: enterpriseId,
            ),
          ),
        ),
      );
      
      _logger.info('[CONFLICT] Choix utilisateur', code: 'conflict_choice', ctx: {
        'choice': choice?.toString() ?? 'null',
        'enterpriseId': enterpriseId,
      });
      
      return choice;
    } catch (e) {
      _logger.error('[CONFLICT] Erreur affichage écran', code: 'conflict_error', ctx: {
        'error': e.toString(),
      });
      return null;
    }
  }

  /// Extrait un GameSnapshot depuis un SaveGame
  GameSnapshot _extractSnapshot(SaveGame save) {
    final data = save.gameData;
    final snapshotKey = LocalGamePersistenceService.snapshotKey;
    final rawSnapshot = data[snapshotKey];
    
    if (rawSnapshot is Map<String, dynamic>) {
      return GameSnapshot.fromJson(rawSnapshot);
    } else if (rawSnapshot is Map) {
      return GameSnapshot.fromJson(Map<String, dynamic>.from(rawSnapshot));
    } else if (rawSnapshot is String) {
      return GameSnapshot.fromJsonString(rawSnapshot);
    }
    
    throw StateError('Snapshot format invalide: ${rawSnapshot.runtimeType}');
  }

  // --- Wrappers locaux (unifié, sans SaveManagerAdapter) ---
  Future<List<SaveGameInfo>> _listSavesViaLocalManager() async {
    final mgr = await LocalSaveGameManager.getInstance();
    final metas = await mgr.listSaves();
    // Construire une vue SaveGameInfo minimale à partir des métadonnées
    return metas
        .map((m) => SaveGameInfo.fromMetadata(m, isBackup: m.name.contains(GameConstants.BACKUP_DELIMITER)))
        .toList();
  }

  // Mission: log un snapshot des mondes (IDs non-backup) pour visibilité A->B
  Future<void> _logWorldsSnapshot({required String codeTag}) async {
    try {
      final metas = await _listSavesViaLocalManager();
      final ids = metas
          .where((m) => !m.name.contains(GameConstants.BACKUP_DELIMITER))
          .map((m) => m.id)
          .toList();
      _logger.info('📃 WORLDS-SNAPSHOT', code: codeTag, ctx: {
        'count': ids.length,
        'ids': ids.join(','),
      });
    } catch (_) {}
  }

  Future<SaveGame?> _loadSaveByIdViaLocalManager(String id) async {
    final mgr = await LocalSaveGameManager.getInstance();
    return mgr.loadSave(id);
  }

  Future<SaveMetadata?> _getSaveMetadataByIdViaLocalManager(String id) async {
    final mgr = await LocalSaveGameManager.getInstance();
    return mgr.getSaveMetadata(id);
  }

  Future<bool> _updateSaveMetadataByIdViaLocalManager(String id, SaveMetadata metadata) async {
    final mgr = await LocalSaveGameManager.getInstance();
    return mgr.updateSaveMetadata(id, metadata);
  }

  Future<SaveGame?> _getLastSaveViaLocalManager() async {
    final mgr = await LocalSaveGameManager.getInstance();
    final metas = await mgr.listSaves();
    if (metas.isEmpty) return null;
    // Préférer la plus récente non-backup si possible
    final regular = metas.where((m) => !m.name.contains(GameConstants.BACKUP_DELIMITER)).toList();
    final first = (regular.isNotEmpty ? regular.first : metas.first);
    return mgr.loadSave(first.id);
  }

  Future<void> _deleteSaveByIdViaLocalManager(String id) async {
    final mgr = await LocalSaveGameManager.getInstance();
    await mgr.deleteSave(id);
  }

  /// Boot: vérifie la dernière sauvegarde (si elle existe) et tente une restauration
  /// depuis le backup le plus récent si la sauvegarde semble invalide.
  ///
  /// Note: cette méthode n'applique rien dans le GameState; elle ne fait qu'assurer
  /// que la sauvegarde principale est saine avant d'entrer dans l'UI.
  Future<void> checkAndRestoreLastSaveFromBackupIfNeeded() async {
    try {
      final lastSave = await _getLastSaveViaLocalManager();
      if (lastSave == null) {
        return;
      }
      
      // Utiliser l'ID unique comme base key pour les backups (ID-first)
      final baseKey = lastSave.id;

      ValidationResult validation;
      try {
        final data = lastSave.gameData;
        final snapshotKey = LocalGamePersistenceService.snapshotKey;
        if (!data.containsKey(snapshotKey)) {
          validation = ValidationResult(
            isValid: false,
            errors: ['Snapshot manquant dans la sauvegarde'],
            severity: ValidationSeverity.critical,
          );
        } else {
          final rawSnapshot = data[snapshotKey];
          GameSnapshot? snapshot;
          if (rawSnapshot is Map<String, dynamic>) {
            final snapshotMap = rawSnapshot;
            snapshot = GameSnapshot.fromJson(snapshotMap);
          } else if (rawSnapshot is Map) {
            final snapshotMap = Map<String, dynamic>.from(rawSnapshot);
            snapshot = GameSnapshot.fromJson(snapshotMap);
          } else if (rawSnapshot is String) {
            snapshot = GameSnapshot.fromJsonString(rawSnapshot);
          }

          if (snapshot == null) {
            validation = ValidationResult(
              isValid: false,
              errors: ['Snapshot illisible (format inattendu)'],
              severity: ValidationSeverity.critical,
            );
          } else {
            await _persistence.migrateSnapshot(snapshot);
            validation = ValidationResult(
              isValid: true,
              errors: const [],
              severity: ValidationSeverity.none,
            );
          }
        }
      } catch (e) {
        validation = ValidationResult(
          isValid: false,
          errors: ['Erreur lors de la validation rapide: $e'],
          severity: ValidationSeverity.critical,
        );
      }

      if (validation.severity != ValidationSeverity.critical) {
        return;
      }

      _logger.info(
        'checkAndRestoreLastSaveFromBackupIfNeeded: sauvegarde invalide, tentative de restauration',
        code: 'restore_attempt',
        ctx: {'name': lastSave.name, 'errors': validation.errors.length},
      );

      final saves = await _listSavesViaLocalManager();
      final backups = saves
          .where((save) => save.name.startsWith('$baseKey${GameConstants.BACKUP_DELIMITER}'))
          .toList();

      if (backups.isEmpty) {
        _logger.debug(
          'checkAndRestoreLastSaveFromBackupIfNeeded: aucun backup trouvé',
          code: 'no_backup',
          ctx: {'baseKey': baseKey},
        );
        return;
      }

      backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final latestBackupName = backups.first.name;

      try {
        // Résoudre le backup par nom vers son ID, puis charger par ID (ID-first)
        final allMetas = await _listSavesViaLocalManager();
        final match = allMetas.where((m) => m.name == latestBackupName).toList()
          ..sort((a,b)=>b.timestamp.compareTo(a.timestamp));
        if (match.isEmpty) {
          return;
        }
        final backupSave = await _loadSaveByIdViaLocalManager(match.first.id);
        if (backupSave == null) {
          return;
        }

        final restoredSave = SaveGame(
          // Écraser la sauvegarde existante en conservant exactement le même identifiant
          id: lastSave.id,
          name: lastSave.name,
          lastSaveTime: DateTime.now(),
          gameData: backupSave.gameData,
          version: backupSave.version,
          isRestored: true,
        );

        final mgr = await LocalSaveGameManager.getInstance();
        final ok = await mgr.saveGame(restoredSave);
        _logger.info(
          'Restauration depuis backup',
          code: 'restore_result',
          ctx: {'backup': latestBackupName, 'name': lastSave.name, 'ok': ok},
        );
      } catch (e) {
        _logger.warn(
          'Echec restauration depuis backup',
          code: 'restore_fail',
          ctx: {'backup': latestBackupName, 'err': e.toString()},
        );
      }
    } catch (e) {
      _logger.warn('checkAndRestoreLastSaveFromBackupIfNeeded: erreur', code: 'restore_error', ctx: {'err': e.toString()});
    }
  }

  /// Parse un horodatage ISO8601 en DateTime (ou null si invalide)
  DateTime? _parseIso(String v) {
    if (v.isEmpty) return null;
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }

  Future<void> requestAutoSave(GameState state, {String? reason}) async {
    if (!state.isInitialized) return;
    // ID-first: utiliser l'identité technique de la partie pour le keying/coalescing
    final pid = state.enterpriseId;
    if (pid == null || pid.isEmpty) return;
    // Anti-rafale: ignorer si une autosave récente a déjà été enfilée pour ce slot
    final now = DateTime.now();
    final lastAuto = _lastAutoSaveAtBySlot[pid];
    if (lastAuto != null && now.difference(lastAuto) < _autoSaveDebounceWindow) {
      return;
    }
    _lastAutoSaveAtBySlot[pid] = now;
    await _enqueue(
      state,
      SaveRequest(
        trigger: SaveTrigger.autosave,
        priority: SavePriority.low,
        slotId: pid,
        isBackup: false,
        requestedAt: now,
        reason: reason,
      ),
    );
  }

  Future<void> requestImportantSave(GameState state, {String? reason}) async {
    if (!state.isInitialized) return;
    final pid = state.enterpriseId;
    if (pid == null || pid.isEmpty) return;

    final now = DateTime.now();
    _lastImportantEventEnqueuedAt ??= now;
    // Anti-rafale: limiter les événements importants par slot sur une fenêtre courte
    final lastImp = _lastImportantEventAtBySlot[pid];
    if (lastImp != null && now.difference(lastImp) < _importantEventCoalesceWindow) {
      return;
    }
    _lastImportantEventAtBySlot[pid] = now;

    await _enqueue(
      state,
      SaveRequest(
        trigger: SaveTrigger.importantEvent,
        priority: SavePriority.normal,
        slotId: pid,
        isBackup: false,
        requestedAt: now,
        reason: reason,
      ),
    );
  }

  Future<void> requestManualSave(
    GameState state, {
    String? slotId,
    String? reason,
  }) async {
    if (!state.isInitialized) return;
    // ID-first: force l'utilisation du enterpriseId, ignore un slotId textuel si fourni
    final pid = state.enterpriseId;
    if (pid == null || pid.isEmpty) return;
    await _enqueue(
      state,
      SaveRequest(
        trigger: SaveTrigger.manual,
        priority: SavePriority.high,
        slotId: pid,
        isBackup: false,
        requestedAt: DateTime.now(),
        reason: reason,
      ),
    );
  }

  Future<void> requestLifecycleSave(GameState state, {String? reason}) async {
    if (!state.isInitialized) return;
    final pid = state.enterpriseId;
    if (pid == null || pid.isEmpty) return;

    final now = DateTime.now();

    await _enqueue(
      state,
      SaveRequest(
        trigger: SaveTrigger.lifecycle,
        // Phase 4: priorité intermédiaire (manual > lifecycle > autosave)
        priority: SavePriority.normal,
        slotId: pid,
        isBackup: false,
        requestedAt: now,
        reason: reason,
      ),
    );

    // ZONE D'OMBRE #4: Vérifier cooldown par enterpriseId
    final baseKey = state.enterpriseId;
    if (baseKey == null || baseKey.isEmpty) {
      // Pas d'ID -> pas de backup (on n'autorise pas de backup sans identifiant)
      return;
    }
    
    final lastBackup = _lastBackupAtByPartie[baseKey];
    final shouldBackup = lastBackup == null || now.difference(lastBackup) >= _backupCooldown;
    if (shouldBackup) {
      final backupName = '$baseKey${GameConstants.BACKUP_DELIMITER}${now.millisecondsSinceEpoch}';
      _lastBackupAtByPartie[baseKey] = now;
      await _enqueue(
        state,
        SaveRequest(
          trigger: SaveTrigger.backup,
          priority: SavePriority.high,
          slotId: backupName,
          isBackup: true,
          requestedAt: now,
          reason: 'lifecycle_backup',
        ),
      );
    }
  }

  Future<void> requestBackup(
    GameState state, {
    required String backupName,
    String? reason,
    bool bypassCooldown = false,
  }) async {
    if (!state.isInitialized || state.enterpriseName == null) return;
    // Identité stricte: refuser les backups si l'ID de partie est absent
    if (state.enterpriseId == null || state.enterpriseId!.isEmpty) return;

    final now = DateTime.now();
    // ZONE D'OMBRE #4: Vérifier cooldown par enterpriseId
    final baseKey = state.enterpriseId;
    if (baseKey == null || baseKey.isEmpty) return;
    
    final lastBackup = _lastBackupAtByPartie[baseKey];
    if (!bypassCooldown && lastBackup != null && now.difference(lastBackup) < _backupCooldown) {
      return;
    }
    _lastBackupAtByPartie[baseKey] = now;

    await _enqueue(
      state,
      SaveRequest(
        trigger: SaveTrigger.backup,
        priority: SavePriority.high,
        slotId: backupName,
        isBackup: true,
        requestedAt: now,
        reason: reason,
      ),
    );
  }

  Future<void> _enqueue(GameState state, SaveRequest request) async {
    // Coalescing autosave: 1 seule autosave en attente par slot.
    if (request.trigger == SaveTrigger.autosave) {
      _queue.removeWhere((r) => r.trigger == SaveTrigger.autosave && r.slotId == request.slotId);
    }

    // Coalescing important events: 1 seule en attente par slot.
    if (request.trigger == SaveTrigger.importantEvent) {
      _queue.removeWhere(
        (r) => r.trigger == SaveTrigger.importantEvent && r.slotId == request.slotId,
      );
    }

    // CORRECTION: Coalescing lifecycle: 1 seule en attente par slot pour éviter tempête de requêtes
    if (request.trigger == SaveTrigger.lifecycle) {
      _queue.removeWhere(
        (r) => r.trigger == SaveTrigger.lifecycle && r.slotId == request.slotId,
      );
    }

    // Anti-rafale complémentaire: si un manual est déjà en file pour ce slot,
    // on peut ignorer les autosave/importantEvent plus faibles.
    final hasManualForSlot = _queue.any((r) => r.slotId == request.slotId && r.trigger == SaveTrigger.manual);
    if (hasManualForSlot && (request.trigger == SaveTrigger.autosave || request.trigger == SaveTrigger.importantEvent)) {
      return;
    }

    _queue.add(request);

    _logger.info(
      '[SAVE-QUEUE] enqueue',
      code: 'save_queue_enqueue',
      ctx: {
        'trigger': request.trigger.toString(),
        'priority': request.priority.toString(),
        'worldId': request.slotId,
        'backup': request.isBackup,
        'queue': _queue.length,
      },
    );

    // Ne pas bloquer le thread appelant: lancer la pompe en tâche de fond
    Future.microtask(() => _pump(state));
  }

  SaveRequest _pickNext() {
    // Priorité puis ancienneté.
    _queue.sort((a, b) {
      final p = b.priority.index.compareTo(a.priority.index);
      if (p != 0) return p;
      return a.requestedAt.compareTo(b.requestedAt);
    });
    return _queue.removeAt(0);
  }

  Future<void> _pump(GameState state) async {
    if (_isPumping) return;
    _isPumping = true;
    try {
      syncState.value = SyncState.syncing;
      while (_queue.isNotEmpty) {
        final next = _pickNext();
        try {
          _logger.info(
            '[SAVE-PUMP] pump_start',
            code: 'save_pump_start',
            ctx: {
              'trigger': next.trigger.toString(),
              'worldId': next.slotId,
              'backup': next.isBackup,
            },
          );
          // ID-first: pour les sauvegardes non-backup, interpréter slotId comme enterpriseId
          final isBackupName = next.isBackup || next.slotId.contains(GameConstants.BACKUP_DELIMITER);
          // Sécurité monde courant: si l'utilisateur a changé de monde entre l'enqueue et l'exécution,
          // éviter toute écriture sur un monde non courant. On ne traite que si l'identité correspond.
          if (!isBackupName) {
            final currentPid = state.enterpriseId;
            if (currentPid == null || currentPid.isEmpty || currentPid != next.slotId) {
              _logger.warn('[SAVE-PUMP] Skip request: monde courant différent', code: 'save_skip_world_mismatch', ctx: {
                'requestedWorldId': next.slotId,
                'currentWorldId': currentPid ?? '',
                'trigger': next.trigger.toString(),
              });
              // On ignore cette requête pour éviter une confusion entre mondes
              continue;
            }
          }
          // CORRECTION #7: Séparer timeouts local (10s) et cloud (60s)
          // Sauvegarde locale doit être rapide, push cloud peut être lent sur connexion 3G
          try {
            if (isBackupName) {
              // Backup : timeout court (local only)
              await saveGame(state, next.slotId).timeout(
                kLocalSaveTimeout,
                onTimeout: () {
                  _logger.error('[SAVE-PUMP] Timeout backup', code: 'save_timeout_backup', ctx: {
                    'slotId': next.slotId,
                    'timeout': kLocalSaveTimeout.inSeconds,
                  });
                  throw TimeoutException('Backup timeout après ${kLocalSaveTimeout.inSeconds}s');
                },
              );
            } else {
              // Sauvegarde normale : timeout local court (10s)
              // Le push cloud sera fait séparément avec timeout long (60s)
              await saveGameById(state).timeout(
                kLocalSaveTimeout,
                onTimeout: () {
                  _logger.error('[SAVE-PUMP] Timeout local save', code: 'save_timeout_local', ctx: {
                    'enterpriseId': state.enterpriseId,
                    'timeout': kLocalSaveTimeout.inSeconds,
                  });
                  throw TimeoutException('Local save timeout après ${kLocalSaveTimeout.inSeconds}s');
                },
              );
            }
          } on TimeoutException catch (e) {
            _logger.error('[SAVE-PUMP] Save timeout détecté', code: 'save_timeout_caught', ctx: {
              'error': e.toString(),
              'slotId': next.slotId,
            });
            rethrow;
          }
          try {
            _logger.info('[WORLD-SAVE] done', code: 'world_save_done', ctx: {
              'worldId': isBackupName ? next.slotId : next.slotId,
              'type': next.trigger.toString(),
              'backup': isBackupName,
            });
          } catch (_) {}
          state.markLastSaveTime(DateTime.now());
          // CORRECTION: Push cloud centralisé ici après chaque save réussie (sauf backups)
          if (!isBackupName) {
            try {
              final pid = next.slotId;
              if (pid != null && pid.isNotEmpty) {
                // P0-1: Utiliser uid Firebase comme identité canonique
                final uid = FirebaseAuthService.instance.currentUser?.uid;
                if (uid != null && uid.isNotEmpty) {
                  // CORRECTION #7: Timeout cloud long (60s) pour connexions lentes
                  await pushCloudById(
                    enterpriseId: pid,
                    state: state,
                    uid: uid, // ✅ Identité Firebase canonique
                    reason: 'pump_auto_push_${next.trigger.toString()}',
                  ).timeout(
                    kCloudPushTimeout,
                    onTimeout: () {
                      _logger.warn('[PUMP] Timeout cloud push - marquage pending', code: 'pump_cloud_timeout', ctx: {
                        'worldId': pid,
                        'timeout': kCloudPushTimeout.inSeconds,
                      });
                      throw TimeoutException('Cloud push timeout après ${kCloudPushTimeout.inSeconds}s');
                    },
                  );
                } else {
                  // P0-1: uid Firebase manquant (utilisateur non connecté)
                  _logger.warn('[PUMP] uid Firebase manquant, marquage pending', code: 'pump_no_uid', ctx: {
                    'worldId': pid,
                  });
                  
                  // Marquer comme pending pour retry au prochain login
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('pending_identity_$pid', DateTime.now().toIso8601String());
                  } catch (_) {}
                  
                  // P0-1: Notification utilisateur (uid Firebase requis)
                  NotificationManager.instance.showNotification(
                    message: '💾 Monde sauvegardé localement\n'
                             '🔐 Connectez-vous avec Google pour synchroniser',
                    level: NotificationLevel.WARNING,
                    duration: const Duration(seconds: 7),
                  );
                }
              }
            } on TimeoutException catch (e) {
              // CORRECTION #7: Gérer timeout cloud spécifiquement
              _logger.warn('[PUMP] Timeout cloud push (60s)', code: 'pump_cloud_timeout', ctx: {
                'error': e.toString(),
                'worldId': next.slotId,
              });
              
              // Marquer comme pending pour retry
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('pending_identity_${next.slotId}', DateTime.now().toIso8601String());
              } catch (_) {}
              
              // Notification timeout spécifique
              NotificationManager.instance.showNotification(
                message: '⏱️ Synchronisation lente - Retry automatique au prochain login',
                level: NotificationLevel.INFO,
                duration: const Duration(seconds: 5),
              );
            } catch (e) {
              // CORRECTION #6: Logger et notifier au lieu d'avaler l'exception
              _logger.error('[PUMP] Push cloud échoué', code: 'pump_push_error', ctx: {
                'error': e.toString(),
                'worldId': next.slotId,
              });
              
              // Marquer comme pending pour retry
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('pending_identity_${next.slotId}', DateTime.now().toIso8601String());
              } catch (_) {}
              
              // Notification contextuelle selon le type d'erreur
              final errorMsg = e.toString().toLowerCase();
              String userMessage = '⚠️ Synchronisation cloud échouée';
              
              if (errorMsg.contains('network') || errorMsg.contains('socket')) {
                userMessage = '📡 Erreur réseau - Retry automatique au prochain login';
              } else if (errorMsg.contains('auth') || errorMsg.contains('token') || errorMsg.contains('unauthorized')) {
                userMessage = '🔐 Reconnectez-vous pour synchroniser';
              } else if (errorMsg.contains('cloud_disabled') || errorMsg.contains('noop')) {
                userMessage = '☁️ Cloud désactivé - Activez-le dans les paramètres';
              }
              
              NotificationManager.instance.showNotification(
                message: userMessage,
                level: NotificationLevel.WARNING,
                duration: const Duration(seconds: 5),
              );
            }
          }
          // Mission: après la toute première sauvegarde d'un monde, logguer le snapshot des mondes
          try {
            if (!isBackupName) {
              final wid = state.enterpriseId ?? next.slotId;
              if (wid.isNotEmpty && !_firstSaveLogged.contains(wid)) {
                _firstSaveLogged.add(wid);
                await _logWorldsSnapshot(codeTag: 'worlds_snapshot_after_first_save');
              }
            }
          } catch (_) {}
        } catch (e) {
          _logger.warn('pump: erreur', code: 'pump_error', ctx: {'err': e.toString()});
          if (next.trigger == SaveTrigger.lifecycle) {
            try {
              final now = DateTime.now();
              final baseKey = state.enterpriseId ?? (state.enterpriseName ?? 'default');
              final backupName =
                  '$baseKey${GameConstants.BACKUP_DELIMITER}${now.millisecondsSinceEpoch}';
              await saveGame(state, backupName);
            } catch (_) {
              // Best-effort seulement.
            }
          }
        }
      }
    } finally {
      _isPumping = false;
      // Revenir en état prêt si file vidée
      if (_queue.isEmpty) {
        // Si une erreur globale est détectée précédemment on ne la conserve pas bloquante
        syncState.value = SyncState.ready;
      }
    }
  }

  /// Sauvegarde complète de l'état de jeu courant.
  /// ID-first: utilise `state.enterpriseId` si présent; sinon fallback legacy par nom.
  /// MISSION STABILISATION: Push cloud automatique pour toutes les sauvegardes (cloud-first strict).
  Future<void> saveGame(GameState state, String name) async {
    if (!state.isInitialized) {
      throw SaveError('NOT_INITIALIZED', "Le jeu n'est pas initialisé");
    }

    try {
      // PR3 (A2): écriture snapshot-only.
      // On n'écrit plus le payload legacy complet (prepareGameData) afin d'éviter
      // les divergences + faciliter l'évolution de schéma.
      final snapshot = state.toSnapshot();
      // Cohérence identité: pour les sauvegardes non-backup, enterpriseId du snapshot doit correspondre
      final bool isBackupName = name.contains(GameConstants.BACKUP_DELIMITER);
      if (!isBackupName) {
        final snapPartieId = snapshot.metadata['enterpriseId'];
        if (snapPartieId is! String || snapPartieId.isEmpty) {
          throw SaveError('PARTIE_ID_MISSING', 'Snapshot sans metadata.enterpriseId');
        }
        if (state.enterpriseId != null && state.enterpriseId!.isNotEmpty && snapPartieId != state.enterpriseId) {
          throw SaveError('PARTIE_ID_MISMATCH', 'metadata.enterpriseId ne correspond pas à la partie courante');
        }
      }
      // Normalisation contrat (timestamps/version)
      final normalized = _normalizeSnapshotContract(snapshot);
      // Validation stricte du snapshot avant toute persistance
      final snapValidationSaveGame = SnapshotValidator.validate(normalized);
      if (!snapValidationSaveGame.isValid) {
        final msg = snapValidationSaveGame.errors.map((e) => e.toString()).join('; ');
        throw SaveError('SNAPSHOT_INVALID', 'Snapshot invalide: ' + msg);
      }
      final gameData = <String, dynamic>{
        LocalGamePersistenceService.snapshotKey: normalized.toJson(),
      };

      // Identité stricte: l'ID technique de la partie est obligatoire pour toute sauvegarde non-backup
      String? existingId = state.enterpriseId;
      if (isBackupName) {
        // Backups: toujours une nouvelle entrée indépendante de l'ID de la partie
        existingId = null;
      } else {
        if (existingId == null || existingId.isEmpty) {
          throw SaveError('MISSING_ID', 'ID de partie absent: impossible de sauvegarder sans identifiant technique');
        }
      }

      final saveData = SaveGame(
        id: existingId,
        name: name,
        lastSaveTime: DateTime.now(),
        gameData: gameData,
        version: GameConstants.VERSION,
      );

      final mgr = await LocalSaveGameManager.getInstance();
      await mgr.saveGame(saveData);
      // CORRECTION: Push cloud supprimé ici - géré uniquement par la queue via _pump()
      // pour éviter les cascades de requêtes simultanées
    } catch (e) {
      if (_isDebug) {
        _logger.warn('saveGame: ERREUR: $e', code: 'save_error');
      }
      rethrow;
    }
  }

  /// Nouvelle API ID-first: sauvegarder la partie courante par identifiant technique.
  /// Conserve le nom affichable actuel via `state.enterpriseName`.
  /// MISSION STABILISATION: Push cloud automatique pour toutes les sauvegardes (cloud-first strict).
  Future<void> saveGameById(GameState state) async {
    if (!state.isInitialized) {
      throw SaveError('NOT_INITIALIZED', "Le jeu n'est pas initialisé");
    }
    // ID obligatoire pour toute sauvegarde standard
    final existingId = state.enterpriseId;
    if (existingId == null || existingId.isEmpty) {
      throw SaveError('MISSING_ID', 'ID de partie absent: impossible de sauvegarder sans identifiant technique');
    }
    try {
      final snapshot = state.toSnapshot();
      // Cohérence identité (ID-first): enterpriseId du snapshot doit correspondre
      final snapPartieId = snapshot.metadata['enterpriseId'];
      if (snapPartieId is! String || snapPartieId.isEmpty) {
        throw SaveError('PARTIE_ID_MISSING', 'Snapshot sans metadata.enterpriseId');
      }
      if (snapPartieId != existingId) {
        throw SaveError('PARTIE_ID_MISMATCH', 'metadata.enterpriseId ne correspond pas à la partie courante');
      }
      // Normalisation contrat (timestamps/version)
      final normalized = _normalizeSnapshotContract(snapshot);
      final snapValidationSaveById = SnapshotValidator.validate(normalized);
      if (!snapValidationSaveById.isValid) {
        final msg = snapValidationSaveById.errors.map((e) => e.toString()).join('; ');
        throw SaveError('SNAPSHOT_INVALID', 'Snapshot invalide: ' + msg);
      }
      final gameData = <String, dynamic>{
        LocalGamePersistenceService.snapshotKey: normalized.toJson(),
      };
      final saveData = SaveGame(
        id: existingId,
        name: state.enterpriseName ?? existingId,
        lastSaveTime: DateTime.now(),
        gameData: gameData,
        version: GameConstants.VERSION,
      );

      final mgr = await LocalSaveGameManager.getInstance();
      await mgr.saveGame(saveData);
      // CORRECTION: Push cloud supprimé ici - géré uniquement par la queue via _pump()
      // pour éviter les cascades de requêtes simultanées
    } catch (e) {
      if (_isDebug) {
        _logger.warn('saveGameById: ERREUR: $e', code: 'save_by_id_error');
      }
      rethrow;
    }
  }

  /// Sauvegarde automatique déclenchée lors d'événements importants.
  Future<void> saveOnImportantEvent(GameState state) async {
    await requestImportantSave(state, reason: 'legacy_saveOnImportantEvent');
  }

  // Chargement par nom supprimé: utiliser loadGameById(state, id)

  /// Nettoyage de la file et des compteurs d'anti-rafale lors d'un changement de monde.
  ///
  /// Conserve uniquement les requêtes non-backup ciblant [keepPartieId].
  /// Supprime toutes les autres requêtes (autosave, important, manual, lifecycle)
  /// pour éviter des écritures sur un monde différent après un switch.
  void discardPendingForWorldSwitch(String keepPartieId) {
    try {
      final before = _queue.length;
      _queue.removeWhere((r) => !r.isBackup && r.slotId != keepPartieId);
      final after = _queue.length;
      // Nettoyer les fenêtres d'anti-rafale pour les autres mondes
      _lastAutoSaveAtBySlot.removeWhere((k, _) => k != keepPartieId);
      _lastImportantEventAtBySlot.removeWhere((k, _) => k != keepPartieId);
      _logger.info('[WORLD-SWITCH] Queue nettoyée', code: 'world_switch_queue_clean', ctx: {
        'keptWorldId': keepPartieId,
        'removed': before - after,
        'remaining': after,
      });
    } catch (e) {
      _logger.warn('[WORLD-SWITCH] Échec nettoyage queue: '+e.toString(), code: 'world_switch_queue_clean_error');
    }
  }

  Future<GameSnapshot?> _loadSnapshotIfPresent(
    GameState state,
    String name,
    Map<String, dynamic> gameData,
  ) async {
    try {
      final snapshotKey = LocalGamePersistenceService.snapshotKey;
      if (!gameData.containsKey(snapshotKey)) {
        return null;
      }

      final rawSnapshot = gameData[snapshotKey];
      GameSnapshot? snapshot;

      if (rawSnapshot is Map<String, dynamic>) {
        snapshot = GameSnapshot.fromJson(rawSnapshot);
      } else if (rawSnapshot is Map) {
        snapshot = GameSnapshot.fromJson(Map<String, dynamic>.from(rawSnapshot));
      } else if (rawSnapshot is String) {
        snapshot = GameSnapshot.fromJsonString(rawSnapshot);
      }

      if (snapshot == null) {
        throw FormatException(
          'GameSnapshot illisible: type inattendu (${rawSnapshot.runtimeType})',
        );
      }

      try {
        final now = DateTime.now();
        final baseKey = state.enterpriseId ?? name;
        final backupName = '$baseKey${GameConstants.BACKUP_DELIMITER}${now.millisecondsSinceEpoch}';
        final backupData = <String, dynamic>{
          LocalGamePersistenceService.snapshotKey: rawSnapshot,
        };
        final backupSave = SaveGame(
          name: backupName,
          lastSaveTime: now,
          gameData: backupData,
          version: GameConstants.VERSION,
        );
        final mgr = await LocalSaveGameManager.getInstance();
        await mgr.saveGame(backupSave);
      } catch (_) {}

      final migrated = await _persistence.migrateSnapshot(snapshot);
      if (_isDebug) {
        _logger.debug('loadGame: GameSnapshot appliqué avec succès', code: 'load_ok', ctx: {'name': name});
      }
      return migrated;
    } catch (e) {
      if (_isDebug) {
        _logger.warn('loadGame: erreur lors du chargement du GameSnapshot: $e', code: 'load_error');
      }

      // PR3 (B2/X): snapshot présent mais invalide -> pas de fallback legacy.
      // On remonte l'erreur pour déclencher une tentative de restauration depuis backup.
      if (e is Exception) {
        rethrow;
      }
    }

    return null;
  }

  Future<bool> _tryRestoreFromBackupsAndLoad(GameState state, String baseName) async {
    try {
      // Utiliser en priorité l'identifiant technique connu sur l'état; sinon
      // retomber sur le nom/baseName fourni par l'appelant (id quand disponible).
      final pid = (state.enterpriseId == null || state.enterpriseId!.isEmpty) ? baseName : state.enterpriseId!;
      if (pid.isEmpty) {
        // Sans identité exploitable on ne peut pas cibler les backups
        return false;
      }
      final saves = await _listSavesViaLocalManager();
      final backups = saves
          .where((save) => save.name.startsWith('$pid${GameConstants.BACKUP_DELIMITER}'))
          .toList();

      List<SaveGameInfo> candidateBackups = backups;

      if (candidateBackups.isEmpty) {
        return false;
      }

      candidateBackups.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      for (final backup in candidateBackups) {
        try {
          // Résoudre l'ID réel du backup à partir de son nom
          final metas = await _listSavesViaLocalManager();
          final match = metas.where((m) => m.name == backup.name).toList()
            ..sort((a,b)=>b.timestamp.compareTo(a.timestamp));
          if (match.isEmpty) continue;
          final bSave = await _loadSaveByIdViaLocalManager(match.first.id);
          if (bSave == null) continue;
          // Extraire le snapshot du backup et vérifier sa migrabilité
          final data = bSave.gameData;
          final key = LocalGamePersistenceService.snapshotKey;
          if (!data.containsKey(key)) continue;
          Map<String, dynamic>? snapJson;
          final raw = data[key];
          if (raw is Map) {
            snapJson = Map<String, dynamic>.from(raw as Map);
          } else if (raw is String) {
            final snap = GameSnapshot.fromJsonString(raw);
            if (snap != null) snapJson = snap.toJson();
          }
          if (snapJson == null) continue;
          // Tester migration; si échec → passer au backup suivant
          try {
            final migrated = await _persistence.migrateSnapshot(GameSnapshot.fromJson(snapJson));
            snapJson = migrated.toJson();
          } catch (_) {
            continue;
          }
          // Écrire le contenu validé du backup sous l'identifiant technique cible (pid)
          final restored = SaveGame(
            id: pid,
            name: pid,
            lastSaveTime: DateTime.now(),
            gameData: { LocalGamePersistenceService.snapshotKey: snapJson },
            version: bSave.version,
            isRestored: true,
          );
          final mgr = await LocalSaveGameManager.getInstance();
          final ok = await mgr.saveGame(restored);
          if (!ok) continue;
          // Charger strictement par identifiant technique
          await loadGameById(state, pid, allowRestore: false);
          return true;
        } catch (_) {
          // On essaie le backup suivant.
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Vérifie et tente de restaurer une sauvegarde depuis les backups disponibles.
  Future<void> checkAndRestoreFromBackup(GameState state) async {
    if (!state.isInitialized || state.enterpriseName == null) return;

    try {
      // ID-first strict: restaurer par enterpriseId uniquement
      final pid = state.enterpriseId;
      if (pid == null || pid.isEmpty) return;
      final saves = await _listSavesViaLocalManager();
      final backups = saves
          .where((save) => save.name.startsWith('$pid${GameConstants.BACKUP_DELIMITER}'))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      for (final backup in backups) {
        try {
          final ok = await restoreFromBackup(state, backup.name);
          if (!ok) continue;
          await loadGameById(state, pid, allowRestore: false);
          if (_isDebug) {
            _logger.info('checkAndRestoreFromBackup: Restauration réussie depuis le backup', code: 'restore_ok', ctx: {'backup': backup.name});
          }
          return;
        } catch (e) {
          if (_isDebug) {
            _logger.warn('checkAndRestoreFromBackup: Échec de la restauration', code: 'restore_fail', ctx: {'backup': backup.name, 'err': e.toString()});
          }
        }
      }
    } catch (e) {
      if (_isDebug) {
        _logger.warn('checkAndRestoreFromBackup: erreur: $e', code: 'restore_error');
      }
    }
  }

  Future<List<SaveGameInfo>> listSaves() {
    return _listSavesViaLocalManager();
  }

  // Legacy supprimé: deleteSaveByName(name)

  // --- ID-first wrappers (compatibilité ascendante conservée) ---
  Future<void> deleteSaveById(String id) {
    return _deleteSaveByIdViaLocalManager(id);
  }

  Future<SaveGame?> loadSaveById(String id) {
    return _loadSaveByIdViaLocalManager(id);
  }

  Future<SaveMetadata?> getSaveMetadataById(String id) {
    return _getSaveMetadataByIdViaLocalManager(id);
  }

  Future<bool> updateSaveMetadataById(String id, SaveMetadata metadata) {
    return _updateSaveMetadataByIdViaLocalManager(id, metadata);
  }

  Future<SaveGame?> getLastSave() {
    return _getLastSaveViaLocalManager();
  }

  // Legacy supprimé: saveExists(name)

  Future<bool> restoreFromBackup(GameState state, String backupName) async {
    try {
      // Résoudre l'ID réel du backup à partir du nom
      final metas = await _listSavesViaLocalManager();
      final match = metas.where((m) => m.name == backupName).toList()
        ..sort((a,b)=>b.timestamp.compareTo(a.timestamp));
      if (match.isEmpty) return false;

      final bSave = await _loadSaveByIdViaLocalManager(match.first.id);
      if (bSave == null) return false;

      final data = bSave.gameData;
      final key = LocalGamePersistenceService.snapshotKey;
      if (!data.containsKey(key)) return false;

      Map<String, dynamic>? snapJson;
      final raw = data[key];
      if (raw is Map) {
        snapJson = Map<String, dynamic>.from(raw as Map);
      } else if (raw is String) {
        final snap = GameSnapshot.fromJsonString(raw);
        if (snap != null) snapJson = snap.toJson();
      }
      if (snapJson == null) return false;

      // Migration de sûreté
      try {
        final migrated = await _persistence.migrateSnapshot(GameSnapshot.fromJson(snapJson));
        snapJson = migrated.toJson();
      } catch (_) {
        return false;
      }

      final pid = state.enterpriseId;
      if (pid == null || pid.isEmpty) return false;

      // Écrire sous l'identifiant technique courant
      final restored = SaveGame(
        id: pid,
        name: state.enterpriseName ?? pid,
        lastSaveTime: DateTime.now(),
        gameData: { LocalGamePersistenceService.snapshotKey: snapJson },
        version: bSave.version,
        isRestored: true,
      );
      final mgr = await LocalSaveGameManager.getInstance();
      final ok = await mgr.saveGame(restored);
      return ok;
    } catch (_) {
      return false;
    }
  }

  // --- Validation centralisée pour l'affichage/l'UI ---
  /// Statut d'intégrité minimal d'une sauvegarde pour décision UI
  /// valid: données présentes + snapshot lisible (ou migré)
  /// migratable: snapshot absent mais chargeable via chemin legacy (migration à l'ouverture)
  /// corrupt: snapshot présent mais illisible (action de restauration requise)
  /// missing: données introuvables pour l'ID (métadonnées orphelines)
  static const String integrityValid = 'valid';
  static const String integrityMigratable = 'migratable';
  static const String integrityCorrupt = 'corrupt';
  static const String integrityMissing = 'missing';

  /// Valide une sauvegarde par identifiant pour lister/bloquer dans l'UI.
  /// Ne modifie rien, n'applique pas de restauration automatique.
  Future<String> validateForListing(String id) async {
    try {
      final save = await _loadSaveByIdViaLocalManager(id);
      if (save == null) {
        return integrityMissing;
      }
      final data = save.gameData;
      final key = LocalGamePersistenceService.snapshotKey;
      if (!data.containsKey(key)) {
        // Ancien format: chargeable via migration au moment du load
        return integrityMigratable;
      }

      final raw = data[key];
      GameSnapshot? snapshot;
      if (raw is Map<String, dynamic>) {
        snapshot = GameSnapshot.fromJson(raw);
      } else if (raw is Map) {
        snapshot = GameSnapshot.fromJson(Map<String, dynamic>.from(raw));
      } else if (raw is String) {
        snapshot = GameSnapshot.fromJsonString(raw);
      } else {
        return integrityCorrupt;
      }

      if (snapshot == null) {
        return integrityCorrupt;
      }

      // Vérifier la migrabilité du snapshot (migrations de schéma)
      try {
        await _persistence.migrateSnapshot(snapshot);
      } catch (_) {
        // En cas d'échec migration, considérer comme corrompu pour l'UI
        return integrityCorrupt;
      }
      return integrityValid;
    } catch (_) {
      return integrityMissing;
    }
  }

  /// Chargement complet d'une partie par identifiant technique (ID-first).
  ///
  /// Cette méthode sélectionne la sauvegarde par `id` puis applique le même
  /// pipeline de chargement que `loadGame`, y compris le traitement snapshot-first
  /// et la migration. Elle évite d'utiliser un nom arbitraire comme clé de lookup.
  Future<void> loadGameById(GameState state, String id, {bool allowRestore = true}) async {
    // CORRECTION POST-AUDIT: Matérialisation automatique des mondes cloud-only
    // Vérifier si le monde existe localement avant de tenter le chargement
    final localMeta = await _getSaveMetadataByIdViaLocalManager(id);
    
    if (localMeta == null) {
      // Monde absent localement → tenter matérialisation depuis cloud
      // CORRECTION: Indicateur téléchargement cloud + notification utilisateur
      print('🔥🔥🔥 [LOAD] Monde absent localement, tentative matérialisation | worldId=$id 🔥🔥🔥');
      
      try {
        syncState.value = SyncState.downloading;
      } catch (_) {}
      
      // CORRECTION: Notification utilisateur visible
      NotificationManager.instance.showNotification(
        message: '📥 Téléchargement de la partie depuis le cloud...',
        level: NotificationLevel.INFO,
        duration: const Duration(seconds: 2),
      );
      
      _logger.info('[LOAD] Monde absent localement, tentative matérialisation cloud', code: 'load_materialize_attempt', ctx: {
        'worldId': id,
      });
      
      try {
        // CORRECTION: Timeout de 30 secondes pour éviter blocage indéfini
        final materialized = await materializeFromCloud(enterpriseId: id).timeout(
          kCloudMaterializeTimeout,
          onTimeout: () {
            _logger.error('[LOAD] Timeout matérialisation cloud', code: 'load_materialize_timeout', ctx: {
              'worldId': id,
              'timeout': kCloudMaterializeTimeout.inSeconds,
            });
            throw TimeoutException('Téléchargement trop long (${kCloudMaterializeTimeout.inSeconds}s) - vérifiez votre connexion');
          },
        );
        
        if (!materialized) {
          throw StateError('Monde introuvable (local et cloud): $id');
        }
        
        _logger.info('[LOAD] Monde matérialisé depuis cloud avec succès', code: 'load_materialize_success', ctx: {
          'worldId': id,
        });
        
        // CORRECTION: Notification succès
        NotificationManager.instance.showNotification(
          message: '✅ Partie téléchargée avec succès',
          level: NotificationLevel.SUCCESS,
          duration: const Duration(seconds: 2),
        );
        
        // Remettre en état ready après téléchargement
        try {
          syncState.value = SyncState.ready;
        } catch (_) {}
      } on TimeoutException catch (e) {
        _logger.error('[LOAD] Timeout matérialisation cloud', code: 'load_materialize_timeout_caught', ctx: {
          'worldId': id,
          'error': e.toString(),
        });
        
        // Notification erreur timeout
        NotificationManager.instance.showNotification(
          message: '⏱️ Téléchargement trop long - vérifiez votre connexion',
          level: NotificationLevel.ERROR,
          duration: const Duration(seconds: 5),
        );
        
        try {
          syncState.value = SyncState.error;
        } catch (_) {}
        rethrow;
      } catch (e) {
        print('🔥🔥🔥 [LOAD] EXCEPTION matérialisation: ${e.toString()} 🔥🔥🔥');
        
        _logger.error('[LOAD] Échec matérialisation cloud', code: 'load_materialize_error', ctx: {
          'worldId': id,
          'error': e.toString(),
        });
        
        // CORRECTION: Notification erreur avec message contextuel
        final errorStr = e.toString().toLowerCase();
        String userMessage = '❌ Échec téléchargement de la partie';
        
        if (errorStr.contains('network') || errorStr.contains('connection')) {
          userMessage = '📡 Erreur réseau - vérifiez votre connexion';
        } else if (errorStr.contains('cloud_disabled')) {
          userMessage = '☁️ Cloud désactivé - activez-le dans les paramètres';
        } else if (errorStr.contains('not_found')) {
          userMessage = '🔍 Partie introuvable dans le cloud';
        }
        
        NotificationManager.instance.showNotification(
          message: userMessage,
          level: NotificationLevel.ERROR,
          duration: const Duration(seconds: 5),
        );
        
        // Remettre en état error
        try {
          syncState.value = SyncState.error;
        } catch (_) {}
        rethrow;
      }
    }
    
    try {
      var save = await _loadSaveByIdViaLocalManager(id);
      
      // CORRECTION CRITIQUE: Fallback cloud si sauvegarde absente localement
      // Scénario: monde créé sur appareil A, login sur appareil B → local vide mais cloud contient le monde
      if (save == null) {
        _logger.warn('[LOAD] Sauvegarde locale absente, tentative matérialisation cloud', 
          code: 'load_fallback_cloud', ctx: {'enterpriseId': id});
        
        // Vérifier état du CloudPort avant tentative
        final port = _cloudPort;
        if (port == null || port is NoopCloudPersistenceAdapter) {
          _logger.error('[LOAD] CloudPort inactif - impossible de matérialiser', 
            code: 'load_cloud_disabled', ctx: {
              'enterpriseId': id,
              'portType': port?.runtimeType.toString() ?? 'null',
            });
          throw StateError(
            'CLOUD_DISABLED: Cette partie existe uniquement dans le cloud. '
            'Activez la synchronisation cloud dans les paramètres pour y accéder.'
          );
        }
        
        try {
          final materialized = await materializeFromCloud(enterpriseId: id);
          if (materialized) {
            _logger.info('[LOAD] Matérialisation cloud réussie, rechargement local',
              code: 'load_cloud_success', ctx: {'enterpriseId': id});
            save = await _loadSaveByIdViaLocalManager(id);
          } else {
            _logger.error('[LOAD] Matérialisation échouée - partie introuvable cloud', 
              code: 'load_cloud_not_found', ctx: {'enterpriseId': id});
            throw StateError(
              'WORLD_NOT_FOUND: Cette partie n\'existe ni localement ni dans le cloud. '
              'Elle a peut-être été supprimée sur un autre appareil.'
            );
          }
        } catch (e) {
          // Analyser le type d'erreur pour message approprié
          final errorStr = e.toString().toLowerCase();
          
          if (errorStr.contains('cloud_disabled')) {
            rethrow; // Message déjà clair
          } else if (errorStr.contains('world_not_found')) {
            rethrow; // Message déjà clair
          } else if (errorStr.contains('socketexception') || 
                     errorStr.contains('timeoutexception') ||
                     errorStr.contains('network') ||
                     errorStr.contains('connection')) {
            _logger.error('[LOAD] Erreur réseau lors matérialisation', 
              code: 'load_network_error', ctx: {
                'enterpriseId': id,
                'error': e.toString(),
              });
            throw StateError(
              'NETWORK_ERROR: Impossible de télécharger cette partie depuis le cloud. '
              'Vérifiez votre connexion internet et réessayez.'
            );
          } else if (errorStr.contains('not_authenticated') || 
                     errorStr.contains('token_unavailable') ||
                     errorStr.contains('unauthorized')) {
            _logger.error('[LOAD] Erreur authentification lors matérialisation', 
              code: 'load_auth_error', ctx: {
                'enterpriseId': id,
                'error': e.toString(),
              });
            throw StateError(
              'AUTH_ERROR: Votre session a expiré. '
              'Reconnectez-vous pour accéder à vos parties cloud.'
            );
          } else {
            _logger.error('[LOAD] Erreur inconnue lors matérialisation', 
              code: 'load_unknown_error', ctx: {
                'enterpriseId': id,
                'error': e.toString(),
              });
            throw StateError(
              'SYNC_ERROR: Impossible de charger cette partie (${e.toString().split(':').first}). '
              'Réessayez ou contactez le support si le problème persiste.'
            );
          }
        }
      }
      
      if (save == null) {
        _logger.error('[LOAD] Sauvegarde toujours null après matérialisation', 
          code: 'load_still_null', ctx: {'enterpriseId': id});
        throw StateError(
          'LOAD_ERROR: Échec du chargement de la partie après téléchargement. '
          'Réessayez ou vérifiez l\'espace de stockage disponible.'
        );
      }
      final String name = save.name;
      final Map<String, dynamic> gameData = save.gameData;

      // Snapshot-first identique à loadGame()
      final snapshot = await _loadSnapshotIfPresent(state, name, gameData);
      if (snapshot != null) {
        state.applyLoadedGameDataWithoutSnapshot(name, <String, dynamic>{});
        state.applySnapshot(snapshot);
        await state.finishLoadGameAfterSnapshot(name, <String, dynamic>{});
        state.applyOfflineProgressV2();
        try {
          await saveGame(state, name);
        } catch (_) {}
        try {
          final pid = state.enterpriseId ?? id;
          final port = _cloudPort;
          if (port != null && pid.isNotEmpty) {
            Future.microtask(() => checkCloudAndPullIfNeeded(state: state, enterpriseId: pid));
          }
        } catch (_) {}
        return;
      }

      // Migration depuis legacy si aucun snapshot trouvé
      state.applyLoadedGameDataWithoutSnapshot(name, gameData);
      await state.finishLoadGameAfterSnapshot(name, gameData);
      try {
        await saveGame(state, name);
      } catch (_) {}
      try {
        final pid = state.enterpriseId ?? id;
        final port = _cloudPort;
        if (port != null && pid.isNotEmpty) {
          Future.microtask(() => checkCloudAndPullIfNeeded(state: state, enterpriseId: pid));
        }
      } catch (_) {}
    } catch (e) {
      // Aligner le comportement de fallback de loadGame()
      if (allowRestore && e is FormatException) {
        // En cas de snapshot corrompu, tenter restauration en utilisant l'identité
        // fournie à l'appel (id) comme baseName si l'état ne possède pas encore enterpriseId.
        final restored = await _tryRestoreFromBackupsAndLoad(state, id);
        if (restored) return;
      }
      if (_isDebug) {
        _logger.error('[SAVE] loadGameById: ERREUR: '+e.toString());
      }
      rethrow;
    }
    
    // CORRECTION: Vérification d'intégrité post-chargement
    final loadedId = state.enterpriseId;
    if (loadedId != id) {
      _logger.error('[LOAD] ⚠️ INCOHÉRENCE CRITIQUE: enterpriseId ne correspond pas', 
        code: 'load_id_mismatch', ctx: {
          'expected': id,
          'actual': loadedId,
        });
      throw StateError(
        'LOAD_ID_MISMATCH: L\'identité de la partie chargée ne correspond pas.\n'
        'Attendu: $id\n'
        'Obtenu: $loadedId\n'
        'Cela indique une corruption des données ou un bug dans le système de sauvegarde.'
      );
    }
    
    _logger.info('[LOAD] ✅ Vérification d\'intégrité réussie', code: 'load_integrity_ok', ctx: {
      'enterpriseId': id,
      'gameName': state.enterpriseName,
    });
  }

  // --- Cloud (Option A: cloud par partie) ---
  
  /// NOUVEAU: Retry automatique avec backoff exponentiel sur erreur réseau
  Future<void> _retryWithBackoff({
    required Future<void> Function() operation,
    required String operationName,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 2),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;
    
    while (attempt < maxRetries) {
      try {
        await operation();
        return; // Succès
      } catch (e) {
        attempt++;
        
        if (attempt >= maxRetries) {
          _logger.error('[RETRY] $operationName échoué après $maxRetries tentatives', 
            code: 'retry_exhausted', ctx: {'error': e.toString()});
          rethrow;
        }
        
        // Vérifier si erreur réseau temporaire
        final errorStr = e.toString().toLowerCase();
        final isNetworkError = errorStr.contains('socketexception') ||
                              errorStr.contains('timeoutexception') ||
                              errorStr.contains('httpexception') ||
                              errorStr.contains('network') ||
                              errorStr.contains('connection');
        
        if (!isNetworkError) {
          rethrow; // Erreur non réseau, ne pas retry
        }
        
        _logger.warn('[RETRY] $operationName tentative $attempt/$maxRetries échouée, retry dans ${delay.inSeconds}s',
          code: 'retry_attempt', ctx: {'error': e.toString()});
        
        await Future.delayed(delay);
        delay *= 2; // Backoff exponentiel
      }
    }
  }
  
  /// Push snapshot vers le cloud
  /// 
  /// [uid] : Identité Firebase canonique (source de vérité)
  /// [enterpriseId] : UUID v4 de la partie
  /// [state] : État complet du jeu à sauvegarder
  /// [reason] : Raison du push (pour logs/debug)
  Future<void> pushCloudById({
    required String enterpriseId,
    required GameState state,
    required String uid, // ✅ Identité Firebase canonique
    String? reason,
  }) async {
    final port = _cloudPort;
    if (port == null) {
      throw StateError('Cloud port not configured');
    }
    if (_isDebug) {
      _logger.info('[cloud][start] pushCloudById', code: 'cloud_start', ctx: {
        'enterpriseId': enterpriseId,
        if (reason != null) 'reason': reason,
      });
    }
    // P1-3: Vérifier limite de 10 mondes avant push cloud
    try {
      final cloudEntries = await _cloudPort?.listParties() ?? [];
      final existingWorldIds = cloudEntries.map((e) => e.enterpriseId).toSet();
      
      // Si ce monde n'existe pas déjà dans le cloud ET on a déjà 10 mondes
      if (!existingWorldIds.contains(enterpriseId) && cloudEntries.length >= GameConstants.MAX_WORLDS) {
        _logger.error('[cloud][error] Limite de ${GameConstants.MAX_WORLDS} mondes atteinte', 
          code: 'cloud_max_worlds', ctx: {
          'enterpriseId': enterpriseId,
          'currentCount': cloudEntries.length,
        });
        
        NotificationManager.instance.showNotification(
          message: '⚠️ Limite de ${GameConstants.MAX_WORLDS} mondes atteinte\n'
                   'Supprimez un monde existant pour en créer un nouveau',
          level: NotificationLevel.ERROR,
          duration: const Duration(seconds: 7),
        );
        
        throw StateError('MAX_WORLDS_REACHED: Limite de ${GameConstants.MAX_WORLDS} mondes atteinte');
      }
    } catch (e) {
      // Si erreur lors de la vérification, logger mais continuer (ne pas bloquer push)
      if (e is StateError && e.message.contains('MAX_WORLDS_REACHED')) {
        rethrow; // Propager l'erreur de limite atteinte
      }
      _logger.warn('[cloud][warn] Impossible de vérifier limite mondes: $e', code: 'cloud_limit_check_failed');
    }
    
    // P0-1: Vérification stricte uid Firebase - lever exception si manquant
    if (uid.isEmpty) {
      _logger.error('[cloud][error] pushCloudById - uid Firebase manquant', code: 'cloud_no_uid', ctx: {
        'enterpriseId': enterpriseId,
        'uid': uid,
      });
      
      // CORRECTION AUDIT #2: Marquer comme pending avec timestamp pour TTL (7 jours)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_identity_'+enterpriseId, DateTime.now().toIso8601String());
      } catch (_) {}
      
      try {
        syncState.value = SyncState.pendingIdentity;
      } catch (_) {}
      
      // P0-1: LEVER UNE EXCEPTION au lieu de return silencieux
      throw StateError('UID_REQUIRED: Utilisateur non authentifié (uid Firebase manquant) pour enterpriseId=$enterpriseId');
    }
    // Construire snapshot normalisé et métadonnées minimales
    final snap = _normalizeSnapshotContract(state.toSnapshot()).toJson();
    String displayName = state.enterpriseName;
    try {
      final metaLocal = await _getSaveMetadataByIdViaLocalManager(enterpriseId);
      if (metaLocal != null && (metaLocal.name).isNotEmpty) {
        displayName = metaLocal.name;
      }
    } catch (_) {}
    if (displayName.isEmpty) displayName = enterpriseId;
    // P2-1: Métadonnées minimales - timestamps gérés server-side
    final meta = <String, dynamic>{
      'enterpriseId': enterpriseId,
      'gameVersion': GameConstants.VERSION,
      // P2-1: savedAt supprimé - backend génère updated_at server-side
      'name': displayName,
      // P0-1: Attachement obligatoire au joueur cloud (uid Firebase)
      'uid': uid, // Identité Firebase canonique
      if (reason != null) 'reason': reason,
    };
    try {
      // NOUVEAU: Retry automatique avec backoff exponentiel
      await _retryWithBackoff(
        operation: () async {
          await port.pushById(enterpriseId: enterpriseId, snapshot: snap, metadata: meta);
        },
        operationName: 'pushCloudById($enterpriseId)',
      );
      
      // Succès: nettoyer les flags de pending
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pending_cloud_push_'+enterpriseId);
        await prefs.remove('pending_identity_'+enterpriseId);
      } catch (_) {}
      // TOUJOURS logger le succès, même en production
      _logger.info('[cloud][success] pushCloudById', code: 'cloud_success', ctx: {
        'enterpriseId': enterpriseId,
      });
    } catch (e, stackTrace) {
      // TOUJOURS logger les erreurs, même en production
      _logger.error('[cloud][error] pushCloudById failed', code: 'cloud_error', ctx: {
        'enterpriseId': enterpriseId,
        'error': e.toString(),
        'stackTrace': stackTrace.toString().substring(0, 500),
      });
      try {
        syncState.value = SyncState.error;
      } catch (_) {}
      // Ne pas rethrow pour éviter de crasher l'app
    }
  }

  Future<CloudWorldDetail?> pullCloudById({
    required String partieId,
  }) async {
    final port = _cloudPort;
    if (port == null) {
      throw StateError('Cloud port not configured');
    }
    return port.pullById(enterpriseId: partieId);
  }

  Future<CloudStatus> cloudStatusById({
    required String partieId,
  }) async {
    final port = _cloudPort;
    if (port == null) {
      throw StateError('Cloud port not configured');
    }
    return port.statusById(enterpriseId: partieId);
  }

  /// Liste les parties présentes côté cloud (selon l'implémentation du port)
  Future<List<CloudIndexEntry>> listCloudParties() async {
    final port = _cloudPort;
    if (port == null) {
      throw StateError('Cloud port not configured');
    }
    return port.listParties();
  }

  /// CORRECTION CRITIQUE: Hook pour déclencher la synchronisation complète post-connexion
  /// Cette méthode est appelée par le listener Firebase dans main.dart après login réussi.
  /// 
  /// Flux complet:
  /// 1. Sync toutes les parties depuis le cloud (téléchargement)
  /// 2. Retry des pushes en attente (parties créées hors-ligne)
  /// 
  /// P0-1: Le paramètre [playerId] est DEPRECATED, il contient uid Firebase
  /// Retourne SyncResult pour permettre feedback utilisateur et retry si nécessaire.
  Future<SyncResult> onPlayerConnected({required String playerId}) async {
    if (kDebugMode) {
      _logger.info('[PLAYER-CONNECTED] Début synchronisation complète | playerId=$playerId', 
        code: 'player_connected_start');
    }
    
    try {
      // 1. Synchronisation complète depuis le cloud (télécharge toutes les parties)
      if (kDebugMode) {
        _logger.info('[PLAYER-CONNECTED] Calling syncAllWorldsFromCloud() | playerId=$playerId', 
          code: 'player_connected_sync_call');
      }
      final syncResult = await syncAllWorldsFromCloud(playerId: playerId);
      
      if (kDebugMode) {
        _logger.info('[PLAYER-CONNECTED] syncAllWorldsFromCloud() returned | result=${syncResult.status} isSuccess=${syncResult.isSuccess}', 
          code: 'player_connected_sync_returned');
      }
      
      _logger.info('[PLAYER-CONNECTED] Sync cloud terminée', code: 'player_connected_sync_done', ctx: {
        'result': syncResult.name,
        'isSuccess': syncResult.isSuccess,
      });
      
      // 2. Retry des pushes en attente (parties créées hors-ligne)
      try {
        await retryPendingCloudPushes();
        _logger.info('[PLAYER-CONNECTED] Retry pushes terminé', code: 'player_connected_retry_done');
      } catch (e) {
        _logger.warn('[PLAYER-CONNECTED] Erreur retry pushes (non bloquant)', code: 'player_connected_retry_error', ctx: {
          'error': e.toString(),
        });
        // Erreur non bloquante, on continue
      }
      
      _logger.info('[PLAYER-CONNECTED] Synchronisation complète terminée', code: 'player_connected_complete', ctx: {
        'finalResult': syncResult.name,
      });
      
      return syncResult;
    } catch (e) {
      _logger.error('[PLAYER-CONNECTED] Erreur critique synchronisation', code: 'player_connected_error', ctx: {
        'error': e.toString(),
      });
      return SyncResult.networkError;
    }
  }

  /// Vérifie l'état cloud et pull si le cloud est plus récent
  /// Utilisé après chargement local pour synchroniser avec le cloud
  Future<void> checkCloudAndPullIfNeeded({
    required GameState state,
    required String enterpriseId,
  }) async {
    final port = _cloudPort;
    if (port == null) return;
    
    try {
      final status = await port.statusById(enterpriseId: enterpriseId);
      if (!status.exists) return;
      
      // Vérifier si cloud plus récent que local
      final localMeta = await _getSaveMetadataByIdViaLocalManager(enterpriseId);
      if (localMeta == null) {
        // Pas de version locale, pull cloud
        await materializeFromCloud(enterpriseId: enterpriseId);
        return;
      }
      
      // Comparer timestamps si disponibles
      if (status.lastSavedAt != null) {
        final cloudTime = status.lastSavedAt!;
        final localTime = localMeta.lastModified;
        
        if (cloudTime.isAfter(localTime)) {
          // Cloud plus récent, pull
          _logger.info('[SYNC] Cloud plus récent, pull automatique', code: 'sync_auto_pull', ctx: {
            'enterpriseId': enterpriseId,
            'cloudTime': cloudTime.toIso8601String(),
            'localTime': localTime.toIso8601String(),
          });
          
          final detail = await port.pullById(enterpriseId: enterpriseId);
          if (detail != null) {
            await _importCloudObject(
              enterpriseId: enterpriseId,
              obj: detail.snapshot,
              cloudName: detail.name ?? status.name,
            );
          }
        }
      }
    } catch (e) {
      _logger.warn('[SYNC] Erreur checkCloudAndPullIfNeeded', code: 'sync_check_error', ctx: {
        'enterpriseId': enterpriseId,
        'error': e.toString(),
      });
    }
  }

  /// Push l'état actuel du jeu vers le cloud
  /// P0-1: Récupération automatique du uid Firebase
  Future<void> pushCloudForState(GameState state, {String? reason}) async {
    final pid = state.enterpriseId;
    if (pid == null || pid.isEmpty) return;
    
    // P0-1: Utiliser uid Firebase comme identité canonique
    final uid = FirebaseAuthService.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      _logger.warn('[CLOUD] pushCloudForState: uid Firebase manquant', code: 'push_no_uid');
      return;
    }
    
    await pushCloudById(
      enterpriseId: pid,
      state: state,
      uid: uid, // Identité Firebase canonique
      reason: reason,
    );
  }

  /// CORRECTION POST-AUDIT: Synchronisation "cloud always wins" au login.
  /// Cette méthode remplace l'arbitrage de fraîcheur pour garantir que le cloud
  /// écrase toujours le local au login, conformément au modèle cloud-first strict.
  /// 
  /// Règles:
  /// - Si cloud existe → TOUJOURS pull (écrase local)
  /// - Si cloud n'existe pas ET local existe → push local
  /// - Si ni cloud ni local → noop
  /// 
  /// P0-1: Le paramètre [playerId] est DEPRECATED, il contient uid Firebase
  Future<void> _syncFromCloudAtLogin({
    required String enterpriseId,
    String? playerId,
  }) async {
    final port = _cloudPort;
    if (port == null) {
      return;
    }
    
    // Récupérer le statut et le contenu cloud
    Map<String, dynamic>? cloudObj;
    String? cloudName;
    bool cloudExists = false;
    CloudStatus? cloudStatus; // P1-4: Déclarer avant try pour accès dans détection conflits
    
    try {
      cloudStatus = await port.statusById(enterpriseId: enterpriseId);
      cloudExists = cloudStatus.exists;
      
      if (cloudExists) {
        final detail = await port.pullById(enterpriseId: enterpriseId);
        if (detail != null) {
          cloudObj = detail.snapshot;
          cloudName = detail.name ?? cloudStatus.name;
        }
      }
    } catch (e) {
      _logger.warn('[SYNC-LOGIN] Erreur récupération cloud', code: 'sync_login_cloud_error', ctx: {
        'worldId': enterpriseId,
        'error': e.toString(),
      });
      return; // Erreur réseau, skip ce monde
    }
    
    // P1-4: Détection de conflits multi-device
    // RÈGLE 1: Si cloud existe → vérifier conflit avec local
    if (cloudExists && cloudObj != null) {
      final localMeta = await _getSaveMetadataByIdViaLocalManager(enterpriseId);
      
      // Si local existe aussi, détecter conflit potentiel
      if (localMeta != null) {
        try {
          // Comparer timestamps pour détecter conflit
          final cloudTimestamp = cloudStatus?.lastSavedAt;
          final localTimestamp = localMeta.lastModified;
          
          if (cloudTimestamp != null && localTimestamp != null) {
            final diff = cloudTimestamp.difference(localTimestamp).abs();
            
            // P1-4: Si diff > 5 minutes, conflit potentiel multi-device
            if (diff.inMinutes > 5) {
              _logger.info('[CONFLICT] Conflit détecté', code: 'conflict_detected', ctx: {
                'enterpriseId': enterpriseId,
                'diffMinutes': diff.inMinutes,
                'cloudTimestamp': cloudTimestamp.toIso8601String(),
                'localTimestamp': localTimestamp.toIso8601String(),
              });
              
              // Charger snapshot local
              final localSave = await _loadSaveByIdViaLocalManager(enterpriseId);
              if (localSave == null) {
                _logger.warn('[CONFLICT] Local save introuvable, appliquer cloud', code: 'conflict_no_local');
                await _importCloudObject(
                  enterpriseId: enterpriseId,
                  obj: cloudObj,
                  cloudName: cloudName,
                );
                return;
              }
              
              // Extraire snapshots
              GameSnapshot localSnapshot;
              GameSnapshot cloudSnapshot;
              
              try {
                localSnapshot = _extractSnapshot(localSave);
                cloudSnapshot = GameSnapshot.fromJson(cloudObj);
              } catch (e) {
                _logger.error('[CONFLICT] Erreur extraction snapshots', code: 'conflict_extract_error', ctx: {
                  'error': e.toString(),
                });
                // En cas d'erreur, appliquer cloud par défaut
                await _importCloudObject(
                  enterpriseId: enterpriseId,
                  obj: cloudObj,
                  cloudName: cloudName,
                );
                return;
              }
              
              // Afficher écran de choix
              final choice = await _showConflictResolution(
                localSnapshot: localSnapshot,
                cloudSnapshot: cloudSnapshot,
                enterpriseId: enterpriseId,
              );
              
              if (choice == ConflictChoice.keepLocal) {
                _logger.info('[CONFLICT] Choix: garder local', code: 'conflict_keep_local', ctx: {
                  'enterpriseId': enterpriseId,
                });
                
                try {
                  // Supprimer cloud
                  await port.deleteById(enterpriseId: enterpriseId);
                  _logger.info('[CONFLICT] Cloud supprimé', code: 'conflict_cloud_deleted');
                  
                  // Push local vers cloud
                  if (playerId != null && playerId.isNotEmpty) {
                    await pushCloudFromSaveId(
                      enterpriseId: enterpriseId,
                      uid: playerId,
                      reason: 'conflict_resolution_keep_local',
                    );
                    _logger.info('[CONFLICT] Local poussé vers cloud', code: 'conflict_local_pushed');
                  }
                  
                  NotificationManager.instance.showNotification(
                    message: '✅ Version locale conservée et synchronisée',
                    level: NotificationLevel.SUCCESS,
                    duration: const Duration(seconds: 5),
                  );
                } catch (e) {
                  _logger.error('[CONFLICT] Erreur keep local', code: 'conflict_keep_local_error', ctx: {
                    'error': e.toString(),
                  });
                  NotificationManager.instance.showNotification(
                    message: '❌ Erreur lors de la synchronisation',
                    level: NotificationLevel.ERROR,
                  );
                }
                
                return;
                
              } else if (choice == ConflictChoice.keepCloud) {
                _logger.info('[CONFLICT] Choix: garder cloud', code: 'conflict_keep_cloud', ctx: {
                  'enterpriseId': enterpriseId,
                });
                
                try {
                  // Supprimer local
                  await _deleteSaveByIdViaLocalManager(enterpriseId);
                  _logger.info('[CONFLICT] Local supprimé', code: 'conflict_local_deleted');
                  
                  // Appliquer cloud
                  await _importCloudObject(
                    enterpriseId: enterpriseId,
                    obj: cloudObj,
                    cloudName: cloudName,
                  );
                  _logger.info('[CONFLICT] Cloud appliqué', code: 'conflict_cloud_applied');
                  
                  NotificationManager.instance.showNotification(
                    message: '✅ Version cloud conservée et appliquée',
                    level: NotificationLevel.SUCCESS,
                    duration: const Duration(seconds: 5),
                  );
                } catch (e) {
                  _logger.error('[CONFLICT] Erreur keep cloud', code: 'conflict_keep_cloud_error', ctx: {
                    'error': e.toString(),
                  });
                  NotificationManager.instance.showNotification(
                    message: '❌ Erreur lors de l\'application',
                    level: NotificationLevel.ERROR,
                  );
                }
                
                return;
                
              } else {
                // Cancel ou null → ne rien faire
                _logger.warn('[CONFLICT] Choix annulé ou null', code: 'conflict_cancelled', ctx: {
                  'choice': choice?.toString() ?? 'null',
                });
                NotificationManager.instance.showNotification(
                  message: '⚠️ Résolution de conflit annulée',
                  level: NotificationLevel.WARNING,
                  duration: const Duration(seconds: 3),
                );
                return;
              }
            }
          }
        } catch (e) {
          _logger.warn('[SYNC-LOGIN] Erreur comparaison timestamps: $e', code: 'sync_timestamp_error');
        }
      }
      
      // Appliquer cloud (cloud wins)
      await _importCloudObject(
        enterpriseId: enterpriseId,
        obj: cloudObj,
        cloudName: cloudName,
      );
      _logger.info('[SYNC-LOGIN] Cloud importé (cloud wins)', code: 'sync_login_cloud_wins', ctx: {
        'worldId': enterpriseId,
      });
      return;
    }
    
    // RÈGLE 2: Si cloud n'existe pas → pousser le local (si présent)
    final localMeta = await _getSaveMetadataByIdViaLocalManager(enterpriseId);
    if (localMeta != null && playerId != null && playerId.isNotEmpty) {
      try {
        await pushCloudFromSaveId(
          enterpriseId: enterpriseId,
          uid: playerId,
          reason: 'sync_login_local_only',
        );
        _logger.info('[SYNC-LOGIN] Local poussé au cloud', code: 'sync_login_push_local', ctx: {
          'worldId': enterpriseId,
        });
      } catch (e) {
        _logger.warn('[SYNC-LOGIN] Échec push local', code: 'sync_login_push_error', ctx: {
          'worldId': enterpriseId,
          'error': e.toString(),
        });
      }
    }
  }

  Future<void> _importCloudObject({
    required String enterpriseId,
    required Map<String, dynamic> obj,
    GameState? state,
    String? cloudName,
  }) async {
    final raw = obj['snapshot'];
    if (raw is! Map) return;
    final snap = GameSnapshot.fromJson(Map<String, dynamic>.from(raw));
    // Harmoniser le nom local d'après le cloud avant d'appliquer
    try {
      final metaLocal = await _getSaveMetadataByIdViaLocalManager(enterpriseId);
      if (cloudName != null && cloudName.isNotEmpty && metaLocal != null && metaLocal.name != cloudName) {
        await _updateSaveMetadataByIdViaLocalManager(enterpriseId, metaLocal.copyWith(name: cloudName));
      }
    } catch (_) {}
    if (state != null) {
      // IMPORTANT: Forcer l'identité technique et le nom avant d'appliquer le snapshot
      // pour éviter d'écrire sous un mauvais ID lors d'un monde déjà initialisé.
      try {
        // setPartieId removed in CHANTIER-01
      } catch (_) {}
      final targetName = cloudName ?? enterpriseId;
      state.applyLoadedGameDataWithoutSnapshot(targetName, <String, dynamic>{});
      state.applySnapshot(snap);
      await state.finishLoadGameAfterSnapshot(targetName, <String, dynamic>{});
      // Vérification d'intégrité défensive
      if (state.enterpriseId != enterpriseId) {
        _logger.warn('[IMPORT] enterpriseId mismatch après import; correction forcée', code: 'import_id_mismatch', ctx: {
          'expected': enterpriseId,
          'actual': state.enterpriseId ?? 'null',
        });
      }
      try {
        await saveGameById(state);
      } catch (_) {}
    } else {
      // matérialisation silencieuse via gestionnaire local
      final save = SaveGame(
        id: enterpriseId,
        name: cloudName ?? enterpriseId,
        lastSaveTime: DateTime.now(),
        gameData: { LocalGamePersistenceService.snapshotKey: snap.toJson() },
        version: GameConstants.VERSION,
      );
      final mgr = await LocalSaveGameManager.getInstance();
      await mgr.saveGame(save);
    }
  }

  /// Pousse au cloud le snapshot stocké pour une sauvegarde identifiée, sans charger l'UI
  /// - Lit la sauvegarde locale (par ID)
  /// - Extrait `gameSnapshot` depuis le `gameData`
  /// - Envoie via le port cloud avec des métadonnées minimales
  Future<void> pushCloudFromSaveId({
    required String enterpriseId,
    required String uid,
    String? reason,
  }) async {
    final port = _cloudPort;
    if (port == null) {
      throw StateError('Cloud port not configured');
    }
    if (_isDebug) {
      _logger.info('[cloud][start] pushCloudFromSaveId', code: 'cloud_start', ctx: {
        'enterpriseId': enterpriseId,
        if (reason != null) 'reason': reason,
      });
    }
    // P0-1: Vérification stricte uid Firebase - lever exception si manquant
    // L'UI DOIT savoir que la sauvegarde a échoué pour informer l'utilisateur
    if (uid.isEmpty) {
      _logger.error('[cloud][error] pushCloudFromSaveId - uid Firebase manquant', code: 'cloud_no_uid', ctx: {
        'enterpriseId': enterpriseId,
        'uid': uid,
      });
      
      // CORRECTION AUDIT #2: Marquer comme pending avec timestamp pour TTL (7 jours)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_identity_'+enterpriseId, DateTime.now().toIso8601String());
      } catch (_) {}
      
      try {
        syncState.value = SyncState.pendingIdentity;
      } catch (_) {}
      
      // P0-1: LEVER UNE EXCEPTION au lieu de return silencieux
      throw StateError('UID_REQUIRED: Utilisateur non authentifié (uid Firebase manquant) pour enterpriseId=$enterpriseId');
    }
    final save = await _loadSaveByIdViaLocalManager(enterpriseId);
    if (save == null) {
      throw StateError('Sauvegarde introuvable pour id=$enterpriseId');
    }
    final data = save.gameData;
    final key = LocalGamePersistenceService.snapshotKey;
    if (!data.containsKey(key)) {
      throw StateError('Snapshot absent dans la sauvegarde id=$enterpriseId');
    }
    Map<String, dynamic>? snapshot;
    final raw = data[key];
    if (raw is Map) {
      snapshot = Map<String, dynamic>.from(raw as Map);
    } else if (raw is String) {
      final snap = GameSnapshot.fromJsonString(raw);
      if (snap != null) snapshot = snap.toJson();
    }
    if (snapshot == null) {
      throw StateError('Snapshot illisible pour id=$enterpriseId');
    }
    // P2-1: Métadonnées minimales - timestamps gérés server-side
    final meta = <String, dynamic>{
      'enterpriseId': enterpriseId,
//       'gameMode': save.gameMode == GameMode.COMPETITIVE ? 'COMPETITIVE' : 'INFINITE',
      'gameVersion': save.version,
      // P2-1: savedAt supprimé - backend génère updated_at server-side
      'name': save.name,
      // P0-1: Attachement obligatoire au joueur cloud (uid Firebase)
      'uid': uid, // ✅ Identité Firebase canonique
      if (reason != null) 'reason': reason,
    };
    // Télémétrie: tentative
    final sw = Stopwatch()..start();
    try {
      _logger.info('worlds_put_attempt', code: 'worlds_put_attempt', ctx: {
        'worldId': enterpriseId,
        'reason': reason ?? 'unspecified',
      });
      await port.pushById(enterpriseId: enterpriseId, snapshot: snapshot, metadata: meta);
      // Succès: nettoyer le flag pending_identity
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pending_identity_'+enterpriseId);
      } catch (_) {}
      sw.stop();
      _logger.info('worlds_put_success', code: 'worlds_put_success', ctx: {
        'worldId': enterpriseId,
        'latency_ms': sw.elapsedMilliseconds,
      });
      if (_isDebug) {
        _logger.info('[cloud][success] pushCloudFromSaveId', code: 'cloud_success', ctx: {
          'enterpriseId': enterpriseId,
          'latency_ms': sw.elapsedMilliseconds,
        });
      }
    } catch (e, stackTrace) {
      // Notifier l'UI d'un état d'erreur pour surfacing non silencieux
      try {
        syncState.value = SyncState.error;
      } catch (_) {}
      sw.stop();
      // Extraire un code HTTP s'il est présent dans le message d'erreur de l'adaptateur
      int? httpCode;
      String cause = 'unknown';
      try {
        final msg = e.toString();
        final m = RegExp(r'push_failed_(\\d{3})').firstMatch(msg);
        if (m != null) {
          httpCode = int.tryParse(m.group(1) ?? '');
          cause = (httpCode == 401) ? 'auth' : 'server';
        }
      } catch (_) {}
      
      _logger.error('[cloud] pushCloudFromSaveId failed', code: 'worlds_put_failure', ctx: {
        'worldId': enterpriseId,
        'latency_ms': sw.elapsedMilliseconds,
        if (httpCode != null) 'http_code': httpCode,
        'cause_category': cause,
        'error': e.toString(),
      });
      if (_isDebug) {
        _logger.warn('[cloud][backoff] pushCloudFromSaveId', code: 'cloud_backoff', ctx: {
          'enterpriseId': enterpriseId,
          if (httpCode != null) 'http_code': httpCode,
        });
      }
      rethrow;
    }
  }

  /// Matérialise localement une partie à partir du cloud (écrit snapshot-only sous l'ID)
  Future<bool> materializeFromCloud({required String enterpriseId}) async {
    _logger.info('[MATERIALIZE] START', code: 'materialize_start', ctx: {'enterpriseId': enterpriseId});
    
    final port = _cloudPort;
    if (port == null) {
      _logger.error('[MATERIALIZE] Cloud port null', code: 'materialize_no_port');
      throw StateError('Cloud port not configured');
    }
    
    _logger.info('[MATERIALIZE] Calling pullById', code: 'materialize_pull');
    final detail = await port.pullById(enterpriseId: enterpriseId);
    
    if (detail == null) {
      _logger.warn('[MATERIALIZE] World not found in cloud', code: 'materialize_not_found', ctx: {
        'enterpriseId': enterpriseId,
      });
      return false;
    }
    
    final snapshot = detail.snapshot;
    if (snapshot.isEmpty) {
      _logger.error('[MATERIALIZE] Empty snapshot', code: 'materialize_empty_snapshot', ctx: {
        'enterpriseId': enterpriseId,
      });
      return false;
    }
    
    final name = detail.name ?? enterpriseId;
    final version = detail.gameVersion ?? GameConstants.VERSION;
    
    _logger.info('[MATERIALIZE] Creating SaveGame', code: 'materialize_create_save', ctx: {
      'enterpriseId': enterpriseId,
      'name': name,
      'version': version,
    });
    
    final save = SaveGame(
      id: enterpriseId,
      name: name,
      lastSaveTime: DateTime.now(),
      gameData: {LocalGamePersistenceService.snapshotKey: snapshot},
      version: version,
    );
    
    final mgr = await LocalSaveGameManager.getInstance();
    final result = await mgr.saveGame(save);
    
    _logger.info('[MATERIALIZE] Result', code: 'materialize_result', ctx: {
      'enterpriseId': enterpriseId,
      'success': result,
    });
    
    return result;
  }

  /// MISSION STABILISATION: Retente les pushes cloud pour les mondes marqués pending_identity.
  /// Utilisé après reconnexion pour pousser les mondes créés hors-ligne.
  /// 
  /// CORRECTION AUDIT #2: Implémente TTL (7 jours) et limite de retry (3 tentatives).
  Future<void> retryPendingCloudPushes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // P0-1: Utiliser uid Firebase comme identité canonique
      final uid = FirebaseAuthService.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        _logger.warn('[RETRY] uid Firebase manquant, skip retry', code: 'retry_no_uid');
        return;
      }
      
      final metas = await _listSavesViaLocalManager();
      int successCount = 0;
      int failureCount = 0;
      int expiredCount = 0;
      int limitReachedCount = 0;
      
      for (final m in metas.where((e) => !e.isBackup)) {
        final keyIdentity = 'pending_identity_'+m.id;
        final keyRetryCount = 'pending_identity_retry_'+m.id;
        
        // CORRECTION AUDIT #2: Vérifier si le flag existe (maintenant String avec timestamp)
        final pendingTimestamp = prefs.getString(keyIdentity);
        if (pendingTimestamp == null) continue;
        
        // CORRECTION AUDIT #2: Vérifier TTL (7 jours)
        try {
          final createdAt = DateTime.parse(pendingTimestamp);
          final age = DateTime.now().difference(createdAt);
          if (age.inDays > 7) {
            _logger.warn('[RETRY] Flag expiré (${age.inDays} jours) pour ${m.id}', code: 'retry_expired');
            await prefs.remove(keyIdentity);
            await prefs.remove(keyRetryCount);
            expiredCount++;
            continue;
          }
        } catch (_) {
          // Timestamp invalide, nettoyer
          await prefs.remove(keyIdentity);
          await prefs.remove(keyRetryCount);
          continue;
        }
        
        // CORRECTION AUDIT #2: Vérifier limite de retry (3 tentatives)
        final retryCount = prefs.getInt(keyRetryCount) ?? 0;
        if (retryCount >= 3) {
          _logger.warn('[RETRY] Limite de retry atteinte (3/3) pour ${m.id}', code: 'retry_limit_reached');
          await prefs.remove(keyIdentity);
          await prefs.remove(keyRetryCount);
          limitReachedCount++;
          continue;
        }
        
        // Tenter le push
        try {
          await pushCloudFromSaveId(enterpriseId: m.id, uid: uid); // ✅ uid Firebase
          await prefs.remove(keyIdentity);
          await prefs.remove(keyRetryCount);
          successCount++;
          _logger.info('[RETRY] Succès pour ${m.id}', code: 'retry_success');
        } catch (e) {
          // Incrémenter le compteur de retry
          await prefs.setInt(keyRetryCount, retryCount + 1);
          failureCount++;
          _logger.warn('[RETRY] Échec pour ${m.id} (tentative ${retryCount + 1}/3)', 
            code: 'retry_failure', ctx: {'error': e.toString()});
        }
      }
      
      _logger.info('[RETRY] Terminé: $successCount succès, $failureCount échecs, $expiredCount expirés, $limitReachedCount limites atteintes', 
        code: 'retry_complete');
      
      // P1-2: Notification utilisateur du résultat de la réconciliation
      if (successCount > 0) {
        NotificationManager.instance.showNotification(
          message: '✅ $successCount monde(s) synchronisé(s) avec le cloud',
          level: NotificationLevel.SUCCESS,
          duration: const Duration(seconds: 5),
        );
      }
      
      if (failureCount > 0 && successCount == 0) {
        NotificationManager.instance.showNotification(
          message: '⚠️ Échec synchronisation de $failureCount monde(s) - Réessayez plus tard',
          level: NotificationLevel.WARNING,
          duration: const Duration(seconds: 5),
        );
      }
      
      if (limitReachedCount > 0) {
        NotificationManager.instance.showNotification(
          message: '⚠️ $limitReachedCount monde(s) non synchronisé(s) (limite retry atteinte)',
          level: NotificationLevel.WARNING,
          duration: const Duration(seconds: 7),
        );
      }
    } catch (e) {
      _logger.error('[RETRY] Erreur globale: $e', code: 'retry_error');
    }
  }

  /// MISSION STABILISATION: Synchronisation obligatoire de tous les mondes depuis le cloud au login.
  /// Cette méthode garantit que tous les mondes cloud sont matérialisés localement et synchronisés.
  /// 
  /// CORRECTION AUDIT #5: Retourne SyncResult au lieu de void pour permettre feedback utilisateur.
  /// 
  /// Règles:
  /// - Cloud = source de vérité au login
  /// - Tous les mondes cloud sont matérialisés localement
  /// - L'arbitrage de fraîcheur s'applique pour chaque monde
  /// - Aucun monde n'est supprimé (mondes locaux orphelins sont poussés au cloud)
  /// 
  /// P0-1: Le paramètre [playerId] est DEPRECATED, il contient uid Firebase
  /// Appelée depuis le bootstrap après confirmation que l'utilisateur est connecté et prêt.
  Future<SyncResult> syncAllWorldsFromCloud({String? playerId}) async {
    if (kDebugMode) {
      _logger.info('[SYNC-LOGIN] syncAllWorldsFromCloud() called | playerId=${playerId ?? "null"}', 
        code: 'sync_login_entry');
    }
    
    final port = _cloudPort;
    if (kDebugMode) {
      _logger.info('[SYNC-LOGIN] Checking cloud port | port=${port?.runtimeType ?? "null"}', 
        code: 'sync_login_port_check');
    }
    
    if (port == null) {
      _logger.warn('[SYNC-LOGIN] Cloud port non configuré', code: 'sync_login_no_port');
      return SyncResult.noCloudPort;
    }

    // CORRECTION CRITIQUE: Vérifier que le port n'est pas NOOP
    if (port is NoopCloudPersistenceAdapter) {
      _logger.warn('[SYNC-LOGIN] CloudPort NOOP détecté - sync annulée', code: 'sync_login_noop_port', ctx: {
        'portType': port.runtimeType.toString(),
      });
      return SyncResult.noCloudPort;
    }

    if (kDebugMode) {
      _logger.info('[SYNC-LOGIN] Cloud port is active | portType=${port.runtimeType}', 
        code: 'sync_login_port_active');
    }

    // P0-1: Respecter l'invariant - ne jamais contacter le cloud sans uid Firebase
    final ensuredUid = playerId ?? FirebaseAuthService.instance.currentUser?.uid;
    if (kDebugMode) {
      _logger.info('[SYNC-LOGIN] UID Firebase resolved | uid=${ensuredUid ?? "null"}', 
        code: 'sync_login_uid_resolved');
    }
    
    if (ensuredUid == null || ensuredUid.isEmpty) {
      _logger.warn('[SYNC-LOGIN] UID Firebase manquant, sync annulée', code: 'sync_login_no_uid');
      try { syncState.value = SyncState.pendingIdentity; } catch (_) {}
      return SyncResult.noUid;
    }

    _logger.info('[SYNC-LOGIN] Début synchronisation au login', code: 'sync_login_start', ctx: {
      'uid': ensuredUid,
    });

    try {
      syncState.value = SyncState.syncing;

      // 1. Récupérer la liste des mondes depuis le cloud
      List<CloudIndexEntry> cloudWorlds = [];
      try {
        cloudWorlds = await port.listParties();
        _logger.info('[SYNC-LOGIN] Mondes cloud récupérés', code: 'sync_login_cloud_list', ctx: {
          'count': cloudWorlds.length,
        });
      } catch (e) {
        _logger.error('[SYNC-LOGIN] Échec récupération liste cloud', code: 'sync_login_list_error', ctx: {
          'error': e.toString(),
        });
        syncState.value = SyncState.error;
        return SyncResult.networkError;
      }

      // 2. Récupérer la liste des mondes locaux (non-backup)
      final localMetas = await _listSavesViaLocalManager();
      final localWorldIds = localMetas
          .where((m) => !m.name.contains(GameConstants.BACKUP_DELIMITER))
          .map((m) => m.id)
          .toSet();

      _logger.info('[SYNC-LOGIN] Mondes locaux identifiés', code: 'sync_login_local_list', ctx: {
        'count': localWorldIds.length,
      });

      // 3. Pour chaque monde cloud, appliquer l'arbitrage de fraîcheur
      int syncedCount = 0;
      int errorCount = 0;
      final List<String> failedEnterpriseIds = [];

      for (final cloudEntry in cloudWorlds) {
        final worldId = cloudEntry.enterpriseId;
        if (worldId.isEmpty) continue;

        try {
          _logger.info('[SYNC-LOGIN] Synchronisation monde', code: 'sync_login_world_start', ctx: {
            'worldId': worldId,
            'hasLocal': localWorldIds.contains(worldId),
          });

          // CORRECTION POST-AUDIT: Utiliser "cloud always wins" au lieu de l'arbitrage
          await _syncFromCloudAtLogin(
            enterpriseId: worldId,
            playerId: ensuredUid,
          );

          syncedCount++;
          _logger.info('[SYNC-LOGIN] Monde synchronisé', code: 'sync_login_world_ok', ctx: {
            'worldId': worldId,
          });
        } catch (e) {
          errorCount++;
          failedEnterpriseIds.add(worldId);
          _logger.warn('[SYNC-LOGIN] Échec sync monde', code: 'sync_login_world_error', ctx: {
            'worldId': worldId,
            'error': e.toString(),
          });
          // Continuer avec les autres mondes même en cas d'erreur
        }
      }

      // 4. Pousser les mondes locaux orphelins vers le cloud (cloud-first)
      final cloudWorldIds = cloudWorlds.map((e) => e.enterpriseId).toSet();
      final orphanLocalIds = localWorldIds.difference(cloudWorldIds);

      if (orphanLocalIds.isNotEmpty) {
        _logger.info('[SYNC-LOGIN] Mondes locaux orphelins détectés', code: 'sync_login_orphans', ctx: {
          'count': orphanLocalIds.length,
        });

        for (final orphanId in orphanLocalIds) {
          try {
            _logger.info('[SYNC-LOGIN] Push monde orphelin vers cloud', code: 'sync_login_orphan_push', ctx: {
              'worldId': orphanId,
            });

            await pushCloudFromSaveId(
              enterpriseId: orphanId,
              uid: ensuredUid,
              reason: 'sync_login_orphan',
            );

            syncedCount++;
          } catch (e) {
            errorCount++;
            _logger.warn('[SYNC-LOGIN] Échec push orphelin', code: 'sync_login_orphan_error', ctx: {
              'worldId': orphanId,
              'error': e.toString(),
            });
          }
        }
      }

      // 5. Finaliser
      final totalWorlds = cloudWorlds.length + orphanLocalIds.length;
      syncState.value = errorCount > 0 ? SyncState.error : SyncState.ready;

      _logger.info('[SYNC-LOGIN] Synchronisation terminée', code: 'sync_login_complete', ctx: {
        'cloudWorlds': cloudWorlds.length,
        'localWorlds': localWorldIds.length,
        'synced': syncedCount,
        'errors': errorCount,
        'orphans': orphanLocalIds.length,
        'failedEnterpriseIds': failedEnterpriseIds.join(','),
      });
      
      // CORRECTION AUDIT #5: Retourner statut approprié avec détails
      if (errorCount > 0 && syncedCount > 0) {
        return SyncResult.partialSuccess(
          failedEnterpriseIds: failedEnterpriseIds,
          syncedCount: syncedCount,
          totalCount: totalWorlds,
          errorDetails: '${failedEnterpriseIds.length} monde(s) non synchronisé(s)',
        );
      } else if (errorCount > 0) {
        return SyncResult(
          status: SyncStatus.networkError,
          failedEnterpriseIds: failedEnterpriseIds,
          syncedCount: syncedCount,
          totalCount: totalWorlds,
          errorDetails: 'Échec synchronisation de tous les mondes',
        );
      } else {
        return SyncResult(
          status: SyncStatus.success,
          syncedCount: syncedCount,
          totalCount: totalWorlds,
        );
      }
    } catch (e) {
      _logger.error('[SYNC-LOGIN] Erreur critique synchronisation', code: 'sync_login_critical_error', ctx: {
        'error': e.toString(),
      });
      syncState.value = SyncState.error;
      return SyncResult.networkError;
    }
  }

  /// Mission 7: Contrôles d'intégrité non-intrusifs (debug-only)
  /// - Détecte les noms en doublon pointant vers des IDs différents
  /// - Vérifie la présence du snapshot (clé LocalGamePersistenceService.snapshotKey)
  ///   et un format minimalement lisible (Map<String,dynamic> ou String JSON)
  Future<void> runIntegrityChecks() async {
    if (!_isDebug) return;
    try {
      final metas = await _listSavesViaLocalManager();
      // 1) Doublons de noms -> IDs différents
      final Map<String, Set<String>> nameToIds = {};
      for (final m in metas) {
        nameToIds.putIfAbsent(m.name, () => <String>{}).add(m.id);
      }
      final duplicates = nameToIds.entries.where((e) => e.value.length > 1).toList();
      if (duplicates.isNotEmpty) {
        _logger.warn('INTEGRITY WARNING: Noms en doublon sur IDs différents', code: 'integrity_duplicate_names', ctx: {
          'count': duplicates.length,
        });
        for (final d in duplicates) {
          _logger.warn('Duplicate name mapping', code: 'integrity_duplicate_detail', ctx: {
            'name': d.key,
            'ids': d.value.join(', '),
          });
        }
      }

      // 2) Snapshot présent et lisible (à minima)
      for (final m in metas) {
        try {
          final save = await _loadSaveByIdViaLocalManager(m.id);
          if (save == null) {
            _logger.error('INTEGRITY ERROR: Sauvegarde introuvable', code: 'integrity_missing_save', ctx: {
              'id': m.id,
              'name': m.name,
            });
            continue;
          }
          // 2.a) Harmonisation SaveGame vs Metadata (name, version, gameMode)
          try {
            final meta = await _getSaveMetadataByIdViaLocalManager(m.id);
            if (meta == null) {
              _logger.warn('INTEGRITY WARNING: Métadonnées manquantes', code: 'integrity_missing_meta', ctx: {
                'id': m.id,
                'name': m.name,
              });
            } else {
              if (meta.name != save.name) {
                _logger.warn('INTEGRITY WARNING: Désalignement name', code: 'integrity_name_mismatch', ctx: {
                  'id': m.id,
                  'meta': meta.name,
                  'save': save.name,
                });
              }
              if (meta.version != save.version) {
                _logger.warn('INTEGRITY WARNING: Désalignement version', code: 'integrity_version_mismatch', ctx: {
                  'id': m.id,
                  'meta': meta.version,
                  'save': save.version,
                });
              }
            }
          } catch (e) {
            _logger.error('INTEGRITY ERROR: Lecture metadata échouée', code: 'integrity_meta_read_error', ctx: {
              'id': m.id,
              'err': e.toString(),
            });
          }
          final data = save.gameData;
          final key = LocalGamePersistenceService.snapshotKey;
          if (!data.containsKey(key)) {
            _logger.error('INTEGRITY ERROR: Snapshot manquant', code: 'integrity_snapshot_missing', ctx: {
              'id': m.id,
              'name': m.name,
            });
            continue;
          }
          final raw = data[key];
          if (raw is Map<String, dynamic>) {
            // ok
          } else if (raw is Map) {
            // ok-ish
          } else if (raw is String) {
            try {
              // Valider au moins que c'est un JSON objet
              final decoded = GameSnapshot.fromJsonString(raw);
              if (decoded == null) {
                _logger.error('INTEGRITY ERROR: Snapshot JSON invalide (null)', code: 'integrity_snapshot_json_null', ctx: {'id': m.id});
              }
            } catch (e) {
              _logger.error('INTEGRITY ERROR: Snapshot JSON illisible', code: 'integrity_snapshot_json_unreadable', ctx: {'id': m.id, 'err': e.toString()});
            }
          } else {
            _logger.error('INTEGRITY ERROR: Snapshot type inattendu', code: 'integrity_snapshot_type', ctx: {'id': m.id, 'type': raw.runtimeType.toString()});
          }
        } catch (e) {
          _logger.error('INTEGRITY ERROR: Exception lors du check', code: 'integrity_check_exception', ctx: {'id': m.id, 'err': e.toString()});
        }
      }

      // 3) Backups: format enterpriseId|timestamp, association à une sauvegarde régulière, rétention N/TTL
      try {
        final now = DateTime.now();
        final regularIds = metas
            .where((mm) => !mm.name.contains(GameConstants.BACKUP_DELIMITER))
            .map((mm) => mm.id)
            .toSet();

        final backups = metas.where((mm) => mm.name.contains(GameConstants.BACKUP_DELIMITER)).toList();
        final Map<String, List<dynamic>> byBase = {};
        for (final b in backups) {
          final parts = b.name.split(GameConstants.BACKUP_DELIMITER);
          if (parts.length != 2) {
            _logger.warn('INTEGRITY WARNING: Nom de backup invalide (pas exactement une séparation)', code: 'integrity_backup_name_invalid', ctx: {'name': b.name});
            continue;
          }
          final base = parts.first;
          final ts = int.tryParse(parts.last);
          if (base.isEmpty || ts == null) {
            _logger.warn('INTEGRITY WARNING: Backup non conforme (base vide ou timestamp invalide)', code: 'integrity_backup_nonconform', ctx: {'name': b.name});
          }
          if (!regularIds.contains(base)) {
            _logger.warn('INTEGRITY WARNING: Backup orphelin (aucune sauvegarde régulière trouvée)', code: 'integrity_backup_orphan', ctx: {'id': base, 'name': b.name});
          }
          byBase.putIfAbsent(base, () => <dynamic>[]).add(b);
        }

        for (final entry in byBase.entries) {
          final list = entry.value..
              sort((a,b)=>b.lastModified.compareTo(a.lastModified));
          if (list.length > GameConstants.BACKUP_RETENTION_MAX) {
            _logger.warn('INTEGRITY WARNING: Trop de backups', code: 'integrity_backup_too_many', ctx: {'id': entry.key, 'count': list.length, 'max': GameConstants.BACKUP_RETENTION_MAX});
          }
          for (final b in list) {
            final age = now.difference(b.lastModified);
            if (age > GameConstants.BACKUP_RETENTION_TTL) {
              _logger.warn('INTEGRITY WARNING: Backup au-delà de la TTL', code: 'integrity_backup_ttl_exceeded', ctx: {'id': entry.key, 'days': age.inDays, 'name': b.name});
            }
          }
        }
      } catch (e) {
        _logger.error('INTEGRITY ERROR: Exception lors des vérifications backups', code: 'integrity_backup_checks_exception', ctx: {'err': e.toString()});
      }
    } catch (e) {
      _logger.error('INTEGRITY CHECKS FAILED', code: 'integrity_checks_failed', ctx: {'err': e.toString()});
    }
  }
}
