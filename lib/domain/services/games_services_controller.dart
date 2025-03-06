// lib/services/games_services_controller.dart
import 'package:games_services/games_services.dart' as gs;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:paperclip2/domain/entities/game_state_entity.dart';
import 'save_manager.dart';
import 'dart:convert';

class GamesServicesController {
  static const String generalLeaderboardID = 'CgkIrYnj8KYOEAIQAQ';
  static const String productionLeaderboardID = 'CgkIrYnj8KYOEAIQAg';
  static const String bankerLeaderboardID = 'CgkIrYnj8KYOEAIQAw';

  // Achievement IDs
  static const String achievement1000PaperclipsID = 'CgkIrYnj8KYOEAIQBA';
  static const String achievementFirstUpgradeID = 'CgkIrYnj8KYOEAIQBQ';

  // Singleton instance
  static final GamesServicesController _instance = GamesServicesController._internal();
  factory GamesServicesController() => _instance;
  GamesServicesController._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await gs.GamesServices.signIn();
      _initialized = true;
    } catch (e) {
      print('Error initializing Games Services: $e');
    }
  }

  Future<bool> isSignedIn() async {
    try {
      return await gs.GamesServices.isSignedIn;
    } catch (e) {
      print('Error checking sign-in status: $e');
      return false;
    }
  }

  Future<void> signIn() async {
    try {
      await gs.GamesServices.signIn();
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  Future<void> switchAccount() async {
    try {
      await gs.GamesServices.signIn();  // Remplacez signOut() par signIn()
    } catch (e) {
      print('Error switching account: $e');
    }
  }

  Future<void> submitScore({required String leaderboardID, required int score}) async {
    try {
      await gs.GamesServices.submitScore(
        score: score,
        leaderboardID: leaderboardID,
      );
    } catch (e) {
      print('Error submitting score: $e');
    }
  }

  Future<void> showLeaderboard({required String leaderboardID}) async {
    try {
      await gs.GamesServices.showLeaderboards(
        leaderboardID: leaderboardID,
      );
    } catch (e) {
      print('Error showing leaderboard: $e');
    }
  }

  Future<void> unlockAchievement({required String achievementID}) async {
    try {
      await gs.GamesServices.unlock(
        achievementID: achievementID,
      );
    } catch (e) {
      print('Error unlocking achievement: $e');
    }
  }
  Future<void> unlock({required String achievementID}) async {
    try {
      await gs.GamesServices.unlock(
        achievementID: achievementID,
      );
    } catch (e) {
      print('Error unlocking achievement: $e');
    }
  }
  Future<void> showAchievements() async {
    try {
      await gs.GamesServices.showAchievements();
    } catch (e) {
      print('Error showing achievements: $e');
    }
  }

  Future<bool> syncSaves() async {
    if (!await isSignedIn()) return false;

    try {
      // Synchronization logic between local saves and cloud saves
      // Implement based on your specific requirements
      return true;
    } catch (e) {
      print('Error syncing saves: $e');
      return false;
    }
  }

  Future<bool> saveGameToCloud(GameStateEntity gameState) async {
    if (!await isSignedIn()) return false;

    try {
      // Implement cloud save logic
      // This is a placeholder - actual implementation would depend on your backend
      return true;
    } catch (e) {
      print('Error saving game to cloud: $e');
      return false;
    }
  }

  Future<GameStateEntity?> loadGameFromCloud(String cloudId) async {
    if (!await isSignedIn()) return null;

    try {
      // Implement cloud load logic
      // This is a placeholder - actual implementation would depend on your backend
      return null;
    } catch (e) {
      print('Error loading game from cloud: $e');
      return null;
    }
  }
}