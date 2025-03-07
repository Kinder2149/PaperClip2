abstract class ILeaderboardService {
  Future<void> initialize();
  Future<void> submitScore(String leaderboardId, int score);
  Future<void> showLeaderboard(String leaderboardId);
  Future<List<Map<String, dynamic>>> getTopScores(String leaderboardId, int limit);
  Future<Map<String, dynamic>?> getPlayerScore(String leaderboardId);
  Future<void> syncLeaderboards();
} 