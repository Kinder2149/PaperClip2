import '../common/games_services_facade.dart';
import 'play_games_identity_adapter.dart';

class GamesServicesPlayGamesIdentityAdapter implements PlayGamesIdentityAdapter {
  final GamesServicesFacade _facade;

  GamesServicesPlayGamesIdentityAdapter({GamesServicesFacade? facade})
      : _facade = facade ?? GamesServicesFacadeImpl();

  @override
  Future<bool> signIn() async {
    try {
      await _facade.signIn();
      return await _facade.isSignedIn();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    // Non supporté par le plugin; no-op.
    return;
  }

  @override
  Future<bool> isSignedIn() async {
    try {
      return await _facade.isSignedIn();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> getPlayerId() async {
    try {
      final signedIn = await _facade.isSignedIn();
      if (!signedIn) return null;
      return await _facade.getPlayerId();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getDisplayName() async {
    try {
      final signedIn = await _facade.isSignedIn();
      if (!signedIn) return null;
      return await _facade.getPlayerName();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getAvatarUrl() async {
    try {
      final signedIn = await _facade.isSignedIn();
      if (!signedIn) return null;
      return await _facade.getPlayerIconImage();
    } catch (_) {
      return null;
    }
  }
}
