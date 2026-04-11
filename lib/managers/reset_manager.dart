import 'package:flutter/foundation.dart';
import '../services/reset/reset_rewards_calculator.dart';
import '../models/game_state.dart';
import '../models/reset_history_entry.dart';

/// Manager pour le système de reset progression (prestige)
/// 
/// Architecture refactorée : injection directe de GameState au lieu de callbacks.
/// Gère la logique de reset volontaire permettant au joueur de recommencer
/// avec des bonus permanents (Quantum + Points Innovation).
class ResetManager extends ChangeNotifier {
  static const int MIN_LEVEL_FOR_RESET = 20;
  static const double MIN_PAPERCLIPS_FOR_RESET = 100000.0;
  
  final GameState _gameState;
  
  ResetManager(this._gameState);
  
  /// Vérifier si reset possible
  bool canReset() {
    return _gameState.levelSystem.currentLevel >= MIN_LEVEL_FOR_RESET &&
           _gameState.statistics.totalPaperclipsProduced >= MIN_PAPERCLIPS_FOR_RESET;
  }
  
  /// Calculer récompenses potentielles (synchrone, testable)
  ResetRewards calculatePotentialRewards() {
    return ResetRewardsCalculator.calculateRewards(
      totalPaperclipsProduced: _gameState.statistics.totalPaperclipsProduced.toDouble(),
      totalMoneyEarned: _gameState.statistics.totalMoneyEarned,
      autoClipperCount: _gameState.playerManager.autoClipperCount,
      playerLevel: _gameState.levelSystem.currentLevel,
      playTimeHours: _gameState.statistics.totalGameTimeSec / 3600.0,
      resetCount: _gameState.resetCount,
      researchesCompleted: _gameState.research.completedResearchCount,
      quantumResearchBonus: _getQuantumResearchBonus(),
      innovationResearchBonus: _getInnovationResearchBonus(),
    );
  }
  
  /// Calculer bonus recherches META pour Quantum
  double _getQuantumResearchBonus() {
    // TODO: Implémenter quand recherches META seront ajoutées
    return 0.0;
  }
  
  /// Calculer bonus recherches META pour Innovation
  double _getInnovationResearchBonus() {
    // TODO: Implémenter quand recherches META seront ajoutées
    return 0.0;
  }
  
  /// Effectuer le reset (async pour sauvegarde)
  Future<ResetResult> performReset() async {
    if (!canReset()) {
      return ResetResult.failed('Conditions non remplies pour le reset');
    }
    
    try {
      // 1. Calculer récompenses
      final rewards = calculatePotentialRewards();
      
      if (kDebugMode) {
        print('[ResetManager] Reset démarré - Quantum: ${rewards.quantum}, PI: ${rewards.innovationPoints}');
      }
      
      // 2. Sauvegarder historique
      final resetEntry = ResetHistoryEntry(
        timestamp: DateTime.now(),
        levelBefore: _gameState.levelSystem.currentLevel,
        quantumGained: rewards.quantum,
        innovationGained: rewards.innovationPoints,
      );
      
      // 3. Reset tous les managers
      await _resetAllManagers();
      
      // 4. Appliquer récompenses
      _gameState.addQuantum(rewards.quantum);
      _gameState.addPointsInnovation(rewards.innovationPoints);
      
      // 5. Ajouter à l'historique
      _gameState.addResetEntry(resetEntry);
      
      // 6. Sauvegarder
      await _gameState.saveOnImportantEvent();
      
      if (kDebugMode) {
        print('[ResetManager] Reset terminé avec succès');
      }
      
      // 7. Notifier UI
      notifyListeners();
      
      return ResetResult.success(rewards);
      
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[ResetManager] Erreur lors du reset: $e');
        print(stackTrace);
      }
      return ResetResult.failed('Erreur lors du reset: $e');
    }
  }
  
  /// Reset tous les managers dans l'ordre
  Future<void> _resetAllManagers() async {
    // Reset dans l'ordre pour éviter les dépendances
    _gameState.playerManager.resetForProgression(); // autoclippers → 0, coût → 15€
    _gameState.productionManager.reset();
    _gameState.marketManager.resetForProgression();
    _gameState.levelSystem.reset();
    _gameState.statistics.resetCurrentRun();
    _gameState.agents.deactivateAll();
    _gameState.missionSystem.cancelAll();
  }
  
  /// Obtenir recommandation pour le joueur
  String getResetRecommendation(int currentLevel, ResetRewards currentRewards) {
    if (!canReset()) {
      return 'Niveau $MIN_LEVEL_FOR_RESET minimum requis';
    }
    
    if (currentLevel < 25) {
      return 'Recommandé : Attendre niveau 25-30 pour plus de gains';
    } else if (currentLevel >= 30 && currentRewards.quantum < 100) {
      return 'Bon moment pour reset';
    } else if (currentRewards.quantum >= 150) {
      return 'Excellent moment pour reset !';
    } else {
      return 'Reset disponible';
    }
  }
}

/// Résultat d'une opération de reset
class ResetResult {
  final bool success;
  final String? error;
  final ResetRewards? rewards;
  
  ResetResult.success(this.rewards) : success = true, error = null;
  ResetResult.failed(this.error) : success = false, rewards = null;
}
