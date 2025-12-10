// lib/models/mission.dart
import 'package:flutter/foundation.dart';
import 'json_loadable.dart';
import '../constants/game_config.dart'; // Import de l'énumération MissionType

// MissionType est maintenant défini dans constants/game_config.dart

/// Représente une mission individuelle
class Mission {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final double target;
  double progress;
  bool completed;
  final Map<String, dynamic> rewards;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    this.progress = 0.0,
    this.completed = false,
    required this.rewards,
  });

  double get progressPercent => (progress / target) * 100;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'target': target,
      'progress': progress,
      'completed': completed,
      'rewards': rewards,
    };
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: MissionType.values[json['type'] as int],
      target: (json['target'] as num).toDouble(),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      completed: json['completed'] as bool? ?? false,
      rewards: json['rewards'] as Map<String, dynamic>,
    );
  }
}

/// Système de gestion des missions
class MissionSystem extends ChangeNotifier implements JsonLoadable {
  List<Mission> _missions = [];
  List<Mission> _completedMissions = [];

  List<Mission> get activeMissions => _missions.where((m) => !m.completed).toList();
  List<Mission> get completedMissions => _completedMissions;

  void initializeMissions() {
    // Initialisation des missions par défaut
    _missions = [
      Mission(
        id: 'mission1',
        title: 'Produire 1000 trombones',
        description: 'Produisez votre premier lot de trombones',
        type: MissionType.PRODUCE_PAPERCLIPS,
        target: 1000,
        rewards: {'money': 100.0},
      ),
      Mission(
        id: 'mission2',
        title: 'Acheter 3 autoclippeuses',
        description: 'Automatisez votre production',
        type: MissionType.BUY_AUTOCLIPPERS,
        target: 3,
        rewards: {'money': 50.0},
      ),
    ];
    notifyListeners();
  }

  void updateMissions(MissionType type, double amount) {
    bool updated = false;

    for (var mission in _missions) {
      if (!mission.completed && mission.type == type) {
        mission.progress += amount;
        
        // Vérifier si la mission est terminée
        if (mission.progress >= mission.target && !mission.completed) {
          mission.completed = true;
          _completedMissions.add(mission);
          updated = true;
        }
      }
    }

    if (updated) {
      notifyListeners();
    }
  }

  void claimReward(String missionId) {
    var mission = _missions.firstWhere((m) => m.id == missionId && m.completed);
    // La logique d'application des récompenses sera gérée par GameState
    // Ici, on marque juste la mission comme ayant sa récompense réclamée
    
    notifyListeners();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'missions': _missions.map((m) => m.toJson()).toList(),
      'completedMissions': _completedMissions.map((m) => m.toJson()).toList(),
    };
  }

  @override
  void fromJson(Map<String, dynamic> json) {
    if (json['missions'] != null) {
      _missions = (json['missions'] as List)
          .map((m) => Mission.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    
    if (json['completedMissions'] != null) {
      _completedMissions = (json['completedMissions'] as List)
          .map((m) => Mission.fromJson(m as Map<String, dynamic>))
          .toList();
    }
  }

  // Réinitialisation des missions
  void reset() {
    _missions.clear();
    _completedMissions.clear();
    initializeMissions();
  }
}
