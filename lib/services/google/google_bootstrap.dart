import 'google_services_wiring.dart';
import 'google_ids.dart';
import 'achievements/achievements_service.dart';
import 'identity/google_identity_service.dart';
import 'leaderboards/leaderboards_service.dart';

class GoogleServicesBundle {
  final GoogleIdentityService identity;
  final AchievementsService achievements;
  final LeaderboardsService leaderboards;

  const GoogleServicesBundle({
    required this.identity,
    required this.achievements,
    required this.leaderboards,
  });
}

GoogleServicesBundle createGoogleServices({
  bool enableOnAndroid = true,
  bool? forceDebugEnable,
}) {
  final factory = GoogleAdaptersFactory();

  final identityAdapter = factory.buildIdentityAdapter(
    enableOnAndroid: enableOnAndroid,
    forceDebugEnable: forceDebugEnable,
  );

  final achievementsAdapter = factory.buildAchievementsAdapter(
    enableOnAndroid: enableOnAndroid,
    androidAchievementIds: GoogleIds.achievementsAndroid,
    forceDebugEnable: forceDebugEnable,
  );

  final leaderboardsAdapter = factory.buildLeaderboardsAdapter(
    enableOnAndroid: enableOnAndroid,
    androidLeaderboardIds: GoogleIds.leaderboardsAndroid,
    forceDebugEnable: forceDebugEnable,
  );

  return GoogleServicesBundle(
    identity: GoogleIdentityService(adapter: identityAdapter),
    achievements: AchievementsService(adapter: achievementsAdapter),
    leaderboards: LeaderboardsService(adapter: leaderboardsAdapter),
  );
}
