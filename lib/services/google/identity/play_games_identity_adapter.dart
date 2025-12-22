abstract class PlayGamesIdentityAdapter {
  /// Lance un sign-in Google Play Games. Retourne true si la session est valide.
  Future<bool> signIn();

  /// Déconnecte la session côté Google Play Games (si supporté).
  Future<void> signOut();

  /// Indique si une session Google Play Games est active côté adapter.
  Future<bool> isSignedIn();

  /// Identifiant joueur Play Games (peut être null si non connecté).
  Future<String?> getPlayerId();

  /// Métadonnées facultatives (non utilisées au core pour l'étape 1)
  Future<String?> getDisplayName() => Future.value(null);
  Future<String?> getAvatarUrl() => Future.value(null);
}
