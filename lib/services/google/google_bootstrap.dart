import 'google_ids.dart';
import 'achievements/achievements_service.dart';
import 'achievements/achievements_adapter.dart';
import 'achievements/games_services_achievements_adapter.dart';
import 'achievements/noop_achievements_adapter.dart';
import 'identity/google_identity_service.dart';
import 'identity/play_games_identity_adapter.dart';
import 'identity/games_services_play_games_identity_adapter.dart';
import 'identity/noop_play_games_identity_adapter.dart';
import 'leaderboards/leaderboards_service.dart';
import 'leaderboards/leaderboards_adapter.dart';
import 'leaderboards/games_services_leaderboards_adapter.dart';
import 'leaderboards/noop_leaderboards_adapter.dart';

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
  // Identity adapter
  final PlayGamesIdentityAdapter identityAdapter = enableOnAndroid
      ? GamesServicesPlayGamesIdentityAdapter()
      : NoopPlayGamesIdentityAdapter();

  // Achievements adapter
  final AchievementsAdapter achievementsAdapter = enableOnAndroid
      ? GamesServicesAchievementsAdapter(
          androidAchievementIds: GoogleIds.achievementsAndroid,
        )
      : NoopAchievementsAdapter();

  // Leaderboards adapter
  final LeaderboardsAdapter leaderboardsAdapter = enableOnAndroid
      ? GamesServicesLeaderboardsAdapter(
          androidLeaderboardIds: GoogleIds.leaderboardsAndroid,
        )
      : NoopLeaderboardsAdapter();

  return GoogleServicesBundle(
    identity: GoogleIdentityService(adapter: identityAdapter),
    achievements: AchievementsService(adapter: achievementsAdapter),
    leaderboards: LeaderboardsService(adapter: leaderboardsAdapter),
  );
}
