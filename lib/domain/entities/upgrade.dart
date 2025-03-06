import 'package:flutter/material.dart';

class Upgrade {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final IconData icon;
  final double baseCost;
  final double costMultiplier;
  final int maxLevel;
  final int currentLevel;
  final double effectValue;
  final double effectMultiplier;
  final VoidCallback onPurchase;

  const Upgrade({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.icon,
    required this.baseCost,
    required this.costMultiplier,
    required this.maxLevel,
    required this.currentLevel,
    required this.effectValue,
    required this.effectMultiplier,
    required this.onPurchase,
  });

  double get cost {
    if (currentLevel >= maxLevel) return double.infinity;
    return baseCost * pow(costMultiplier, currentLevel);
  }

  double get progress => currentLevel / maxLevel;

  bool get isMaxed => currentLevel >= maxLevel;

  bool get canAfford {
    // Cette propriété sera calculée en fonction de l'état du joueur
    // Elle sera injectée par le ViewModel
    return false;
  }

  factory Upgrade.fromJson(Map<String, dynamic> json) {
    return Upgrade(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      baseCost: (json['baseCost'] as num).toDouble(),
      costMultiplier: (json['costMultiplier'] as num).toDouble(),
      maxLevel: json['maxLevel'] as int,
      currentLevel: json['currentLevel'] as int,
      effectValue: (json['effectValue'] as num).toDouble(),
      effectMultiplier: (json['effectMultiplier'] as num).toDouble(),
      onPurchase: () {}, // Cette fonction sera injectée par le ViewModel
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'baseCost': baseCost,
      'costMultiplier': costMultiplier,
      'maxLevel': maxLevel,
      'currentLevel': currentLevel,
      'effectValue': effectValue,
      'effectMultiplier': effectMultiplier,
    };
  }

  Upgrade copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? description,
    IconData? icon,
    double? baseCost,
    double? costMultiplier,
    int? maxLevel,
    int? currentLevel,
    double? effectValue,
    double? effectMultiplier,
    VoidCallback? onPurchase,
  }) {
    return Upgrade(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      baseCost: baseCost ?? this.baseCost,
      costMultiplier: costMultiplier ?? this.costMultiplier,
      maxLevel: maxLevel ?? this.maxLevel,
      currentLevel: currentLevel ?? this.currentLevel,
      effectValue: effectValue ?? this.effectValue,
      effectMultiplier: effectMultiplier ?? this.effectMultiplier,
      onPurchase: onPurchase ?? this.onPurchase,
    );
  }
} 