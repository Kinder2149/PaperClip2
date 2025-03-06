import '../entities/game_save.dart';

abstract class SaveRepository {
  Future<List<GameSave>> getAvailableSaves();
  Future<GameSave?> getSave(String id);
  Future<void> createSave(GameSave save);
  Future<void> updateSave(GameSave save);
  Future<void> deleteSave(String id);
  Future<void> saveCurrentGame(String name);
  Future<void> loadGame(String id);
} 