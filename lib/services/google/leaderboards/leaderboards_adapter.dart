/// Port d'adaptation vers Google Play Games Leaderboards.
/// Aucune logique métier ici: soumission d'un score pour un leaderboard clé.
abstract class LeaderboardsAdapter {
  /// Indique si la couche sous-jacente est prête à publier (ex: signé + services dispos).
  Future<bool> isReady();

  /// Soumet un score entier pour une clé de leaderboard.
  /// Idempotence/écrasement gérés côté service; l'adapter ne doit pas recalculer.
  Future<void> submitScore(String leaderboardKey, int score);
}
