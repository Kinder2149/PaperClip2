import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'game_cloud_save_adapter.dart';

/// Adapter Google Play Games Saved Games (Snapshots) via MethodChannel Android.
///
/// Attention: nécessite l'implémentation native Android dans MainActivity.
class GpgSnapshotCloudSaveAdapter implements GameCloudSaveAdapter {
  static const String _tag = '[GpgSnapshotAdapter]';
  static const MethodChannel _ch = MethodChannel('paperclip2/gpg_snapshots');

  Future<void> _ensureReady() async {
    // Ici, on pourrait vérifier une précondition si exposée côté natif.
    if (kDebugMode) {
      // ignore: avoid_print
      print('$_tag ensureReady');
    }
  }

  @override
  Future<List<int>?> loadCompressed({required String slot}) async {
    await _ensureReady();
    try {
      final res = await _ch.invokeMethod<Uint8List>('loadCompressed', {
        'slot': slot,
      });
      // Android retourne Uint8List; on convertit en List<int> pour rester conforme à l'interface
      return res?.toList();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('$_tag loadCompressed error: ${e.code} ${e.message}');
      }
      return null; // L'appelant gère le fallback/local
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('$_tag loadCompressed unexpected error: $e');
      }
      return null;
    }
  }

  @override
  Future<void> saveCompressed({required String slot, required List<int> compressedJson}) async {
    await _ensureReady();
    try {
      await _ch.invokeMethod<void>('saveCompressed', {
        'slot': slot,
        'bytes': compressedJson,
      });
    } on PlatformException catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('$_tag saveCompressed error: ${e.code} ${e.message}');
      }
      rethrow; // L'appelant est encapsulé dans try/catch avec fallback
    }
  }

  /// Supprime le slot côté Google Play Games (s'il existe).
  /// Ne fait rien sur iOS/Web (MethodChannel Android uniquement).
  Future<void> deleteSlot({required String slot}) async {
    await _ensureReady();
    try {
      await _ch.invokeMethod<void>('deleteSlot', {
        'slot': slot,
      });
    } on PlatformException catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('$_tag deleteSlot error: ${e.code} ${e.message}');
      }
      rethrow;
    }
  }
}
