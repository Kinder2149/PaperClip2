import 'dart:async';

enum MissionType {
  PRODUCE_PAPERCLIPS,
  SELL_PAPERCLIPS,
  BUY_AUTOCLIPPERS,
  UPGRADE_PURCHASE,
  EARN_MONEY
}

class Mission {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final double target;
  final double experienceReward;
  double progress = 0;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.experienceReward,
  });

  bool get isCompleted => progress >= target;

  void updateProgress(double amount) {
    progress = (progress + amount).clamp(0, target);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'progress': progress,
  };

  factory Mission.fromJson(Map<String, dynamic> json) {
    return getMissionTemplate(json['id'])..progress = json['progress'];
  }

  static Mission getMissionTemplate(String id) {
    switch (id) {
      case 'daily_production':
        return Mission(
          id: 'daily_production',
          title: 'Production journalière',
          description: 'Produire 1000 trombones',
          type: MissionType.PRODUCE_PAPERCLIPS,
          target: 1000,
          experienceReward: 500,
        );
      case 'daily_sales':
        return Mission(
          id: 'daily_sales',
          title: 'Ventes journalières',
          description: 'Vendre 500 trombones',
          type: MissionType.SELL_PAPERCLIPS,
          target: 500,
          experienceReward: 300,
        );
      case 'weekly_autoclippers':
        return Mission(
          id: 'weekly_autoclippers',
          title: 'Expansion automatique',
          description: 'Acheter 10 autoclippeuses',
          type: MissionType.BUY_AUTOCLIPPERS,
          target: 10,
          experienceReward: 750,
        );
      default:
        throw Exception('Mission template not found');
    }
  }
}

class MissionSystem {
  List<Mission> dailyMissions = [];
  List<Mission> weeklyMissions = [];
  List<Mission> achievements = [];

  Timer? missionRefreshTimer;

  void initialize() {
    generateDailyMissions();
    generateWeeklyMissions();
    startMissionRefreshTimer();
  }

  void generateDailyMissions() {
    dailyMissions.clear();
    dailyMissions.addAll([
      Mission.getMissionTemplate('daily_production'),
      Mission.getMissionTemplate('daily_sales'),
    ]);
  }

  void generateWeeklyMissions() {
    weeklyMissions.clear();
    weeklyMissions.add(Mission.getMissionTemplate('weekly_autoclippers'));
  }

  void startMissionRefreshTimer() {
    missionRefreshTimer?.cancel();

    // Missions quotidiennes - réinitialisation toutes les 24h
    missionRefreshTimer = Timer.periodic(
      const Duration(hours: 24),
          (_) {
        generateDailyMissions();
        onMissionSystemRefresh?.call();
      },
    );
  }

  void updateMissions(MissionType type, double amount) {
    // Mettre à jour les missions quotidiennes
    for (var mission in dailyMissions) {
      if (mission.type == type && !mission.isCompleted) {
        mission.updateProgress(amount);
        if (mission.isCompleted) {
          onMissionCompleted?.call(mission);
        }
      }
    }

    // Mettre à jour les missions hebdomadaires
    for (var mission in weeklyMissions) {
      if (mission.type == type && !mission.isCompleted) {
        mission.updateProgress(amount);
        if (mission.isCompleted) {
          onMissionCompleted?.call(mission);
        }
      }
    }
  }

  Function(Mission mission)? onMissionCompleted;
  Function()? onMissionSystemRefresh;

  // Sauvegarde et chargement
  Map<String, dynamic> toJson() => {
    'dailyMissions': dailyMissions.map((m) => m.toJson()).toList(),
    'weeklyMissions': weeklyMissions.map((m) => m.toJson()).toList(),
  };

  void fromJson(Map<String, dynamic> json) {
    if (json['dailyMissions'] != null) {
      dailyMissions = (json['dailyMissions'] as List)
          .map((missionJson) => Mission.fromJson(missionJson))
          .toList();
    }

    if (json['weeklyMissions'] != null) {
      weeklyMissions = (json['weeklyMissions'] as List)
          .map((missionJson) => Mission.fromJson(missionJson))
          .toList();
    }
  }

  void dispose() {
    missionRefreshTimer?.cancel();
  }
}