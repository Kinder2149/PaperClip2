import 'dart:math';
import 'package:flutter/material.dart';

class LevelSystem {
  // Variables privées sans pointeurs (Dart n'utilise pas de pointeurs)
  double _experience = 0;
  int _level = 1;

  final Map<int, String> _levelUnlocks = {
    2: "Débloque l'amélioration de vente automatique",
    5: "Débloque les objectifs quotidiens",
    10: "Débloque les missions spéciales",
    15: "Débloque les bonus de production",
    20: "Débloque le système de prestige",
  };

  // Getters
  double get experience => _experience;
  int get level => _level;
  double get experienceForNextLevel => (_level + 1) * (_level + 1) * 200;
  double get experienceProgress => _experience / experienceForNextLevel;
  Map<int, String> get levelUnlocks => _levelUnlocks;

  // Multiplicateurs basés sur le niveau
  double get productionMultiplier => 1 + (_level * 0.01);
  double get salesMultiplier => 1 + (_level * 0.005);

  // Callback pour le levelUp
  Function(int level, List<String> unlocks)? onLevelUp;

  // Gains d'XP
  void addManualProduction() {
    gainExperience(0.5);
  }

  void addAutomaticProduction(int amount) {
    gainExperience(0.25 * amount);
  }

  void addSale(int amount, double price) {
    gainExperience(1.0 * amount * (1 + price));
  }

  void addAutoclipperPurchase() {
    gainExperience(25);
  }

  void addUpgradePurchase(int upgradeLevel) {
    gainExperience(50.0 * upgradeLevel);
  }

  void gainExperience(double amount) {
    _experience += amount;
    _checkLevelUp();
  }

  void _checkLevelUp() {
    int newLevel = sqrt(_experience / 200).floor();
    if (newLevel > _level) {
      List<String> newUnlocks = [];
      for (int i = _level + 1; i <= newLevel; i++) {
        if (_levelUnlocks.containsKey(i)) {
          newUnlocks.add(_levelUnlocks[i]!);
        }
      }
      _level = newLevel;
      if (newUnlocks.isNotEmpty) {
        onLevelUp?.call(_level, newUnlocks);
      }
    }
  }

  // Sérialisation
  Map<String, dynamic> toJson() => {
    'experience': _experience,
    'level': _level,
  };

  void loadFromJson(Map<String, dynamic> json) {
    _experience = (json['experience'] as num?)?.toDouble() ?? 0;
    _level = (json['level'] as num?)?.toInt() ?? 1;
    _checkLevelUp();
  }
}