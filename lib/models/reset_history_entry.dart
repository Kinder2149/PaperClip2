/// Entrée dans l'historique des resets progression
/// 
/// Enregistre les détails d'un reset effectué : niveau avant reset,
/// gains en Quantum et Points Innovation, et timestamp.
class ResetHistoryEntry {
  final DateTime timestamp;
  final int levelBefore;
  final int quantumGained;
  final int innovationGained;
  
  const ResetHistoryEntry({
    required this.timestamp,
    required this.levelBefore,
    required this.quantumGained,
    required this.innovationGained,
  });
  
  /// Sérialisation JSON
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'levelBefore': levelBefore,
    'quantumGained': quantumGained,
    'innovationGained': innovationGained,
  };
  
  /// Désérialisation JSON
  factory ResetHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ResetHistoryEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      levelBefore: json['levelBefore'] as int,
      quantumGained: json['quantumGained'] as int,
      innovationGained: json['innovationGained'] as int,
    );
  }
  
  @override
  String toString() => 'ResetHistoryEntry(timestamp: $timestamp, levelBefore: $levelBefore, Q: $quantumGained, PI: $innovationGained)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResetHistoryEntry &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          levelBefore == other.levelBefore &&
          quantumGained == other.quantumGained &&
          innovationGained == other.innovationGained;
  
  @override
  int get hashCode =>
      timestamp.hashCode ^
      levelBefore.hashCode ^
      quantumGained.hashCode ^
      innovationGained.hashCode;
}
