// lib/services/cloud/local_cloud_persistence_port.dart

import 'dart:async';

import 'cloud_persistence_port.dart';

/// Implémentation locale (mock) de CloudPersistencePort.
/// Stocke les snapshots en mémoire de processus pour permettre de tester le flux UI/Orchestrateur
/// sans dépendance réseau.
class LocalCloudPersistencePort implements CloudPersistencePort {
  static final Map<String, Map<String, dynamic>> _snapshotsById = <String, Map<String, dynamic>>{};
  static final Map<String, _CloudMeta> _metaById = <String, _CloudMeta>{};

  @override
  Future<void> pushById({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    final prev = _metaById[partieId];
    final nextVersion = (prev?.remoteVersion ?? 0) + 1;
    _snapshotsById[partieId] = {
      'snapshot': snapshot,
      'metadata': metadata,
    };
    _metaById[partieId] = _CloudMeta(
      remoteVersion: nextVersion,
      lastPushAt: DateTime.now(),
      lastPullAt: prev?.lastPullAt,
    );
  }

  @override
  Future<Map<String, dynamic>?> pullById({
    required String partieId,
  }) async {
    final data = _snapshotsById[partieId];
    if (data == null) return null;
    final prev = _metaById[partieId];
    _metaById[partieId] = _CloudMeta(
      remoteVersion: prev?.remoteVersion ?? 1,
      lastPushAt: prev?.lastPushAt,
      lastPullAt: DateTime.now(),
    );
    return data;
  }

  @override
  Future<CloudStatus> statusById({
    required String partieId,
  }) async {
    final meta = _metaById[partieId];
    final exists = _snapshotsById.containsKey(partieId);
    // Heuristique locale testable:
    // - Pas de données: unknown
    // - Si une donnée existe:
    //   * ahead_remote si lastPushAt > lastPullAt (remote plus récent que le dernier pull local)
    //   * in_sync si lastPullAt != null et (lastPushAt == null ou lastPullAt >= lastPushAt)
    //   * sinon unknown
    String state = 'unknown';
    if (exists) {
      final lp = meta?.lastPushAt;
      final lr = meta?.lastPullAt;
      if (lp != null && (lr == null || lr.isBefore(lp))) {
        state = 'ahead_remote';
      } else if (lr != null && (lp == null || !lr.isBefore(lp))) {
        state = 'in_sync';
      }
    }
    return CloudStatus(
      partieId: partieId,
      syncState: state,
      remoteVersion: meta?.remoteVersion,
      lastPushAt: meta?.lastPushAt,
      lastPullAt: meta?.lastPullAt,
    );
  }

  @override
  Future<List<CloudIndexEntry>> listParties() async {
    final List<CloudIndexEntry> result = [];
    for (final entry in _snapshotsById.entries) {
      final pid = entry.key;
      final data = entry.value;
      final meta = _metaById[pid];
      String? name;
      String? gameVersion;
      int? remoteVersion = meta?.remoteVersion;
      DateTime? lastPushAt = meta?.lastPushAt;
      DateTime? lastPullAt = meta?.lastPullAt;
      try {
        if (data['metadata'] is Map) {
          final m = Map<String, dynamic>.from(data['metadata'] as Map);
          name = m['name']?.toString();
          gameVersion = m['gameVersion']?.toString();
        }
      } catch (_) {}
    
      result.add(CloudIndexEntry(
        partieId: pid,
        name: name,
        gameVersion: gameVersion,
        remoteVersion: remoteVersion,
        lastPushAt: lastPushAt,
        lastPullAt: lastPullAt,
      ));
    }
    return result;
  }

  @override
  Future<void> deleteById({required String partieId}) async {
    // Suppression locale en mémoire (POC): retirer snapshot et métadonnées
    _snapshotsById.remove(partieId);
    _metaById.remove(partieId);
  }
}

class _CloudMeta {
  final int remoteVersion;
  final DateTime? lastPushAt;
  final DateTime? lastPullAt;

  const _CloudMeta({
    required this.remoteVersion,
    this.lastPushAt,
    this.lastPullAt,
  });
}
