import 'package:flutter/foundation.dart';
import 'dart:math';
import 'game_config.dart';
import 'event_system.dart';

class LevelSystem extends ChangeNotifier {
  double _experience = 0.0;
  int _level = 1;
  int _currentPath = 0;
  double _xpMultiplier = 1.0;
  DateTime? _xpBoostEndTime;
  bool _isXPBoostActive = false;

  // Getters
  double get experience => _experience;
  int get level => _level;
  int get currentPath => _currentPath;
  double get xpMultiplier => _xpMultiplier;
  bool get isXPBoostActive => _isXPBoostActive;

  double getRequiredXP(int level) {
    return GameConstants.BASE_XP_REQUIREMENT *
        pow(GameConstants.XP_MULTIPLIER, level - 1);
  }

  void addExperience(double amount, ExperienceType type) {
    if (amount <= 0) return;

    // Appliquer les multiplicateurs
    double finalAmount = amount * _xpMultiplier;
    if (_isXPBoostActive && _xpBoostEndTime != null) {
      if (DateTime.now().isBefore(_xpBoostEndTime!)) {
        finalAmount *= 2;
      } else {
        _isXPBoostActive = false;
        _xpBoostEndTime = null;
      }
    }

    // Ajouter l'expérience
    _experience += finalAmount;

    // Vérifier le niveau
    double requiredXP = getRequiredXP(_level);
    while (_experience >= requiredXP) {
      _experience -= requiredXP;
      _level++;
      _onLevelUp();
      requiredXP = getRequiredXP(_level);
    }

    notifyListeners();
  }

  void _onLevelUp() {
    final unlockedFeatures = _checkUnlocks();
    EventManager.instance.addLevelUpEvent(_level, unlockedFeatures);
  }

  List<UnlockableFeature> _checkUnlocks() {
    List<UnlockableFeature> unlocked = [];

    if (_level == GameConstants.MARKET_UNLOCK_LEVEL) {
      unlocked.add(UnlockableFeature(
        'Marché',
        'Vous pouvez maintenant accéder au marché !',
        FeatureType.MARKET,
      ));
    }

    if (_level == GameConstants.UPGRADES_UNLOCK_LEVEL) {
      unlocked.add(UnlockableFeature(
        'Améliorations',
        'Les améliorations sont maintenant disponibles !',
        FeatureType.UPGRADES,
      ));
    }

    if (_level == GameConstants.AUTOMATION_UNLOCK_LEVEL) {
      unlocked.add(UnlockableFeature(
        'Automation',
        'Vous pouvez maintenant automatiser la production !',
        FeatureType.AUTOMATION,
      ));
    }

    return unlocked;
  }

  void activateXPBoost({Duration duration = const Duration(minutes: 30)}) {
    _isXPBoostActive = true;
    _xpBoostEndTime = DateTime.now().add(duration);
    
    EventManager.instance.addNotification(
      title: 'Boost XP Activé !',
      description: 'Expérience doublée pendant ${duration.inMinutes} minutes !',
      icon: Icons.star,
      priority: NotificationPriority.HIGH,
    );

    notifyListeners();
  }

  void setXPMultiplier(double multiplier) {
    _xpMultiplier = max(1.0, multiplier);
    notifyListeners();
  }

  void choosePath(int pathIndex) {
    _currentPath = pathIndex;
    notifyListeners();
  }

  double getProgressToNextLevel() {
    final requiredXP = getRequiredXP(_level);
    return _experience / requiredXP;
  }

  Map<String, dynamic> toJson() => {
    'experience': _experience,
    'level': _level,
    'currentPath': _currentPath,
    'xpMultiplier': _xpMultiplier,
    'isXPBoostActive': _isXPBoostActive,
    'xpBoostEndTime': _xpBoostEndTime?.toIso8601String(),
  };

  void loadFromJson(Map<String, dynamic> json) {
    _experience = (json['experience'] as num?)?.toDouble() ?? 0.0;
    _level = (json['level'] as num?)?.toInt() ?? 1;
    _currentPath = (json['currentPath'] as num?)?.toInt() ?? 0;
    _xpMultiplier = (json['xpMultiplier'] as num?)?.toDouble() ?? 1.0;
    _isXPBoostActive = json['isXPBoostActive'] as bool? ?? false;
    
    if (json['xpBoostEndTime'] != null) {
      _xpBoostEndTime = DateTime.parse(json['xpBoostEndTime'] as String);
      if (_xpBoostEndTime!.isBefore(DateTime.now())) {
        _isXPBoostActive = false;
        _xpBoostEndTime = null;
      }
    }

    notifyListeners();
  }
}

class MissionSystem extends ChangeNotifier {
  final Map<String, DateTime> _completedMissions = {};
  final Map<String, int> _missionProgress = {};

  Set<String> get completedMissions => Set.from(_completedMissions.keys);

  void completeMission(String missionId) {
    if (_completedMissions.containsKey(missionId)) return;

    _completedMissions[missionId] = DateTime.now();
    
    EventManager.instance.addNotification(
      title: 'Mission Accomplie !',
      description: 'Vous avez complété une nouvelle mission !',
      icon: Icons.assignment_turned_in,
      priority: NotificationPriority.HIGH,
    );

    notifyListeners();
  }

  void updateProgress(String missionId, int progress) {
    _missionProgress[missionId] = progress;
    notifyListeners();
  }

  int getProgress(String missionId) {
    return _missionProgress[missionId] ?? 0;
  }

  bool isMissionCompleted(String missionId) {
    return _completedMissions.containsKey(missionId);
  }

  DateTime? getMissionCompletionTime(String missionId) {
    return _completedMissions[missionId];
  }

  List<String> getCompletedMissionsForDay(DateTime date) {
    return _completedMissions.entries
        .where((entry) => _isSameDay(entry.value, date))
        .map((entry) => entry.key)
        .toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void resetDailyMissions() {
    final today = DateTime.now();
    _completedMissions.removeWhere((_, date) => _isSameDay(date, today));
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'completedMissions': _completedMissions.map(
      (key, value) => MapEntry(key, value.toIso8601String()),
    ),
    'missionProgress': _missionProgress,
  };

  void fromJson(Map<String, dynamic> json) {
    _completedMissions.clear();
    if (json['completedMissions'] != null) {
      final missions = json['completedMissions'] as Map<String, dynamic>;
      missions.forEach((key, value) {
        _completedMissions[key] = DateTime.parse(value as String);
      });
    }

    _missionProgress.clear();
    if (json['missionProgress'] != null) {
      final progress = json['missionProgress'] as Map<String, dynamic>;
      progress.forEach((key, value) {
        _missionProgress[key] = value as int;
      });
    }

    notifyListeners();
  }
} 