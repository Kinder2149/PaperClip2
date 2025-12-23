// lib/services/cloud/snapshots_cloud_persistence_port.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../google/snapshots/game_cloud_save_adapter.dart';
import '../google/snapshots/gpg_snapshot_cloud_save_adapter.dart';
import '../google/snapshots/local_cloud_save_adapter.dart';
import 'cloud_persistence_port.dart';

/// Implémentation CloudPersistencePort basée sur GameCloudSaveAdapter (GPG/Local)
/// avec un slot par partieId. Sert de POC local/offline sans backend.
class SnapshotsCloudPersistencePort implements CloudPersistencePort {
  final GameCloudSaveAdapter _adapter;

  SnapshotsCloudPersistencePort({GameCloudSaveAdapter? adapter})
      : _adapter = adapter ?? _defaultAdapter();

  static GameCloudSaveAdapter _defaultAdapter() {
    try {
      // Essaie l'adapter GPG; si indisponible (plateforme/impl), fallback local.
      return GpgSnapshotCloudSaveAdapter();
    } catch (_) {
      if (kDebugMode) {
        print('[SnapshotsCloudPersistencePort] Fallback to LocalCloudSaveAdapter');
      }
      return LocalCloudSaveAdapter();
    }
  }

  String _slotFor(String partieId) => 'paperclip2_partie_${_sanitize(partieId)}.bin';

  static String _sanitize(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');

  // Métadonnées locales pour fournir un status minimal (POC)
  static final Map<String, _CloudMeta> _metaById = <String, _CloudMeta>{};

  @override
  Future<void> pushById({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    // Construire le payload compressé (JSON gzip)
    final body = jsonEncode({
      'snapshot': snapshot,
      'metadata': metadata,
    });
    final bytes = utf8.encode(body);
    final compressed = gzip.encode(bytes);

    final slot = _slotFor(partieId);
    await _adapter.saveCompressed(slot: slot, compressedJson: compressed);

    final prev = _metaById[partieId];
    _metaById[partieId] = _CloudMeta(
      remoteVersion: (prev?.remoteVersion ?? 0) + 1,
      lastPushAt: DateTime.now(),
      lastPullAt: prev?.lastPullAt,
      playerId: (metadata['playerId'] as String?)?.trim(),
    );
  }

  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async {
    final slot = _slotFor(partieId);
    final data = await _adapter.loadCompressed(slot: slot);
    if (data == null) return null;
    try {
      final decompressed = gzip.decode(data);
      final text = utf8.decode(decompressed);
      final obj = jsonDecode(text);
      if (obj is Map<String, dynamic>) {
        final prev = _metaById[partieId];
        _metaById[partieId] = _CloudMeta(
          remoteVersion: prev?.remoteVersion ?? 1,
          lastPushAt: prev?.lastPushAt,
          lastPullAt: DateTime.now(),
          playerId: prev?.playerId ?? ((obj['metadata'] is Map && (obj['metadata'] as Map)['playerId'] is String) ? (obj['metadata'] as Map)['playerId'] as String : null),
        );
        return obj;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('[SnapshotsCloudPersistencePort] pull decode error: $e');
      }
      return null;
    }
  }

  @override
  Future<CloudStatus> statusById({required String partieId}) async {
    final meta = _metaById[partieId];
    // Heuristique POC: unknown si aucune op; ahead_remote si push > pull; in_sync si pull >= push
    String state = 'unknown';
    if (meta != null) {
      final lp = meta.lastPushAt;
      final lr = meta.lastPullAt;
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
      playerId: meta?.playerId,
    );
  }

  @override
  Future<List<CloudIndexEntry>> listParties() async {
    // Limitation POC: nous ne pouvons pas énumérer les slots via l'adapter.
    // On retourne les entrées connues via _metaById (celles qui ont subi push/pull).
    final List<CloudIndexEntry> out = [];
    for (final entry in _metaById.entries) {
      final pid = entry.key;
      final meta = entry.value;
      String? name;
      String? gameVersion;
      try {
        // Tenter de lire les métadonnées depuis le payload compressé si disponible
        final slot = _slotFor(pid);
        final data = await _adapter.loadCompressed(slot: slot);
        if (data != null) {
          final decompressed = gzip.decode(data);
          final text = utf8.decode(decompressed);
          final obj = jsonDecode(text);
          if (obj is Map<String, dynamic> && obj['metadata'] is Map) {
            final m = Map<String, dynamic>.from(obj['metadata'] as Map);
            name = m['name']?.toString();
            gameVersion = m['gameVersion']?.toString();
          }
        }
      } catch (_) {}
      out.add(CloudIndexEntry(
        partieId: pid,
        name: name,
        gameVersion: gameVersion,
        remoteVersion: meta.remoteVersion,
        lastPushAt: meta.lastPushAt,
        lastPullAt: meta.lastPullAt,
      ));
    }
    return out;
  }
}

class _CloudMeta {
  final int remoteVersion;
  final DateTime? lastPushAt;
  final DateTime? lastPullAt;
  final String? playerId;

  const _CloudMeta({
    required this.remoteVersion,
    this.lastPushAt,
    this.lastPullAt,
    this.playerId,
  });
}
