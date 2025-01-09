import 'dart:math';
import 'package:flutter/material.dart';

class LevelSystem {
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
  double get experienceForNextLevel => (_level + 1) * (_level + 1) * 200; // Augmenté
  double get experienceProgress => _experience / experienceForNextLevel;

  // Ajouté : Getter pour levelUnlocks
  Map<int, String> get levelUnlocks => _levelUnlocks;

  // Multiplicateurs basés sur le niveau
  double get productionMultiplier => 1 + (_level * 0.01); // Réduit à +1% par niveau
  double get salesMultiplier => 1 + (_level * 0.005); // Réduit à +0.5% par niveau

  // Gains d'XP
  void addManualProduction() {
    gainExperience(0.5); // Réduit
  }

  void addAutomaticProduction(int amount) {
    gainExperience(0.25 * amount); // Réduit
  }

  void addSale(int amount, double price) {
    // Plus le prix est élevé, plus on gagne d'XP
    gainExperience(1.0 * amount * (1 + price)); // Réduit
  }

  void addAutoclipperPurchase() {
    gainExperience(25); // Réduit
  }

  void addUpgradePurchase(int upgradeLevel) {
    gainExperience(50.0 * upgradeLevel); // Réduit
  }

  void gainExperience(double amount) {
    _experience += amount;
    _checkLevelUp();
  }

  void _checkLevelUp() {
    int newLevel = sqrt(_experience / 200).floor(); // Augmenté
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

  Function(int level, List<String> unlocks)? onLevelUp;

  Map<String, dynamic> toJson() => {
    'experience': _experience,
    'level': _level,
  };

  void fromJson(Map<String, dynamic> json) {
    _experience = json['experience'] ?? 0;
    _level = json['level'] ?? 1;
    _checkLevelUp();
  }
}