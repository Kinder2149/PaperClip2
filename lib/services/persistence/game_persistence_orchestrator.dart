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
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/persistence/game_persistence_service.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/save_game.dart';
import 'package:paperclip2/services/save_system/save_validator.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final GamePersistenceService _persistence = const LocalGamePersistenceService();
  // Port cloud optionnel (injecté depuis le bootstrap ou un service)
  CloudPersistencePort? _cloudPort;
  // Fournisseur d'identité joueur (Google playerId) pour les pushes automatiques
  FutureOr<String?> Function()? _playerIdProvider;

  static const Duration _backupCooldown = Duration(minutes: 10);
  static const Duration _importantEventCoalesceWindow = Duration(seconds: 2);

  final List<SaveRequest> _queue = <SaveRequest>[];
  bool _isPumping = false;
  DateTime? _lastBackupAt;
  DateTime? _lastImportantEventEnqueuedAt;

  // Etat de synchronisation applicatif
  // 'ready' | 'syncing' | 'error'
  final ValueNotifier<String> syncState = ValueNotifier<String>('ready');

  void resetForTesting() {
    _queue.clear();
    _isPumping = false;
    _lastBackupAt = null;
    _lastImportantEventEnqueuedAt = null;
  }

  /// Supprime l'entrée cloud pour une partie (cloud-only ou non)
  Future<void> deleteCloudById({
    required String partieId,
  }) async {
    final port = _cloudPort;
    if (port == null) {
      throw StateError('Cloud port not configured');
    }
    await port.deleteById(partieId: partieId);
  }

  // Injection du port cloud (GPG, HTTP, etc.)
  void setCloudPort(CloudPersistencePort port) {
    _cloudPort = port;
  }

  // Injection du provider de playerId (ex: GoogleIdentityService.playerId)
  void setPlayerIdProvider(FutureOr<String?> Function() provider) {
    _playerIdProvider = provider;
  }

  /// Boot: vérifie la dernière sauvegarde (si elle existe) et tente une restauration
  /// depuis le backup le plus récent si la sauvegarde semble invalide.
  ///
  /// Note: cette méthode n'applique rien dans le GameState; elle ne fait qu'assurer
  /// que la sauvegarde principale est saine avant d'entrer dans l'UI.
  Future<void> checkAndRestoreLastSaveFromBackupIfNeeded() async {
    try {
      final lastSave = await SaveManagerAdapter.getLastSave();
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

      if (_isDebug) {
        print(
          'GamePersistenceOrchestrator.checkAndRestoreLastSaveFromBackupIfNeeded: '
          'Sauvegarde "${lastSave.name}" invalide (${validation.errors.length} erreurs). '
          'Tentative de restauration depuis un backup...',
        );
      }

      final saves = await SaveManagerAdapter.listSaves();
      final backups = saves
          .where((save) => save.name.startsWith('$baseKey${GameConstants.BACKUP_DELIMITER}'))
          .toList();

      if (backups.isEmpty) {
        if (_isDebug) {
          print(
            'GamePersistenceOrchestrator.checkAndRestoreLastSaveFromBackupIfNeeded: '
            'Aucun backup trouvé pour baseKey=$baseKey',
          );
        }
        return;
      }

      backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final latestBackupName = backups.first.name;

      try {
        // Résoudre le backup par nom vers son ID, puis charger par ID (ID-first)
        final allMetas = await SaveManagerAdapter.listSaves();
        final match = allMetas.where((m) => m.name == latestBackupName).toList()
          ..sort((a,b)=>b.timestamp.compareTo(a.timestamp));
        if (match.isEmpty) {
          return;
        }
        final backupSave = await SaveManagerAdapter.loadGameById(match.first.id);
        if (backupSave == null) {
          return;
        }

        final restoredSave = SaveGame(
          // On restaure sous le même ID (conservé par l'adapter via metadata)
          name: lastSave.name,
          lastSaveTime: DateTime.now(),
          gameData: backupSave.gameData,
          version: backupSave.version,
          gameMode: backupSave.gameMode,
          isRestored: true,
        );

        final ok = await SaveManagerAdapter.saveGame(restoredSave);
        if (_isDebug) {
          print(
            'GamePersistenceOrchestrator.checkAndRestoreLastSaveFromBackupIfNeeded: '
            'Restauration depuis "$latestBackupName" → "${lastSave.name}": ${ok ? 'OK' : 'ECHEC'}',
          );
        }
      } catch (e) {
        if (_isDebug) {
          print(
            'GamePersistenceOrchestrator.checkAndRestoreLastSaveFromBackupIfNeeded: '
            'Echec restauration depuis "$latestBackupName": $e',
          );
        }
      }
    } catch (e) {
      if (_isDebug) {
        print(
          'GamePersistenceOrchestrator.checkAndRestoreLastSaveFromBackupIfNeeded: erreur: $e',
        );
      }
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
    final pid = state.partieId;
    if (pid == null || pid.isEmpty) return;
    await _enqueue(
      state,
      SaveRequest(
        trigger: SaveTrigger.autosave,
        priority: SavePriority.low,
        slotId: pid,
        isBackup: false,
        requestedAt: DateTime.now(),
        reason: reason,
      ),
    );
  }

  Future<void> requestImportantSave(GameState state, {String? reason}) async {
    if (!state.isInitialized) return;
    final pid = state.partieId;
    if (pid == null || pid.isEmpty) return;

    final now = DateTime.now();
    _lastImportantEventEnqueuedAt ??= now;

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
    // ID-first: force l'utilisation du partieId, ignore un slotId textuel si fourni
    final pid = state.partieId;
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
    final pid = state.partieId;
    if (pid == null || pid.isEmpty) return;

    final now = DateTime.now();

    await _enqueue(
      state,
      SaveRequest(
        trigger: SaveTrigger.lifecycle,
        priority: SavePriority.critical,
        slotId: pid,
        isBackup: false,
        requestedAt: now,
        reason: reason,
      ),
    );

    final lastBackup = _lastBackupAt;
    final shouldBackup = lastBackup == null || now.difference(lastBackup) >= _backupCooldown;
    if (shouldBackup) {
      // Identité stricte: backups indexés par l'ID technique uniquement
      final baseKey = state.partieId;
      if (baseKey == null || baseKey.isEmpty) {
        // Pas d'ID -> pas de backup (on n'autorise pas de backup sans identité)
        return;
      }
      final backupName = '$baseKey${GameConstants.BACKUP_DELIMITER}${now.millisecondsSinceEpoch}';
      _lastBackupAt = now;
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
    if (!state.isInitialized || state.gameName == null) return;
    // Identité stricte: refuser les backups si l'ID de partie est absent
    if (state.partieId == null || state.partieId!.isEmpty) return;

    final now = DateTime.now();
    final lastBackup = _lastBackupAt;
    if (!bypassCooldown && lastBackup != null && now.difference(lastBackup) < _backupCooldown) {
      return;
    }
    _lastBackupAt = now;

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

    _queue.add(request);

    if (_isDebug) {
      print(
        'GamePersistenceOrchestrator.enqueue: trigger=${request.trigger}, '
        'priority=${request.priority}, slot=${request.slotId}, backup=${request.isBackup}, '
        'queue=${_queue.length}',
      );
    }

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
      syncState.value = 'syncing';
      while (_queue.isNotEmpty) {
        final next = _pickNext();
        try {
          if (_isDebug) {
            print(
              'GamePersistenceOrchestrator.pump: start trigger=${next.trigger}, '
              'slot=${next.slotId}, backup=${next.isBackup}',
            );
          }
          // ID-first: pour les sauvegardes non-backup, interpréter slotId comme partieId
          final isBackupName = next.isBackup || next.slotId.contains(GameConstants.BACKUP_DELIMITER);
          if (isBackupName) {
            await saveGame(state, next.slotId);
          } else {
            await saveGameById(state);
            try {
              final pid = state.partieId;
              final port = _cloudPort;
              if (pid != null && pid.isNotEmpty && port != null) {
                // Si un playerId est disponible, pousser immédiatement vers le cloud.
                final playerId = await _playerIdProvider?.call();
                if (playerId != null && playerId.isNotEmpty) {
                  try {
                    await pushCloudById(partieId: pid, state: state, playerId: playerId);
                  } catch (e) {
                    // Marquer un push en attente si le cloud est indisponible
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('pending_cloud_push_'+pid, true);
                    } catch (_) {}
                    rethrow;
                  }
                }
                // Sinon: hors ligne ou non connecté → sauvegarde locale; la sync sera faite plus tard (post-login).
              }
            } catch (_) {}
          }
          state.markLastSaveTime(DateTime.now());
        } catch (e) {
          if (_isDebug) {
            print('GamePersistenceOrchestrator.pump: erreur: $e');
          }
          if (next.trigger == SaveTrigger.lifecycle) {
            try {
              final now = DateTime.now();
              final baseKey = state.partieId ?? (state.gameName ?? 'default');
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
        syncState.value = 'ready';
      }
    }
  }

  /// Sauvegarde complète de l'état de jeu courant.
  /// ID-first: utilise `state.partieId` si présent; sinon fallback legacy par nom.
  Future<void> saveGame(GameState state, String name) async {
    if (!state.isInitialized) {
      throw SaveError('NOT_INITIALIZED', "Le jeu n'est pas initialisé");
    }

    try {
      // PR3 (A2): écriture snapshot-only.
      // On n'écrit plus le payload legacy complet (prepareGameData) afin d'éviter
      // les divergences + faciliter l'évolution de schéma.
      final snapshot = state.toSnapshot();
      final gameData = <String, dynamic>{
        LocalGamePersistenceService.snapshotKey: snapshot.toJson(),
      };

      // Identité stricte: l'ID technique de la partie est obligatoire pour toute sauvegarde non-backup
      String? existingId = state.partieId;
      final bool isBackupName = name.contains(GameConstants.BACKUP_DELIMITER);
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
        gameMode: state.gameMode,
      );

      await SaveManagerAdapter.saveGame(saveData);
    } catch (e) {
      if (_isDebug) {
        print('GamePersistenceOrchestrator.saveGame: ERREUR: $e');
      }
      rethrow;
    }
  }

  /// Nouvelle API ID-first: sauvegarder la partie courante par identifiant technique.
  /// Conserve le nom affichable actuel via `state.gameName`.
  Future<void> saveGameById(GameState state) async {
    if (!state.isInitialized) {
      throw SaveError('NOT_INITIALIZED', "Le jeu n'est pas initialisé");
    }
    // ID obligatoire pour toute sauvegarde standard
    final existingId = state.partieId;
    if (existingId == null || existingId.isEmpty) {
      throw SaveError('MISSING_ID', 'ID de partie absent: impossible de sauvegarder sans identifiant technique');
    }
    try {
      final snapshot = state.toSnapshot();
      final gameData = <String, dynamic>{
        LocalGamePersistenceService.snapshotKey: snapshot.toJson(),
      };
      final saveData = SaveGame(
        id: existingId,
        name: state.gameName ?? existingId,
        lastSaveTime: DateTime.now(),
        gameData: gameData,
        version: GameConstants.VERSION,
        gameMode: state.gameMode,
      );

      await SaveManagerAdapter.saveGame(saveData);
    } catch (e) {
      if (_isDebug) {
        print('GamePersistenceOrchestrator.saveGameById: ERREUR: $e');
      }
      rethrow;
    }
  }

  /// Sauvegarde automatique déclenchée lors d'événements importants.
  Future<void> saveOnImportantEvent(GameState state) async {
    await requestImportantSave(state, reason: 'legacy_saveOnImportantEvent');
  }

  // Chargement par nom supprimé: utiliser loadGameById(state, id)

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

      final migrated = await _persistence.migrateSnapshot(snapshot);
      if (_isDebug) {
        print(
            'GamePersistenceOrchestrator.loadGame: GameSnapshot appliqué avec succès pour la sauvegarde: $name');
      }
      return migrated;
    } catch (e) {
      if (_isDebug) {
        print(
            'GamePersistenceOrchestrator.loadGame: erreur lors du chargement du GameSnapshot: $e');
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
      final pid = state.partieId;
      if (pid == null || pid.isEmpty) {
        // ID-first strict: sans identifiant technique, pas de restauration automatique
        return false;
      }
      final saves = await SaveManagerAdapter.listSaves();
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
          // Utiliser l'API de restauration ID-first (écrase la cible par partieId)
          final ok = await SaveManagerAdapter.restoreFromBackup(backup.name, state);
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
    if (!state.isInitialized || state.gameName == null) return;

    try {
      // ID-first strict: restaurer par partieId uniquement
      final pid = state.partieId;
      if (pid == null || pid.isEmpty) return;
      final saves = await SaveManagerAdapter.listSaves();
      final backups = saves
          .where((save) => save.name.startsWith('$pid${GameConstants.BACKUP_DELIMITER}'))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      for (final backup in backups) {
        try {
          final ok = await SaveManagerAdapter.restoreFromBackup(backup.name, state);
          if (!ok) continue;
          await loadGameById(state, pid, allowRestore: false);
          if (_isDebug) {
            print(
                'GamePersistenceOrchestrator.checkAndRestoreFromBackup: Restauration réussie depuis le backup: ${backup.name}');
          }
          return;
        } catch (e) {
          if (_isDebug) {
            print(
                'GamePersistenceOrchestrator.checkAndRestoreFromBackup: Échec de la restauration depuis ${backup.name}: $e');
          }
        }
      }
    } catch (e) {
      if (_isDebug) {
        print('GamePersistenceOrchestrator.checkAndRestoreFromBackup: erreur: $e');
      }
    }
  }

  Future<List<SaveGameInfo>> listSaves() {
    return SaveManagerAdapter.listSaves();
  }

  // Legacy supprimé: deleteSaveByName(name)

  // --- ID-first wrappers (compatibilité ascendante conservée) ---
  Future<void> deleteSaveById(String id) {
    return SaveManagerAdapter.deleteSaveById(id);
  }

  Future<SaveGame?> loadSaveById(String id) {
    return SaveManagerAdapter.loadGameById(id);
  }

  Future<SaveMetadata?> getSaveMetadataById(String id) {
    return SaveManagerAdapter.getSaveMetadataById(id);
  }

  Future<bool> updateSaveMetadataById(String id, SaveMetadata metadata) {
    return SaveManagerAdapter.updateSaveMetadataById(id, metadata);
  }

  Future<SaveGame?> getLastSave() {
    return SaveManagerAdapter.getLastSave();
  }

  // Legacy supprimé: saveExists(name)

  Future<bool> restoreFromBackup(GameState state, String backupName) {
    return SaveManagerAdapter.restoreFromBackup(backupName, state);
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
      final save = await SaveManagerAdapter.loadGameById(id);
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
    try {
      final save = await SaveManagerAdapter.loadGameById(id);
      if (save == null) {
        throw StateError('Sauvegarde introuvable pour id=$id');
      }
      final String name = save.name;
      final Map<String, dynamic> gameData = SaveManagerAdapter.extractGameData(save);

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
          final pid = state.partieId ?? id;
          final port = _cloudPort;
          if (port != null && pid.isNotEmpty) {
            Future.microtask(() => checkCloudAndPullIfNeeded(state: state, partieId: pid));
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
        final pid = state.partieId ?? id;
        final port = _cloudPort;
        if (port != null && pid.isNotEmpty) {
          Future.microtask(() => checkCloudAndPullIfNeeded(state: state, partieId: pid));
        }
      } catch (_) {}
    } catch (e) {
      // Aligner le comportement de fallback de loadGame()
      if (allowRestore && e is FormatException) {
        final restored = await _tryRestoreFromBackupsAndLoad(state, state.gameName ?? '');
        if (restored) return;
      }
      if (_isDebug) {
        print('GamePersistenceOrchestrator.loadGameById: ERREUR: $e');
      }
      rethrow;
    }
  }

  // --- Cloud (Option A: cloud par partie) ---
  Future<void> pushCloudById({
    required String partieId,
    required GameState state,
    String? playerId,
  }) async {
    final port = _cloudPort;
    if (port == null) {
      throw StateError('Cloud port not configured');
    }
    // Source de vérité cloud: chaque push doit être rattaché à un joueur
    if (playerId == null || playerId.isEmpty) {
      throw StateError('playerId requis pour le push cloud');
    }
    // Construire snapshot et métadonnées minimales
    final snap = state.toSnapshot().toJson();
    String displayName = state.gameName ?? '';
    try {
      final metaLocal = await SaveManagerAdapter.getSaveMetadataById(partieId);
      if (metaLocal != null && (metaLocal.name).isNotEmpty) {
        displayName = metaLocal.name;
      }
    } catch (_) {}
    if (displayName.isEmpty) displayName = partieId;
    final meta = <String, dynamic>{
      'partieId': partieId,
      'gameMode': state.gameMode == GameMode.COMPETITIVE ? 'COMPETITIVE' : 'INFINITE',
      'gameVersion': GameConstants.VERSION,
      'savedAt': DateTime.now().toIso8601String(),
      'name': displayName,
      // Attachement obligatoire au joueur cloud
      'playerId': playerId,
    };
    await port.pushById(partieId: partieId, snapshot: snap, metadata: meta);
  }

  Future<Map<String, dynamic>?> pullCloudById({
    required String partieId,
  }) async {
    final port = _cloudPort;
    if (port == null) {
      throw StateError('Cloud port not configured');
    }
    return port.pullById(partieId: partieId);
  }

  Future<CloudStatus> cloudStatusById({
    required String partieId,
  }) async {
    final port = _cloudPort;
    if (port == null) {
      throw StateError('Cloud port not configured');
    }
    return port.statusById(partieId: partieId);
  }

  /// Liste les parties présentes côté cloud (selon l'implémentation du port)
  Future<List<CloudIndexEntry>> listCloudParties() async {
    final port = _cloudPort;
    if (port == null) {
      throw StateError('Cloud port not configured');
    }
    return port.listParties();
  }

  /// Hook public simple pour déclencher la synchronisation post-connexion
  Future<void> onPlayerConnected({required String playerId}) {
    return postLoginSync(playerId: playerId).then((_) => retryPendingCloudPushes());
  }

  /// Synchronisation post-connexion (cloud gagne toujours).
  /// - Inventorie cloud et local (hors backups)
  /// - Pour chaque partieId:
  ///   * local ∧ cloud → importer du cloud (overwrite local)
  ///   * local seul → push immédiat au cloud
  ///   * cloud seul → matérialiser localement
  Future<void> postLoginSync({String? playerId}) async {
    final port = _cloudPort;
    if (port == null) {
      // Pas de port cloud configuré → rien à faire
      return;
    }
    try {
      // 1) Inventaires
      final cloudEntries = await listCloudParties();
      final Map<String, CloudIndexEntry> cloudIndex = {
        for (final e in cloudEntries) e.partieId: e,
      };

      final localMetas = await SaveManagerAdapter.listSaves();
      final Set<String> localIds = localMetas
          .where((m) => !m.isBackup)
          .map((m) => m.id)
          .toSet();

      // 2) Union des IDs
      final Set<String> unionIds = {...localIds, ...cloudIndex.keys};

      // 3) Arbitrage déterministe par ID (fraîcheur obligatoire)
      for (final id in unionIds) {
        final hasLocal = localIds.contains(id);
        final hasCloud = cloudIndex.containsKey(id);

        try {
          if (hasLocal && hasCloud) {
            // Règle fraîcheur: comparer cloud vs local et décider
            await _arbitrateFreshnessAndSync(
              partieId: id,
              playerId: playerId,
            );
          } else if (hasLocal && !hasCloud) {
            // Partie locale seulement → push de création
            await pushCloudFromSaveId(partieId: id, playerId: playerId);
          } else if (!hasLocal && hasCloud) {
            // Cloud-only → matérialiser local
            await materializeFromCloud(partieId: id);
          }
        } catch (_) {
          // Best-effort: continuer les autres ids
        }
      }
    } catch (_) {
      // Best-effort global
    }
  }

  /// Vérifie l'état cloud et applique un pull si le cloud est en avance.
  Future<void> checkCloudAndPullIfNeeded({
    required GameState state,
    required String partieId,
  }) async {
    try {
      final port = _cloudPort;
      if (port == null) return;
      // Appliquer la règle d'arbitrage fraîcheur
      await _arbitrateFreshnessAndSync(
        partieId: partieId,
        state: state,
      );
    } catch (e) {
      // Erreur réseau non bloquante
      try {
        syncState.value = 'error';
      } catch (_) {}
    }
  }

  /// Compare la fraîcheur cloud vs local et applique l'action sûre:
  /// - Cloud plus récent → importer cloud
  /// - Local plus récent → pousser au cloud
  /// - Égal → no-op
  /// Si `state` est fourni, applique directement; sinon agit au niveau stockage.
  Future<void> _arbitrateFreshnessAndSync({
    required String partieId,
    GameState? state,
    String? playerId,
  }) async {
    final port = _cloudPort;
    if (port == null) return;
    Map<String, dynamic>? obj;
    try {
      obj = await port.pullById(partieId: partieId);
    } catch (_) {
      obj = null;
    }

    // Récupérer fraîcheur locale
    final localMeta = await SaveManagerAdapter.getSaveMetadataById(partieId);
    final localTs = localMeta?.lastModified;

    // Récupérer fraîcheur cloud
    DateTime? cloudTs;
    String? cloudName;
    if (obj != null && obj['metadata'] is Map) {
      final m = Map<String, dynamic>.from(obj['metadata'] as Map);
      final savedAt = (m['savedAt']?.toString() ?? '').trim();
      cloudTs = _parseIso(savedAt);
      cloudName = (m['name']?.toString() ?? '').trim();
    }

    // Journalisation technique
    if (_isDebug) {
      print('[SYNC-ARBITER] id='+partieId+' localTs='+(localTs?.toIso8601String() ?? 'null')+' cloudTs='+(cloudTs?.toIso8601String() ?? 'null'));
    }

    if (obj == null) {
      // Aucun cloud → rien à importer; si local existe et playerId dispo, on pourra pousser ailleurs
      final pid = playerId ?? await _playerIdProvider?.call();
      if (localTs != null && pid != null && pid.isNotEmpty) {
        try {
          await pushCloudFromSaveId(partieId: partieId, playerId: pid);
          if (_isDebug) print('[SYNC-ARBITER] push (cloud absent)');
        } catch (_) {}
      }
      return;
    }

    // Comparaison
    if (cloudTs != null && localTs != null) {
      if (cloudTs.isAfter(localTs)) {
        // Importer cloud
        await _importCloudObject(partieId: partieId, obj: obj, state: state, cloudName: cloudName);
        if (_isDebug) print('[SYNC-ARBITER] action=import-cloud');
      } else if (localTs.isAfter(cloudTs)) {
        // Pousser local
        final pid = playerId ?? await _playerIdProvider?.call();
        if (pid != null && pid.isNotEmpty) {
          try {
            await pushCloudFromSaveId(partieId: partieId, playerId: pid);
            if (_isDebug) print('[SYNC-ARBITER] action=push-local');
          } catch (_) {}
        }
      } else {
        if (_isDebug) print('[SYNC-ARBITER] action=no-op (equal)');
      }
      return;
    }

    // Cas dégradés: privilégier la sécurité (pas d'écrasement aveugle)
    if (cloudTs != null && localTs == null) {
      await _importCloudObject(partieId: partieId, obj: obj, state: state, cloudName: cloudName);
      if (_isDebug) print('[SYNC-ARBITER] action=import-cloud (no localTs)');
      return;
    }
    if (localTs != null && cloudTs == null) {
      final pid = playerId ?? await _playerIdProvider?.call();
      if (pid != null && pid.isNotEmpty) {
        try {
          await pushCloudFromSaveId(partieId: partieId, playerId: pid);
          if (_isDebug) print('[SYNC-ARBITER] action=push-local (no cloudTs)');
        } catch (_) {}
      }
      return;
    }
    // Aucun timestamp disponible → no-op sécurisé
    if (_isDebug) print('[SYNC-ARBITER] action=no-op (no timestamps)');
  }

  Future<void> _importCloudObject({
    required String partieId,
    required Map<String, dynamic> obj,
    GameState? state,
    String? cloudName,
  }) async {
    final raw = obj['snapshot'];
    if (raw is! Map) return;
    final snap = GameSnapshot.fromJson(Map<String, dynamic>.from(raw));
    // Harmoniser le nom local d'après le cloud avant d'appliquer
    try {
      final metaLocal = await SaveManagerAdapter.getSaveMetadataById(partieId);
      if (cloudName != null && cloudName.isNotEmpty && metaLocal != null && metaLocal.name != cloudName) {
        await SaveManagerAdapter.updateSaveMetadataById(partieId, metaLocal.copyWith(name: cloudName));
      }
    } catch (_) {}
    if (state != null) {
      state.applyLoadedGameDataWithoutSnapshot(state.gameName ?? partieId, <String, dynamic>{});
      state.applySnapshot(snap);
      await state.finishLoadGameAfterSnapshot(state.gameName ?? partieId, <String, dynamic>{});
      try {
        await saveGameById(state);
      } catch (_) {}
    } else {
      // matérialisation silencieuse via SaveManagerAdapter
      final save = SaveGame(
        id: partieId,
        name: cloudName ?? partieId,
        lastSaveTime: DateTime.now(),
        gameData: { LocalGamePersistenceService.snapshotKey: snap.toJson() },
        version: GameConstants.VERSION,
        gameMode: GameMode.INFINITE,
      );
      await SaveManagerAdapter.saveGame(save);
    }
  }

  /// Pousse au cloud le snapshot stocké pour une sauvegarde identifiée, sans charger l'UI
  /// - Lit la sauvegarde locale (par ID)
  /// - Extrait `gameSnapshot` depuis le `gameData`
  /// - Envoie via le port cloud avec des métadonnées minimales
  Future<void> pushCloudFromSaveId({
    required String partieId,
    String? playerId,
  }) async {
    final port = _cloudPort;
    if (port == null) {
      throw StateError('Cloud port not configured');
    }
    // Source de vérité cloud: push exige un playerId pour rattacher la partie
    if (playerId == null || playerId.isEmpty) {
      throw StateError('playerId requis pour le push cloud');
    }
    final save = await SaveManagerAdapter.loadGameById(partieId);
    if (save == null) {
      throw StateError('Sauvegarde introuvable pour id=$partieId');
    }
    final data = save.gameData;
    final key = LocalGamePersistenceService.snapshotKey;
    if (!data.containsKey(key)) {
      throw StateError('Snapshot absent dans la sauvegarde id=$partieId');
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
      throw StateError('Snapshot illisible pour id=$partieId');
    }
    final meta = <String, dynamic>{
      'partieId': partieId,
      'gameMode': save.gameMode == GameMode.COMPETITIVE ? 'COMPETITIVE' : 'INFINITE',
      'gameVersion': save.version,
      'savedAt': DateTime.now().toIso8601String(),
      'name': save.name,
      // Attachement obligatoire au joueur cloud
      'playerId': playerId,
    };
    try {
      await port.pushById(partieId: partieId, snapshot: snapshot, metadata: meta);
    } catch (e) {
      // En cas d'échec, marquer pour retry ultérieur
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pending_cloud_push_'+partieId, true);
      } catch (_) {}
      rethrow;
    }
  }

  /// Matérialise localement une partie à partir du cloud (écrit snapshot-only sous l'ID)
  Future<bool> materializeFromCloud({required String partieId}) async {
    final port = _cloudPort;
    if (port == null) {
      throw StateError('Cloud port not configured');
    }
    final obj = await port.pullById(partieId: partieId);
    if (obj == null) return false;
    Map<String, dynamic>? snapshot;
    String name = partieId;
    String version = GameConstants.VERSION;
    GameMode mode = GameMode.INFINITE;
    try {
      final raw = obj['snapshot'];
      if (raw is Map) {
        snapshot = Map<String, dynamic>.from(raw as Map);
      }
      if (obj['metadata'] is Map) {
        final m = Map<String, dynamic>.from(obj['metadata'] as Map);
        final n = m['name']?.toString();
        if (n != null && n.isNotEmpty) name = n;
        final v = m['gameVersion']?.toString();
        if (v != null && v.isNotEmpty) version = v;
        final gm = m['gameMode']?.toString();
        if (gm != null && gm.contains('COMPETITIVE')) mode = GameMode.COMPETITIVE;
      }
    } catch (_) {}
    if (snapshot == null) return false;
    final save = SaveGame(
      id: partieId,
      name: name,
      lastSaveTime: DateTime.now(),
      gameData: { LocalGamePersistenceService.snapshotKey: snapshot },
      version: version,
      gameMode: mode,
    );
    return await SaveManagerAdapter.saveGame(save);
  }

  /// Retente les pushes cloud marqués en attente (backend dormant ou offline)
  Future<void> retryPendingCloudPushes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playerId = await _playerIdProvider?.call();
      if (playerId == null || playerId.isEmpty) return;
      final metas = await SaveManagerAdapter.listSaves();
      for (final m in metas.where((e) => !e.isBackup)) {
        final key = 'pending_cloud_push_'+m.id;
        final pending = prefs.getBool(key) ?? false;
        if (!pending) continue;
        try {
          await pushCloudFromSaveId(partieId: m.id, playerId: playerId);
          await prefs.remove(key);
        } catch (_) {
          // laisser pour prochaine tentative
        }
      }
    } catch (_) {}
  }

  /// Mission 7: Contrôles d'intégrité non-intrusifs (debug-only)
  /// - Détecte les noms en doublon pointant vers des IDs différents
  /// - Vérifie la présence du snapshot (clé LocalGamePersistenceService.snapshotKey)
  ///   et un format minimalement lisible (Map<String,dynamic> ou String JSON)
  Future<void> runIntegrityChecks() async {
    if (!_isDebug) return;
    try {
      final metas = await SaveManagerAdapter.instance.listSaves();
      // 1) Doublons de noms -> IDs différents
      final Map<String, Set<String>> nameToIds = {};
      for (final m in metas) {
        nameToIds.putIfAbsent(m.name, () => <String>{}).add(m.id);
      }
      final duplicates = nameToIds.entries.where((e) => e.value.length > 1).toList();
      if (duplicates.isNotEmpty) {
        print('INTEGRITY WARNING: Noms en doublon sur IDs différents (${duplicates.length})');
        for (final d in duplicates) {
          print('  - "${d.key}": ${d.value.join(', ')}');
        }
      }

      // 2) Snapshot présent et lisible (à minima)
      for (final m in metas) {
        try {
          final save = await SaveManagerAdapter.loadGameById(m.id);
          if (save == null) {
            print('INTEGRITY ERROR: Sauvegarde introuvable pour id=${m.id} ("${m.name}")');
            continue;
          }
          // 2.a) Harmonisation SaveGame vs Metadata (name, version, gameMode)
          try {
            final meta = await SaveManagerAdapter.getSaveMetadataById(m.id);
            if (meta == null) {
              print('INTEGRITY WARNING: Métadonnées manquantes pour id=${m.id} ("${m.name}")');
            } else {
              if (meta.name != save.name) {
                print('INTEGRITY WARNING: Désalignement name meta="${meta.name}" vs save="${save.name}" pour id=${m.id}');
              }
              if (meta.version != save.version) {
                print('INTEGRITY WARNING: Version meta=${meta.version} vs save=${save.version} pour id=${m.id}');
              }
              if (meta.gameMode != save.gameMode) {
                print('INTEGRITY WARNING: GameMode meta=${meta.gameMode} vs save=${save.gameMode} pour id=${m.id}');
              }
            }
          } catch (e) {
            print('INTEGRITY ERROR: Lecture metadata échouée pour id=${m.id}: $e');
          }
          final data = save.gameData;
          final key = LocalGamePersistenceService.snapshotKey;
          if (!data.containsKey(key)) {
            print('INTEGRITY ERROR: Snapshot manquant pour id=${m.id} ("${m.name}")');
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
                print('INTEGRITY ERROR: Snapshot JSON invalide (null) pour id=${m.id}');
              }
            } catch (e) {
              print('INTEGRITY ERROR: Snapshot JSON illisible pour id=${m.id}: $e');
            }
          } else {
            print('INTEGRITY ERROR: Snapshot type inattendu (${raw.runtimeType}) pour id=${m.id}');
          }
        } catch (e) {
          print('INTEGRITY ERROR: Exception lors du check pour id=${m.id}: $e');
        }
      }

      // 3) Backups: format partieId|timestamp, association à une sauvegarde régulière, rétention N/TTL
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
            print('INTEGRITY WARNING: Nom de backup invalide (pas exactement une séparation) → ${b.name}');
            continue;
          }
          final base = parts.first;
          final ts = int.tryParse(parts.last);
          if (base.isEmpty || ts == null) {
            print('INTEGRITY WARNING: Backup non conforme (base vide ou timestamp invalide) → ${b.name}');
          }
          if (!regularIds.contains(base)) {
            print('INTEGRITY WARNING: Backup orphelin (aucune sauvegarde régulière trouvée pour id=$base) → ${b.name}');
          }
          byBase.putIfAbsent(base, () => <dynamic>[]).add(b);
        }

        for (final entry in byBase.entries) {
          final list = entry.value..
              sort((a,b)=>b.lastModified.compareTo(a.lastModified));
          if (list.length > GameConstants.BACKUP_RETENTION_MAX) {
            print('INTEGRITY WARNING: Trop de backups pour id=${entry.key} (${list.length}/${GameConstants.BACKUP_RETENTION_MAX})');
          }
          for (final b in list) {
            final age = now.difference(b.lastModified);
            if (age > GameConstants.BACKUP_RETENTION_TTL) {
              print('INTEGRITY WARNING: Backup au-delà de la TTL (${age.inDays}j) pour id=${entry.key} → ${b.name}');
            }
          }
        }
      } catch (e) {
        print('INTEGRITY ERROR: Exception lors des vérifications backups: $e');
      }
    } catch (e) {
      print('INTEGRITY CHECKS FAILED: $e');
    }
  }
}
