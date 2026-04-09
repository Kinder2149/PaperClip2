import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/managers/research_manager.dart';
import 'package:paperclip2/managers/rare_resources_manager.dart';
import 'package:paperclip2/managers/player_manager.dart';
import 'package:paperclip2/models/research_node.dart';

void main() {
  group('Recherches META - CHANTIER-06', () {
    late ResearchManager researchManager;
    late RareResourcesManager rareResourcesManager;
    late PlayerManager playerManager;

    setUp(() {
      rareResourcesManager = RareResourcesManager();
      playerManager = PlayerManager();
      researchManager = ResearchManager(rareResourcesManager, playerManager);
      
      // Simuler 1 reset effectué pour débloquer les recherches META
      rareResourcesManager.recordReset(
        quantumGained: 100,
        innovationPointsGained: 50,
        levelReached: 25,
        paperclipsProduced: 100000,
        moneyEarned: 5000,
        autoclippersOwned: 10,
        playTimeHours: 2.0,
      );
      
      // Ajouter des ressources pour les tests
      rareResourcesManager.addQuantum(50, source: 'test');
      rareResourcesManager.addPointsInnovation(50, source: 'test');
    });

    test('Quantum Amplifier coûte 5 Quantum et donne +10% bonus Quantum', () {
      final node = researchManager.allNodes.firstWhere((n) => n.id == 'quantum_amplifier');
      
      expect(node.quantumCost, 5);
      expect(node.innovationPointsCost, 0);
      expect(node.category, ResearchCategory.META);
      expect(node.effect.type, ResearchEffectType.MODIFY_RESET);
      expect(node.effect.params['quantumBonus'], 0.10);
    });

    test('Innovation Catalyst coûte 5 PI et donne +10% bonus PI', () {
      final node = researchManager.allNodes.firstWhere((n) => n.id == 'innovation_catalyst');
      
      expect(node.quantumCost, 0);
      expect(node.innovationPointsCost, 5);
      expect(node.category, ResearchCategory.META);
      expect(node.effect.type, ResearchEffectType.MODIFY_RESET);
      expect(node.effect.params['innovationBonus'], 0.10);
    });

    test('Meta Researcher coûte 10 Quantum + 10 PI et débloque agent', () {
      final node = researchManager.allNodes.firstWhere((n) => n.id == 'meta_researcher');
      
      expect(node.quantumCost, 10);
      expect(node.innovationPointsCost, 10);
      expect(node.category, ResearchCategory.META);
      expect(node.effect.type, ResearchEffectType.UNLOCK_AGENT);
      expect(node.effect.params['agentId'], 'innovation_researcher');
      expect(node.prerequisites, containsAll(['quantum_amplifier', 'innovation_catalyst']));
    });

    test('Quantum Efficiency nécessite 2 resets et Quantum Amplifier', () {
      final node = researchManager.allNodes.firstWhere((n) => n.id == 'quantum_efficiency');
      
      expect(node.quantumCost, 15);
      expect(node.prerequisites, contains('quantum_amplifier'));
      
      // Avec 1 seul reset, ne peut pas rechercher
      expect(researchManager.canResearch('quantum_efficiency'), false);
      
      // Simuler un 2ème reset
      rareResourcesManager.recordReset(
        quantumGained: 100,
        innovationPointsGained: 50,
        levelReached: 25,
        paperclipsProduced: 100000,
        moneyEarned: 5000,
        autoclippersOwned: 10,
        playTimeHours: 2.0,
      );
      rareResourcesManager.addQuantum(50, source: 'test');
      
      // Rechercher Quantum Amplifier d'abord
      researchManager.research('quantum_amplifier');
      
      // Maintenant peut rechercher Quantum Efficiency
      expect(researchManager.canResearch('quantum_efficiency'), true);
    });

    test('Innovation Mastery nécessite 2 resets et Innovation Catalyst', () {
      final node = researchManager.allNodes.firstWhere((n) => n.id == 'innovation_mastery');
      
      expect(node.innovationPointsCost, 15);
      expect(node.prerequisites, contains('innovation_catalyst'));
      
      // Avec 1 seul reset, ne peut pas rechercher
      expect(researchManager.canResearch('innovation_mastery'), false);
      
      // Simuler un 2ème reset
      rareResourcesManager.recordReset(
        quantumGained: 100,
        innovationPointsGained: 50,
        levelReached: 25,
        paperclipsProduced: 100000,
        moneyEarned: 5000,
        autoclippersOwned: 10,
        playTimeHours: 2.0,
      );
      rareResourcesManager.addPointsInnovation(50, source: 'test');
      
      // Rechercher Innovation Catalyst d'abord
      researchManager.research('innovation_catalyst');
      
      // Maintenant peut rechercher Innovation Mastery
      expect(researchManager.canResearch('innovation_mastery'), true);
    });

    test('Rechercher Quantum Amplifier dépense 5 Quantum', () {
      final initialQuantum = rareResourcesManager.quantum;
      
      // Le nœud doit être disponible (root est déjà recherché)
      final node = researchManager.allNodes.firstWhere((n) => n.id == 'quantum_amplifier');
      expect(node.isUnlocked, true, reason: 'quantum_amplifier devrait être débloqué car root est recherché');
      
      final canResearch = researchManager.canResearch('quantum_amplifier');
      expect(canResearch, true, reason: 'Devrait pouvoir rechercher quantum_amplifier avec 1 reset et 50 Quantum');
      
      final success = researchManager.research('quantum_amplifier');
      
      expect(success, true);
      expect(rareResourcesManager.quantum, initialQuantum - 5);
    });

    test('Rechercher Innovation Catalyst dépense 5 PI', () {
      final initialPI = rareResourcesManager.pointsInnovation;
      
      final success = researchManager.research('innovation_catalyst');
      
      expect(success, true);
      expect(rareResourcesManager.pointsInnovation, initialPI - 5);
    });

    test('getResetBonus accumule les bonus Quantum des recherches META', () {
      // Vérifier que quantum_amplifier peut être recherché
      expect(researchManager.canResearch('quantum_amplifier'), true);
      
      // Rechercher Quantum Amplifier (+10%)
      final success = researchManager.research('quantum_amplifier');
      expect(success, true, reason: 'La recherche devrait réussir');
      expect(researchManager.getResetBonus('quantum'), 0.10);
      
      // Ajouter 2ème reset et rechercher Quantum Efficiency (+15%)
      rareResourcesManager.recordReset(
        quantumGained: 100,
        innovationPointsGained: 50,
        levelReached: 25,
        paperclipsProduced: 100000,
        moneyEarned: 5000,
        autoclippersOwned: 10,
        playTimeHours: 2.0,
      );
      rareResourcesManager.addQuantum(50, source: 'test');
      
      researchManager.research('quantum_efficiency');
      
      // Total: 10% + 15% = 25%
      expect(researchManager.getResetBonus('quantum'), 0.25);
    });

    test('getResetBonus accumule les bonus Innovation des recherches META', () {
      // Rechercher Innovation Catalyst (+10%)
      researchManager.research('innovation_catalyst');
      expect(researchManager.getResetBonus('innovation'), 0.10);
      
      // Ajouter 2ème reset et rechercher Innovation Mastery (+15%)
      rareResourcesManager.recordReset(
        quantumGained: 100,
        innovationPointsGained: 50,
        levelReached: 25,
        paperclipsProduced: 100000,
        moneyEarned: 5000,
        autoclippersOwned: 10,
        playTimeHours: 2.0,
      );
      rareResourcesManager.addPointsInnovation(50, source: 'test');
      
      researchManager.research('innovation_mastery');
      
      // Total: 10% + 15% = 25%
      expect(researchManager.getResetBonus('innovation'), 0.25);
    });

    test('resetForProgression conserve les recherches META', () {
      // Rechercher quelques recherches META
      expect(researchManager.canResearch('quantum_amplifier'), true);
      researchManager.research('quantum_amplifier');
      
      expect(researchManager.canResearch('innovation_catalyst'), true);
      researchManager.research('innovation_catalyst');
      
      // Rechercher une recherche non-META
      expect(researchManager.canResearch('prod_efficiency_1'), true);
      researchManager.research('prod_efficiency_1');
      
      // root est déjà compté, donc 1 + 3 = 4
      expect(researchManager.completedResearchCount, 4); // root + 3 recherches
      
      // Reset progression
      researchManager.resetForProgression();
      
      // Vérifier que les META sont conservées mais pas les autres
      expect(researchManager.completedResearchCount, 3); // root + 2 META
      
      final researchedIds = researchManager.researchedNodes.map((n) => n.id).toList();
      expect(researchedIds, contains('quantum_amplifier'));
      expect(researchedIds, contains('innovation_catalyst'));
      expect(researchedIds, isNot(contains('prod_efficiency_1')));
    });

    test('resetForProgression conserve les bonus META', () {
      // Rechercher des recherches META avec bonus
      expect(researchManager.canResearch('quantum_amplifier'), true);
      final success1 = researchManager.research('quantum_amplifier');
      expect(success1, true);
      
      expect(researchManager.canResearch('innovation_catalyst'), true);
      final success2 = researchManager.research('innovation_catalyst');
      expect(success2, true);
      
      final quantumBonusBefore = researchManager.getResetBonus('quantum');
      final innovationBonusBefore = researchManager.getResetBonus('innovation');
      
      expect(quantumBonusBefore, 0.10);
      expect(innovationBonusBefore, 0.10);
      
      // Reset progression
      researchManager.resetForProgression();
      
      // Les bonus doivent être conservés
      expect(researchManager.getResetBonus('quantum'), quantumBonusBefore);
      expect(researchManager.getResetBonus('innovation'), innovationBonusBefore);
    });

    test('Toutes les recherches META sont bien catégorisées', () {
      final metaNodes = researchManager.allNodes
          .where((n) => n.category == ResearchCategory.META)
          .toList();
      
      final metaIds = metaNodes.map((n) => n.id).toList();
      
      // Vérifier que nos 5 nouvelles recherches sont bien META
      expect(metaIds, contains('quantum_amplifier'));
      expect(metaIds, contains('innovation_catalyst'));
      expect(metaIds, contains('meta_researcher'));
      expect(metaIds, contains('quantum_efficiency'));
      expect(metaIds, contains('innovation_mastery'));
    });
  });
}
