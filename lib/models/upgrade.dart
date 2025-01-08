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
    this.maxLevel = 10,
  });

  // Getter pour obtenir le coût actuel de l'amélioration
  double get currentCost {
    return baseCost * (1.15 * level);
  }

  // Méthode pour réinitialiser l'amélioration
  void reset() {
    level = 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'baseCost': baseCost,
      'level': level,
      'maxLevel': maxLevel,
    };
  }

  static Upgrade fromJson(Map<String, dynamic> json) {
    return Upgrade(
      name: json['name'],
      description: json['description'],
      baseCost: json['baseCost'],
      level: json['level'],
      maxLevel: json['maxLevel'],
    );
  }
}