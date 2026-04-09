import 'package:paperclip2/models/game_state.dart';

/// Snapshot des métriques à un instant T
class PhaseSnapshot {
  final String phaseName;
  final int level;
  final double xp;
  final int paperclipsProduced;
  final double moneyEarned;
  final int autoclippers;
  final double metalUsed;
  final int quantum;
  final int pointsInnovation;
  final DateTime timestamp;

  PhaseSnapshot({
    required this.phaseName,
    required this.level,
    required this.xp,
    required this.paperclipsProduced,
    required this.moneyEarned,
    required this.autoclippers,
    required this.metalUsed,
    required this.quantum,
    required this.pointsInnovation,
    required this.timestamp,
  });

  factory PhaseSnapshot.fromGameState(GameState gs, String phaseName) {
    return PhaseSnapshot(
      phaseName: phaseName,
      level: gs.levelSystem.currentLevel,
      xp: gs.levelSystem.experience.toDouble(),
      paperclipsProduced: gs.statistics.totalPaperclipsProduced,
      moneyEarned: gs.statistics.totalMoneyEarned,
      autoclippers: gs.playerManager.autoClipperCount,
      metalUsed: gs.statistics.totalMetalUsed,
      quantum: gs.rareResources.quantum,
      pointsInnovation: gs.rareResources.pointsInnovation,
      timestamp: DateTime.now(),
    );
  }
}

/// Rapport de simulation complète
class SimulationReport {
  final List<PhaseSnapshot> snapshots = [];
  final List<String> warnings = [];
  final List<String> errors = [];
  DateTime? startTime;
  DateTime? endTime;

  void start() {
    startTime = DateTime.now();
  }

  void end() {
    endTime = DateTime.now();
  }

  void addSnapshot(PhaseSnapshot snapshot) {
    snapshots.add(snapshot);
  }

  void addWarning(String warning) {
    warnings.add(warning);
  }

  void addError(String error) {
    errors.add(error);
  }

  Duration get totalDuration {
    if (startTime == null || endTime == null) return Duration.zero;
    return endTime!.difference(startTime!);
  }

  /// Afficher le rapport formaté dans la console
  void printReport() {
    final buffer = StringBuffer();
    
    buffer.writeln('╔══════════════════════════════════════════════════════════════╗');
    buffer.writeln('║         SIMULATION COMPLÈTE - RAPPORT FINAL                  ║');
    buffer.writeln('╠══════════════════════════════════════════════════════════════╣');
    
    for (int i = 0; i < snapshots.length; i++) {
      final snapshot = snapshots[i];
      
      buffer.writeln('║ ${snapshot.phaseName.padRight(58)}║');
      buffer.writeln('╠══════════════════════════════════════════════════════════════╣');
      buffer.writeln('║ Niveau atteint      : ${snapshot.level.toString().padRight(39)}║');
      buffer.writeln('║ XP gagnée           : ${_formatNumber(snapshot.xp).padRight(39)}║');
      buffer.writeln('║ Trombones produits  : ${_formatNumber(snapshot.paperclipsProduced.toDouble()).padRight(39)}║');
      buffer.writeln('║ Argent gagné        : ${_formatMoney(snapshot.moneyEarned).padRight(39)}║');
      buffer.writeln('║ Autoclippers        : ${snapshot.autoclippers.toString().padRight(39)}║');
      buffer.writeln('║ Métal utilisé       : ${_formatNumber(snapshot.metalUsed).padRight(39)}║');
      buffer.writeln('║ Quantum             : ${snapshot.quantum.toString().padRight(39)}║');
      buffer.writeln('║ Points Innovation   : ${snapshot.pointsInnovation.toString().padRight(39)}║');
      
      // Comparer avec snapshot précédent
      if (i > 0) {
        final prev = snapshots[i - 1];
        final improvement = _calculateImprovement(prev, snapshot);
        if (improvement.isNotEmpty) {
          buffer.writeln('║ Amélioration        : $improvement');
        }
      }
      
      buffer.writeln('╠══════════════════════════════════════════════════════════════╣');
    }
    
    // Validation globale
    buffer.writeln('║ VALIDATION GLOBALE                                           ║');
    buffer.writeln('╠══════════════════════════════════════════════════════════════╣');
    
    if (errors.isEmpty) {
      buffer.writeln('║ ✅ Aucune erreur critique                                    ║');
    } else {
      for (final error in errors) {
        buffer.writeln('║ ❌ $error');
      }
    }
    
    if (warnings.isEmpty) {
      buffer.writeln('║ ✅ Aucun avertissement                                       ║');
    } else {
      for (final warning in warnings) {
        buffer.writeln('║ ⚠️  $warning');
      }
    }
    
    buffer.writeln('╠══════════════════════════════════════════════════════════════╣');
    buffer.writeln('║ TEMPS TOTAL : ${_formatDuration(totalDuration).padRight(47)}║');
    
    final result = errors.isEmpty ? '✅ SUCCÈS' : '❌ ÉCHEC';
    final warningCount = warnings.isNotEmpty ? ' (${warnings.length} warnings)' : '';
    buffer.writeln('║ RÉSULTAT    : $result$warningCount'.padRight(62) + '║');
    buffer.writeln('╚══════════════════════════════════════════════════════════════╝');
    
    print(buffer.toString());
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _formatMoney(double value) {
    return '${_formatNumber(value)}€';
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  String _calculateImprovement(PhaseSnapshot prev, PhaseSnapshot current) {
    // Calculer l'amélioration en termes de production
    if (prev.paperclipsProduced > 0) {
      final increase = ((current.paperclipsProduced - prev.paperclipsProduced) / 
                       prev.paperclipsProduced * 100);
      if (increase > 10) {
        return '+${increase.toStringAsFixed(0)}% production vs phase précédente ✅'.padRight(39);
      }
    }
    return '';
  }
}
