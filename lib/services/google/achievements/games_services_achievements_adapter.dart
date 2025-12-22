import 'achievements_adapter.dart';
import '../common/games_services_facade.dart';

/// Adapter concret Google Play Games pour les succès.
/// - Traduction stricte: achievementKey (canonique client) -> ID Play Console (Android)
/// - Erreurs silencieuses: aucune exception propagée
class GamesServicesAchievementsAdapter implements AchievementsAdapter {
  final Map<String, String> _androidIds;
  final GamesServicesFacade _facade;

  GamesServicesAchievementsAdapter({
    required Map<String, String> androidAchievementIds,
    GamesServicesFacade? facade,
  })  : _androidIds = Map.unmodifiable(androidAchievementIds),
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
  Future<void> unlock(String achievementKey) async {
    try {
      final signedIn = await _facade.isSignedIn();
      if (!signedIn) return;
      final androidId = _androidIds[achievementKey];
      if (androidId == null || androidId.isEmpty) return; // clé non mappée -> no-op
      await _facade.unlockAchievement(androidId: androidId);
    } catch (_) {
      // erreurs silencieuses
    }
  }
}
