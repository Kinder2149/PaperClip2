class SyncQueueItem {
  final String id;
  final String type; // 'achievement' | 'leaderboard' | 'cloudsave'
  final DateTime createdAt;
  int attempts;
  DateTime? nextAttemptAt;
  final Map<String, dynamic> payload;

  SyncQueueItem({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.payload,
    this.attempts = 0,
    this.nextAttemptAt,
  });
}
