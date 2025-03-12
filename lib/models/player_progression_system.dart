import 'package:flutter/foundation.dart';
import 'dart:math';
import 'game_config.dart';
import 'event_system.dart';

/// Classe pour représenter une mission ou un objectif
class Mission {
  final String id;
  final String title;
  final String description;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> rewards;
  bool isCompleted;
  bool isActive;
  double progress;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.requirements,
    required this.rewards,
    this.isCompleted = false,
    this.isActive = true,
    this.progress = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'isCompleted': isCompleted,
    'isActive': isActive,
    'progress': progress,
  };

  factory Mission.fromJson(Map<String, dynamic> json, Mission template) {
    template.isCompleted = json['isCompleted'] ?? false;
    template.isActive = json['isActive'] ?? true;
    template.progress = (json['progress'] as num?)?.toDouble() ?? 0.0;
    return template;
  }
}

/// Classe pour gérer le système de niveau
class LevelSystem extends ChangeNotifier {
  int _level = 1;
  int _experience = 0;
  int _experienceToNextLevel = 100;
  Function? _onLevelUp;

  // Getters
  int get level => _level;
  int get experience => _experience;
  int get experienceToNextLevel => _experienceToNextLevel;
  double get progressToNextLevel => _experience / _experienceToNextLevel;

  // Setter pour le callback de niveau supérieur
  set onLevelUp(Function? callback) {
    _onLevelUp = callback;
  }

  // Ajouter de l'expérience
  void addExperience(int amount) {
    if (amount <= 0) return;

    _experience += amount;
    
    // Vérifier si le joueur a gagné un niveau
    while (_experience >= _experienceToNextLevel) {
      _experience -= _experienceToNextLevel;
      _level++;
      _experienceToNextLevel = calculateExperienceForLevel(_level + 1);
      
      // Appeler le callback de niveau supérieur
      if (_onLevelUp != null) {
        _onLevelUp!(_level);
      }
    }
    
    notifyListeners();
  }

  // Calculer l'expérience nécessaire pour un niveau donné
  int calculateExperienceForLevel(int targetLevel) {
    return (100 * pow(1.5, targetLevel - 1)).round();
  }

  // Réinitialiser le système de niveau
  void reset() {
    _level = 1;
    _experience = 0;
    _experienceToNextLevel = 100;
    notifyListeners();
  }

  // Sérialisation
  Map<String, dynamic> toJson() => {
    'level': _level,
    'experience': _experience,
    'experienceToNextLevel': _experienceToNextLevel,
  };

  // Désérialisation
  void fromJson(Map<String, dynamic> json) {
    _level = (json['level'] as num?)?.toInt() ?? 1;
    _experience = (json['experience'] as num?)?.toInt() ?? 0;
    _experienceToNextLevel = (json['experienceToNextLevel'] as num?)?.toInt() ?? 100;
    notifyListeners();
  }
}

/// Classe pour gérer le système de missions
class MissionSystem extends ChangeNotifier {
  final List<Mission> _missions = [];
  final List<Mission> _completedMissions = [];
  final List<Mission> _activeMissions = [];

  // Getters
  List<Mission> get missions => _missions;
  List<Mission> get completedMissions => _completedMissions;
  List<Mission> get activeMissions => _activeMissions.where((m) => m.isActive).toList();

  // Constructeur
  MissionSystem() {
    _initialize();
  }

  void _initialize() {
    _createMissions();
    _updateActiveMissions();
  }

  void _createMissions() {
    _missions.clear();
    
    // Missions de production
    _addMission(Mission(
      id: 'produce_first_paperclip',
      title: 'Premier Trombone',
      description: 'Produire votre premier trombone',
      requirements: {'paperclips_produced': 1},
      rewards: {'experience': 10},
    ));
    
    _addMission(Mission(
      id: 'produce_100_paperclips',
      title: 'Production en Série',
      description: 'Produire 100 trombones',
      requirements: {'paperclips_produced': 100},
      rewards: {'experience': 50, 'money': 50},
    ));
    
    _addMission(Mission(
      id: 'produce_1000_paperclips',
      title: 'Production de Masse',
      description: 'Produire 1000 trombones',
      requirements: {'paperclips_produced': 1000},
      rewards: {'experience': 200, 'money': 200},
    ));
    
    // Missions de vente
    _addMission(Mission(
      id: 'first_sale',
      title: 'Première Vente',
      description: 'Vendre votre premier trombone',
      requirements: {'paperclips_sold': 1},
      rewards: {'experience': 10},
    ));
    
    _addMission(Mission(
      id: 'sell_100_paperclips',
      title: 'Vendeur Débutant',
      description: 'Vendre 100 trombones',
      requirements: {'paperclips_sold': 100},
      rewards: {'experience': 50, 'money': 50},
    ));
    
    // Missions d'amélioration
    _addMission(Mission(
      id: 'first_upgrade',
      title: 'Première Amélioration',
      description: 'Acheter votre première amélioration',
      requirements: {'upgrades_purchased': 1},
      rewards: {'experience': 20},
    ));
    
    _addMission(Mission(
      id: 'reach_level_5',
      title: 'Progression',
      description: 'Atteindre le niveau 5',
      requirements: {'player_level': 5},
      rewards: {'experience': 100, 'money': 100},
    ));
    
    _addMission(Mission(
      id: 'reach_level_10',
      title: 'Entrepreneur',
      description: 'Atteindre le niveau 10',
      requirements: {'player_level': 10},
      rewards: {'experience': 200, 'money': 200},
    ));
    
    // Missions économiques
    _addMission(Mission(
      id: 'earn_1000_money',
      title: 'Premier Millier',
      description: 'Gagner 1000 dollars au total',
      requirements: {'total_money_earned': 1000},
      rewards: {'experience': 100},
    ));
  }

  void _addMission(Mission mission) {
    _missions.add(mission);
  }

  // Mettre à jour les missions actives
  void _updateActiveMissions() {
    _activeMissions.clear();
    
    // Ajouter jusqu'à 3 missions non complétées
    for (var mission in _missions) {
      if (!mission.isCompleted && _activeMissions.length < 3) {
        _activeMissions.add(mission);
      }
    }
  }

  // Mettre à jour la progression d'une mission
  void updateMissionProgress(String missionId, double progress) {
    Mission? mission = _findMission(missionId);
    if (mission == null || mission.isCompleted) return;
    
    mission.progress = progress.clamp(0.0, 1.0);
    
    if (mission.progress >= 1.0) {
      completeMission(missionId);
    }
    
    notifyListeners();
  }

  // Compléter une mission
  Map<String, dynamic> completeMission(String missionId) {
    Mission? mission = _findMission(missionId);
    if (mission == null || mission.isCompleted) return {};
    
    mission.isCompleted = true;
    mission.isActive = false;
    mission.progress = 1.0;
    
    _completedMissions.add(mission);
    _updateActiveMissions();
    
    notifyListeners();
    return mission.rewards;
  }

  // Vérifier la progression des missions en fonction des statistiques du joueur
  void checkMissionsProgress(Map<String, dynamic> playerStats) {
    for (var mission in _activeMissions) {
      if (mission.isCompleted) continue;
      
      double progress = 0.0;
      
      // Vérifier chaque exigence de la mission
      for (var req in mission.requirements.entries) {
        if (playerStats.containsKey(req.key)) {
          double currentValue = (playerStats[req.key] is int)
              ? playerStats[req.key].toDouble()
              : (playerStats[req.key] as num).toDouble();
          
          double targetValue = (req.value is int)
              ? req.value.toDouble()
              : (req.value as num).toDouble();
          
          double reqProgress = (currentValue / targetValue).clamp(0.0, 1.0);
          progress = max(progress, reqProgress);
        }
      }
      
      mission.progress = progress;
      
      if (mission.progress >= 1.0) {
        completeMission(mission.id);
      }
    }
    
    notifyListeners();
  }

  // Trouver une mission par ID
  Mission? _findMission(String id) {
    return _missions.firstWhere((m) => m.id == id, orElse: () => throw Exception('Mission not found: $id'));
  }

  // Réinitialiser le système de missions
  void reset() {
    for (var mission in _missions) {
      mission.isCompleted = false;
      mission.isActive = true;
      mission.progress = 0.0;
    }
    
    _completedMissions.clear();
    _updateActiveMissions();
    
    notifyListeners();
  }

  // Sérialisation
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    for (var mission in _missions) {
      json[mission.id] = mission.toJson();
    }
    return json;
  }

  // Désérialisation
  void fromJson(Map<String, dynamic> json) {
    // Réinitialiser d'abord
    for (var mission in _missions) {
      mission.isCompleted = false;
      mission.isActive = true;
      mission.progress = 0.0;
    }
    
    // Charger les données sauvegardées
    for (var entry in json.entries) {
      try {
        Mission? mission = _findMission(entry.key);
        if (mission != null && entry.value is Map<String, dynamic>) {
          mission.isCompleted = entry.value['isCompleted'] ?? false;
          mission.isActive = entry.value['isActive'] ?? true;
          mission.progress = (entry.value['progress'] as num?)?.toDouble() ?? 0.0;
          
          if (mission.isCompleted) {
            _completedMissions.add(mission);
          }
        }
      } catch (e) {
        // Ignorer les missions qui n'existent plus
      }
    }
    
    _updateActiveMissions();
    notifyListeners();
  }
}

/// Gestionnaire centralisé pour la progression du joueur
class PlayerProgressionSystem extends ChangeNotifier {
  // Sous-systèmes
  final LevelSystem _levelSystem = LevelSystem();
  final MissionSystem _missionSystem = MissionSystem();
  
  // Statistiques du joueur
  final Map<String, dynamic> _playerStats = {
    'paperclips_produced': 0,
    'paperclips_sold': 0,
    'total_money_earned': 0.0,
    'upgrades_purchased': 0,
    'play_time_seconds': 0,
    'market_transactions': 0,
    'metal_purchased': 0.0,
    'metal_used': 0.0,
  };
  
  // Getters
  LevelSystem get levelSystem => _levelSystem;
  MissionSystem get missionSystem => _missionSystem;
  Map<String, dynamic> get playerStats => _playerStats;
  
  // Constructeur
  PlayerProgressionSystem() {
    _initialize();
  }
  
  void _initialize() {
    // Configurer le callback de niveau supérieur
    _levelSystem.onLevelUp = _handleLevelUp;
  }
  
  // Gérer le niveau supérieur
  void _handleLevelUp(int newLevel) {
    // Mettre à jour les statistiques
    _playerStats['player_level'] = newLevel;
    
    // Vérifier les missions
    _missionSystem.checkMissionsProgress(_playerStats);
    
    // Notifier les changements
    notifyListeners();
  }
  
  // Mettre à jour une statistique
  void updateStat(String stat, dynamic value) {
    if (!_playerStats.containsKey(stat)) {
      _playerStats[stat] = value;
    } else {
      if (value is num && _playerStats[stat] is num) {
        _playerStats[stat] = (_playerStats[stat] as num) + value;
      } else {
        _playerStats[stat] = value;
      }
    }
    
    // Vérifier les missions
    _missionSystem.checkMissionsProgress(_playerStats);
    
    notifyListeners();
  }
  
  // Obtenir une statistique
  dynamic getStat(String stat) {
    return _playerStats[stat];
  }
  
  // Ajouter de l'expérience
  void addExperience(int amount) {
    _levelSystem.addExperience(amount);
  }
  
  // Récompenser le joueur pour une mission complétée
  void rewardPlayer(Map<String, dynamic> rewards) {
    if (rewards.containsKey('experience')) {
      addExperience(rewards['experience']);
    }
    
    // Les autres récompenses (argent, etc.) seront gérées par le GameState
    
    notifyListeners();
  }
  
  // Réinitialiser le système de progression
  void reset() {
    _levelSystem.reset();
    _missionSystem.reset();
    
    // Réinitialiser les statistiques
    for (var key in _playerStats.keys) {
      if (_playerStats[key] is num) {
        _playerStats[key] = 0;
      } else if (_playerStats[key] is bool) {
        _playerStats[key] = false;
      }
    }
    
    notifyListeners();
  }
  
  // Sérialisation
  Map<String, dynamic> toJson() => {
    'levelSystem': _levelSystem.toJson(),
    'missionSystem': _missionSystem.toJson(),
    'playerStats': _playerStats,
  };
  
  // Désérialisation
  void fromJson(Map<String, dynamic> json) {
    if (json.containsKey('levelSystem')) {
      final levelData = Map<String, dynamic>.from(json['levelSystem'] as Map);
      _levelSystem.fromJson(levelData);
    }
    
    if (json.containsKey('missionSystem')) {
      final missionData = Map<String, dynamic>.from(json['missionSystem'] as Map);
      _missionSystem.fromJson(missionData);
    }
    
    if (json.containsKey('playerStats')) {
      _playerStats.clear();
      final statsData = Map<String, dynamic>.from(json['playerStats'] as Map);
      statsData.forEach((key, value) {
        _playerStats[key] = value;
      });
    }
    
    notifyListeners();
  }
} 