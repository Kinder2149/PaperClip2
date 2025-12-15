// lib/services/persistence/game_persistence_orchestrator.dart
// Service d'orchestration de la persistance de l'état de jeu.
//
// Ce service centralise la logique de sauvegarde/chargement/backup
// et délègue au système existant (SaveManagerAdapter, GamePersistenceService),
// afin de garder GameState focalisé sur la logique métier et la sérialisation.

import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:paperclip2/services/persistence/game_persistence_service.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/save_game.dart';
import 'package:paperclip2/services/save_system/save_validator.dart';

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

  static const Duration _backupCooldown = Duration(minutes: 10);
  static const Duration _importantEventCoalesceWindow = Duration(seconds: 2);

  final List<SaveRequest> _queue = <SaveRequest>[];
  bool _isPumping = false;
  DateTime? _lastBackupAt;
  DateTime? _lastImportantEventEnqueuedAt;

  void resetForTesting() {
    _queue.clear();
    _isPumping = false;
    _lastBackupAt = null;
    _lastImportantEventEnqueuedAt = null;
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
      final baseName = lastSave.name;

      ValidationResult validation;
      try {
        final validatedPayload = <String, dynamic>{
          'version': SaveManagerAdapter.SAVE_FORMAT_VERSION,
          'timestamp': DateTime.now().toIso8601String(),
          'gameData': lastSave.gameData,
        };
        validation = SaveValidator.quickValidate(validatedPayload);
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
          'Sauvegarde "$baseName" invalide (${validation.errors.length} erreurs). '
          'Tentative de restauration depuis un backup...',
        );
      }

      final saves = await SaveManagerAdapter.instance.listSaves();
      final backups = saves
          .where((save) => save.name.startsWith('$baseName${GameConstants.BACKUP_DELIMITER}'))
          .toList();

      if (backups.isEmpty) {
        if (_isDebug) {
          print(
            'GamePersistenceOrchestrator.checkAndRestoreLastSaveFromBackupIfNeeded: '
            'Aucun backup trouvé pour "$baseName"',
          );
        }
        return;
      }

      backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final latestBackupName = backups.first.name;

      try {
        final backupSave = await SaveManagerAdapter.loadGame(latestBackupName);

        final restoredSave = SaveGame(
          name: baseName,
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
            'Restauration depuis "$latestBackupName" → "$baseName": ${ok ? 'OK' : 'ECHEC'}',
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

  Future<void> requestAutoSave(GameState state, {String? reason}) async {
    if (!state.isInitialized || state.gameName == null) return;
    await _enqueue(
      state,
      SaveRequest(
        trigger: SaveTrigger.autosave,
        priority: SavePriority.low,
        slotId: state.gameName!,
        isBackup: false,
        requestedAt: DateTime.now(),
        reason: reason,
      ),
    );
  }

  Future<void> requestImportantSave(GameState state, {String? reason}) async {
    if (!state.isInitialized || state.gameName == null) return;

    final now = DateTime.now();
    _lastImportantEventEnqueuedAt ??= now;

    await _enqueue(
      state,
      SaveRequest(
        trigger: SaveTrigger.importantEvent,
        priority: SavePriority.normal,
        slotId: state.gameName!,
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
    final targetSlotId = slotId ?? state.gameName;
    if (targetSlotId == null) return;
    await _enqueue(
      state,
      SaveRequest(
        trigger: SaveTrigger.manual,
        priority: SavePriority.high,
        slotId: targetSlotId,
        isBackup: false,
        requestedAt: DateTime.now(),
        reason: reason,
      ),
    );
  }

  Future<void> requestLifecycleSave(GameState state, {String? reason}) async {
    if (!state.isInitialized || state.gameName == null) return;

    final now = DateTime.now();

    await _enqueue(
      state,
      SaveRequest(
        trigger: SaveTrigger.lifecycle,
        priority: SavePriority.critical,
        slotId: state.gameName!,
        isBackup: false,
        requestedAt: now,
        reason: reason,
      ),
    );

    final lastBackup = _lastBackupAt;
    final shouldBackup = lastBackup == null || now.difference(lastBackup) >= _backupCooldown;
    if (shouldBackup) {
      final backupName =
          '${state.gameName!}${GameConstants.BACKUP_DELIMITER}${now.millisecondsSinceEpoch}';
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

    await _pump(state);
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
      while (_queue.isNotEmpty) {
        final next = _pickNext();
        try {
          if (_isDebug) {
            print(
              'GamePersistenceOrchestrator.pump: start trigger=${next.trigger}, '
              'slot=${next.slotId}, backup=${next.isBackup}',
            );
          }
          await saveGame(state, next.slotId);
          state.markLastSaveTime(DateTime.now());
        } catch (e) {
          if (_isDebug) {
            print('GamePersistenceOrchestrator.pump: erreur: $e');
          }
          if (next.trigger == SaveTrigger.lifecycle) {
            try {
              final now = DateTime.now();
              final backupName =
                  '${state.gameName!}${GameConstants.BACKUP_DELIMITER}${now.millisecondsSinceEpoch}';
              await saveGame(state, backupName);
            } catch (_) {
              // Best-effort seulement.
            }
          }
        }
      }
    } finally {
      _isPumping = false;
    }
  }

  /// Sauvegarde complète de l'état de jeu courant sous le nom [name].
  Future<void> saveGame(GameState state, String name) async {
    if (!state.isInitialized) {
      throw SaveError('NOT_INITIALIZED', "Le jeu n'est pas initialisé");
    }

    try {
      final gameData = state.prepareGameData();

      // Snapshot-first (écriture): on injecte le snapshot directement dans gameData
      // afin d'avoir une écriture unique (évite divergence et lost updates).
      try {
        final snapshot = state.toSnapshot();
        gameData[LocalGamePersistenceService.snapshotKey] = snapshot.toJson();
      } catch (e) {
        if (_isDebug) {
          print(
              'GamePersistenceOrchestrator.saveGame: erreur lors de la génération du GameSnapshot (écriture legacy seule): $e');
        }
      }

      final saveData = SaveGame(
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

  /// Sauvegarde automatique déclenchée lors d'événements importants.
  Future<void> saveOnImportantEvent(GameState state) async {
    await requestImportantSave(state, reason: 'legacy_saveOnImportantEvent');
  }

  /// Chargement complet d'une partie existante.
  Future<void> loadGame(GameState state, String name) async {
    try {
      if (_isDebug) {
        print('GamePersistenceOrchestrator.loadGame: Chargement de la partie: $name');
      }

      // Mission 2: l'orchestration autosave est gérée ici (hors GameState).
      state.autoSaveService.stop();

      final loadedSave = await SaveManagerAdapter.loadGame(name);

      final Map<String, dynamic> gameData =
          SaveManagerAdapter.extractGameData(loadedSave);

      // Snapshot-first: le GameSnapshot est la source de vérité si présent.
      final snapshot = await _loadSnapshotIfPresent(state, name, gameData);

      if (snapshot != null) {
        // Réinitialiser l'état (via l'entrée existante) puis appliquer snapshot.
        // On passe un gameData vide pour éviter d'écraser l'état snapshot.
        state.applyLoadedGameDataWithoutSnapshot(name, <String, dynamic>{});
        state.applySnapshot(snapshot);

        await state.finishLoadGameAfterSnapshot(name, <String, dynamic>{});

        await _applyOfflineBestEffortProduction(state, snapshot);

        // Persister les timestamps offline (ex: lastOfflineAppliedAt) pour éviter
        // de ré-appliquer l'offline sur le même intervalle lors d'un futur load.
        try {
          await saveGame(state, name);
        } catch (_) {
          // Best-effort uniquement.
        }
      } else {
        // Fallback legacy.
        state.applyLoadedGameDataWithoutSnapshot(name, gameData);
        await state.finishLoadGameAfterSnapshot(name, gameData);

        // Migration lazy vers snapshot-only: si on a chargé en legacy,
        // on réécrit best-effort pour injecter un GameSnapshot dans la sauvegarde.
        try {
          await saveGame(state, name);
        } catch (_) {
          // Best-effort uniquement.
        }
      }

      // Mission 2: démarrer l'autosave après un chargement complet.
      await state.autoSaveService.start();
    } catch (e) {
      if (_isDebug) {
        print('GamePersistenceOrchestrator.loadGame: ERREUR: $e');
      }
      rethrow;
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

      if (rawSnapshot is Map) {
        snapshot = GameSnapshot.fromJson(
            Map<String, dynamic>.from(rawSnapshot as Map));
      } else if (rawSnapshot is String) {
        snapshot = GameSnapshot.fromJsonString(rawSnapshot as String);
      }

      if (snapshot != null) {
        final migrated = await _persistence.migrateSnapshot(snapshot);
        if (_isDebug) {
          print(
              'GamePersistenceOrchestrator.loadGame: GameSnapshot appliqué avec succès pour la sauvegarde: $name');
        }
        return migrated;
      }
    } catch (e) {
      if (_isDebug) {
        print(
            'GamePersistenceOrchestrator.loadGame: erreur lors du chargement du GameSnapshot: $e');
      }

      // Snapshot présent mais invalide: fallback legacy explicite.
      // On retire la clé du snapshot pour éviter des tentatives répétées et
      // pour que le chargement legacy voie un gameData "propre".
      try {
        final snapshotKey = LocalGamePersistenceService.snapshotKey;
        gameData.remove(snapshotKey);
      } catch (_) {
        // Best-effort uniquement.
      }
    }

    return null;
  }

  Future<void> _applyOfflineBestEffortProduction(
    GameState state,
    GameSnapshot snapshot,
  ) async {
    try {
      if (!state.isInitialized || state.isPaused) {
        return;
      }

      final lastActiveRaw = snapshot.metadata['lastActiveAt'] as String?;
      final lastOfflineAppliedRaw = snapshot.metadata['lastOfflineAppliedAt'] as String?;

      final lastActiveAt = lastActiveRaw != null ? DateTime.tryParse(lastActiveRaw) : null;
      final lastOfflineAppliedAt =
          lastOfflineAppliedRaw != null ? DateTime.tryParse(lastOfflineAppliedRaw) : null;

      final base = [lastActiveAt, lastOfflineAppliedAt]
          .whereType<DateTime>()
          .fold<DateTime?>(null, (acc, v) => acc == null || v.isAfter(acc) ? v : acc);

      if (base == null) {
        return;
      }

      final now = DateTime.now();
      var delta = now.difference(base);
      if (delta.isNegative || delta.inSeconds <= 0) {
        return;
      }

      if (delta > GameConstants.OFFLINE_MAX_DURATION) {
        delta = GameConstants.OFFLINE_MAX_DURATION;
      }

      // Best-effort: production automatique uniquement (pas de ventes offline).
      state.productionManager.processProduction(
        elapsedSeconds: delta.inMilliseconds / 1000.0,
      );

      state.markLastOfflineAppliedAt(now);
      state.markLastActiveAt(now);
    } catch (e) {
      if (_isDebug) {
        print('GamePersistenceOrchestrator: erreur offline best-effort: $e');
      }
    }
  }

  /// Vérifie et tente de restaurer une sauvegarde depuis les backups disponibles.
  Future<void> checkAndRestoreFromBackup(GameState state) async {
    if (!state.isInitialized || state.gameName == null) return;

    try {
      final saves = await SaveManagerAdapter.instance.listSaves();
      final backups = saves
          .where((save) => save.name.startsWith('${state.gameName!}_backup_'))
          .toList();

      if (backups.isEmpty) return;

      backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      for (final backup in backups) {
        try {
          await loadGame(state, backup.name);
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
}
