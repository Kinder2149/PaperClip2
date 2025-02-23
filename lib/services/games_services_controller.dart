import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:games_services/games_services.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/progression_system.dart';

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

  factory GamesServicesController() {
    return _instance;
  }

  GamesServicesController._internal();

  // IDs des classements (à remplacer par vos vrais IDs de la Console Play)
  static const String _generalLeaderboardId = 'CgkI-ICryvIBEAIQAg'; // Remplacer par votre ID
  static const String _productionLeaderboardId = 'CgkI-ICryvIBEAIQAw';
  static const String _bankerLeaderboardId = 'CgkI-ICryvIBEAIQBA';

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

  Future<void> signIn() async {
    try {
      await GamesServices.signIn();
      _isSignedIn = true;
      debugPrint('Sign in successful');
    } catch (e, stack) {
      _isSignedIn = false;
      debugPrint('Error signing in to GameServices: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<bool> isSignedIn() async {
    return _isSignedIn;
  }

  // Méthode pour soumettre le score général
  Future<void> submitGeneralScore(int paperclips, int money, int playTime) async {
    if (!_isSignedIn) return;

    try {
      // Score général basé sur les trombones, l'argent et le temps de jeu
      // Plus le temps est court, meilleur est le score
      final int score = _calculateGeneralScore(paperclips, money, playTime);

      await GamesServices.submitScore(
        score: Score(
            androidLeaderboardID: _generalLeaderboardId,
            value: score
        ),
      );
      debugPrint('General score submitted: $score');
    } catch (e, stack) {
      debugPrint('Error submitting general score: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }
  // Cette méthode doit être modifiée car getLeaderboardScores n'existe pas
  Future<LeaderboardInfo?> getLeaderboardInfo(String leaderboardId, String name) async {
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
      final achievements = await GamesServices.loadAchievements();
      if (achievements == null) return 0.0;

      final achievement = achievements.firstWhere(
            (a) => a.id == achievementId,
        orElse: () => AchievementItemData(
          id: achievementId,
          name: 'Achievement',  // Requis
          description: 'Achievement Description',  // Requis
          completedSteps: 0,  // Requis
          totalSteps: 100,  // Requis
          unlocked: false,  // Requis
        ),
      );

      // Calcul du pourcentage basé sur les étapes complétées
      if (achievement.totalSteps > 0) {
        return (achievement.completedSteps / achievement.totalSteps);
      }
      return achievement.unlocked ? 1.0 : 0.0;
    } catch (e, stack) {
      debugPrint('Error getting achievement progress: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
      return null;
    }
  }
  // Méthode pour soumettre le score de production
  Future<void> submitProductionScore(int paperclips) async {
    if (!_isSignedIn) return;

    try {
      await GamesServices.submitScore(
        score: Score(
            androidLeaderboardID: _productionLeaderboardId,
            value: paperclips
        ),
      );
      debugPrint('Production score submitted: $paperclips');
    } catch (e, stack) {
      debugPrint('Error submitting production score: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<void> incrementAchievement(LevelSystem levelSystem) async {
    if (!_isSignedIn) return;

    try {
      final progress = ((levelSystem.level * 10) + (levelSystem.experience / levelSystem.experienceForNextLevel * 10)).clamp(0, 100).toInt();

      await GamesServices.increment(
          achievement: Achievement(
            androidID: 'CgkI-ICryvIBEAIQAQ',
            steps: progress,
            name: 'Progression du joueur',  // Ajouté
            description: 'Progression globale du joueur dans le jeu',  // Ajouté
            totalSteps: 100,  // Ajouté
          )
      );
      debugPrint('Achievement progress updated to: $progress%');
    } catch (e, stack) {
      debugPrint('Error updating achievement progress: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }


  // Méthode pour soumettre le score bancaire
  Future<void> submitBankerScore(int totalMoney) async {
    if (!_isSignedIn) return;

    try {
      await GamesServices.submitScore(
        score: Score(
            androidLeaderboardID: _bankerLeaderboardId,
            value: totalMoney
        ),
      );
      debugPrint('Banker score submitted: $totalMoney');
    } catch (e, stack) {
      debugPrint('Error submitting banker score: $e');
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
    // Limité à un maximum pour éviter les scores extrêmes
    int timeBonus = playTime > 0 ? (TIME_EFFICIENCY * 1000) ~/ playTime : 0;
    timeBonus = timeBonus.clamp(0, TIME_EFFICIENCY);

    return baseScore + timeBonus;
  }

  // Méthode pour afficher les achievements
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
  Future<void> showLeaderboard({String? specificLeaderboard, bool friendsOnly = false}) async {
    if (!_isSignedIn) return;

    try {
      await GamesServices.showLeaderboards(
        androidLeaderboardID: specificLeaderboard ?? _generalLeaderboardId,
      );
      debugPrint('Showing leaderboard: ${specificLeaderboard ?? _generalLeaderboardId}');
    } catch (e, stack) {
      debugPrint('Error showing leaderboard: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  // Méthode pour afficher le classement de production
  Future<void> showProductionLeaderboard({bool friendsOnly = false}) async {
    await showLeaderboard(
      specificLeaderboard: _productionLeaderboardId,
      friendsOnly: friendsOnly,
    );
  }

  // Méthode pour afficher le classement bancaire
  Future<void> showBankerLeaderboard({bool friendsOnly = false}) async {
    await showLeaderboard(
      specificLeaderboard: _bankerLeaderboardId,
      friendsOnly: friendsOnly,
    );
  }

  // Méthode pour mettre à jour tous les classements d'un coup
  Future<void> updateAllLeaderboards(GameState gameState) async {
    if (!_isSignedIn) return;

    await submitGeneralScore(
        gameState.totalPaperclipsProduced,
        gameState.statistics.getTotalMoneyEarned().toInt(),
        gameState.totalTimePlayed
    );
    await submitProductionScore(gameState.totalPaperclipsProduced);
    await submitBankerScore(gameState.statistics.getTotalMoneyEarned().toInt());
  }
}

class AchievementConstants {
  static const String PROGRESSION_ID = 'CgkI-ICryvIBEAIQAQ';

  static Achievement createProgressionAchievement({
    required int currentSteps,
    String? customName,
    String? customDescription
  }) {
    return Achievement(
      androidID: PROGRESSION_ID,
      steps: currentSteps.clamp(0, 100),
      name: customName ?? 'Progression du joueur',
      description: customDescription ?? 'Progression globale dans le jeu',
      totalSteps: 100,
    );
  }

  static AchievementItemData createDefaultAchievementData(String id) {
    return AchievementItemData(
      id: id,
      name: 'Achievement',
      description: 'Achievement Description',
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