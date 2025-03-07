abstract class IAchievementService {
  Future<void> initialize();
  Future<void> unlockAchievement(String id);
  Future<void> incrementAchievement(String id, int value);
  Future<void> showAchievements();
  Future<void> syncAchievements();
  Future<bool> isAchievementUnlocked(String id);
  Future<int> getAchievementProgress(String id);
  Future<void> resetAchievements();
} 