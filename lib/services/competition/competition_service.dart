import 'package:flutter/material.dart';
import 'package:games_services/games_services.dart';
import 'package:paperclip2/screens/competitive_result_screen.dart';
import 'package:paperclip2/screens/main_screen.dart';
import 'package:paperclip2/services/games_services_controller.dart';
import 'competition_interface.dart';

/// Implémentation du service de compétition
class CompetitionService implements CompetitionInterface {
  // IDs des classements
  static const String generalLeaderboardID = "CgkI-ICryvIBEAIQAg";
  static const String productionLeaderboardID = "CgkI-ICryvIBEAIQAw";
  static const String bankerLeaderboardID = "CgkI-ICryvIBEAIQBA";
  
  // IDs des succès compétitifs
  static const String _competitiveScore10kId = 'CgkI-ICryvIBEAIQBQ';
  static const String _competitiveScore50kId = 'CgkI-ICryvIBEAIQBg';
  static const String _competitiveScore100kId = 'CgkI-ICryvIBEAIQBw';
  static const String _competitiveSpeedRunId = 'CgkI-ICryvIBEAIQCA';
  static const String _competitiveEfficiencyId = 'CgkI-ICryvIBEAIQCQ';
  
  // Fonction pour démarrer une nouvelle partie
  final Future<void> Function(String, {required bool isCompetitive}) _startNewGameCallback;
  
  /// Constructeur
  CompetitionService({
    required Future<void> Function(String, {required bool isCompetitive}) startNewGameCallback,
  }) : _startNewGameCallback = startNewGameCallback;
  
  @override
  int calculateScore({
    required int paperclips,
    required double money,
    required Duration playTime,
    required int level,
    required double efficiency,
  }) {
    // Base: production de trombones (50% du score)
    double productionScore = paperclips * 10;
    
    // Argent gagné (25% du score)
    double moneyScore = money * 5;
    
    // Niveau atteint (15% du score)
    double levelScore = level * 1000;
    
    // Bonus d'efficacité (10% du score)
    double efficiencyBonus = efficiency * 500;
    
    // Temps de jeu - bonus inversement proportionnel
    // Plus c'est rapide, plus le bonus est élevé
    int minutes = playTime.inMinutes;
    double timeMultiplier = 1.0;
    
    if (minutes < 10) {
      // Partie très courte, bonus maximal
      timeMultiplier = 1.5;
    } else if (minutes < 20) {
      timeMultiplier = 1.3;
    } else if (minutes < 30) {
      timeMultiplier = 1.2;
    } else if (minutes < 60) {
      timeMultiplier = 1.1;
    }
    
    // Calcul du score total
    double totalScore = (productionScore + moneyScore + levelScore + efficiencyBonus) * timeMultiplier;
    
    return totalScore.round();
  }
  
  @override
  Future<void> submitScore({
    required int score,
    required int paperclips,
    required double money,
    required int timePlayed,
    required int level,
    required double efficiency,
  }) async {
    final gamesServices = GamesServicesController();
    
    try {
      // 1. Soumettre le score principal
      await GamesServices.submitScore(
        score: Score(
          androidLeaderboardID: generalLeaderboardID,
          value: score,
        ),
      );
      
      // 2. Soumettre le score de production
      await GamesServices.submitScore(
        score: Score(
          androidLeaderboardID: productionLeaderboardID,
          value: paperclips,
        ),
      );
      
      // 3. Soumettre le score d'argent
      await GamesServices.submitScore(
        score: Score(
          androidLeaderboardID: bankerLeaderboardID,
          value: money.round(),
        ),
      );
      
      debugPrint('Scores compétitifs soumis avec succès');
    } catch (e) {
      debugPrint('Erreur lors de la soumission des scores: $e');
    }
  }
  
  @override
  Future<void> checkAchievements(int score, Duration playTime, double efficiency) async {
    try {
      // Vérifier les succès basés sur le score
      if (score >= 10000) {
        await GamesServices.unlock(achievement: Achievement(androidID: _competitiveScore10kId));
      }
      
      if (score >= 50000) {
        await GamesServices.unlock(achievement: Achievement(androidID: _competitiveScore50kId));
      }
      
      if (score >= 100000) {
        await GamesServices.unlock(achievement: Achievement(androidID: _competitiveScore100kId));
      }
      
      // Vérifier le succès de vitesse
      if (playTime.inMinutes < 15) {
        await GamesServices.unlock(achievement: Achievement(androidID: _competitiveSpeedRunId));
      }
      
      // Vérifier le succès d'efficacité
      if (efficiency >= 0.9) {
        await GamesServices.unlock(achievement: Achievement(androidID: _competitiveEfficiencyId));
      }
      
      debugPrint('Vérification des succès compétitifs terminée');
    } catch (e) {
      debugPrint('Erreur lors de la vérification des succès: $e');
    }
  }
  
  @override
  Future<void> showResults({
    required BuildContext context,
    required int score,
    required int paperclips,
    required double money,
    required Duration playTime,
    required int level,
    required double efficiency,
    required VoidCallback onNewGame,
  }) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompetitiveResultScreen(
          score: score,
          paperclips: paperclips,
          money: money,
          playTime: playTime,
          level: level,
          efficiency: efficiency,
          onNewGame: onNewGame,
          onShowLeaderboard: showLeaderboard,
        ),
      ),
    );
  }
  
  @override
  Future<void> showLeaderboard() async {
    try {
      await GamesServices.showLeaderboards(
        androidLeaderboardID: generalLeaderboardID,
      );
      debugPrint('Classement affiché avec succès');
    } catch (e) {
      debugPrint('Erreur lors de l\'affichage du classement: $e');
    }
  }
  
  @override
  Future<void> startNewGame(BuildContext context, String gameName) async {
    await _startNewGameCallback(gameName, isCompetitive: true);
    
    // Retourner à l'écran principal avec la nouvelle partie
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }
  
  @override
  Future<bool> isSignedIn() async {
    final gamesServices = GamesServicesController();
    return await gamesServices.isSignedIn();
  }
  
  @override
  Future<bool> signIn() async {
    final gamesServices = GamesServicesController();
    return await gamesServices.signIn();
  }
  
  @override
  Future<bool> switchAccount() async {
    try {
      await GamesServices.signOut();
      return await signIn();
    } catch (e) {
      debugPrint('Erreur lors du changement de compte: $e');
      return false;
    }
  }
  
  @override
  Future<Map<String, dynamic>> getLeaderboardInfo(String leaderboardId, String title) async {
    try {
      final gamesServices = GamesServicesController();
      final leaderboardInfo = await gamesServices.getLeaderboardInfo(leaderboardId, title);
      
      return {
        'currentScore': leaderboardInfo.currentScore,
        'bestScore': leaderboardInfo.bestScore,
        'rank': leaderboardInfo.rank,
        'leaderboardName': leaderboardInfo.leaderboardName,
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des informations du classement: $e');
      return {
        'currentScore': 0,
        'bestScore': 0,
        'rank': null,
        'leaderboardName': title,
      };
    }
  }
} 