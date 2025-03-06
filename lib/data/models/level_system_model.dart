// lib/data/models/level_system_model.dart
import '../../domain/entities/level_system_entity.dart';
import '../../core/constants/enums.dart';

class LevelSystemModel {
  final double experience;
  final int level;
  final ProgressionPath currentPath;
  final double xpMultiplier;
  final int comboCount;
  final bool dailyBonusClaimed;
  final List<PathProgressModel> pathProgress;
  final Map<String, bool> unlockedMilestones;

  LevelSystemModel({
    required this.experience,
    required this.level,
    required this.currentPath,
    required this.xpMultiplier,
    required this.comboCount,
    required this.dailyBonusClaimed,
    required this.pathProgress,
    required this.unlockedMilestones,
  });

  factory LevelSystemModel.fromJson(Map<String, dynamic> json) {
    final List<PathProgressModel> progressList = [];
    if (json['pathProgress'] != null) {
      (json['pathProgress'] as List).forEach((progress) {
        progressList.add(PathProgressModel.fromJson(progress));
      });
    }

    return LevelSystemModel(
      experience: (json['experience'] as num?)?.toDouble() ?? 0.0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      currentPath: ProgressionPath.values[(json['currentPath'] as num?)?.toInt() ?? 0],
      xpMultiplier: (json['xpMultiplier'] as num?)?.toDouble() ?? 1.0,
      comboCount: (json['comboCount'] as num?)?.toInt() ?? 0,
      dailyBonusClaimed: json['dailyBonusClaimed'] as bool? ?? false,
      pathProgress: progressList,
      unlockedMilestones: (json['unlockedMilestones'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as bool),
      ) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'experience': experience,
    'level': level,
    'currentPath': currentPath.index,
    'xpMultiplier': xpMultiplier,
    'comboCount': comboCount,
    'dailyBonusClaimed': dailyBonusClaimed,
    'pathProgress': pathProgress.map((progress) => progress.toJson()).toList(),
    'unlockedMilestones': unlockedMilestones,
  };

  LevelSystemEntity toEntity() {
    return LevelSystemEntity(
      experience: experience,
      level: level,
      currentPath: currentPath,
      xpMultiplier: xpMultiplier,
      comboCount: comboCount,
      dailyBonusClaimed: dailyBonusClaimed,
      pathProgress: pathProgress.map((progress) => progress.toEntity()).toList(),
      unlockedMilestones: unlockedMilestones,
    );
  }

  static LevelSystemModel fromEntity(LevelSystemEntity entity) {
    return LevelSystemModel(
      experience: entity.experience,
      level: entity.level,
      currentPath: entity.currentPath,
      xpMultiplier: entity.xpMultiplier,
      comboCount: entity.comboCount,
      dailyBonusClaimed: entity.dailyBonusClaimed,
      pathProgress: entity.pathProgress.map((progress) =>
          PathProgressModel.fromEntity(progress)).toList(),
      unlockedMilestones: entity.unlockedMilestones,
    );
  }

  LevelSystemModel copyWith({
    double? experience,
    int? level,
    ProgressionPath? currentPath,
    double? xpMultiplier,
    int? comboCount,
    bool? dailyBonusClaimed,
    List<PathProgressModel>? pathProgress,
    Map<String, bool>? unlockedMilestones,
  }) {
    return LevelSystemModel(
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

class PathProgressModel {
  final ProgressionPath path;
  final double progress;

  PathProgressModel({
    required this.path,
    required this.progress,
  });

  factory PathProgressModel.fromJson(Map<String, dynamic> json) {
    return PathProgressModel(
      path: ProgressionPath.values[(json['path'] as num?)?.toInt() ?? 0],
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'path': path.index,
    'progress': progress,
  };

  PathProgressEntity toEntity() {
    return PathProgressEntity(
      path: path,
      progress: progress,
    );
  }

  static PathProgressModel fromEntity(PathProgressEntity entity) {
    return PathProgressModel(
      path: entity.path,
      progress: entity.progress,
    );
  }
}