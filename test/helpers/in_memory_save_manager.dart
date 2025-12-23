import 'package:paperclip2/models/save_game.dart' as model;
import 'package:paperclip2/models/save_metadata.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';

class InMemorySaveGameManager implements LocalSaveGameManager {
  final Map<String, model.SaveGame> _saves = <String, model.SaveGame>{};
  final Map<String, SaveMetadata> _metas = <String, SaveMetadata>{};
  String? _activeSaveId;

  @override
  String? get activeSaveId => _activeSaveId;
  @override
  set activeSaveId(String? id) => _activeSaveId = id;

  @override
  Future<List<SaveMetadata>> listSaves() async {
    final list = _metas.values.toList();
    list.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return list;
  }

  @override
  Future<model.SaveGame?> loadSave(String saveId) async => _saves[saveId];

  @override
  Future<bool> saveGame(model.SaveGame save) async {
    _saves[save.id] = save;
    final now = DateTime.now();
    final existing = _metas[save.id];
    _metas[save.id] = SaveMetadata(
      id: save.id,
      name: save.name,
      creationDate: existing?.creationDate ?? now,
      lastModified: now,
      version: save.version,
      gameMode: save.gameMode,
      isRestored: save.isRestored ?? false,
    );
    _activeSaveId ??= save.id;
    return true;
  }

  @override
  Future<bool> deleteSave(String saveId) async {
    _saves.remove(saveId);
    _metas.remove(saveId);
    if (_activeSaveId == saveId) _activeSaveId = null;
    return true;
  }

  @override
  Future<bool> updateSaveMetadata(String saveId, SaveMetadata metadata) async {
    _metas[saveId] = metadata;
    return true;
  }

  @override
  Future<SaveMetadata?> getSaveMetadata(String saveId) async => _metas[saveId];

  @override
  String compressData(String data) => data;
  @override
  String decompressData(String compressed) => compressed;

  // Additional required interface methods (stubbed for tests)
  @override
  Future<Map<String, dynamic>> cleanupOrphanedSaves() async => <String, dynamic>{};
  @override
  Future<model.SaveGame> createNewSave({
    String? name,
    GameMode gameMode = GameMode.INFINITE,
    Map<String, dynamic>? initialData,
  }) async {
    final save = model.SaveGame(
      id: (name ?? 'new-save'),
      name: name ?? 'new-save',
      lastSaveTime: DateTime.now(),
      gameData: initialData ?? const {},
      version: 'test',
      gameMode: gameMode,
    );
    await saveGame(save);
    return save;
  }
  @override
  Future<void> disableAutoSave() async {}
  @override
  Future<model.SaveGame?> duplicateSave(String sourceId, {String? newName}) async => null;
  @override
  Future<void> enableAutoSave({
    required Duration interval,
    required String saveId,
  }) async {}
  @override
  Future<bool> exportSave(String saveId, String path) async => false;
  @override
  Future<Map<String, dynamic>> forceCleanupOrphanedSaves() async => <String, dynamic>{};
  @override
  Future<model.SaveGame?> importSave(dynamic sourceData, {String? newName, bool overwriteIfExists = false}) async => null;
  @override
  Future<bool> quickValidate(String saveId) async => _metas.containsKey(saveId);
  @override
  Future<void> reloadMetadataCache() async {}
  @override
  Future<bool> saveExists(String saveId) async => _metas.containsKey(saveId);

  // Helpers for tests
  Future<void> setMetadata(String id, SaveMetadata meta) async { _metas[id] = meta; }
}
