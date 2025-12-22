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
    return CloudStatus(
      partieId: partieId,
      syncState: exists ? 'unknown' : 'unknown',
      remoteVersion: meta?.remoteVersion,
      lastPushAt: meta?.lastPushAt,
      lastPullAt: meta?.lastPullAt,
    );
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
