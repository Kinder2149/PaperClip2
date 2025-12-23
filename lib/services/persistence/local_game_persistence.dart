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

  static const int _latestSupportedSchemaVersion = 1;

  const LocalGamePersistenceService();

  @override
  Future<void> saveSnapshot(GameSnapshot snapshot, {required String slotId}) async {
    // S'assurer que le système de sauvegarde est prêt
    await SaveManagerAdapter.ensureInitialized();

    SaveGame? existing;
    try {
      // ID-first: slotId correspond à l'identifiant technique (partieId)
      existing = await SaveManagerAdapter.loadGameById(slotId);
    } catch (_) {
      // Si la sauvegarde n'existe pas encore, on en créera une nouvelle.
      existing = null;
    }

    final now = DateTime.now();
    Map<String, dynamic> gameData = existing?.gameData ?? <String, dynamic>{};

    // Injecter / remplacer le snapshot
    gameData[snapshotKey] = snapshot.toJson();

    final saveGame = SaveGame(
      // ID-first strict: l'identifiant persistant doit être le partieId (slotId)
      id: existing?.id ?? slotId,
      name: slotId,
      gameData: gameData,
      gameMode: existing?.gameMode ?? GameMode.INFINITE,
      lastSaveTime: now,
      version: existing?.version,
    );

    await SaveManagerAdapter.saveGame(saveGame);
  }

  /// Variante ID-first: sauvegarder un snapshot pour une partie identifiée par `partieId`.
  Future<void> saveSnapshotById(GameSnapshot snapshot, {required String partieId}) async {
    await saveSnapshot(snapshot, slotId: partieId);
  }

  @override
  Future<GameSnapshot?> loadSnapshot({required String slotId}) async {
    await SaveManagerAdapter.ensureInitialized();

    SaveGame? saveGame;
    try {
      // ID-first: resolver par identifiant unique
      saveGame = await SaveManagerAdapter.loadGameById(slotId);
    } catch (_) {
      // Aucune sauvegarde disponible pour ce slot
      return null;
    }

    final data = saveGame?.gameData;
    if (data == null) {
      return null;
    }
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

  /// Variante ID-first: charger un snapshot pour une partie identifiée par `partieId`.
  Future<GameSnapshot?> loadSnapshotById({required String partieId}) async {
    return loadSnapshot(slotId: partieId);
  }

  @override
  Future<GameSnapshot> migrateSnapshot(GameSnapshot snapshot) async {
    final migratedMetadata = Map<String, dynamic>.from(snapshot.metadata);
    final migratedCore = Map<String, dynamic>.from(snapshot.core);

    // v1 minimal: metadata.schemaVersion + lastActiveAt
    final schemaVersionRaw =
        migratedMetadata['snapshotSchemaVersion'] ?? migratedMetadata['schemaVersion'];
    final schemaVersion = (schemaVersionRaw is num) ? schemaVersionRaw.toInt() : 0;

    // Si on rencontre un snapshot plus récent que ce que l'app sait gérer,
    // on échoue explicitement afin de permettre une restauration backup (sinon erreur).
    if (schemaVersion > _latestSupportedSchemaVersion) {
      throw FormatException(
        'GameSnapshot.schemaVersion=$schemaVersion non supporté (max=$_latestSupportedSchemaVersion)',
      );
    }

    if (schemaVersion < 1) {
      migratedMetadata['schemaVersion'] = 1;
      migratedMetadata['snapshotSchemaVersion'] = 1;
    } else {
      migratedMetadata['schemaVersion'] = schemaVersion;
      migratedMetadata['snapshotSchemaVersion'] = schemaVersion;
    }

    migratedMetadata['appVersion'] ??= GameConstants.VERSION;
    migratedMetadata['saveFormatVersion'] ??= GameConstants.CURRENT_SAVE_FORMAT_VERSION;

    if (migratedMetadata['lastActiveAt'] == null) {
      migratedMetadata['lastActiveAt'] =
          (migratedMetadata['savedAt'] as String?) ?? DateTime.now().toIso8601String();
    }

    if (migratedMetadata['lastOfflineAppliedAt'] == null) {
      migratedMetadata['lastOfflineAppliedAt'] = migratedMetadata['lastActiveAt'];
    }

    // Normaliser les champs de temps au format ISO si possible.
    final lastActiveAtRaw = migratedMetadata['lastActiveAt'];
    if (lastActiveAtRaw is! String || DateTime.tryParse(lastActiveAtRaw) == null) {
      migratedMetadata['lastActiveAt'] = DateTime.now().toIso8601String();
    }
    final lastOfflineAppliedAtRaw = migratedMetadata['lastOfflineAppliedAt'];
    if (lastOfflineAppliedAtRaw is! String || DateTime.tryParse(lastOfflineAppliedAtRaw) == null) {
      migratedMetadata['lastOfflineAppliedAt'] = migratedMetadata['lastActiveAt'];
    }

    return GameSnapshot(
      metadata: migratedMetadata,
      core: migratedCore,
      market: snapshot.market,
      production: snapshot.production,
      stats: snapshot.stats,
    );
  }
}
