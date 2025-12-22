import 'cloud_save_adapter.dart';
import 'cloud_save_models.dart';
import 'supabase_friends_repository.dart';

/// Service Sauvegarde Cloud (Étape 4)
/// - Ne touche jamais au core: construit des objets de transport et appelle l'adapter
/// - Export: prend un snapshot fourni (SAVE_SCHEMA_V1) + métadonnées pour créer un CloudSaveRecord
/// - Upload/Download: opérations explicites, jamais automatiques
/// - Conflits: propose une recommandation (local vs cloud) sans écrire nulle part
class CloudSaveService {
  final CloudSaveAdapter _adapter;
  final FriendsRepository? _friends; // optionnel pour gestion amis

  CloudSaveService({required CloudSaveAdapter adapter, FriendsRepository? friends})
      : _adapter = adapter,
        _friends = friends;

  /// Construit un enregistrement cloud à partir d'un snapshot local (source de vérité)
  CloudSaveRecord buildRecord({
    required String playerId,
    required String appVersion,
    required Map<String, dynamic> gameSnapshot, // conforme SAVE_SCHEMA_V1
    required CloudSaveDisplayData displayData,
    required CloudSaveDeviceInfo device,
    DateTime? createdAt,
    DateTime? uploadedAt,
  }) {
    // Validation contractuelle: lastSavedAt obligatoire
    final lastSaved = _extractLastSavedAt(gameSnapshot);
    if (lastSaved == null) {
      throw StateError('snapshot.meta.timestamps.lastSavedAt manquant ou invalide');
    }
    final owner = CloudSaveOwner(provider: 'google', playerId: playerId);
    final payload = CloudSavePayload(
      version: 'SAVE_SCHEMA_V1',
      snapshot: gameSnapshot,
      displayData: displayData,
    );
    final meta = CloudSaveMeta(
      appVersion: appVersion,
      createdAt: createdAt ?? DateTime.now(),
      uploadedAt: uploadedAt ?? DateTime.now(),
      device: device,
    );
    return CloudSaveRecord(id: null, owner: owner, payload: payload, meta: meta);
  }

  /// Upload explicite (append-only). Ne modifie pas le local.
  Future<CloudSaveRecord> upload(CloudSaveRecord record) async {
    final ready = await _adapter.isReady();
    if (!ready) {
      throw StateError('CloudSaveAdapter is not ready');
    }
    return _adapter.upload(record);
  }

  /// Liste des révisions pour un joueur (owner.playerId)
  Future<List<CloudSaveRecord>> listByOwner(String playerId) async {
    final ready = await _adapter.isReady();
    if (!ready) return <CloudSaveRecord>[];
    return _adapter.listByOwner(playerId);
  }

  /// Récupère une révision par id (pour import manuel ultérieur par l'orchestrateur/UI)
  Future<CloudSaveRecord?> getById(String id) async {
    final ready = await _adapter.isReady();
    if (!ready) return null;
    return _adapter.getById(id);
  }

  /// Marque optionnellement une révision (favorite/current). Non destructeur côté serveur.
  Future<void> label(String id, {required String label}) async {
    final ready = await _adapter.isReady();
    if (!ready) return;
    await _adapter.label(id, label: label);
  }

  /// Recommandation de résolution de conflit basée sur les timestamps de snapshot.
  CloudConflictResolution recommendResolution({
    required Map<String, dynamic> localSnapshot,
    required CloudSaveRecord cloud,
  }) {
    final localTs = _extractLastSavedAt(localSnapshot);
    final cloudTs = _extractLastSavedAt(cloud.payload.snapshot) ?? cloud.meta.uploadedAt;
    if (localTs != null && cloudTs != null) {
      if (localTs.isAfter(cloudTs)) {
        return CloudConflictResolution.keepLocalCreateNewRevision;
      } else if (cloudTs.isAfter(localTs)) {
        return CloudConflictResolution.importCloudReplaceLocal;
      }
    }
    return CloudConflictResolution.undecided;
  }

  DateTime? _extractLastSavedAt(Map<String, dynamic> snapshot) {
    try {
      final meta = (snapshot['meta'] as Map?)?.cast<String, dynamic>();
      final ts = (meta?['timestamps'] as Map?)?.cast<String, dynamic>();
      final v = ts?['lastSavedAt'] as String?;
      if (v == null) return null;
      return DateTime.tryParse(v);
    } catch (_) {
      return null;
    }
  }

  // --- Friends (optionnels, pass-through vers repository RLS) ---
  Future<void> addFriend({required String friendExternalId}) async {
    if (_friends == null) return; // optionnel
    await _friends!.addFriend(friendExternalId: friendExternalId);
  }

  Future<List<FriendEntry>> listFriends() async {
    if (_friends == null) return const <FriendEntry>[];
    return _friends!.listFriends();
  }
}

/// Stratégies de résolution de conflit (recommandations non contraignantes)
enum CloudConflictResolution {
  /// Conserver le local et publier une nouvelle révision cloud (append-only)
  keepLocalCreateNewRevision,
  /// Importer la révision cloud choisie par l’utilisateur (remplace l’état local)
  importCloudReplaceLocal,
  /// Impossible de trancher automatiquement; demander à l’utilisateur
  undecided,
}
