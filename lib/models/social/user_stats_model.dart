// lib/models/social/user_stats_model.dart
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_stats_model.g.dart';

@JsonSerializable(explicitToJson: true)
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

  // Méthode générée par json_serializable
  factory UserStatsModel.fromJson(Map<String, dynamic> json) => _$UserStatsModelFromJson(json);
  
  // Pour conserver la compatibilité avec l'ancien code qui utilise l'ID en paramètre
  factory UserStatsModel.fromJsonWithId(Map<String, dynamic> json, {String? id}) {
    var updatedJson = Map<String, dynamic>.from(json);
    if (id != null) updatedJson['userId'] = id;
    return _$UserStatsModelFromJson(updatedJson);
  }

  // Méthode générée par json_serializable
  Map<String, dynamic> toJson() => _$UserStatsModelToJson(this);

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