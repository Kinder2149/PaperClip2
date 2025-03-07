import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:games_services/games_services.dart';
import '../models/game_state.dart';
import '../models/progression_system.dart';
import 'cloud_save_manager.dart';
import 'package:games_services/games_services.dart' as gs;
import 'save_manager.dart' as sm;

enum CompetitiveAchievement {
  SCORE_10K,
  SCORE_50K,
  SCORE_100K,
  SPEED_RUN,
  EFFICIENCY_MASTER,
}

class GooglePlayerInfo {
  final String id;
  final String displayName;
  final String? iconImageUrl;

  GooglePlayerInfo({
    required this.id,
    required this.displayName,
    this.iconImageUrl,
  });
}

class LeaderboardInfo {
  final int currentScore;
  final int bestScore;
  final int? rank;
  final String leaderboardName;

  LeaderboardInfo({
    required this.currentScore,
    required this.bestScore,
    this.rank,
    required this.leaderboardName,
  });
}

class GamesServicesController {
  static final GamesServicesController _instance = GamesServicesController._internal();

  // IDs des classements
  static const String generalLeaderboardID = "CgkI-ICryvIBEAIQAg";
  static const String productionLeaderboardID = "CgkI-ICryvIBEAIQAw";
  static const String bankerLeaderboardID = "CgkI-ICryvIBEAIQBA";
  static const String _progressionAchievementId = 'CgkI-ICryvIBEAIQAQ';

  static const String _competitiveScore10kId = 'CgkI-ICryvIBEAIQBQ';
  static const String _competitiveScore50kId = 'CgkI-ICryvIBEAIQBg';
  static const String _competitiveScore100kId = 'CgkI-ICryvIBEAIQBw';
  static const String _competitiveSpeedRunId = 'CgkI-ICryvIBEAIQCA';
  static const String _competitiveEfficiencyId = 'CgkI-ICryvIBEAIQCQ';

  factory GamesServicesController() {
    return _instance;
  }

  GamesServicesController._internal();

  Future<bool> isSignedIn() async {
    try {
      return await GamesServices.isSignedIn;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la connexion: $e');
      return false;
    }
  }

  Future<void> signIn() async {
    try {
      await GamesServices.signIn();
    } catch (e, stack) {
      debugPrint('Erreur lors de la connexion: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<void> showLeaderboard({required String leaderboardID}) async {
    try {
      await GamesServices.showLeaderboards(
        leaderboardID: leaderboardID,
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'affichage du classement: $e');
    }
  }

  Future<void> submitScore({
    required String leaderboardID,
    required int score,
  }) async {
    try {
      await GamesServices.submitScore(
        score: score,
        leaderboardID: leaderboardID,
      );
    } catch (e) {
      debugPrint('Erreur lors de la soumission du score: $e');
    }
  }

  Future<void> unlockAchievement(String achievementID) async {
    try {
      await GamesServices.unlock(
        achievementID: achievementID,
      );
    } catch (e) {
      debugPrint('Erreur lors du déblocage de l\'achievement: $e');
    }
  }

  Future<void> incrementAchievement(String achievementID, int steps) async {
    try {
      await GamesServices.increment(
        achievementID: achievementID,
        steps: steps,
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'incrémentation de l\'achievement: $e');
    }
  }

  Future<void> showAchievements() async {
    try {
      await GamesServices.showAchievements();
    } catch (e) {
      debugPrint('Erreur lors de l\'affichage des achievements: $e');
    }
  }

  Future<void> showBankerLeaderboard() async {
    try {
      await showLeaderboard(leaderboardID: bankerLeaderboardID);
    } catch (e) {
      debugPrint('Erreur lors de l\'affichage du classement banquier: $e');
    }
  }

  Future<void> updateCompetitiveAchievements(GameState gameState) async {
    if (gameState.gameMode != GameMode.COMPETITIVE) return;

    try {
      final paperclips = gameState.playerManager.paperclips;
      final playTime = gameState.competitivePlayTime;
      final efficiency = gameState.playerManager.calculateEfficiency();

      // Achievements basés sur le score
      if (paperclips >= 10000) {
        await unlockAchievement(_competitiveScore10kId);
      }
      if (paperclips >= 50000) {
        await unlockAchievement(_competitiveScore50kId);
      }
      if (paperclips >= 100000) {
        await unlockAchievement(_competitiveScore100kId);
      }

      // Achievement de speed run (moins de 30 minutes)
      if (paperclips >= 10000 && playTime.inMinutes < 30) {
        await unlockAchievement(_competitiveSpeedRunId);
      }

      // Achievement d'efficacité (ratio production/coût > 2.0)
      if (efficiency > 2.0 && paperclips >= 5000) {
        await unlockAchievement(_competitiveEfficiencyId);
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des achievements: $e');
    }
  }

  Future<void> updateProgressionAchievement(int level) async {
    try {
      await incrementAchievement(_progressionAchievementId, level);
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la progression: $e');
    }
  }

  Future<void> saveGameToCloud(sm.SaveGame saveGame) async {
    try {
      final cloudManager = CloudSaveManager();
      await cloudManager.syncSaves();
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde dans le cloud: $e');
    }
  }

  Future<sm.SaveGame?> loadGameFromCloud(String cloudId) async {
    try {
      final cloudManager = CloudSaveManager();
      final cloudSaves = await cloudManager.getCloudSaves();
      final targetSave = cloudSaves.firstWhere(
        (save) => save.cloudId == cloudId,
        orElse: () => throw Exception('Sauvegarde non trouvée'),
      );

      return await sm.SaveManager.loadGame(targetSave.name);
    } catch (e) {
      debugPrint('Erreur lors du chargement depuis le cloud: $e');
      return null;
    }
  }

  Future<sm.SaveGameInfo?> showSaveSelector() async {
    try {
      final cloudManager = CloudSaveManager();
      final cloudSaves = await cloudManager.getCloudSaves();
      
      if (cloudSaves.isEmpty) {
        debugPrint('Aucune sauvegarde cloud disponible');
        return null;
      }

      // Ici, vous devriez implémenter une interface utilisateur pour sélectionner la sauvegarde
      // Pour l'instant, on retourne simplement la plus récente
      return cloudSaves.first;
    } catch (e) {
      debugPrint('Erreur lors de la sélection de la sauvegarde: $e');
      return null;
    }
  }
}

class AchievementManager {
  static AchievementItemData createDefaultAchievement({
    required String id,
    String? customName,
    String? customDescription,
  }) {
    return AchievementItemData(
      id: id,
      name: customName ?? 'Achievement',
      description: customDescription ?? 'Achievement Description',
      completedSteps: 0,
      totalSteps: 100,
      unlocked: false,
    );
  }
}

extension AchievementExtensions on AchievementItemData {
  double getProgress() {
    if (totalSteps <= 0) return unlocked ? 1.0 : 0.0;
    return completedSteps / totalSteps;
  }

  bool isInProgress() {
    return completedSteps > 0 && completedSteps < totalSteps;
  }
} 