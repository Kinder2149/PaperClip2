import 'package:paperclip2/services/persistence/game_data_compat.dart';
import 'package:paperclip2/models/progression_system.dart';
import 'package:paperclip2/models/statistics_manager.dart';
import 'package:paperclip2/managers/player_manager.dart';
import 'package:paperclip2/managers/market_manager.dart';
import 'package:paperclip2/managers/resource_manager.dart';
import 'package:paperclip2/models/game_state_interfaces.dart';
import 'package:paperclip2/models/game_state.dart';
import 'game_snapshot.dart';

class GamePersistenceMapper {
  static Map<String, dynamic> prepareGameData({
    required PlayerManager playerManager,
    required MarketManager marketManager,
    required LevelSystem levelSystem,
    required MissionSystem missionSystem,
    required StatisticsManager statistics,
  }) {
    return {
      'playerManager': playerManager.toJson(),
      'marketManager': marketManager.toJson(),
      'levelSystem': levelSystem.toJson(),
      'missionSystem': missionSystem.toJson(),
      'statistics': statistics.toJson(),
    };
  }

  static void applyLoadedGameDataWithoutSnapshot({
    required PlayerManager playerManager,
    required ResourceManager resourceManager,
    required MarketManager marketManager,
    required LevelSystem levelSystem,
    required MissionSystem missionSystem,
    required StatisticsManager statistics,
    required Map<String, dynamic> gameData,
  }) {

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

  // CHANTIER-01 : Sérialisation snapshot v3 (entreprise unique)
  static GameSnapshot toSnapshotV3(GameState state) {
    return GameSnapshot(
      metadata: {
        'version': 3,
        'enterpriseId': state.enterpriseId,
        'enterpriseName': state.enterpriseName,
        'createdAt': state.enterpriseCreatedAt?.toUtc().toIso8601String(),
        'lastModified': DateTime.now().toUtc().toIso8601String(),
        // CHANTIER-02 : Ressources rares (stats complètes)
        'quantum': state.rareResources.quantum,
        'pointsInnovation': state.rareResources.pointsInnovation,
        'totalResets': state.rareResources.totalResets,
        'quantumLifetime': state.rareResources.quantumLifetime,
        'innovationPointsLifetime': state.rareResources.innovationPointsLifetime,
        'quantumSpent': state.rareResources.quantumSpent,
        'innovationPointsSpent': state.rareResources.innovationPointsSpent,
      },
      core: {
        'player': state.playerManager.toJson(),
        'levelSystem': state.levelSystem.toJson(),
        'missionSystem': state.missionSystem.toJson(),
        // CHANTIER-02 : Ressources rares
        'rareResources': state.rareResources.toJson(),
        'agents': _serializeAgents(state),
        'research': _serializeResearch(state),
      },
      market: state.marketManager.toJson(),
      production: state.productionManager.toJson(),
      stats: state.statistics.toJson(),
    );
  }

  static Map<String, dynamic> _serializeAgents(GameState state) {
    // CHANTIER-04 : Sérialiser l'état complet des agents
    return state.agents.toJson();
  }

  static Map<String, dynamic> _serializeResearch(GameState state) {
    // CHANTIER-03 : Sérialiser arbre de recherche complet
    return state.research.toJson();
  }

  static void fromSnapshotV3(GameState state, GameSnapshot snapshot) {
    final metadata = snapshot.metadata;
    final core = snapshot.core;
    
    // Charger identité entreprise
    if (metadata['enterpriseId'] != null) {
      state.setEnterpriseId(metadata['enterpriseId'] as String);
    }
    if (metadata['enterpriseName'] != null) {
      state.setEnterpriseName(metadata['enterpriseName'] as String);
    }
    
    // CHANTIER-02 : Charger ressources rares
    if (core['rareResources'] != null) {
      // Nouveau format : données complètes dans core
      state.rareResources.fromJson(core['rareResources'] as Map<String, dynamic>);
    } else {
      // Fallback pour anciens snapshots v3 (migration)
      if (metadata['quantum'] != null) {
        state.rareResources.addQuantum(metadata['quantum'] as int);
      }
      if (metadata['pointsInnovation'] != null) {
        state.rareResources.addPointsInnovation(metadata['pointsInnovation'] as int);
      }
    }
    
    // Charger core
    if (core['player'] != null) {
      state.playerManager.fromJson(core['player'] as Map<String, dynamic>);
    }
    if (core['levelSystem'] != null) {
      state.levelSystem.fromJson(core['levelSystem'] as Map<String, dynamic>);
    }
    if (core['missionSystem'] != null) {
      state.missionSystem.fromJson(core['missionSystem'] as Map<String, dynamic>);
    }
    
    // Charger market
    if (snapshot.market != null) {
      state.marketManager.fromJson(snapshot.market!);
    }
    
    // Charger production
    if (snapshot.production != null) {
      state.productionManager.fromJson(snapshot.production!);
    }
    
    // Charger stats
    if (snapshot.stats != null) {
      state.statistics.fromJson(snapshot.stats!);
    }
    
    // Agents et recherche (pour futurs chantiers)
    if (core['agents'] != null) {
      _deserializeAgents(state, core['agents'] as Map<String, dynamic>);
    }
    if (core['research'] != null) {
      _deserializeResearch(state, core['research'] as Map<String, dynamic>);
    }
  }

  static void _deserializeAgents(GameState state, Map<String, dynamic> data) {
    // CHANTIER-04 : Charger l'état complet des agents
    state.agents.fromJson(data);
  }

  static void _deserializeResearch(GameState state, Map<String, dynamic> data) {
    // CHANTIER-03 : Charger arbre de recherche
    state.research.fromJson(data);
  }
}
