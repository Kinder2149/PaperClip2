import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kReleaseMode, kIsWeb;

import 'achievements/achievements_adapter.dart';
import 'achievements/games_services_achievements_adapter.dart';
import 'achievements/noop_achievements_adapter.dart';
import 'identity/games_services_play_games_identity_adapter.dart';
import 'identity/noop_play_games_identity_adapter.dart';
import 'identity/play_games_identity_adapter.dart';
import 'leaderboards/games_services_leaderboards_adapter.dart';
import 'leaderboards/leaderboards_adapter.dart';
import 'leaderboards/noop_leaderboards_adapter.dart';

/// Wiring minimal des adapters Google selon plateforme et flags.
/// - Ne modifie pas les services métiers.
/// - Ne déclenche aucune sync.
/// - Les IDs Play Console sont fournis par l'application via paramètres.
class GoogleAdaptersFactory {
  const GoogleAdaptersFactory();

  PlayGamesIdentityAdapter buildIdentityAdapter({
    required bool enableOnAndroid,
    bool? forceDebugEnable,
  }) {
    final enabled = _isEnabledOnThisPlatform(enableOnAndroid: enableOnAndroid, forceDebugEnable: forceDebugEnable);
    if (enabled) {
      return GamesServicesPlayGamesIdentityAdapter();
    }
    return NoopPlayGamesIdentityAdapter();
  }

  AchievementsAdapter buildAchievementsAdapter({
    required bool enableOnAndroid,
    required Map<String, String> androidAchievementIds,
    bool? forceDebugEnable,
  }) {
    final enabled = _isEnabledOnThisPlatform(enableOnAndroid: enableOnAndroid, forceDebugEnable: forceDebugEnable);
    if (enabled) {
      return GamesServicesAchievementsAdapter(androidAchievementIds: androidAchievementIds);
    }
    return NoopAchievementsAdapter();
  }

  LeaderboardsAdapter buildLeaderboardsAdapter({
    required bool enableOnAndroid,
    required Map<String, String> androidLeaderboardIds,
    bool? forceDebugEnable,
  }) {
    final enabled = _isEnabledOnThisPlatform(enableOnAndroid: enableOnAndroid, forceDebugEnable: forceDebugEnable);
    if (enabled) {
      return GamesServicesLeaderboardsAdapter(androidLeaderboardIds: androidLeaderboardIds);
    }
    return NoopLeaderboardsAdapter();
  }

  bool _isEnabledOnThisPlatform({
    required bool enableOnAndroid,
    bool? forceDebugEnable,
  }) {
    if (kIsWeb) return false;
    if (!Platform.isAndroid) return false;
    // Autoriser en prod si enableOnAndroid=true. En debug, on peut forcer.
    if (kReleaseMode) return enableOnAndroid;
    if (forceDebugEnable == true) return true;
    return enableOnAndroid;
  }
}
