import 'leaderboards_adapter.dart';
import '../common/games_services_facade.dart';

/// Adapter concret Google Play Games pour les classements.
/// - Traduction stricte: leaderboardKey (canonique client) -> ID Play Console (Android)
/// - Erreurs silencieuses: aucune exception propagée
class GamesServicesLeaderboardsAdapter implements LeaderboardsAdapter {
  final Map<String, String> _androidIds;
  final GamesServicesFacade _facade;

  GamesServicesLeaderboardsAdapter({
    required Map<String, String> androidLeaderboardIds,
    GamesServicesFacade? facade,
  })  : _androidIds = Map.unmodifiable(androidLeaderboardIds),
        _facade = facade ?? GamesServicesFacadeImpl();

  @override
  Future<bool> isReady() async {
    try {
      return await _facade.isSignedIn();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> submitScore(String leaderboardKey, int score) async {
    try {
      final signedIn = await _facade.isSignedIn();
      if (!signedIn) return;
      final androidId = _androidIds[leaderboardKey];
      if (androidId == null || androidId.isEmpty) return; // clé non mappée -> no-op
      await _facade.submitScore(androidLeaderboardId: androidId, value: score);
    } catch (_) {
      // erreurs silencieuses
    }
  }
}
