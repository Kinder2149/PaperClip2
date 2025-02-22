import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:games_services/games_services.dart';

class GamesServicesController {
  static final GamesServicesController _instance = GamesServicesController._internal();

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

  // Nouvelle méthode pour vérifier l'état de connexion
  Future<bool> isSignedIn() async {
    return _isSignedIn;
  }

  Future<void> showAchievements() async {
    try {
      await GamesServices.showAchievements();
    } catch (e, stack) {
      debugPrint('Error showing achievements: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<void> submitScore(int scoreValue) async {
    if (!_isSignedIn) return;

    try {
      await GamesServices.submitScore(
        score: Score(
            androidLeaderboardID: 'CgkI-Do', // À remplacer par votre ID
            iOSLeaderboardID: 'your_leaderboard_id',     // À remplacer par votre ID
            value: scoreValue
        ),
      );
      debugPrint('Score submitted: $scoreValue');
    } catch (e, stack) {
      debugPrint('Error submitting score: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<void> showLeaderboard() async {
    try {
      await GamesServices.showLeaderboards();
    } catch (e, stack) {
      debugPrint('Error showing leaderboard: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<void> unlockAchievement(Achievement achievement) async {
    if (!_isSignedIn) return;

    try {
      await GamesServices.unlock(achievement: achievement);
      debugPrint('Achievement unlocked: ${achievement.androidID}');
    } catch (e, stack) {
      debugPrint('Error unlocking achievement: $e');
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }
}