abstract class ILeaderboardService {
  Future<void> submitScore(String leaderboardId, int score);
  Future<void> showLeaderboard(String leaderboardId);
  Future<List<LeaderboardEntry>> getTopScores(String leaderboardId, int limit);
  Future<LeaderboardEntry?> getPlayerScore(String leaderboardId);
  Future<void> syncLeaderboards();
}

class LeaderboardEntry {
  final String playerId;
  final String playerName;
  final int score;
  final int rank;
  final DateTime timestamp;

  LeaderboardEntry({
    required this.playerId,
    required this.playerName,
    required this.score,
    required this.rank,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'playerName': playerName,
    'score': score,
    'rank': rank,
    'timestamp': timestamp.toIso8601String(),
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      score: json['score'] as int,
      rank: json['rank'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
} 