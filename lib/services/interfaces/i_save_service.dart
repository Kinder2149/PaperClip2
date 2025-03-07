abstract class ISaveService {
  Future<void> initialize();
  Future<void> saveGame(String slot, Map<String, dynamic> data);
  Future<Map<String, dynamic>> loadGame(String slot);
  Future<void> deleteGame(String slot);
  Future<List<String>> listSaveSlots();
  Future<void> syncWithCloud();
  Future<void> backupGame(String slot);
  Future<void> restoreFromBackup(String slot);
} 