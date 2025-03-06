// lib/data/models/game_state_model.dart
import 'package:paperclip2/domain/entities/game_state_entity.dart';
import 'package:paperclip2/core/constants/enums.dart';
import 'player_model.dart';
import 'market_model.dart';
import 'level_system_model.dart';
import 'statistics_model.dart';

class GameStateModel {
  final PlayerModel player;
  final MarketModel market;
  final LevelSystemModel level;
  final StatisticsModel statistics;
  final int totalPaperclipsProduced;
  final int totalTimePlayedInSeconds;
  final bool isInCrisisMode;
  final GameMode gameMode;
  final String version;
  final DateTime timestamp;

  GameStateModel({
    required this.player,
    required this.market,
    required this.level,
    required this.statistics,
    required this.totalPaperclipsProduced,
    required this.totalTimePlayedInSeconds,
    required this.isInCrisisMode,
    required this.gameMode,
    required this.version,
    required this.timestamp,
  });

  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    return GameStateModel(
      player: PlayerModel.fromJson(json['playerManager'] ?? {}),
      market: MarketModel.fromJson(json['marketManager'] ?? {}),
      level: LevelSystemModel.fromJson(json['levelSystem'] ?? {}),
      statistics: StatisticsModel.fromJson(json['statistics'] ?? {}),
      totalPaperclipsProduced: (json['totalPaperclipsProduced'] as num?)?.toInt() ?? 0,
      totalTimePlayedInSeconds: (json['totalTimePlayedInSeconds'] as num?)?.toInt() ?? 0,
      isInCrisisMode: json['crisisMode']?['isInCrisisMode'] as bool? ?? false,
      gameMode: GameMode.values[json['gameMode'] as int? ?? 0],
      version: json['version'] as String? ?? '1.0.3',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'playerManager': player.toJson(),
    'marketManager': market.toJson(),
    'levelSystem': level.toJson(),
    'statistics': statistics.toJson(),
    'totalPaperclipsProduced': totalPaperclipsProduced,
    'totalTimePlayedInSeconds': totalTimePlayedInSeconds,
    'crisisMode': {
      'isInCrisisMode': isInCrisisMode,
    },
    'gameMode': gameMode.index,
    'version': version,
    'timestamp': timestamp.toIso8601String(),
  };

  GameStateEntity toEntity() {
    return GameStateEntity(
      player: player.toEntity(),
      market: market.toEntity(),
      level: level.toEntity(),
      statistics: statistics.toEntity(),
      totalPaperclipsProduced: totalPaperclipsProduced,
      totalTimePlayedInSeconds: totalTimePlayedInSeconds,
      isInCrisisMode: isInCrisisMode,
      gameMode: gameMode,
    );
  }

  static GameStateModel fromEntity(GameStateEntity entity) {
    return GameStateModel(
      player: PlayerModel.fromEntity(entity.player),
      market: MarketModel.fromEntity(entity.market),
      level: LevelSystemModel.fromEntity(entity.level),
      statistics: StatisticsModel.fromEntity(entity.statistics),
      totalPaperclipsProduced: entity.totalPaperclipsProduced,
      totalTimePlayedInSeconds: entity.totalTimePlayedInSeconds,
      isInCrisisMode: entity.isInCrisisMode,
      gameMode: entity.gameMode,
      version: '1.0.3', // Vous pouvez ajuster cette valeur
      timestamp: DateTime.now(),
    );
  }
}