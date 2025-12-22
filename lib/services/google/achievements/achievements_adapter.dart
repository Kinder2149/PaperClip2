/// Port d'adaptation vers Google Play Games Achievements.
/// Aucune logique métier ici: un simple récepteur de clés de succès.
abstract class AchievementsAdapter {
  /// Indique si la couche sous-jacente est prête à publier (ex: signé + services dispos).
  Future<bool> isReady();

  /// Débloque un succès par sa clé canoniquement définie côté client.
  /// Doit être idempotent côté adapter.
  Future<void> unlock(String achievementKey);
}
