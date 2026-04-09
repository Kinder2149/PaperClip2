import 'package:flutter/foundation.dart';

/// Manager pour les ressources rares (Quantum & Points Innovation)
/// 
/// Gère les ressources de méta-progression qui persistent après les resets :
/// - Quantum : Monnaie stratégique pour débloquer agents et capacités majeures
/// - Points Innovation : Monnaie pour l'arbre de recherche
/// 
/// Ce manager track également les statistiques lifetime (total gagné, total dépensé)
/// pour chaque ressource rare.
class RareResourcesManager extends ChangeNotifier {
  // ============================================================================
  // État des ressources rares
  // ============================================================================
  
  /// Quantum disponible (solde actuel)
  int _quantum = 0;
  
  /// Points Innovation disponibles (solde actuel)
  int _pointsInnovation = 0;
  
  /// Nombre total de resets effectués
  int _totalResets = 0;
  
  /// Historique des resets effectués
  final List<ResetRecord> _resetHistory = [];
  
  // ============================================================================
  // Statistiques lifetime
  // ============================================================================
  
  /// Total de Quantum gagné depuis la création de l'entreprise
  int _quantumLifetime = 0;
  
  /// Total de Points Innovation gagnés depuis la création de l'entreprise
  int _innovationPointsLifetime = 0;
  
  /// Total de Quantum dépensé depuis la création de l'entreprise
  int _quantumSpent = 0;
  
  /// Total de Points Innovation dépensés depuis la création de l'entreprise
  int _innovationPointsSpent = 0;
  
  // ============================================================================
  // Getters
  // ============================================================================
  
  /// Quantum disponible
  int get quantum => _quantum;
  
  /// Points Innovation disponibles
  int get pointsInnovation => _pointsInnovation;
  
  /// Nombre total de resets effectués
  int get totalResets => _totalResets;
  
  /// Total de Quantum gagné (lifetime)
  int get quantumLifetime => _quantumLifetime;
  
  /// Total de Points Innovation gagnés (lifetime)
  int get innovationPointsLifetime => _innovationPointsLifetime;
  
  /// Total de Quantum dépensé (lifetime)
  int get quantumSpent => _quantumSpent;
  
  /// Total de Points Innovation dépensés (lifetime)
  int get innovationPointsSpent => _innovationPointsSpent;
  
  /// Historique des resets
  List<ResetRecord> get resetHistory => List.unmodifiable(_resetHistory);
  
  /// Dernier reset effectué
  ResetRecord? get lastReset => _resetHistory.isNotEmpty ? _resetHistory.last : null;
  
  // ============================================================================
  // Méthodes Quantum
  // ============================================================================
  
  /// Ajoute du Quantum au solde actuel
  /// 
  /// [amount] : Quantité de Quantum à ajouter (doit être > 0)
  /// [source] : Source optionnelle du gain (pour logging)
  void addQuantum(int amount, {String? source}) {
    if (amount <= 0) return;
    
    _quantum += amount;
    _quantumLifetime += amount;
    
    if (kDebugMode) {
      print('[RareResourcesManager] Quantum gained: +$amount (source: ${source ?? "unknown"})');
    }
    
    notifyListeners();
  }
  
  /// Vérifie si le joueur peut dépenser une quantité de Quantum
  /// 
  /// [amount] : Quantité à vérifier
  /// Retourne true si le solde est suffisant et amount > 0
  bool canSpendQuantum(int amount) {
    return _quantum >= amount && amount > 0;
  }
  
  /// Dépense du Quantum
  /// 
  /// [amount] : Quantité de Quantum à dépenser
  /// [purpose] : But optionnel de la dépense (pour logging)
  /// Retourne true si la dépense a réussi, false si solde insuffisant
  bool spendQuantum(int amount, {String? purpose}) {
    if (!canSpendQuantum(amount)) return false;
    
    _quantum -= amount;
    _quantumSpent += amount;
    
    if (kDebugMode) {
      print('[RareResourcesManager] Quantum spent: -$amount (purpose: ${purpose ?? "unknown"})');
    }
    
    notifyListeners();
    return true;
  }
  
  // ============================================================================
  // Méthodes Points Innovation
  // ============================================================================
  
  /// Ajoute des Points Innovation au solde actuel
  /// 
  /// [amount] : Quantité de Points Innovation à ajouter (doit être > 0)
  /// [source] : Source optionnelle du gain (pour logging)
  void addPointsInnovation(int amount, {String? source}) {
    if (amount <= 0) return;
    
    _pointsInnovation += amount;
    _innovationPointsLifetime += amount;
    
    if (kDebugMode) {
      print('[RareResourcesManager] Innovation Points gained: +$amount (source: ${source ?? "unknown"})');
    }
    
    notifyListeners();
  }
  
  /// Vérifie si le joueur peut dépenser une quantité de Points Innovation
  /// 
  /// [amount] : Quantité à vérifier
  /// Retourne true si le solde est suffisant et amount > 0
  bool canSpendPointsInnovation(int amount) {
    return _pointsInnovation >= amount && amount > 0;
  }
  
  /// Dépense des Points Innovation
  /// 
  /// [amount] : Quantité de Points Innovation à dépenser
  /// [purpose] : But optionnel de la dépense (pour logging)
  /// Retourne true si la dépense a réussi, false si solde insuffisant
  bool spendPointsInnovation(int amount, {String? purpose}) {
    if (!canSpendPointsInnovation(amount)) return false;
    
    _pointsInnovation -= amount;
    _innovationPointsSpent += amount;
    
    if (kDebugMode) {
      print('[RareResourcesManager] Innovation Points spent: -$amount (purpose: ${purpose ?? "unknown"})');
    }
    
    notifyListeners();
    return true;
  }
  
  // ============================================================================
  // Méthodes Reset
  // ============================================================================
  
  /// Incrémente le compteur de resets et enregistre dans l'historique
  /// 
  /// Appelé par le système de reset (CHANTIER-05) après chaque reset réussi
  void recordReset({
    required int quantumGained,
    required int innovationPointsGained,
    required int levelReached,
    required double paperclipsProduced,
    required double moneyEarned,
    required int autoclippersOwned,
    required double playTimeHours,
  }) {
    _totalResets++;
    
    final record = ResetRecord(
      timestamp: DateTime.now(),
      resetNumber: _totalResets,
      levelReached: levelReached,
      paperclipsProduced: paperclipsProduced,
      moneyEarned: moneyEarned,
      autoclippersOwned: autoclippersOwned,
      playTimeHours: playTimeHours,
      quantumGained: quantumGained,
      innovationPointsGained: innovationPointsGained,
    );
    
    _resetHistory.add(record);
    
    if (kDebugMode) {
      print('[RareResourcesManager] Reset #$_totalResets recorded: +$quantumGained Q, +$innovationPointsGained PI');
    }
    
    notifyListeners();
  }
  
  /// Réinitialise les ressources (pour suppression entreprise)
  /// 
  /// [keepRareResources] : Si true, conserve Quantum et Points Innovation
  ///                       Si false, réinitialise tout (suppression complète)
  void resetResources({bool keepRareResources = true}) {
    if (!keepRareResources) {
      _quantum = 0;
      _pointsInnovation = 0;
      _totalResets = 0;
      _quantumLifetime = 0;
      _innovationPointsLifetime = 0;
      _quantumSpent = 0;
      _innovationPointsSpent = 0;
      _resetHistory.clear();
    }
    // Si keepRareResources = true, on ne touche à rien (comportement reset normal)
    
    notifyListeners();
  }
  
  // ============================================================================
  // Persistence (JSON)
  // ============================================================================
  
  /// Sérialise l'état du manager en JSON
  Map<String, dynamic> toJson() {
    return {
      'quantum': _quantum,
      'pointsInnovation': _pointsInnovation,
      'totalResets': _totalResets,
      'quantumLifetime': _quantumLifetime,
      'innovationPointsLifetime': _innovationPointsLifetime,
      'quantumSpent': _quantumSpent,
      'innovationPointsSpent': _innovationPointsSpent,
      'resetHistory': _resetHistory.map((r) => r.toJson()).toList(),
    };
  }
  
  /// Restaure l'état du manager depuis JSON
  void fromJson(Map<String, dynamic> json) {
    _quantum = json['quantum'] ?? 0;
    _pointsInnovation = json['pointsInnovation'] ?? 0;
    _totalResets = json['totalResets'] ?? 0;
    _quantumLifetime = json['quantumLifetime'] ?? 0;
    _innovationPointsLifetime = json['innovationPointsLifetime'] ?? 0;
    _quantumSpent = json['quantumSpent'] ?? 0;
    _innovationPointsSpent = json['innovationPointsSpent'] ?? 0;
    
    _resetHistory.clear();
    if (json['resetHistory'] != null) {
      _resetHistory.addAll(
        (json['resetHistory'] as List).map((r) => ResetRecord.fromJson(r))
      );
    }
    
    notifyListeners();
  }
}

/// Enregistrement d'un reset effectué
class ResetRecord {
  final DateTime timestamp;
  final int resetNumber;
  final int levelReached;
  final double paperclipsProduced;
  final double moneyEarned;
  final int autoclippersOwned;
  final double playTimeHours;
  final int quantumGained;
  final int innovationPointsGained;
  
  ResetRecord({
    required this.timestamp,
    required this.resetNumber,
    required this.levelReached,
    required this.paperclipsProduced,
    required this.moneyEarned,
    required this.autoclippersOwned,
    required this.playTimeHours,
    required this.quantumGained,
    required this.innovationPointsGained,
  });
  
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'resetNumber': resetNumber,
    'levelReached': levelReached,
    'paperclipsProduced': paperclipsProduced,
    'moneyEarned': moneyEarned,
    'autoclippersOwned': autoclippersOwned,
    'playTimeHours': playTimeHours,
    'quantumGained': quantumGained,
    'innovationPointsGained': innovationPointsGained,
  };
  
  factory ResetRecord.fromJson(Map<String, dynamic> json) {
    return ResetRecord(
      timestamp: DateTime.parse(json['timestamp']),
      resetNumber: json['resetNumber'],
      levelReached: json['levelReached'],
      paperclipsProduced: (json['paperclipsProduced'] as num).toDouble(),
      moneyEarned: (json['moneyEarned'] as num).toDouble(),
      autoclippersOwned: json['autoclippersOwned'],
      playTimeHours: (json['playTimeHours'] as num).toDouble(),
      quantumGained: json['quantumGained'],
      innovationPointsGained: json['innovationPointsGained'],
    );
  }
}
