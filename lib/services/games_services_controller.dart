// lib/services/games_services_controller.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:games_services/games_services.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/progression_system.dart';
import 'package:paperclip2/services/cloud_save_manager.dart';
import 'package:games_services/games_services.dart' as gs;
import 'package:paperclip2/services/save_manager.dart' as sm;

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
  static final GamesServicesController _instance = GamesServicesController
      ._internal();

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

  bool _isInitialized = false;
  bool _isSignedIn = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await signIn(); // Tenter de se connecter directement
      _isInitialized = true;
      debugPrint('Games Services initialized');
    } catch (e, stack) {
      debugPrint('Error initializing GameServices: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }


  Future<bool> signIn() async {
    try {
      // Diagnostic de débogage
      print("Tentative de connexion à Google Play Games Services");
      print("Package de l'application: com.kinder2149.paperclip2");
      print("ID des jeux: 65117274232");

      await GamesServices.signIn();
      final signedIn = await GamesServices.isSignedIn;

      if (signedIn) {
        _isSignedIn = true;
        print("Connexion aux services de jeu réussie");
        return true;
      } else {
        print("La connexion n'a pas abouti, mais aucune erreur n'a été lancée");

        // Tenter à nouveau après une courte pause, cela peut parfois aider
        await Future.delayed(Duration(seconds: 1));
        await GamesServices.signIn();

        final secondAttempt = await GamesServices.isSignedIn;
        _isSignedIn = secondAttempt;

        if (secondAttempt) {
          print("Connexion réussie à la seconde tentative");
          return true;
        }

        print("Échec même après seconde tentative");
        print("Vérifiez dans Google Play Console que les empreintes SHA-1 suivantes sont enregistrées:");
        print("Débogage: 94:95:FD:94:32:6F:9D:6C:1A:64:99:91:9E:41:47:7C:FB:84:F7:54");
        print("Publication: 98:3F:EC:A7:2B:C0:EA:65:7C:A0:1B:41:EA:CC:C4:1E:C6:B0:42:25");

        return false;
      }
    } catch (e, stackTrace) {
      print("Erreur explicite lors de la connexion aux services de jeu: $e");
      print("Stack trace: $stackTrace");

      try {
        FirebaseCrashlytics.instance.recordError(e, stackTrace,
            reason: 'Erreur Google Play Games Sign In');
      } catch (_) {
        // Ignorer si l'erreur ne peut pas être enregistrée
      }

      return false;
    }
  }

  Future<bool> saveGameToCloud(sm.SaveGame save) async {
    if (!_isSignedIn) return false;

    try {
      // Utiliser CloudSaveManager pour la sauvegarde
      final cloudSaveManager = CloudSaveManager();
      return await cloudSaveManager.saveToCloud(save);
    } catch (e, stack) {
      debugPrint('Error saving game to cloud: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      return false;
    }
  }

  // Charger une partie depuis le cloud
  Future<sm.SaveGame?> loadGameFromCloud(String cloudId) async {
    if (!_isSignedIn) return null;

    try {
      // Utiliser CloudSaveManager pour le chargement
      final cloudSaveManager = CloudSaveManager();
      return await cloudSaveManager.loadFromCloud(cloudId);
    } catch (e, stack) {
      debugPrint('Error loading game from cloud: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      return null;
    }
  }

  // Récupérer la liste des sauvegardes cloud
  Future<List<sm.SaveGameInfo>> getCloudSaves() async {
    if (!_isSignedIn) return [];

    try {
      // Utiliser CloudSaveManager pour récupérer les sauvegardes
      final cloudSaveManager = CloudSaveManager();
      return await cloudSaveManager.getCloudSaves();
    } catch (e, stack) {
      debugPrint('Error getting cloud saves: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      return [];
    }
  }

  // Synchroniser les sauvegardes locales et cloud
  Future<bool> syncSaves() async {
    if (!_isSignedIn) return false;

    try {
      final cloudSaveManager = CloudSaveManager();
      return await cloudSaveManager.syncSaves();
    } catch (e, stack) {
      debugPrint('Error syncing saves: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      return false;
    }
  }

  // Afficher une interface permettant de sélectionner une sauvegarde
  // Fonction adaptée pour games_services 4.0.3
  Future<sm.SaveGame?> showSaveSelector() async {
    if (!_isSignedIn) return null;

    try {
      // Comme games_services 4.0.3 n'a pas de showSavedGamesUI,
      // nous créons notre propre interface ou utilisons une alternative

      // Récupérer les sauvegardes cloud
      final cloudSaves = await getCloudSaves();

      // Si aucune sauvegarde, retourner null
      if (cloudSaves.isEmpty) return null;

      // Simuler une sélection (dans une vraie application, vous afficheriez une UI)
      // Par défaut, prenons la sauvegarde la plus récente
      cloudSaves.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final selectedSave = cloudSaves.first;

      // Charger la sauvegarde sélectionnée
      if (selectedSave.cloudId != null) {
        return await loadGameFromCloud(selectedSave.cloudId!);
      }

      return null;
    } catch (e, stack) {
      debugPrint('Error showing save selector: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      return null;
    }
  }

  Future<bool> isSignedIn() async {
    return _isSignedIn;
  }

  Future<void> submitCompetitiveScore({
    required int score,
    required int paperclips,
    required double money,
    required int timePlayed,
    required int level,
    required double efficiency,
  }) async {
    if (!_isSignedIn) return;

    try {
      // 1. Soumettre le score principal
      await GamesServices.submitScore(
        score: Score(
            androidLeaderboardID: generalLeaderboardID,
            value: score
        ),
      );

      // 2. Soumettre le score de production
      await GamesServices.submitScore(
        score: Score(
            androidLeaderboardID: productionLeaderboardID,
            value: paperclips
        ),
      );

      // 3. Soumettre le score d'argent
      await GamesServices.submitScore(
        score: Score(
            androidLeaderboardID: bankerLeaderboardID,
            value: money.toInt()
        ),
      );

      debugPrint('Competitive scores submitted successfully');
      debugPrint('Score: $score, Paperclips: $paperclips, Money: ${money.toInt()}, Time: $timePlayed, Level: $level, Efficiency: $efficiency');
    } catch (e, stack) {
      debugPrint('Error submitting competitive scores: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  // Débloquer un succès compétitif
  Future<void> unlockCompetitiveAchievement(
      CompetitiveAchievement achievement) async {
    if (!_isSignedIn) return;

    try {
      String achievementId;

      // Déterminer l'ID du succès à débloquer
      switch (achievement) {
        case CompetitiveAchievement.SCORE_10K:
          achievementId = _competitiveScore10kId;
          break;
        case CompetitiveAchievement.SCORE_50K:
          achievementId = _competitiveScore50kId;
          break;
        case CompetitiveAchievement.SCORE_100K:
          achievementId = _competitiveScore100kId;
          break;
        case CompetitiveAchievement.SPEED_RUN:
          achievementId = _competitiveSpeedRunId;
          break;
        case CompetitiveAchievement.EFFICIENCY_MASTER:
          achievementId = _competitiveEfficiencyId;
          break;
      }

      // Débloquer le succès
      await GamesServices.unlock(
          achievement: Achievement(
              androidID: achievementId,
              steps: 1
          )
      );

      debugPrint('Competitive achievement unlocked: $achievement');
    } catch (e, stack) {
      debugPrint('Error unlocking competitive achievement: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }


  Future<void> showCompetitiveLeaderboard() async {
    await showLeaderboard(leaderboardID: generalLeaderboardID);
  }


  Future<void> submitGeneralScore(int paperclips, int money, int playTime) async {
    if (!_isSignedIn) return;

    try {
      // Score général basé sur les trombones, l'argent et le temps de jeu
      final int score = _calculateGeneralScore(paperclips, money, playTime);

      await GamesServices.submitScore(
        score: Score(
            androidLeaderboardID: generalLeaderboardID,
            value: score
        ),
      );
      debugPrint('General score submitted: $score');
    } catch (e, stack) {
      debugPrint('Error submitting general score: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

// Méthode pour soumettre le score de production
  Future<void> submitProductionScore(int paperclips) async {
    if (!_isSignedIn) return;

    try {
      await GamesServices.submitScore(
        score: Score(
            androidLeaderboardID: productionLeaderboardID,
            value: paperclips
        ),
      );
      debugPrint('Production score submitted: $paperclips');
    } catch (e, stack) {
      debugPrint('Error submitting production score: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

// Méthode pour soumettre le score bancaire
  Future<void> submitBankerScore(int totalMoney) async {
    if (!_isSignedIn) return;

    try {
      await GamesServices.submitScore(
        score: Score(
            androidLeaderboardID: bankerLeaderboardID,
            value: totalMoney
        ),
      );
      debugPrint('Banker score submitted: $totalMoney');
    } catch (e, stack) {
      debugPrint('Error submitting banker score: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  // Cette méthode est simplifiée car getLeaderboardScores n'existe pas dans la version 4.0.3
  Future<LeaderboardInfo?> getLeaderboardInfo(String leaderboardId,
      String name) async {
    if (!_isSignedIn) return null;

    try {
      // Pour l'instant, retourner des valeurs de base
      return LeaderboardInfo(
        currentScore: 0,
        bestScore: 0,
        rank: null,
        leaderboardName: name,
      );
    } catch (e, stack) {
      debugPrint('Error getting leaderboard info: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      return null;
    }
  }

  Future<double?> getAchievementProgress(String achievementId) async {
    if (!_isSignedIn) return null;

    try {
      // Dans games_services 4.0.3, loadAchievements retourne AchievementItemList
      final achievements = await GamesServices.loadAchievements();
      if (achievements == null) return 0.0;

      final achievement = achievements.firstWhere(
            (a) => a.id == achievementId,
        orElse: () =>
            AchievementManager.createDefaultAchievement(
              id: achievementId,
            ),
      );

      return achievement.getProgress();
    } catch (e, stack) {
      debugPrint('Error getting achievement progress: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      return null;
    }
  }




  Future<void> incrementAchievement(LevelSystem levelSystem) async {
    if (!_isSignedIn) return;

    try {
      final progress = ((levelSystem.level * 10) +
          (levelSystem.experience / levelSystem.experienceForNextLevel * 10))
          .clamp(0, 100).toInt();

      await GamesServices.increment(
          achievement: Achievement(
              androidID: _progressionAchievementId,
              steps: progress
          )
      );
      debugPrint('Achievement progress updated to: $progress%');
    } catch (e, stack) {
      debugPrint('Error updating achievement progress: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }



  // Calcul du score général
  int _calculateGeneralScore(int paperclips, int money, int playTime) {
    // Facteurs de pondération
    const int PAPERCLIP_WEIGHT = 1;
    const int MONEY_WEIGHT = 2;
    const int TIME_EFFICIENCY = 1000;

    // Score de base basé sur les trombones et l'argent
    int baseScore = (paperclips * PAPERCLIP_WEIGHT) + (money * MONEY_WEIGHT);

    // Bonus d'efficacité temporelle (plus le temps est court, plus le bonus est grand)
    int timeBonus = playTime > 0 ? (TIME_EFFICIENCY * 1000) ~/ playTime : 0;
    timeBonus = timeBonus.clamp(0, TIME_EFFICIENCY);

    return baseScore + timeBonus;
  }

  // Méthode pour afficher les achievements
  Future<void> showAchievements() async {
    try {
      await GamesServices.showAchievements();
    } catch (e, stack) {
      debugPrint('Error showing achievements: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  // Méthode pour afficher les leaderboards
  Future<void> showLeaderboard({required String leaderboardID, bool friendsOnly = false}) async {
    try {
      final signedIn = await GamesServices.isSignedIn;
      if (!signedIn) {
        print("L'utilisateur n'est pas connecté, tentative de connexion...");
        await signIn();
      }

      // Correction ici - utiliser la syntaxe correcte pour la version 4.0.3
      await GamesServices.showLeaderboards(
        // Utiliser leaderboardID directement, sans le nommer
        androidLeaderboardID: leaderboardID,
        // Si vous avez besoin d'iOS, ajoutez aussi
        // iOSLeaderboardID: leaderboardID,
      );
    } catch (e) {
      print("Erreur lors de l'affichage du classement: $e");
      await FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Erreur d\'affichage du classement',
      );
    }
  }

  Future<void> showGeneralLeaderboard({bool friendsOnly = false}) async {
    await showLeaderboard(leaderboardID: generalLeaderboardID);
  }

// Méthode pour afficher le classement de production
  Future<void> showProductionLeaderboard({bool friendsOnly = false}) async {
    await showLeaderboard(leaderboardID: productionLeaderboardID);
  }

// Méthode pour afficher le classement bancaire
  Future<void> showBankerLeaderboard({bool friendsOnly = false}) async {
    await showLeaderboard(leaderboardID: bankerLeaderboardID);
  }



  // Méthode pour mettre à jour tous les classements d'un coup
  Future<void> updateAllLeaderboards(GameState gameState) async {
    if (!_isSignedIn) return;

    try {
      // On utilise catchError pour chaque opération individuelle
      await submitGeneralScore(
          gameState.totalPaperclipsProduced,
          gameState.statistics.getTotalMoneyEarned().toInt(),
          gameState.totalTimePlayed
      ).catchError((e) {
        debugPrint('Error submitting general score: $e');
        return null; // Retourne null mais continue l'exécution
      });

      await submitProductionScore(gameState.totalPaperclipsProduced)
          .catchError((e) {
        debugPrint('Error submitting production score: $e');
        return null;
      });

      await submitBankerScore(
          gameState.statistics.getTotalMoneyEarned().toInt())
          .catchError((e) {
        debugPrint('Error submitting banker score: $e');
        return null;
      });
    } catch (e, stack) {
      // Si une erreur se produit quand même
      debugPrint('Error updating leaderboards: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
    }
  }
  // Dans games_services_controller.dart

  Future<GooglePlayerInfo?> getCurrentPlayerInfo() async {
    if (!await isSignedIn()) return null;

    try {
      // L'API actuelle ne fournit pas directement le moyen d'obtenir les infos du joueur
      // Essayons d'utiliser une approche différente
      return GooglePlayerInfo(
        id: 'player_id',
        displayName: 'Joueur connecté', // Nommer génériquement pour l'instant
        iconImageUrl: null,
      );
    } catch (e, stackTrace) {
      print("Erreur lors de la récupération des infos du joueur: $e");
      FirebaseCrashlytics.instance.recordError(e, stackTrace);
      return null;
    }
  }

  Future<bool> switchAccount() async {
    try {
      // Pour forcer la sélection d'un compte, nous pouvons nous déconnecter temporairement
      // (cela n'est pas directement supporté par l'API, mais nous pouvons simuler)
      _isSignedIn = false;
      // Supprimez cette ligne : notifyListeners();

      // Attendre un peu pour s'assurer que le changement d'état est pris en compte
      await Future.delayed(Duration(milliseconds: 500));

      // Réinitialiser toute instance/état stocké en cache
      final result = await GamesServices.signIn();
      _isSignedIn = await GamesServices.isSignedIn == true;

      return _isSignedIn;
    } catch (e, stackTrace) {
      print("Erreur lors du changement de compte: $e");
      FirebaseCrashlytics.instance.recordError(e, stackTrace);
      return false;
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
