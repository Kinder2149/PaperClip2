import 'achievements_adapter.dart';

/// Implémentation No-Op de l'adapter Success Google.
/// N'envoie rien et se déclare toujours non prêt.
class NoopAchievementsAdapter implements AchievementsAdapter {
  @override
  Future<bool> isReady() async => false;

  @override
  Future<void> unlock(String achievementKey) async {
    // No-op
  }

  @override
  Future<void> increment(String achievementKey, int bySteps) async {
    // No-op
  }
}
