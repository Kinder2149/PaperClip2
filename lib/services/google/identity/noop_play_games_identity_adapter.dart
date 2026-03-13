import 'play_games_identity_adapter.dart';

/// Implémentation No-Op de l'adapter Play Games.
/// Ne réalise aucune authentification réelle et reste toujours non connecté.
class NoopPlayGamesIdentityAdapter implements PlayGamesIdentityAdapter {
  @override
  Future<String?> getPlayerId() async => null;

  @override
  Future<bool> isSignedIn() async => false;

  @override
  Future<bool> signIn() async => false;

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> getDisplayName() async => null;

  @override
  Future<String?> getAvatarUrl() async => null;
}
