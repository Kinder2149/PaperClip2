import 'package:flutter/material.dart';
import 'package:paperclip2/models/game_state.dart';
import 'competition_service.dart';

/// Adaptateur pour assurer la compatibilité avec l'ancien code
class CompetitionAdapter {
  final CompetitionService _competitionService;
  
  /// Constructeur
  CompetitionAdapter(this._competitionService);
  
  /// Calcule le score compétitif (compatible avec l'ancien code)
  int calculateCompetitiveScore(GameState gameState) {
    return _competitionService.calculateScore(
      paperclips: gameState.totalPaperclipsProduced,
      money: gameState.playerManager.money,
      playTime: gameState.competitivePlayTime,
      level: gameState.levelSystem.level,
      efficiency: gameState.calculateEfficiencyRating(),
    );
  }
  
  /// Soumet le score compétitif (compatible avec l'ancien code)
  Future<void> submitCompetitiveScore(GameState gameState) async {
    final score = calculateCompetitiveScore(gameState);
    
    await _competitionService.submitScore(
      score: score,
      paperclips: gameState.totalPaperclipsProduced,
      money: gameState.playerManager.money,
      timePlayed: gameState.competitivePlayTime.inSeconds,
      level: gameState.levelSystem.level,
      efficiency: gameState.calculateEfficiencyRating(),
    );
    
    await _competitionService.checkAchievements(
      score,
      gameState.competitivePlayTime,
      gameState.calculateEfficiencyRating(),
    );
  }
  
  /// Gère la fin de partie en mode compétitif (compatible avec l'ancien code)
  Future<void> handleCompetitiveGameEnd(GameState gameState, BuildContext context) async {
    if (gameState.gameMode != GameMode.COMPETITIVE || !gameState.isInCrisisMode) return;
    
    // Calculer les métriques de la partie compétitive
    final competitiveScore = calculateCompetitiveScore(gameState);
    
    // Soumettre le score
    await submitCompetitiveScore(gameState);
    
    // Afficher les résultats
    await _competitionService.showResults(
      context: context,
      score: competitiveScore,
      paperclips: gameState.totalPaperclipsProduced,
      money: gameState.playerManager.money,
      playTime: gameState.competitivePlayTime,
      level: gameState.levelSystem.level,
      efficiency: gameState.calculateEfficiencyRating(),
      onNewGame: () => _startNewCompetitiveGame(context, gameState),
    );
  }
  
  /// Démarre une nouvelle partie compétitive (compatible avec l'ancien code)
  Future<void> _startNewCompetitiveGame(BuildContext context, GameState gameState) async {
    final gameName = 'Compétition_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().hour}${DateTime.now().minute}';
    await _competitionService.startNewGame(context, gameName);
  }
  
  /// Affiche le classement compétitif (compatible avec l'ancien code)
  Future<void> showCompetitiveLeaderboard() async {
    await _competitionService.showLeaderboard();
  }
  
  /// Vérifie si le joueur est connecté aux services de jeu (compatible avec l'ancien code)
  Future<bool> isSignedIn() async {
    return await _competitionService.isSignedIn();
  }
  
  /// Se connecte aux services de jeu (compatible avec l'ancien code)
  Future<bool> signIn() async {
    return await _competitionService.signIn();
  }
  
  /// Change de compte pour les services de jeu (compatible avec l'ancien code)
  Future<bool> switchAccount() async {
    return await _competitionService.switchAccount();
  }
  
  /// Récupère les informations du classement (compatible avec l'ancien code)
  Future<Map<String, dynamic>> getLeaderboardInfo(String leaderboardId, String title) async {
    return await _competitionService.getLeaderboardInfo(leaderboardId, title);
  }
} 