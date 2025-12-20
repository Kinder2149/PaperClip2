import 'package:paperclip2/services/persistence/game_data_compat.dart';
import 'package:paperclip2/models/progression_system.dart';
import 'package:paperclip2/models/statistics_manager.dart';
import 'package:paperclip2/managers/player_manager.dart';
import 'package:paperclip2/managers/market_manager.dart';
import 'package:paperclip2/managers/resource_manager.dart';
import 'package:paperclip2/models/game_state_interfaces.dart';
import 'package:paperclip2/constants/game_config.dart' show GameMode;

class GamePersistenceMapper {
  static Map<String, dynamic> prepareGameData({
    required PlayerManager playerManager,
    required MarketManager marketManager,
    required LevelSystem levelSystem,
    required MissionSystem missionSystem,
    required StatisticsManager statistics,
    required GameMode gameMode,
    DateTime? competitiveStartTime,
  }) {
    return {
      'playerManager': playerManager.toJson(),
      'marketManager': marketManager.toJson(),
      'levelSystem': levelSystem.toJson(),
      'missionSystem': missionSystem.toJson(),
      'statistics': statistics.toJson(),
      'gameMode': gameMode.index,
      if (competitiveStartTime != null)
        'competitiveStartTime': competitiveStartTime.toIso8601String(),
    };
  }

  static GameMode applyLoadedGameDataWithoutSnapshot({
    required PlayerManager playerManager,
    required ResourceManager resourceManager,
    required MarketManager marketManager,
    required LevelSystem levelSystem,
    required MissionSystem missionSystem,
    required StatisticsManager statistics,
    required Map<String, dynamic> gameData,
  }) {
    final mode = gameData.containsKey('gameMode')
        ? GameMode.values[gameData['gameMode'] as int]
        : GameMode.INFINITE;

    if (gameData.containsKey('playerManager')) {
      playerManager.fromJson(gameData['playerManager'] as Map<String, dynamic>);
    }

    if (gameData.containsKey('resourceManager')) {
      resourceManager.fromJson(gameData['resourceManager'] as Map<String, dynamic>);
    }

    if (gameData.containsKey('marketManager')) {
      marketManager.fromJson(gameData['marketManager'] as Map<String, dynamic>);
    }

    if (gameData.containsKey('levelSystem')) {
      levelSystem.fromJson(gameData['levelSystem'] as Map<String, dynamic>);
    }

    if (gameData.containsKey('missionSystem')) {
      missionSystem.fromJson(gameData['missionSystem'] as Map<String, dynamic>);
    }

    if (gameData.containsKey('statistics')) {
      statistics.fromJson(gameData['statistics'] as Map<String, dynamic>);
    }

    return mode;
  }

  static Future<void> finishLoadGameAfterSnapshot({
    required LevelSystem levelSystem,
    required StatisticsManager statistics,
    required Map<String, dynamic> gameData,
    void Function(Map<String, dynamic> crisisMode)? onCrisisMode,
  }) async {
    if (gameData.containsKey('progression')) {
      final progressionData = gameData['progression'] as Map<String, dynamic>;
      if (progressionData.containsKey('combos')) {
        final comboData = progressionData['combos'] as Map<String, dynamic>;
        if (levelSystem.comboSystem != null) {
          levelSystem.comboSystem!.currentCombo = (comboData['currentCombo'] as num).toInt();
          if (comboData.containsKey('comboMultiplier')) {
            levelSystem.comboSystem!.comboMultiplier = (comboData['comboMultiplier'] as num).toDouble();
          }
        }
      }
      if (progressionData.containsKey('dailyBonus') && levelSystem.dailyBonus != null) {
        final bonusData = progressionData['dailyBonus'] as Map<String, dynamic>;
        levelSystem.dailyBonus!.hasClaimedToday = bonusData['claimed'] as bool? ?? false;
        if (bonusData.containsKey('streakDays')) {
          levelSystem.dailyBonus!.streakDays = (bonusData['streakDays'] as num).toInt();
        }
        if (bonusData.containsKey('lastClaimDate')) {
          levelSystem.dailyBonus!.lastClaimDate = DateTime.tryParse(bonusData['lastClaimDate'] as String);
        }
      }
    }

    if (gameData.containsKey('totalPaperclipsProduced')) {
      statistics.setTotalPaperclipsProduced((gameData['totalPaperclipsProduced'] as num).toInt());
    }

    if (gameData.containsKey('totalTimePlayedInSeconds')) {
      final loadedTime = (gameData['totalTimePlayedInSeconds'] as num?)?.toInt();
      if (loadedTime != null) {
        statistics.setTotalGameTimeSec(loadedTime);
      } else {
        statistics.setTotalGameTimeSec(statistics.totalGameTimeSec);
      }
    }

    if (gameData.containsKey('crisisMode') && onCrisisMode != null) {
      final crisisModeData = gameData['crisisMode'] as Map<String, dynamic>;
      onCrisisMode(crisisModeData);
    }
  }

  static void loadGameData({
    required PlayerManager playerManager,
    required MarketManager marketManager,
    required LevelSystem levelSystem,
    required MissionSystem missionSystem,
    required StatisticsManager statistics,
    required Map<String, dynamic> gameData,
  }) {
    if (gameData['playerManager'] != null) {
      playerManager.fromJson(gameData['playerManager']);
    }
    if (gameData['marketManager'] != null) {
      marketManager.fromJson(gameData['marketManager']);
    }
    if (gameData['levelSystem'] != null) {
      levelSystem.fromJson(gameData['levelSystem']);
    }
    if (gameData['missionSystem'] != null) {
      missionSystem.fromJson(gameData['missionSystem']);
    }
    if (gameData['statistics'] != null) {
      statistics.fromJson(gameData['statistics']);
    }

    final loadedTime = (gameData['totalTimePlayedInSeconds'] as num?)?.toInt();
    if (loadedTime != null) {
      statistics.setTotalGameTimeSec(loadedTime);
    } else {
      statistics.setTotalGameTimeSec(statistics.totalGameTimeSec);
    }
    final loadedProduced = (gameData['totalPaperclipsProduced'] as num?)?.toInt();
    if (loadedProduced != null) {
      statistics.setTotalPaperclipsProduced(loadedProduced);
    }
  }
}
