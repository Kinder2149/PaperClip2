enum GameMode {
  NORMAL,
  HARD,
  ENDLESS
}

enum MarketEvent {
  PRICE_WAR,
  DEMAND_SPIKE,
  MARKET_CRASH,
  QUALITY_CONCERNS
}

enum EventType {
  CRISIS_MODE,
  RESOURCE_DEPLETION,
  SPECIAL_ACHIEVEMENT,
  XP_BOOST
}

enum EventImportance {
  LOW,
  MEDIUM,
  HIGH,
  CRITICAL
}

enum MissionType {
  PRODUCE_PAPERCLIPS,
  EARN_MONEY,
  REACH_LEVEL,
  PURCHASE_UPGRADES
}

enum UnlockableFeature {
  MANUAL_PRODUCTION,
  MARKET_SALES,
  AUTOCLIPPERS,
  METAL_PURCHASE,
  MARKET_SCREEN,
  UPGRADES
}

enum CompetitiveAchievement {
  SCORE_100K,
  SCORE_50K,
  SCORE_10K,
  SPEED_RUN,
  EFFICIENCY_MASTER
}

enum NotificationPriority {
  LOW,
  MEDIUM,
  HIGH,
  CRITICAL
}

class NotificationEvent {
  final String title;
  final String description;
  final String? detailedDescription;
  final IconData icon;
  final NotificationPriority priority;
  final DateTime timestamp;

  NotificationEvent({
    required this.title,
    required this.description,
    this.detailedDescription,
    required this.icon,
    this.priority = NotificationPriority.MEDIUM,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
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

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'score': score,
      'rank': rank,
      'timestamp': timestamp.toIso8601String(),
    };
  }

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

class SaveGameInfo {
  final String name;
  final DateTime lastSaveTime;
  final GameMode gameMode;
  final bool isSyncedWithCloud;
  final String? cloudId;

  SaveGameInfo({
    required this.name,
    required this.lastSaveTime,
    required this.gameMode,
    this.isSyncedWithCloud = false,
    this.cloudId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lastSaveTime': lastSaveTime.toIso8601String(),
      'gameMode': gameMode.index,
      'isSyncedWithCloud': isSyncedWithCloud,
      'cloudId': cloudId,
    };
  }

  factory SaveGameInfo.fromJson(Map<String, dynamic> json) {
    return SaveGameInfo(
      name: json['name'] as String,
      lastSaveTime: DateTime.parse(json['lastSaveTime'] as String),
      gameMode: GameMode.values[json['gameMode'] as int],
      isSyncedWithCloud: json['isSyncedWithCloud'] as bool? ?? false,
      cloudId: json['cloudId'] as String?,
    );
  }
} 