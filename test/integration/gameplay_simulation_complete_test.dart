import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import '../helpers/game_simulator.dart';
import '../helpers/simulation_report.dart';

/// Test de simulation complète de gameplay avec 2 resets
void main() {
  group('Gameplay Simulation Complète (2 Resets)', () {
    late GameState gameState;
    late SimulationReport report;

    setUp(() {
      gameState = GameState();
      while (!gameState.isInitialized) {}
      report = SimulationReport();
    });

    test('Simulation complète : 0 → Reset 1 → Reset 2', () async {
      report.start();
      
      print('\n🎮 DÉMARRAGE SIMULATION COMPLÈTE\n');
      
      // ═══════════════════════════════════════════════════════════
      // PHASE 1: Niveau 1 → 20 (Premier Reset)
      // ═══════════════════════════════════════════════════════════
      print('📍 PHASE 1 : Niveau 1 → 20 (Premier Reset)');
      
      await _simulatePhase1(gameState, report);
      
      // Snapshot après phase 1
      report.addSnapshot(PhaseSnapshot.fromGameState(gameState, 'PHASE 1 : Niveau 1 → 20 (Premier Reset)'));
      
      // Vérifier niveau 20 atteint
      expect(gameState.levelSystem.currentLevel, greaterThanOrEqualTo(20),
          reason: 'Phase 1 devrait atteindre niveau 20');
      
      // ═══════════════════════════════════════════════════════════
      // RESET 1
      // ═══════════════════════════════════════════════════════════
      print('\n🔄 RESET 1');
      
      final quantumBefore1 = gameState.rareResources.quantum;
      final piBefore1 = gameState.rareResources.pointsInnovation;
      
      print('  🔍 Quantum AVANT reset : $quantumBefore1');
      await _performReset(gameState, report, resetNumber: 1);
      print('  🔍 Quantum APRÈS reset : ${gameState.rareResources.quantum}');
      
      // Vérifier gains reset
      expect(gameState.rareResources.quantum, greaterThan(quantumBefore1),
          reason: 'Reset 1 devrait donner du Quantum (avant=$quantumBefore1, après=${gameState.rareResources.quantum})');
      expect(gameState.rareResources.pointsInnovation, greaterThan(piBefore1),
          reason: 'Reset 1 devrait donner des PI');
      expect(gameState.resetCount, equals(1),
          reason: 'Compteur reset devrait être 1');
      
      // ═══════════════════════════════════════════════════════════
      // PHASE 2: Niveau 1 → 20 (Deuxième Reset)
      // ═══════════════════════════════════════════════════════════
      print('\n📍 PHASE 2 : Niveau 1 → 20 (Deuxième Reset)');
      
      await _simulatePhase2(gameState, report);
      
      // Snapshot après phase 2
      report.addSnapshot(PhaseSnapshot.fromGameState(gameState, 'PHASE 2 : Niveau 1 → 20 (Deuxième Reset)'));
      
      // Vérifier niveau 20 atteint à nouveau
      expect(gameState.levelSystem.currentLevel, greaterThanOrEqualTo(20),
          reason: 'Phase 2 devrait atteindre niveau 20');
      
      // ═══════════════════════════════════════════════════════════
      // RESET 2
      // ═══════════════════════════════════════════════════════════
      print('\n🔄 RESET 2');
      
      final quantumBefore2 = gameState.rareResources.quantum;
      final piBefore2 = gameState.rareResources.pointsInnovation;
      
      await _performReset(gameState, report, resetNumber: 2);
      
      // Vérifier gains reset 2
      expect(gameState.rareResources.quantum, greaterThan(quantumBefore2),
          reason: 'Reset 2 devrait donner du Quantum');
      expect(gameState.rareResources.pointsInnovation, greaterThan(piBefore2),
          reason: 'Reset 2 devrait donner des PI');
      expect(gameState.resetCount, equals(2),
          reason: 'Compteur reset devrait être 2');
      
      // ═══════════════════════════════════════════════════════════
      // PHASE 3: Validation Finale
      // ═══════════════════════════════════════════════════════════
      print('\n📍 PHASE 3 : Validation Finale');
      
      await _simulatePhase3(gameState, report);
      
      // Snapshot final
      report.addSnapshot(PhaseSnapshot.fromGameState(gameState, 'PHASE 3 : Validation Finale'));
      
      // ═══════════════════════════════════════════════════════════
      // VALIDATION FINALE
      // ═══════════════════════════════════════════════════════════
      _validateFinalStats(gameState, report);
      
      report.end();
      
      // ═══════════════════════════════════════════════════════════
      // RÉSUMÉ FINAL
      // ═══════════════════════════════════════════════════════════
      print('\n📊 RÉSUMÉ FINAL');
      print('   Total Quantum gagné : ${gameState.rareResources.quantum}');
      print('   Total PI gagné : ${gameState.rareResources.pointsInnovation}');
      print('   Agents achetables : ${gameState.rareResources.quantum ~/ 5}');
      print('   Total trombones : ${gameState.statistics.totalPaperclipsProduced}');
      print('   Total argent : ${gameState.statistics.totalMoneyEarned.toStringAsFixed(0)}€');
      print('   Autoclippers : ${gameState.playerManager.autoClipperCount}');
      print('   Niveau final : ${gameState.levelSystem.currentLevel}');
      
      // ═══════════════════════════════════════════════════════════
      // AFFICHER RAPPORT
      // ═══════════════════════════════════════════════════════════
      print('\n');
      report.printReport();
      
      // Assertions finales
      expect(report.errors, isEmpty, reason: 'Aucune erreur critique');
      expect(gameState.resetCount, equals(2), reason: '2 resets effectués');
      expect(gameState.resetHistory.length, equals(2), reason: 'Historique contient 2 resets');
    });
  });
}

/// Phase 1 : Niveau 1 → 20 (Premier Reset)
Future<void> _simulatePhase1(GameState gs, SimulationReport report) async {
  print('  🎯 Objectif : Atteindre niveau 20');
  
  // Simuler temps de jeu (important pour calcul récompenses reset)
  int simulatedSeconds = 0;
  
  // Étape 1 : Production manuelle intensive (0-5000 trombones)
  print('  📦 Production manuelle intensive : 5000 clics');
  GameSimulator.simulateManualClicks(gs, 5000);
  simulatedSeconds += 1800; // 30 minutes
  
  // Étape 2 : Vendre pour avoir de l'argent
  print('  💰 Vente initiale');
  GameSimulator.sellPaperclips(gs, 0.25, quantity: 2000);
  simulatedSeconds += 300; // 5 minutes
  
  // Étape 3 : Acheter premiers autoclippers
  print('  🤖 Achat autoclippers (objectif: 10)');
  GameSimulator.buyAutoclippersUntil(gs, 10);
  simulatedSeconds += 600; // 10 minutes
  
  // Étape 4 : Boucle production/vente/achat jusqu'à 100k trombones ET niveau 20
  int iterations = 0;
  while ((gs.levelSystem.currentLevel < 20 || gs.statistics.totalPaperclipsProduced < 100000) && iterations < 200) {
    // Produire massivement
    GameSimulator.simulateManualClicks(gs, 500);
    
    // Vendre
    GameSimulator.sellPaperclips(gs, 0.30, quantity: 2000);
    
    // Acheter métal si nécessaire
    GameSimulator.buyMetalIfNeeded(gs, threshold: 200.0);
    
    // Acheter plus d'autoclippers
    if (gs.playerManager.autoClipperCount < 50) {
      GameSimulator.buyAutoclippersUntil(gs, gs.playerManager.autoClipperCount + 3);
    }
    
    simulatedSeconds += 300; // 5 minutes par itération (simuler jeu idle)
    iterations++;
  }
  
  // Mettre à jour le temps de jeu simulé
  gs.statistics.updateGameTime(simulatedSeconds);
  
  print('  ✅ Phase 1 terminée - Niveau ${gs.levelSystem.currentLevel}');
  print('  ⏱️  Temps simulé : ${simulatedSeconds ~/ 60}m ${simulatedSeconds % 60}s');
}

/// Phase 2 : Reset 1 → Niveau 20 (Deuxième Reset)
Future<void> _simulatePhase2(GameState gs, SimulationReport report) async {
  print('  🎯 Objectif : Atteindre niveau 20 + 100k trombones (avec bonus reset)');
  print('  ⚡ Quantum : ${gs.rareResources.quantum}, PI : ${gs.rareResources.pointsInnovation}');
  
  int simulatedSeconds = 0;
  
  // Avec les bonus, devrait être plus rapide
  // Étape 1 : Production initiale
  GameSimulator.simulateManualClicks(gs, 3000);
  simulatedSeconds += 900;
  
  // Étape 2 : Vendre et acheter autoclippers rapidement
  GameSimulator.sellPaperclips(gs, 0.35, quantity: 1500);
  GameSimulator.buyAutoclippersUntil(gs, 20);
  simulatedSeconds += 300;
  
  // Étape 3 : Boucle accélérée jusqu'à 100k trombones ET niveau 20
  // Note: totalPaperclipsProduced est réinitialisé après reset, donc on doit produire 100k dans cette run
  int iterations = 0;
  int paperclipsAtStart = gs.statistics.totalPaperclipsProduced;
  while ((gs.levelSystem.currentLevel < 20 || (gs.statistics.totalPaperclipsProduced - paperclipsAtStart) < 100000) && iterations < 200) {
    GameSimulator.simulateManualClicks(gs, 500);
    GameSimulator.sellPaperclips(gs, 0.40, quantity: 2000);
    GameSimulator.buyMetalIfNeeded(gs, threshold: 200.0);
    
    if (gs.playerManager.autoClipperCount < 70) {
      GameSimulator.buyAutoclippersUntil(gs, gs.playerManager.autoClipperCount + 3);
    }
    
    simulatedSeconds += 250;
    iterations++;
  }
  
  gs.statistics.updateGameTime(simulatedSeconds);
  
  print('  ✅ Phase 2 terminée - Niveau ${gs.levelSystem.currentLevel}');
  print('  ⏱️  Temps simulé : ${simulatedSeconds ~/ 60}m ${simulatedSeconds % 60}s');
}

/// Phase 3 : Validation Finale + Test Agents
Future<void> _simulatePhase3(GameState gs, SimulationReport report) async {
  print('  🎯 Objectif : Validation finale + test agents');
  print('  ⚡ Quantum : ${gs.rareResources.quantum}, PI : ${gs.rareResources.pointsInnovation}');
  
  int simulatedSeconds = 0;
  
  // Production finale pour valider
  int iterations = 0;
  while (gs.levelSystem.currentLevel < 25 && iterations < 50) {
    GameSimulator.simulateManualClicks(gs, 200);
    GameSimulator.sellPaperclips(gs, 0.45, quantity: 800);
    GameSimulator.buyMetalIfNeeded(gs, threshold: 200.0);
    
    if (gs.playerManager.autoClipperCount < 100) {
      GameSimulator.buyAutoclippersUntil(gs, gs.playerManager.autoClipperCount + 5);
    }
    
    simulatedSeconds += 15;
    iterations++;
  }
  
  gs.statistics.updateGameTime(simulatedSeconds);
  
  // Test : Vérifier qu'on peut acheter des agents (coût 5 Quantum chacun)
  final quantumAvailable = gs.rareResources.quantum;
  final maxAgentsPossible = quantumAvailable ~/ 5;
  
  print('  🤖 Test agents :');
  print('     Quantum disponible : $quantumAvailable');
  print('     Agents achetables : $maxAgentsPossible (5 Quantum/agent)');
  
  if (maxAgentsPossible < 10) {
    report.addWarning('Quantum insuffisant pour acheter 10+ agents ($maxAgentsPossible possibles)');
  } else {
    print('     ✅ Assez de Quantum pour acheter 10+ agents');
  }
  
  print('  ✅ Phase 3 terminée - Niveau ${gs.levelSystem.currentLevel}');
  print('  ⏱️  Temps simulé : ${simulatedSeconds ~/ 60}m ${simulatedSeconds % 60}s');
}

/// Effectuer un reset
Future<void> _performReset(GameState gs, SimulationReport report, {required int resetNumber}) async {
  final levelBefore = gs.levelSystem.currentLevel;
  final quantumBefore = gs.rareResources.quantum;
  final piBefore = gs.rareResources.pointsInnovation;
  
  // Debug : afficher stats avant reset
  print('  📊 Stats avant reset :');
  print('     Niveau : ${gs.levelSystem.currentLevel}');
  print('     Trombones produits : ${gs.statistics.totalPaperclipsProduced}');
  print('     Argent gagné : ${gs.statistics.totalMoneyEarned}€');
  print('     Autoclippers : ${gs.playerManager.autoClipperCount}');
  print('     Temps de jeu : ${gs.statistics.totalGameTimeSec}s');
  
  // Vérifier conditions
  print('  🔍 Vérification canReset()...');
  final canReset = gs.resetManager.canReset();
  print('  🔍 canReset() = $canReset');
  
  if (!canReset) {
    report.addError('Reset $resetNumber impossible - niveau ${gs.levelSystem.currentLevel} < 20');
    print('  ❌ Reset impossible !');
    return;
  }
  
  print('  ✅ Reset possible, calcul récompenses...');
  
  // Calculer récompenses potentielles
  try {
    final potentialRewards = gs.resetManager.calculatePotentialRewards();
    print('  💎 Récompenses calculées :');
    print('     Quantum : ${potentialRewards.quantum}');
    print('     PI : ${potentialRewards.innovationPoints}');
  } catch (e, stack) {
    print('  ❌ ERREUR calcul récompenses : $e');
    print(stack);
    report.addError('Erreur calcul récompenses : $e');
  }
  
  // Effectuer reset
  final result = await gs.resetManager.performReset();
  
  if (result.success) {
    final quantumGained = gs.rareResources.quantum - quantumBefore;
    final piGained = gs.rareResources.pointsInnovation - piBefore;
    
    print('  ✅ Reset $resetNumber effectué');
    print('     Niveau avant : $levelBefore');
    print('     Quantum gagné : $quantumGained (total: ${gs.rareResources.quantum})');
    print('     PI gagné : $piGained (total: ${gs.rareResources.pointsInnovation})');
  } else {
    report.addError('Reset $resetNumber échoué : ${result.error ?? "erreur inconnue"}');
  }
}

/// Valider les statistiques finales
void _validateFinalStats(GameState gs, SimulationReport report) {
  print('\n🔍 VALIDATION FINALE');
  
  // Vérifier historique
  if (gs.resetHistory.length != 2) {
    report.addError('Historique devrait contenir 2 resets, trouvé: ${gs.resetHistory.length}');
  } else {
    print('  ✅ Historique : 2 resets');
  }
  
  // Vérifier compteur
  if (gs.resetCount != 2) {
    report.addError('Compteur devrait être 2, trouvé: ${gs.resetCount}');
  } else {
    print('  ✅ Compteur : 2 resets');
  }
  
  // Vérifier stats cohérentes
  if (gs.statistics.totalPaperclipsProduced.isNaN || 
      gs.statistics.totalPaperclipsProduced.isInfinite) {
    report.addError('Stats production incohérentes (NaN/Infinite)');
  } else {
    print('  ✅ Stats production cohérentes');
  }
  
  if (gs.statistics.totalMoneyEarned.isNaN || 
      gs.statistics.totalMoneyEarned.isInfinite ||
      gs.statistics.totalMoneyEarned < 0) {
    report.addError('Stats économie incohérentes');
  } else {
    print('  ✅ Stats économie cohérentes');
  }
  
  // Vérifier ressources rares
  if (gs.rareResources.quantum < 0 || gs.rareResources.pointsInnovation < 0) {
    report.addError('Ressources rares négatives');
  } else {
    print('  ✅ Ressources rares positives');
  }
  
  // Warnings équilibrage
  if (gs.rareResources.quantum > 200) {
    report.addWarning('Quantum très élevé (${gs.rareResources.quantum}) - vérifier équilibrage');
  }
  
  if (gs.statistics.totalPaperclipsProduced < 1000) {
    report.addWarning('Production totale faible (${gs.statistics.totalPaperclipsProduced}) - progression lente ?');
  }
  
  print('  ✅ Validation terminée');
}
