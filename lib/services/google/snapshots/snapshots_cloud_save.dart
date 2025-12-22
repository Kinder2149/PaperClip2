import 'dart:convert';
import 'dart:io';

import '../google_bootstrap.dart';
import '../identity/google_identity_service.dart';
import 'game_cloud_save_adapter.dart';
import 'local_cloud_save_adapter.dart';
import 'gpg_snapshot_cloud_save_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SnapshotsCloudSave {
  final GameCloudSaveAdapter _adapter;
  final GoogleIdentityService _identity;

  static const String slotName = 'paperclip2_main_save';

  SnapshotsCloudSave({required GameCloudSaveAdapter adapter, required GoogleIdentityService identity})
      : _adapter = adapter,
        _identity = identity;

  Future<void> saveJson(Map<String, dynamic> json) async {
    // Compress JSON to bytes (gzip)
    final data = utf8.encode(jsonEncode(json));
    final compressed = gzip.encode(data);
    if (kDebugMode) {
      print('[SnapshotsCloudSave] saveJson: slot=$slotName bytes=${compressed.length}');
    }
    await _adapter.saveCompressed(slot: slotName, compressedJson: compressed);
  }

  Future<Map<String, dynamic>?> loadJson() async {
    final bytes = await _adapter.loadCompressed(slot: slotName);
    if (bytes == null) return null;
    try {
      final decompressed = gzip.decode(bytes);
      final txt = utf8.decode(decompressed);
      final obj = jsonDecode(txt) as Map<String, dynamic>;
      return obj;
    } catch (_) {
      return null;
    }
  }

  /// Supprime le slot cloud (si l'adapter actif est GPG). No-op sinon.
  Future<void> deleteCloudSlot() async {
    if (_adapter is GpgSnapshotCloudSaveAdapter) {
      final gpg = _adapter as GpgSnapshotCloudSaveAdapter;
      await gpg.deleteSlot(slot: slotName);
    }
  }
}

/// Crée le service Snapshots en sélectionnant l'adapter via feature flag.
SnapshotsCloudSave createSnapshotsCloudSave({required GoogleIdentityService identity}) {
  final enableGpg = (dotenv.env['FEATURE_CLOUD_SAVES_GPG'] ?? 'false').toLowerCase() == 'true';
  GameCloudSaveAdapter adapter;
  if (enableGpg) {
    // Sélection GPG sous flag; l'adapter peut encore lever UnimplementedError.
    // Le flux appelant est encapsulé dans des try/catch pour éviter toute régression UX.
    try {
      adapter = GpgSnapshotCloudSaveAdapter();
    } catch (_) {
      if (kDebugMode) {
        print('[SnapshotsCloudSave] GPG adapter init failed, fallback to LocalCloudSaveAdapter');
      }
      adapter = LocalCloudSaveAdapter();
    }
  } else {
    adapter = LocalCloudSaveAdapter();
  }
  return SnapshotsCloudSave(adapter: adapter, identity: identity);
}
