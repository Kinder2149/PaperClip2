class AppConfig {
  static const String appName = 'Paperclip Game';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // Configuration des sauvegardes
  static const String saveDirectory = 'saves';
  static const String backupDirectory = 'backups';
  
  // Configuration des notifications
  static const String notificationChannelId = 'paperclip_game_notifications';
  static const String notificationChannelName = 'Paperclip Game Notifications';
  static const String notificationChannelDescription = 'Notifications du jeu Paperclip';
  
  // Configuration des succès
  static const String achievementPrefix = 'achievement_';
  static const String achievementUnlockedMessage = 'Succès débloqué !';
  
  // Configuration des classements
  static const String leaderboardPrefix = 'leaderboard_';
  static const int maxLeaderboardEntries = 100;
  
  // Configuration des événements
  static const String eventPrefix = 'event_';
  static const Duration eventCheckInterval = Duration(minutes: 5);
  
  // Configuration des mises à jour
  static const String updateCheckUrl = 'https://api.example.com/updates';
  static const Duration updateCheckInterval = Duration(hours: 24);
  
  // Configuration des analytics
  static const bool enableAnalytics = true;
  static const Duration analyticsFlushInterval = Duration(minutes: 30);
  
  // Configuration du mode debug
  static const bool enableDebugMode = false;
  static const bool enableCrashlytics = true;
  static const bool enableAnalyticsDebug = false;
  
  // Configuration des tests
  static const bool isTestMode = false;
  static const String testSaveDirectory = 'test_saves';
} 