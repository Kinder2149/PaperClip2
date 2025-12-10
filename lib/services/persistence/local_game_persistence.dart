import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';

import 'game_persistence_service.dart';
import 'game_snapshot.dart';

/// Implémentation locale de [GamePersistenceService] adossée au
/// système de sauvegarde existant (SaveManagerAdapter / LocalSaveGameManager).
///
/// - `slotId` correspond au nom de sauvegarde (save name).
/// - Le `GameSnapshot` est stocké dans `SaveGame.gameData['gameSnapshot']`.
class LocalGamePersistenceService implements GamePersistenceService {
  /// Clé utilisée dans le gameData pour stocker le snapshot sérialisé.
  static const String snapshotKey = 'gameSnapshot';

  const LocalGamePersistenceService();

  @override
  Future<void> saveSnapshot(GameSnapshot snapshot, {required String slotId}) async {
    // S'assurer que le système de sauvegarde est prêt
    await SaveManagerAdapter.ensureInitialized();

    SaveGame? existing;
    try {
      existing = await SaveManagerAdapter.loadGame(slotId);
    } catch (_) {
      // Si la sauvegarde n'existe pas encore, on en créera une nouvelle.
      existing = null;
    }

    final now = DateTime.now();
    Map<String, dynamic> gameData = existing?.gameData ?? <String, dynamic>{};

    // Injecter / remplacer le snapshot
    gameData[snapshotKey] = snapshot.toJson();

    final saveGame = SaveGame(
      id: existing?.id,
      name: slotId,
      gameData: gameData,
      gameMode: existing?.gameMode ?? GameMode.INFINITE,
      lastSaveTime: now,
      version: existing?.version,
    );

    await SaveManagerAdapter.saveGame(saveGame);
  }

  @override
  Future<GameSnapshot?> loadSnapshot({required String slotId}) async {
    await SaveManagerAdapter.ensureInitialized();

    SaveGame? saveGame;
    try {
      saveGame = await SaveManagerAdapter.loadGame(slotId);
    } catch (_) {
      // Aucune sauvegarde disponible pour ce slot
      return null;
    }

    final data = saveGame.gameData;
    if (!data.containsKey(snapshotKey)) {
      return null;
    }

    final raw = data[snapshotKey];
    if (raw is Map) {
      return GameSnapshot.fromJson(Map<String, dynamic>.from(raw));
    }
    if (raw is String) {
      return GameSnapshot.fromJsonString(raw);
    }

    // Format inattendu
    return null;
  }

  @override
  Future<GameSnapshot> migrateSnapshot(GameSnapshot snapshot) async {
    // La logique de migration détaillée (SAVE_FORMAT_VERSION, SaveMigrationService, etc.)
    // sera implémentée dans une PR dédiée. Pour l'instant, on retourne le snapshot tel quel.
    return snapshot;
  }
}
