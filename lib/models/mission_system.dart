// lib/models/mission_system.dart
import 'dart:async'; // Ajouté

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
    return _getMissionTemplate(json['id'])..progress = json['progress'];
  }

  static Mission _getMissionTemplate(String id) {
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
    // ... autres templates de missions
      default:
        throw Exception('Mission template not found');
    }
  }
}

class MissionSystem {
  final List<Mission> _dailyMissions = [];
  final List<Mission> _weeklyMissions = [];
  final List<Mission> _achievements = [];

  Timer? _missionRefreshTimer;

  void initialize() {
    _generateDailyMissions();
    _startMissionRefreshTimer();
  }

  void _generateDailyMissions() {
    _dailyMissions.clear();
    // Ajouter de nouvelles missions quotidiennes
    _dailyMissions.add(Mission(
      id: 'daily_production',
      title: 'Production journalière',
      description: 'Produire 1000 trombones',
      type: MissionType.PRODUCE_PAPERCLIPS,
      target: 1000,
      experienceReward: 500,
    ));
    // ... autres missions
  }

  void _startMissionRefreshTimer() {
    _missionRefreshTimer?.cancel();
    _missionRefreshTimer = Timer.periodic(
      const Duration(hours: 24),
          (_) => _generateDailyMissions(),
    );
  }

  void updateMissions(MissionType type, double amount) {
    for (var mission in _dailyMissions) {
      if (mission.type == type && !mission.isCompleted) {
        mission.updateProgress(amount);
        if (mission.isCompleted) {
          onMissionCompleted?.call(mission);
        }
      }
    }
    // Vérifier également les missions hebdomadaires et achievements
  }

  Function(Mission mission)? onMissionCompleted;

  // Sauvegarde et chargement
  Map<String, dynamic> toJson() => {
    'dailyMissions': _dailyMissions.map((m) => m.toJson()).toList(),
    'weeklyMissions': _weeklyMissions.map((m) => m.toJson()).toList(),
    'achievements': _achievements.map((m) => m.toJson()).toList(),
  };

  void fromJson(Map<String, dynamic> json) {
    // ... logique de chargement
  }

  void dispose() {
    _missionRefreshTimer?.cancel();
  }
}