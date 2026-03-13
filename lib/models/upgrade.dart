// lib/models/upgrade.dart
import 'dart:math';
import '../constants/game_config.dart'; // Importé depuis constants au lieu de models
import '../services/upgrades/upgrade_effects_calculator.dart';

class Upgrade {
  final String id;
  final String name;
  final String description;
  final double baseCost;
  final int maxLevel;
  final int requiredLevel;
  int level;
  
  Upgrade({
    required this.id,
    required this.name,
    required this.description,
    required this.baseCost,
    required this.maxLevel,
    this.requiredLevel = 1,
    this.level = 0,
  });
  
  bool get isMaxLevel => level >= maxLevel;
  
  double getCost() {
    return baseCost * pow(1.15, level);
  }
  
  double getEffectValue() {
    switch (id) {
      case 'efficiency':
        return UpgradeEffectsCalculator.efficiencyReduction(level: level);
      case 'speed':
        return UpgradeEffectsCalculator.speedMultiplier(level: level);
      case 'bulk':
        return UpgradeEffectsCalculator.bulkMultiplier(level: level);
      case 'storage':
        return UpgradeEffectsCalculator.metalStorageCapacity(storageLevel: level);
      case 'quality':
        return UpgradeEffectsCalculator.qualityMultiplier(level: level);
      case 'automation':
        return UpgradeEffectsCalculator.autoclipperDiscount(level: level);
      default:
        return 0.0;
    }
  }
  
  String getEffectDescription() {
    switch (id) {
      case 'efficiency':
        final reduction = UpgradeEffectsCalculator.efficiencyReduction(level: level);
        return "-${(reduction * 100).toStringAsFixed(0)}% métal par trombone";
      case 'speed':
        final mult = UpgradeEffectsCalculator.speedMultiplier(level: level);
        return "Vitesse: x${mult.toStringAsFixed(2)}";
      case 'bulk':
        final mult = UpgradeEffectsCalculator.bulkMultiplier(level: level);
        return "Production: x${mult.toStringAsFixed(2)}";
      case 'storage':
        final capacity = UpgradeEffectsCalculator.metalStorageCapacity(storageLevel: level);
        return "Capacité métal: ${capacity.toStringAsFixed(0)}";
      case 'quality':
        final mult = UpgradeEffectsCalculator.qualityMultiplier(level: level);
        return "Qualité: x${mult.toStringAsFixed(2)}";
      case 'automation':
        final discount = UpgradeEffectsCalculator.autoclipperDiscount(level: level);
        return "-${(discount * 100).toStringAsFixed(0)}% coût autoclippers";
      default:
        return "Aucun effet";
    }
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'level': level,
  };
  
  factory Upgrade.fromJson(Map<String, dynamic> json, Map<String, Upgrade> templates) {
    final String id = json['id'] as String;
    final template = templates[id];
    if (template == null) {
      throw Exception('Template not found for upgrade $id');
    }
    
    return Upgrade(
      id: template.id,
      name: template.name,
      description: template.description,
      baseCost: template.baseCost,
      maxLevel: template.maxLevel,
      requiredLevel: template.requiredLevel,
      level: json['level'] as int? ?? 0,
    );
  }
}
