// lib/domain/entities/upgrade_entity.dart
import 'dart:math';

class UpgradeEntity {
  final String id;
  final String name;
  final String description;
  final int level;
  final double baseCost;
  final double costMultiplier;
  final int maxLevel;
  final int? requiredLevel;
  final Map<String, dynamic>? requirements;

  UpgradeEntity({
    required this.id,
    required this.name,
    required this.description,
    this.level = 0,
    required this.baseCost,
    this.costMultiplier = 1.5,
    this.maxLevel = 10,
    this.requiredLevel,
    this.requirements,
  });

  double getCost() {
    if (level >= maxLevel) return double.infinity;
    return baseCost * pow(costMultiplier, level);
  }

  bool canBePurchased(double money, int playerLevel) {
    if (level >= maxLevel) return false;
    if (requiredLevel != null && playerLevel < requiredLevel!) return false;
    if (requirements != null) {
      for (var req in requirements!.entries) {
        if (req.value is int && req.value > level) return false;
      }
    }
    return money >= getCost();
  }

  static UpgradeEntity getTemplate(String id) {
    switch (id) {
      case 'efficiency':
        return UpgradeEntity(
          id: 'efficiency',
          name: 'Efficacité',
          description: 'Réduit la consommation de métal',
          baseCost: 100,
          requiredLevel: 5,
          maxLevel: 8,
        );
      case 'speed':
        return UpgradeEntity(
          id: 'speed',
          name: 'Vitesse',
          description: 'Augmente la vitesse de production',
          baseCost: 150,
          requiredLevel: 5,
        );
      default:
        throw Exception('Unknown upgrade ID: $id');
    }
  }

  UpgradeEntity copyWith({
    String? id,
    String? name,
    String? description,
    int? level,
    double? baseCost,
    double? costMultiplier,
    int? maxLevel,
    int? requiredLevel,
    Map<String, dynamic>? requirements,
  }) {
    return UpgradeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      level: level ?? this.level,
      baseCost: baseCost ?? this.baseCost,
      costMultiplier: costMultiplier ?? this.costMultiplier,
      maxLevel: maxLevel ?? this.maxLevel,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      requirements: requirements ?? this.requirements,
    );
  }
}