import 'package:paperclip2/models/interfaces/level_interface.dart';
import 'package:paperclip2/models/types/game_types.dart';
import 'dart:math' as math;

class Level implements ILevel {
  static const int _baseExperience = 100;
  static const double _experienceMultiplier = 1.5;

  int _level = 1;
  int _experience = 0;
  Set<UnlockableFeature> _unlockedFeatures = {};
  double _comboMultiplier = 1.0;
  int _comboCount = 0;
  DateTime? _lastProductionTime;

  @override
  int get level => _level;

  @override
  double get levelProgress => _experience / experienceForNextLevel;

  @override
  int get experienceForNextLevel => _level * 1000;

  @override
  bool hasUnlockedFeature(UnlockableFeature feature) {
    return _unlockedFeatures.contains(feature);
  }

  @override
  void addExperience(int amount) {
    _experience += amount;
    _checkLevelUp();
  }

  @override
  void addManualProduction() {
    _updateCombo();
    addExperience(10);
  }

  @override
  void addAutomaticProduction(int amount) {
    addExperience(amount ~/ 100);
  }

  @override
  void addAutoclipperPurchase() {
    addExperience(50);
  }

  @override
  void addStorageUpgrade() {
    addExperience(100);
  }

  @override
  void addMarketingUpgrade() {
    addExperience(75);
  }

  @override
  void addEfficiencyUpgrade() {
    addExperience(150);
  }

  @override
  void addQualityUpgrade() {
    addExperience(200);
  }

  void _checkLevelUp() {
    while (_experience >= experienceForNextLevel) {
      _experience -= experienceForNextLevel;
      _level++;
      _unlockNewFeatures();
    }
  }

  void _unlockNewFeatures() {
    final newFeatures = _getNewUnlockableFeatures();
    _unlockedFeatures.addAll(newFeatures);
  }

  Set<UnlockableFeature> _getNewUnlockableFeatures() {
    final features = <UnlockableFeature>{};
    
    if (_level >= 2) features.add(UnlockableFeature.AUTOCLIPPER);
    if (_level >= 3) features.add(UnlockableFeature.MARKET);
    if (_level >= 4) features.add(UnlockableFeature.UPGRADES);
    if (_level >= 5) features.add(UnlockableFeature.STORAGE);
    if (_level >= 6) features.add(UnlockableFeature.MARKETING);
    if (_level >= 7) features.add(UnlockableFeature.QUALITY);
    if (_level >= 8) features.add(UnlockableFeature.EFFICIENCY);
    
    return features;
  }

  void _updateCombo() {
    final now = DateTime.now();
    if (_lastProductionTime != null &&
        now.difference(_lastProductionTime!) < const Duration(seconds: 5)) {
      _comboCount++;
      _comboMultiplier = 1.0 + (_comboCount * 0.1);
    } else {
      _comboCount = 1;
      _comboMultiplier = 1.1;
    }
    _lastProductionTime = now;
  }

  double get currentComboMultiplier => _comboMultiplier;

  @override
  Map<String, dynamic> toJson() {
    return {
      'level': _level,
      'experience': _experience,
      'unlockedFeatures': _unlockedFeatures.map((f) => f.index).toList(),
    };
  }

  factory Level.fromJson(Map<String, dynamic> json) {
    final level = Level();
    level._level = json['level'] as int;
    level._experience = json['experience'] as int;
    level._unlockedFeatures = (json['unlockedFeatures'] as List)
        .map((index) => UnlockableFeature.values[index as int])
        .toSet();
    return level;
  }
} 