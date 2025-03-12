import 'package:flutter/material.dart';

/// Interface pour les services de compétition
abstract class CompetitionInterface {
  /// Calcule le score compétitif
  int calculateScore({
    required int paperclips,
    required double money,
    required Duration playTime,
    required int level,
    required double efficiency,
  });
  
  /// Soumet le score compétitif
  Future<void> submitScore({
    required int score,
    required int paperclips,
    required double money,
    required int timePlayed,
    required int level,
    required double efficiency,
  });
  
  /// Vérifie et débloque les succès compétitifs
  Future<void> checkAchievements(int score, Duration playTime, double efficiency);
  
  /// Affiche l'écran de résultats compétitifs
  Future<void> showResults({
    required BuildContext context,
    required int score,
    required int paperclips,
    required double money,
    required Duration playTime,
    required int level,
    required double efficiency,
    required VoidCallback onNewGame,
  });
  
  /// Affiche le classement compétitif
  Future<void> showLeaderboard();
  
  /// Démarre une nouvelle partie compétitive
  Future<void> startNewGame(BuildContext context, String gameName);
  
  /// Vérifie si le joueur est connecté aux services de jeu
  Future<bool> isSignedIn();
  
  /// Se connecte aux services de jeu
  Future<bool> signIn();
  
  /// Change de compte pour les services de jeu
  Future<bool> switchAccount();
  
  /// Récupère les informations du classement
  Future<Map<String, dynamic>> getLeaderboardInfo(String leaderboardId, String title);
} 