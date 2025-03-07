import '../../models/types/game_types.dart';

abstract class IAchievementService {
  Future<void> unlockAchievement(String id);
  Future<void> incrementAchievement(String id, int value);
  Future<void> showAchievements();
  Future<void> syncAchievements();
  Future<bool> isAchievementUnlocked(String id);
  Future<int> getAchievementProgress(String id);
  Future<void> resetAchievements();
} 