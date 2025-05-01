// lib/services/save/cloud_save_service.dart
import '../../services/cloud_save_manager.dart';
export '../../services/cloud_save_manager.dart';
import '../../services/save_manager.dart' show SaveGame, SaveGameInfo;
import '../../models/game_config.dart';

class CloudSaveService {
  final CloudSaveManager _cloudManager = CloudSaveManager();

  Future<bool> saveToCloud(SaveGame save) async {
    return await _cloudManager.saveToCloud(save);
  }

  Future<SaveGame?> loadFromCloud(String cloudId) async {
    return await _cloudManager.loadFromCloud(cloudId);
  }

  Future<List<SaveGameInfo>> getCloudSaves() async {
    return await _cloudManager.getCloudSaves();
  }

  Future<bool> syncSaves() async {
    return await _cloudManager.syncSaves();
  }
}