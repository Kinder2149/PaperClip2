// lib/models/upgrade.dart
class Upgrade {
  final String name;
  final String description;
  final double baseCost;
  int level;
  final int maxLevel;

  Upgrade({
    required this.name,
    required this.description,
    required this.baseCost,
    this.level = 0,
    required this.maxLevel,
  });

  double get currentCost => baseCost * (1.5 * level);

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'baseCost': baseCost,
    'level': level,
    'maxLevel': maxLevel,
  };

  factory Upgrade.fromJson(Map<String, dynamic> json) {
    return Upgrade(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      baseCost: (json['baseCost'] ?? 0.0).toDouble(),
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 1,
    );
  }
}