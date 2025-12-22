import 'leaderboards_adapter.dart';

/// Implémentation No-Op: couche leaderboards désactivée.
class NoopLeaderboardsAdapter implements LeaderboardsAdapter {
  @override
  Future<bool> isReady() async => false;

  @override
  Future<void> submitScore(String leaderboardKey, int score) async {
    // no-op
  }
}
