import 'package:games_services/games_services.dart';

/// Facade minimale autour du plugin games_services pour permettre le test unitaire.
/// - En production: utiliser [GamesServicesFacadeImpl].
/// - En test: fournir un fake implémentant cette interface.
abstract class GamesServicesFacade {
  Future<bool> isSignedIn();
  Future<void> signIn();
  Future<String?> getPlayerId();
  Future<String?> getPlayerName();
  Future<String?> getPlayerIconImage();
  Future<void> unlockAchievement({required String androidId});
  Future<void> incrementAchievement({required String androidId, required int bySteps});
  Future<void> submitScore({required String androidLeaderboardId, required int value});
}

class GamesServicesFacadeImpl implements GamesServicesFacade {
  @override
  Future<bool> isSignedIn() => GameAuth.isSignedIn;

  @override
  Future<void> signIn() => GameAuth.signIn();

  @override
  Future<String?> getPlayerId() => Player.getPlayerID();

  @override
  Future<String?> getPlayerName() => Player.getPlayerName();

  @override
  Future<String?> getPlayerIconImage() => Player.getPlayerIconImage();

  @override
  Future<void> unlockAchievement({required String androidId}) =>
      Achievements.unlock(achievement: Achievement(androidID: androidId, percentComplete: 100));

  @override
  Future<void> incrementAchievement({required String androidId, required int bySteps}) async {
    try {
      // API games_services >=4.1: increment() n'accepte plus 'steps'.
      // On appelle increment() 'bySteps' fois (bornage simple pour éviter les rafales énormes).
      final capped = bySteps.clamp(1, 50);
      for (var i = 0; i < capped; i++) {
        await Achievements.increment(achievement: Achievement(androidID: androidId));
      }
    } catch (_) {
      // ignore errors
    }
  }

  @override
  Future<void> submitScore({required String androidLeaderboardId, required int value}) =>
      Leaderboards.submitScore(score: Score(androidLeaderboardID: androidLeaderboardId, value: value));
}
