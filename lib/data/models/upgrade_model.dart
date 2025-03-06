// lib/data/models/upgrade_model.dart
import 'package:paperclip2/domain/entities/upgrade_entity.dart';
import 'dart:math';

class UpgradeModel {
  final String id;
  final String name;
  final String description;
  final int level;
  final double baseCost;
  final double costMultiplier;
  final int maxLevel;
  final int? requiredLevel;

  UpgradeModel({
    required this.id,
    required this.name,
    required this.description,
    this.level = 0,
    required this.baseCost,
    this.costMultiplier = 1.5,
    this.maxLevel = 10,
    this.requiredLevel,
  });

  factory UpgradeModel.fromJson(Map<String, dynamic> json) {
    return UpgradeModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Upgrade',
      description: json['description'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 0,
      baseCost: (json['baseCost'] as num?)?.toDouble() ?? 100.0,
      costMultiplier: (json['costMultiplier'] as num?)?.toDouble() ?? 1.5,
      maxLevel: (json['maxLevel'] as num?)?.toInt() ?? 10,
      requiredLevel: (json['requiredLevel'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'level': level,
    'baseCost': baseCost,
    'costMultiplier': costMultiplier,
    'maxLevel': maxLevel,
    'requiredLevel': requiredLevel,
  };

  UpgradeEntity toEntity() {
    return UpgradeEntity(
      id: id,
      name: name,
      description: description,
      level: level,
      baseCost: baseCost,
      costMultiplier: costMultiplier,
      maxLevel: maxLevel,
      requiredLevel: requiredLevel,
    );
  }

  static UpgradeModel fromEntity(UpgradeEntity entity) {
    return UpgradeModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      level: entity.level,
      baseCost: entity.baseCost,
      costMultiplier: entity.costMultiplier,
      maxLevel: entity.maxLevel,
      requiredLevel: entity.requiredLevel,
    );
  }

  double getCost() {
    if (level >= maxLevel) return double.infinity;
    return baseCost * pow(costMultiplier, level);
  }
}