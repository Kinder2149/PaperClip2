abstract class GameRepository {
  Future<GameState> getGameState();
  Future<void> updateGameState(GameState gameState);
  Future<void> saveGame(String name, {bool syncToCloud = true});
  Future<void> loadGame(String name, {String? cloudId});
  Future<List<SaveGameInfo>> listSaves();
  Future<bool> deleteSave(String name);
  Future<bool> syncSavesToCloud();
  Future<void> startNewGame(String name, {GameMode mode = GameMode.INFINITE, bool syncToCloud = false});
  Future<void> updateTotalTimePlayedInSeconds(int seconds);
  Future<void> updateTotalPaperclipsProduced(int amount);
  Future<bool> enterCrisisMode();
  Future<void> toggleCrisisInterface();
  Future<int> calculateCompetitiveScore();
}