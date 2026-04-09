// lib/models/agent.dart

/// Types d'agents disponibles
enum AgentType {
  PRODUCTION,
  MARKET,
  RESOURCE,
  INNOVATION,
}

/// Statut d'un agent
enum AgentStatus {
  LOCKED,    // Pas encore débloqué via recherche
  UNLOCKED,  // Débloqué mais inactif
  ACTIVE,    // Actif et en cours d'exécution
}

/// Modèle d'agent IA autonome
/// 
/// Les agents automatisent des actions du joueur pendant une durée limitée.
/// Ils sont débloqués via l'arbre de recherche et consomment du Quantum.
class Agent {
  final String id;
  final String name;
  final String description;
  final AgentType type;
  final int activationCost; // Quantum par activation
  final int actionIntervalMinutes; // Intervalle entre actions (0 = passif)
  
  // État dynamique
  AgentStatus status;
  DateTime? activatedAt;
  DateTime? expiresAt;
  DateTime? lastActionAt;
  int totalActions;
  
  Agent({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.activationCost,
    required this.actionIntervalMinutes,
    this.status = AgentStatus.LOCKED,
    this.activatedAt,
    this.expiresAt,
    this.lastActionAt,
    this.totalActions = 0,
  });
  
  /// Vérifie si l'agent est actuellement actif
  bool get isActive {
    if (status != AgentStatus.ACTIVE) return false;
    if (expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt!);
  }
  
  /// Vérifie si l'agent est débloqué
  bool get isUnlocked => status != AgentStatus.LOCKED;
  
  /// Temps restant avant expiration
  Duration? get remainingTime {
    if (!isActive || expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }
  
  /// Sérialise l'agent en JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status.toString(),
    'activatedAt': activatedAt?.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'lastActionAt': lastActionAt?.toIso8601String(),
    'totalActions': totalActions,
  };
  
  /// Restaure l'état depuis JSON
  void fromJson(Map<String, dynamic> json) {
    status = AgentStatus.values.firstWhere(
      (e) => e.toString() == json['status'],
      orElse: () => AgentStatus.LOCKED,
    );
    activatedAt = json['activatedAt'] != null 
        ? DateTime.parse(json['activatedAt']) 
        : null;
    expiresAt = json['expiresAt'] != null 
        ? DateTime.parse(json['expiresAt']) 
        : null;
    lastActionAt = json['lastActionAt'] != null 
        ? DateTime.parse(json['lastActionAt']) 
        : null;
    totalActions = json['totalActions'] ?? 0;
  }
  
  /// Copie l'agent avec modifications
  Agent copyWith({
    AgentStatus? status,
    DateTime? activatedAt,
    DateTime? expiresAt,
    DateTime? lastActionAt,
    int? totalActions,
  }) {
    return Agent(
      id: id,
      name: name,
      description: description,
      type: type,
      activationCost: activationCost,
      actionIntervalMinutes: actionIntervalMinutes,
      status: status ?? this.status,
      activatedAt: activatedAt ?? this.activatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastActionAt: lastActionAt ?? this.lastActionAt,
      totalActions: totalActions ?? this.totalActions,
    );
  }
}
