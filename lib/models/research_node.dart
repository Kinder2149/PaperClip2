// lib/models/research_node.dart

/// Catégories de recherches dans l'arbre
enum ResearchCategory {
  PRODUCTION,
  MARKET,
  RESOURCES,
  AGENTS,
  META,
}

/// Types d'effets qu'une recherche peut avoir
enum ResearchEffectType {
  PASSIVE_BONUS,        // Bonus permanent (ex: +10% prod)
  UNLOCK_AGENT,         // Débloque un agent
  UNLOCK_SLOT,          // Débloque slot agent
  UNLOCK_FEATURE,       // Débloque une mécanique
  MODIFY_RESET,         // Modifie gains reset
}

/// Effet d'une recherche
class ResearchEffect {
  final ResearchEffectType type;
  final Map<String, dynamic> params;
  
  ResearchEffect({
    required this.type,
    required this.params,
  });
  
  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'params': params,
  };
  
  factory ResearchEffect.fromJson(Map<String, dynamic> json) {
    return ResearchEffect(
      type: ResearchEffectType.values.firstWhere(
        (e) => e.toString() == json['type']
      ),
      params: Map<String, dynamic>.from(json['params']),
    );
  }
}

/// Nœud de recherche dans l'arbre
class ResearchNode {
  final String id;
  final String name;
  final String description;
  final ResearchCategory category;
  final int innovationPointsCost;
  final int quantumCost;
  final int moneyCost;
  
  // Dépendances
  final List<String> prerequisites;
  final List<String> exclusiveWith;
  
  // Effet
  final ResearchEffect effect;
  
  // État
  bool isUnlocked;
  bool isResearched;
  DateTime? researchedAt;
  
  ResearchNode({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.innovationPointsCost,
    this.quantumCost = 0,
    this.moneyCost = 0,
    this.prerequisites = const [],
    this.exclusiveWith = const [],
    required this.effect,
    this.isUnlocked = false,
    this.isResearched = false,
    this.researchedAt,
  });
  
  bool get isAvailable => isUnlocked && !isResearched;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category.toString(),
    'innovationPointsCost': innovationPointsCost,
    'quantumCost': quantumCost,
    'moneyCost': moneyCost,
    'prerequisites': prerequisites,
    'exclusiveWith': exclusiveWith,
    'effect': effect.toJson(),
    'isUnlocked': isUnlocked,
    'isResearched': isResearched,
    'researchedAt': researchedAt?.toIso8601String(),
  };
  
  factory ResearchNode.fromJson(Map<String, dynamic> json) {
    return ResearchNode(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: ResearchCategory.values.firstWhere(
        (e) => e.toString() == json['category']
      ),
      innovationPointsCost: json['innovationPointsCost'],
      quantumCost: json['quantumCost'] ?? 0,
      moneyCost: json['moneyCost'] ?? 0,
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      exclusiveWith: List<String>.from(json['exclusiveWith'] ?? []),
      effect: ResearchEffect.fromJson(json['effect']),
      isUnlocked: json['isUnlocked'] ?? false,
      isResearched: json['isResearched'] ?? false,
      researchedAt: json['researchedAt'] != null
          ? DateTime.parse(json['researchedAt'])
          : null,
    );
  }
}
