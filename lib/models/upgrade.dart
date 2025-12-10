// lib/models/upgrade.dart
import 'dart:math';
import '../constants/game_config.dart'; // Importé depuis constants au lieu de models

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
        return level * GameConstants.EFFICIENCY_UPGRADE_MULTIPLIER;
      case 'speed':
        return level * GameConstants.SPEED_BONUS_PER_LEVEL;
      case 'bulk':
        return level * GameConstants.BULK_BONUS_PER_LEVEL;
      case 'storage':
        return level * GameConstants.STORAGE_UPGRADE_MULTIPLIER;
      case 'quality':
        return level * GameConstants.QUALITY_UPGRADE_BASE;
      case 'automation':
        return level * GameConstants.AUTOMATION_DISCOUNT_BASE;
      default:
        return 0.0;
    }
  }
  
  String getEffectDescription() {
    switch (id) {
      case 'efficiency':
        return "+${(GameConstants.EFFICIENCY_UPGRADE_MULTIPLIER * 100).toStringAsFixed(0)}% d'efficacité par niveau";
      case 'speed':
        return "+${(GameConstants.SPEED_BONUS_PER_LEVEL * 100).toStringAsFixed(0)}% de vitesse par niveau";
      case 'bulk':
        return "+${(GameConstants.BULK_BONUS_PER_LEVEL * 100).toStringAsFixed(0)}% de quantité par niveau";
      case 'storage':
        return "+${(GameConstants.STORAGE_UPGRADE_MULTIPLIER * 100).toStringAsFixed(0)}% de capacité de stockage par niveau";
      case 'quality':
        return "+${(GameConstants.QUALITY_UPGRADE_BASE * 100).toStringAsFixed(0)}% de qualité par niveau";
      case 'automation':
        return "-${(GameConstants.AUTOMATION_DISCOUNT_BASE * 100).toStringAsFixed(0)}% sur le coût des autoclippers par niveau";
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
