abstract class GameNotificationPort {
  void showPriceExcessiveWarning({
    required String title,
    required String description,
    required String? detailedDescription,
  });

  void showUnlockNotification(String message);

  void showLeaderboardUnavailable(String message);
}

abstract class GameNavigationPort {
  void showCompetitiveResult(CompetitiveResultData data);
}

abstract class GameUiPort implements GameNotificationPort, GameNavigationPort {}

class CompetitiveResultData {
  final int score;
  final int paperclips;
  final double money;
  final Duration playTime;
  final int level;
  final double efficiency;

  const CompetitiveResultData({
    required this.score,
    required this.paperclips,
    required this.money,
    required this.playTime,
    required this.level,
    required this.efficiency,
  });
}
