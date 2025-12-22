import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'game_cloud_save_adapter.dart';

class LocalCloudSaveAdapter implements GameCloudSaveAdapter {
  Future<File> _fileForSlot(String slot) async {
    final dir = await getApplicationDocumentsDirectory();
    final safe = slot.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    return File('${dir.path}/$safe.bin');
  }

  @override
  Future<List<int>?> loadCompressed({required String slot}) async {
    try {
      final f = await _fileForSlot(slot);
      if (!await f.exists()) return null;
      return await f.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveCompressed({required String slot, required List<int> compressedJson}) async {
    final f = await _fileForSlot(slot);
    await f.writeAsBytes(compressedJson, flush: true);
  }
}
