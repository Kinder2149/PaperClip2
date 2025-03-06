// lib/domain/entities/game_state_entity.dart

import '../../core/constants/game_constants.dart';
import '../../core/constants/enums.dart';
import 'player_entity.dart';
import 'market_entity.dart';
import 'level_system_entity.dart';
import 'statistics_entity.dart';

class GameStateEntity {
  final PlayerEntity player;
  final MarketEntity market;
  final LevelSystemEntity levelSystem;
  final StatisticsEntity statistics;
  final int totalPaperclipsProduced;
  final int totalTimePlayedInSeconds;
  final bool isInCrisisMode;
  final GameMode gameMode;

  GameStateEntity({
    required this.player,
    required this.market,
    required this.levelSystem,
    required this.statistics,
    required this.totalPaperclipsProduced,
    required this.totalTimePlayedInSeconds,
    required this.isInCrisisMode,
    required this.gameMode,
  });

  double get maintenanceCosts {
    return player.autoclippers * GameConstants.STORAGE_MAINTENANCE_RATE;
  }

  Duration get competitivePlayTime {
    if (gameMode != GameMode.COMPETITIVE) return Duration.zero;
    return Duration(seconds: totalTimePlayedInSeconds);
  }

  String get formattedPlayTime {
    int hours = totalTimePlayedInSeconds ~/ 3600;
    int minutes = (totalTimePlayedInSeconds % 3600) ~/ 60;
    int seconds = totalTimePlayedInSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  Map<String, bool> getVisibleScreenElements() {
    return {
      'metalStock': true,
      'paperclipStock': true,
      'manualProductionButton': true,
      'moneyDisplay': true,
      'market': levelSystem.level >= GameConstants.MARKET_UNLOCK_LEVEL,
      'marketPrice': levelSystem.level >= GameConstants.MARKET_UNLOCK_LEVEL,
      'sellButton': levelSystem.level >= GameConstants.MARKET_UNLOCK_LEVEL,
      'marketStats': levelSystem.level >= GameConstants.MARKET_UNLOCK_LEVEL,
      'metalPurchaseButton': levelSystem.level >= 1,
      'autoclippersSection': levelSystem.level >= 3,
      'upgradesSection': levelSystem.level >= GameConstants.UPGRADES_UNLOCK_LEVEL,
    };
  }

  GameStateEntity copyWith({
    PlayerEntity? player,
    MarketEntity? market,
    LevelSystemEntity? levelSystem,
    StatisticsEntity? statistics,
    int? totalPaperclipsProduced,
    int? totalTimePlayedInSeconds,
    bool? isInCrisisMode,
    GameMode? gameMode,
  }) {
    return GameStateEntity(
      player: player ?? this.player,
      market: market ?? this.market,
      levelSystem: levelSystem ?? this.levelSystem,
      statistics: statistics ?? this.statistics,
      totalPaperclipsProduced: totalPaperclipsProduced ?? this.totalPaperclipsProduced,
      totalTimePlayedInSeconds: totalTimePlayedInSeconds ?? this.totalTimePlayedInSeconds,
      isInCrisisMode: isInCrisisMode ?? this.isInCrisisMode,
      gameMode: gameMode ?? this.gameMode,
    );
  }
}