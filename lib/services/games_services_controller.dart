import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:games_services/games_services.dart';
import 'package:paperclip2/models/game_state.dart';

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

  Future<void> incrementAchievement(Achievement achievement) async {
    if (!_isSignedIn) return;

    try {
      await GamesServices.increment(
        achievement: achievement,
      );
      debugPrint('Achievement ${achievement.androidID} incremented to ${achievement.steps} steps');
    } catch (e, stack) {
      debugPrint('Error incrementing achievement: $e');
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
  Future<void> showAchievements() async {
    try {
      await GamesServices.showAchievements();
    } catch (e, stack) {
      debugPrint('Error showing achievements: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  // Méthode pour afficher les leaderboards
  Future<void> showLeaderboard({String? specificLeaderboard}) async {
    try {
      await GamesServices.showLeaderboards(
          androidLeaderboardID: specificLeaderboard ?? _generalLeaderboardId
      );
    } catch (e, stack) {
      debugPrint('Error showing leaderboard: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  // Méthode pour afficher le classement de production
  Future<void> showProductionLeaderboard() async {
    await showLeaderboard(specificLeaderboard: _productionLeaderboardId);
  }

  // Méthode pour afficher le classement bancaire
  Future<void> showBankerLeaderboard() async {
    await showLeaderboard(specificLeaderboard: _bankerLeaderboardId);
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