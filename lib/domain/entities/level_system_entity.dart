// lib/domain/entities/level_system_entity.dart
import 'dart:math';
import '../../core/constants/game_constants.dart';
import '../../core/constants/enums.dart';

class PathProgressEntity {
  final ProgressionPath path;
  final double progress;

  PathProgressEntity({
    required this.path,
    required this.progress,
  });
}

class LevelSystemEntity {
  final double experience;
  final int level;
  final ProgressionPath currentPath;
  final double xpMultiplier;
  final int comboCount;
  final bool dailyBonusClaimed;
  final List<PathProgressEntity> pathProgress;
  final Map<String, bool> unlockedMilestones;

  LevelSystemEntity({
    required this.experience,
    required this.level,
    required this.currentPath,
    required this.xpMultiplier,
    required this.comboCount,
    required this.dailyBonusClaimed,
    required this.pathProgress,
    required this.unlockedMilestones,
  });

  double get experienceForNextLevel => calculateExperienceRequirement(level + 1);

  double get experienceProgress => experience / experienceForNextLevel;

  double get currentComboMultiplier => 1.0 + (comboCount * 0.1);

  double get totalXpMultiplier => xpMultiplier * currentComboMultiplier;

  bool get isDailyBonusAvailable => !dailyBonusClaimed;

  double get productionMultiplier => 1.0 + (level * 0.05);

  double get salesMultiplier => 1.0 + (level * 0.03);

  double calculateExperienceRequirement(int targetLevel) {
    double baseXP = 100.0;
    double linearIncrease = targetLevel * 50.0;
    double smallExponential = pow(1.05, targetLevel).toDouble();

    double tierMultiplier = 1.0;
    if (targetLevel > 25) tierMultiplier = 1.2;
    if (targetLevel > 35) tierMultiplier = 1.5;

    return double.parse(
        ((baseXP + linearIncrease + smallExponential) * tierMultiplier)
            .toStringAsFixed(1)
    );
  }

  LevelSystemEntity gainExperience(double amount) {
    double baseAmount = amount * totalXpMultiplier;
    double levelPenalty = level * 0.02;
    double adjustedAmount = baseAmount * (1 - levelPenalty);

    double newExperience = experience + max(adjustedAmount, 0.2);
    int newComboCount = min(comboCount + 1, GameConstants.MAX_COMBO_COUNT);

    return copyWith(
      experience: newExperience,
      comboCount: newComboCount,
    );
  }

  LevelSystemEntity incrementCombo() {
    return copyWith(
      comboCount: min(comboCount + 1, GameConstants.MAX_COMBO_COUNT),
    );
  }

  LevelSystemEntity claimDailyBonus() {
    if (!dailyBonusClaimed) {
      return copyWith(
        experience: experience + GameConstants.DAILY_BONUS_AMOUNT,
        dailyBonusClaimed: true,
      );
    }
    return this;
  }

  LevelSystemEntity checkLevelUp() {
    // Logique de montée de niveau à implémenter
    return this;
  }

  LevelSystemEntity copyWith({
    double? experience,
    int? level,
    ProgressionPath? currentPath,
    double? xpMultiplier,
    int? comboCount,
    bool? dailyBonusClaimed,
    List<PathProgressEntity>? pathProgress,
    Map<String, bool>? unlockedMilestones,
  }) {
    return LevelSystemEntity(
      experience: experience ?? this.experience,
      level: level ?? this.level,
      currentPath: currentPath ?? this.currentPath,
      xpMultiplier: xpMultiplier ?? this.xpMultiplier,
      comboCount: comboCount ?? this.comboCount,
      dailyBonusClaimed: dailyBonusClaimed ?? this.dailyBonusClaimed,
      pathProgress: pathProgress ?? this.pathProgress,
      unlockedMilestones: unlockedMilestones ?? this.unlockedMilestones,
    );
  }
}