import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';

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

  // CHANTIER-01: Version 3 pour entreprise unique
  static const int _latestSupportedSchemaVersion = 3;

  const LocalGamePersistenceService();

  @override
  Future<void> saveSnapshot(GameSnapshot snapshot, {required String slotId}) async {
    // S'assurer que le système de sauvegarde est prêt
    final mgr = await LocalSaveGameManager.getInstance();

    SaveGame? existing;
    try {
      // ID-first: slotId correspond à l'identifiant technique (enterpriseId)
      existing = await mgr.loadSave(slotId);
    } catch (_) {
      // Si la sauvegarde n'existe pas encore, on en créera une nouvelle.
      existing = null;
    }

    final now = DateTime.now();
    Map<String, dynamic> gameData = existing?.gameData ?? <String, dynamic>{};

    // Enforcer l'intégrité minimale des métadonnées Monde dans le snapshot
    final normalizedSnapshot = _ensureWorldMetadata(snapshot, slotId: slotId, now: now);

    // Injecter / remplacer le snapshot
    gameData[snapshotKey] = normalizedSnapshot.toJson();

    final saveGame = SaveGame(
      // ID-first strict: l'identifiant persistant doit être l'enterpriseId (slotId)
      id: existing?.id ?? slotId,
      name: existing?.name ?? slotId,
      gameData: gameData,
      lastSaveTime: now,
      version: existing?.version,
    );

    await mgr.saveGame(saveGame);
  }

  /// Variante ID-first: sauvegarder un snapshot pour une entreprise identifiée par `enterpriseId`.
  Future<void> saveSnapshotById(GameSnapshot snapshot, {required String enterpriseId}) async {
    await saveSnapshot(snapshot, slotId: enterpriseId);
  }


  @override
  Future<GameSnapshot?> loadSnapshot({required String slotId}) async {
    final mgr = await LocalSaveGameManager.getInstance();

    SaveGame? saveGame;
    try {
      // ID-first: resolver par identifiant unique
      saveGame = await mgr.loadSave(slotId);
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
      final snap = GameSnapshot.fromJson(Map<String, dynamic>.from(raw));
      // À la lecture locale, garantir également la présence de l'enterpriseId si absent
      // sans altérer le stockage tant qu'aucune sauvegarde n'est faite.
      try {
        return _ensureWorldMetadata(snap, slotId: slotId, now: DateTime.now());
      } catch (_) {
        return snap;
      }
    }
    if (raw is String) {
      final snap = GameSnapshot.fromJsonString(raw);
      try {
        return _ensureWorldMetadata(snap, slotId: slotId, now: DateTime.now());
      } catch (_) {
        return snap;
      }
    }

    // Format inattendu
    return null;
  }

  /// Variante ID-first: charger un snapshot pour une entreprise identifiée par `enterpriseId`.
  Future<GameSnapshot?> loadSnapshotById({required String enterpriseId}) async {
    return loadSnapshot(slotId: enterpriseId);
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


  /// Normalise les métadonnées minimales dans le snapshot (createdAt, updatedAt, gameVersion).
  GameSnapshot _ensureWorldMetadata(GameSnapshot snapshot, {required String slotId, required DateTime now}) {
    final md = Map<String, dynamic>.from(snapshot.metadata);

    // createdAt immuable: si absent, créer maintenant
    md['createdAt'] ??= now.toIso8601String();
    // updatedAt = now (monotone non décroissant, garanti par flux d'écriture atomique)
    md['updatedAt'] = now.toIso8601String();
    // gameVersion par défaut
    md['gameVersion'] ??= GameConstants.VERSION;

    return GameSnapshot(
      metadata: md,
      core: snapshot.core,
      market: snapshot.market,
      production: snapshot.production,
      stats: snapshot.stats,
    );
  }
}
