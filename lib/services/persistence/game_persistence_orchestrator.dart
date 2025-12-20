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
      // PR3 (A2): écriture snapshot-only.
      // On n'écrit plus le payload legacy complet (prepareGameData) afin d'éviter
      // les divergences + faciliter l'évolution de schéma.
      final snapshot = state.toSnapshot();
      final gameData = <String, dynamic>{
        LocalGamePersistenceService.snapshotKey: snapshot.toJson(),
      };

      // Réutiliser l'ID existant si une sauvegarde avec ce nom existe déjà
      String? existingId;
      try {
        final metas = await SaveManagerAdapter.instance.listSaves();
        final sameName = metas.where((m) => m.name == name).toList();
        if (sameName.isNotEmpty) {
          sameName.sort((a, b) => b.lastModified.compareTo(a.lastModified));
          existingId = sameName.first.id;
        }
      } catch (_) {}

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

  /// Sauvegarde automatique déclenchée lors d'événements importants.
  Future<void> saveOnImportantEvent(GameState state) async {
    await requestImportantSave(state, reason: 'legacy_saveOnImportantEvent');
  }

  /// Chargement complet d'une partie existante.
  Future<void> loadGame(GameState state, String name, {bool allowRestore = true}) async {
    try {
      if (_isDebug) {
        print('GamePersistenceOrchestrator.loadGame: Chargement de la partie: $name');
      }

      final loadedSave = await SaveManagerAdapter.loadGame(name);

      final Map<String, dynamic> gameData =
          SaveManagerAdapter.extractGameData(loadedSave);

      // Snapshot-first: le GameSnapshot est la source de vérité si présent.
      // PR3 (B2/X): si snapshot présent mais invalide -> pas de fallback legacy.
      // On tente une restauration depuis backup, sinon on échoue explicitement.
      final snapshot = await _loadSnapshotIfPresent(state, name, gameData);

      if (snapshot != null) {
        // Réinitialiser l'état (via l'entrée existante) puis appliquer snapshot.
        // On passe un gameData vide pour éviter d'écraser l'état snapshot.
        state.applyLoadedGameDataWithoutSnapshot(name, <String, dynamic>{});
        state.applySnapshot(snapshot);

        await state.finishLoadGameAfterSnapshot(name, <String, dynamic>{});

        // Offline v2: une seule implémentation (idempotente) utilisée partout.
        state.applyOfflineProgressV2();

        // Persister les timestamps offline (ex: lastOfflineAppliedAt) pour éviter
        // de ré-appliquer l'offline sur le même intervalle lors d'un futur load.
        try {
          await saveGame(state, name);
        } catch (_) {
          // Best-effort uniquement.
        }
      } else {
        // Migration depuis legacy (snapshot absent uniquement).
        state.applyLoadedGameDataWithoutSnapshot(name, gameData);
        await state.finishLoadGameAfterSnapshot(name, gameData);

        // PR3: si on a chargé en legacy, on réécrit snapshot-only.
        try {
          await saveGame(state, name);
        } catch (_) {
          // Best-effort uniquement.
        }
      }

    } catch (e) {
      // PR3 (B2/X): si on échoue à charger à cause d'un snapshot invalide,
      // on tente une restauration depuis backup. Sinon, on laisse remonter.
      if (allowRestore && e is FormatException) {
        final restored = await _tryRestoreFromBackupsAndLoad(state, name);
        if (restored) {
          return;
        }
      }
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
      final saves = await SaveManagerAdapter.instance.listSaves();
      final backups = saves
          .where((save) => save.name.startsWith('$baseName${GameConstants.BACKUP_DELIMITER}'))
          .toList();

      if (backups.isEmpty) {
        return false;
      }

      backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      for (final backup in backups) {
        try {
          final backupSave = await SaveManagerAdapter.loadGame(backup.name);
          final restoredSave = SaveGame(
            name: baseName,
            lastSaveTime: DateTime.now(),
            gameData: backupSave.gameData,
            version: backupSave.version,
            gameMode: backupSave.gameMode,
            isRestored: true,
          );

          final ok = await SaveManagerAdapter.saveGame(restoredSave);
          if (!ok) {
            continue;
          }

          try {
            await loadGame(state, baseName, allowRestore: false);
            return true;
          } catch (_) {
            // Snapshot encore invalide après restauration: essayer le backup suivant.
          }
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
      final saves = await SaveManagerAdapter.instance.listSaves();
      final backups = saves
          .where(
            (save) =>
                save.name.startsWith('${state.gameName!}${GameConstants.BACKUP_DELIMITER}'),
          )
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

  Future<List<SaveGameInfo>> listSaves() {
    return SaveManagerAdapter.listSaves();
  }

  Future<void> deleteSaveByName(String name) {
    return SaveManagerAdapter.deleteSaveByName(name);
  }

  Future<SaveGame?> getLastSave() {
    return SaveManagerAdapter.getLastSave();
  }

  Future<bool> saveExists(String name) {
    return SaveManagerAdapter.saveExists(name);
  }

  Future<bool> restoreFromBackup(GameState state, String backupName) {
    return SaveManagerAdapter.restoreFromBackup(backupName, state);
  }
}
