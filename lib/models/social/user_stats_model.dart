// lib/models/social/user_stats_model.dart
import 'package:flutter/foundation.dart';

class UserStatsModel {
  final String userId;
  final String displayName;
  final int totalPaperclips;
  final int level;
  final double money;
  final int bestScore;
  final double efficiency;
  final int upgradesBought;
  final DateTime lastUpdated;

  UserStatsModel({
    required this.userId,
    required this.displayName,
    required this.totalPaperclips,
    required this.level,
    required this.money,
    required this.bestScore,
    required this.efficiency,
    required this.upgradesBought,
    DateTime? lastUpdated,
  }) : this.lastUpdated = lastUpdated ?? DateTime.now();

  // Création depuis les données JSON
  factory UserStatsModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return UserStatsModel(
      userId: id ?? json['userId'] ?? '',
      displayName: json['displayName'] ?? 'Utilisateur inconnu',
      totalPaperclips: json['totalPaperclips'] ?? 0,
      level: json['level'] ?? 1,
      money: (json['money'] as num?)?.toDouble() ?? 0.0,
      bestScore: json['bestScore'] ?? 0,
      efficiency: (json['efficiency'] as num?)?.toDouble() ?? 0.0,
      upgradesBought: json['upgradesBought'] ?? 0,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
    );
  }

  // Conversion en Map pour API
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'totalPaperclips': totalPaperclips,
      'level': level,
      'money': money,
      'bestScore': bestScore,
      'efficiency': efficiency,
      'upgradesBought': upgradesBought,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Création depuis GameState
  factory UserStatsModel.fromGameState(String userId, String displayName, dynamic gameState) {
    return UserStatsModel(
      userId: userId,
      displayName: displayName,
      totalPaperclips: gameState.totalPaperclipsProduced,
      level: gameState.levelSystem.level,
      money: gameState.playerManager?.money ?? 0.0,
      bestScore: gameState.calculateCompetitiveScore(),
      efficiency: gameState.calculateEfficiencyRating(),
      upgradesBought:
      (gameState.statistics?.getAllStats()['progression']?['Améliorations Achetées'] as int?) ?? 0,
    );
  }

  // Méthode pour comparer avec un autre utilisateur
  Map<String, dynamic> compareWith(UserStatsModel other) {
    return {
      'totalPaperclips': {
        'me': totalPaperclips,
        'friend': other.totalPaperclips,
        'diff': totalPaperclips - other.totalPaperclips,
      },
      'level': {
        'me': level,
        'friend': other.level,
        'diff': level - other.level,
      },
      'money': {
        'me': money,
        'friend': other.money,
        'diff': money - other.money,
      },
      'bestScore': {
        'me': bestScore,
        'friend': other.bestScore,
        'diff': bestScore - other.bestScore,
      },
      'efficiency': {
        'me': efficiency,
        'friend': other.efficiency,
        'diff': efficiency - other.efficiency,
      },
      'upgradesBought': {
        'me': upgradesBought,
        'friend': other.upgradesBought,
        'diff': upgradesBought - other.upgradesBought,
      },
    };
  }
}