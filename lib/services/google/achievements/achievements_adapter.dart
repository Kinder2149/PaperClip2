/// Port d'adaptation vers Google Play Games Achievements.
/// Aucune logique métier ici: un simple récepteur de clés de succès.
abstract class AchievementsAdapter {
  /// Indique si la couche sous-jacente est prête à publier (ex: signé + services dispos).
  Future<bool> isReady();

  /// Débloque un succès par sa clé canoniquement définie côté client.
  /// Doit être idempotent côté adapter.
  Future<void> unlock(String achievementKey);

  /// Incrémente la progression d'un succès progressif (ex: Gain d'exp en 50 étapes).
  /// Les étapes sont cumulatives et bornées côté Play Console.
  Future<void> increment(String achievementKey, int bySteps);
}
