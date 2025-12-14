// lib/services/persistence/game_persistence_orchestrator.dart
// Service d'orchestration de la persistance de l'état de jeu.
//
// Ce service centralise la logique de sauvegarde/chargement/backup
// et délègue au système existant (SaveManagerAdapter, GamePersistenceService),
// afin de garder GameState focalisé sur la logique métier et la sérialisation.

import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/persistence/game_persistence_service.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/save_game.dart';

const bool _isDebug = !bool.fromEnvironment('dart.vm.product');

/// Service d'orchestration de la persistance pour GameState.
class GamePersistenceOrchestrator {
  GamePersistenceOrchestrator._();

  static final GamePersistenceOrchestrator instance = GamePersistenceOrchestrator._();

  final GamePersistenceService _persistence = const LocalGamePersistenceService();

  /// Sauvegarde complète de l'état de jeu courant sous le nom [name].
  Future<void> saveGame(GameState state, String name) async {
    if (!state.isInitialized) {
      throw SaveError('NOT_INITIALIZED', "Le jeu n'est pas initialisé");
    }

    try {
      final gameData = state.prepareGameData();

      final saveData = SaveGame(
        name: name,
        lastSaveTime: DateTime.now(),
        gameData: gameData,
        version: GameConstants.VERSION,
        gameMode: state.gameMode,
      );

      await SaveManagerAdapter.saveGame(saveData);

      try {
        final snapshot = state.toSnapshot();
        await _persistence.saveSnapshot(snapshot, slotId: name);
      } catch (e) {
        if (_isDebug) {
          print(
              'GamePersistenceOrchestrator.saveGame: erreur lors de la sauvegarde du GameSnapshot: $e');
        }
      }
    } catch (e) {
      if (_isDebug) {
        print('GamePersistenceOrchestrator.saveGame: ERREUR: $e');
      }
      rethrow;
    }
  }

  /// Sauvegarde automatique déclenchée lors d'événements importants.
  Future<void> saveOnImportantEvent(GameState state) async {
    if (!state.isInitialized || state.gameName == null) return;

    try {
      await saveGame(state, state.gameName!);
      state.markLastSaveTime(DateTime.now());
    } catch (e) {
      if (_isDebug) {
        print('GamePersistenceOrchestrator.saveOnImportantEvent: erreur: $e');
      }
    }
  }

  /// Chargement complet d'une partie existante.
  Future<void> loadGame(GameState state, String name) async {
    try {
      if (_isDebug) {
        print('GamePersistenceOrchestrator.loadGame: Chargement de la partie: $name');
      }

      final loadedSave = await SaveManagerAdapter.loadGame(name);

      final Map<String, dynamic> gameData =
          SaveManagerAdapter.extractGameData(loadedSave);

      state.applyLoadedGameDataWithoutSnapshot(name, gameData);

      await _applySnapshotIfPresent(state, name, gameData);

      state.finishLoadGameAfterSnapshot(name, gameData);
    } catch (e) {
      if (_isDebug) {
        print('GamePersistenceOrchestrator.loadGame: ERREUR: $e');
      }
      rethrow;
    }
  }

  Future<void> _applySnapshotIfPresent(
    GameState state,
    String name,
    Map<String, dynamic> gameData,
  ) async {
    try {
      final snapshotKey = LocalGamePersistenceService.snapshotKey;
      if (!gameData.containsKey(snapshotKey)) {
        return;
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
        state.applySnapshot(migrated);
        if (_isDebug) {
          print(
              'GamePersistenceOrchestrator.loadGame: GameSnapshot appliqué avec succès pour la sauvegarde: $name');
        }
      }
    } catch (e) {
      if (_isDebug) {
        print(
            'GamePersistenceOrchestrator.loadGame: erreur lors du chargement du GameSnapshot: $e');
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
