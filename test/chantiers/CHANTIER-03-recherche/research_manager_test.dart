// test/unit/research_manager_test.dart
// CHANTIER-03: Tests unitaires ResearchManager

import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/managers/research_manager.dart';
import 'package:paperclip2/managers/rare_resources_manager.dart';
import 'package:paperclip2/models/research_node.dart';

void main() {
  group('CHANTIER-03: ResearchManager', () {
    late ResearchManager researchManager;
    late RareResourcesManager rareResourcesManager;

    setUp(() {
      rareResourcesManager = RareResourcesManager();
      researchManager = ResearchManager(rareResourcesManager);
    });

    test('Initialisation crée 34 nœuds', () {
      expect(researchManager.allNodes.length, equals(34));
    });

    test('ROOT est déjà recherché', () {
      final rootNode = researchManager.allNodes.firstWhere((n) => n.id == 'root');
      expect(rootNode.isResearched, isTrue);
      expect(researchManager.completedResearchCount, equals(1));
    });

    test('canResearch vérifie Points Innovation', () {
      // Nœud P1 coûte 5 PI
      expect(researchManager.canResearch('prod_efficiency_1'), isFalse);
      
      // Ajouter 5 PI
      rareResourcesManager.addPointsInnovation(5);
      expect(researchManager.canResearch('prod_efficiency_1'), isTrue);
    });

    test('canResearch vérifie prérequis', () {
      // P3 nécessite P1
      rareResourcesManager.addPointsInnovation(100);
      expect(researchManager.canResearch('prod_efficiency_2'), isFalse);
      
      // Rechercher P1
      researchManager.research('prod_efficiency_1');
      expect(researchManager.canResearch('prod_efficiency_2'), isTrue);
    });

    test('Choix exclusifs bloquent mutuellement', () {
      rareResourcesManager.addPointsInnovation(100);
      
      // Rechercher prérequis
      researchManager.research('prod_efficiency_1');
      researchManager.research('prod_speed_1');
      researchManager.research('prod_efficiency_2');
      researchManager.research('prod_speed_2');
      
      // Rechercher Production de Masse
      expect(researchManager.canResearch('prod_mass'), isTrue);
      researchManager.research('prod_mass');
      
      // Production Précise devrait être bloqué
      expect(researchManager.canResearch('prod_precise'), isFalse);
    });

    test('research() dépense PI correctement', () {
      rareResourcesManager.addPointsInnovation(10);
      final initialPI = rareResourcesManager.pointsInnovation;
      
      researchManager.research('prod_efficiency_1'); // Coûte 5 PI
      
      expect(rareResourcesManager.pointsInnovation, equals(initialPI - 5));
    });

    test('getResearchBonus agrège correctement', () {
      rareResourcesManager.addPointsInnovation(100);
      
      // Aucun bonus au départ
      expect(researchManager.getResearchBonus('metalEfficiency'), equals(0.0));
      
      // Rechercher P1 (+10% metalEfficiency)
      researchManager.research('prod_efficiency_1');
      expect(researchManager.getResearchBonus('metalEfficiency'), equals(0.10));
      
      // Rechercher P3 (+20% metalEfficiency supplémentaires)
      researchManager.research('prod_efficiency_2');
      expect(researchManager.getResearchBonus('metalEfficiency'), closeTo(0.30, 0.001));
    });

    test('Bonus multiples s\'additionnent', () {
      rareResourcesManager.addPointsInnovation(100);
      
      // Rechercher P1 et P2
      researchManager.research('prod_efficiency_1'); // +10% metalEfficiency
      researchManager.research('prod_speed_1'); // +15% productionSpeed
      
      expect(researchManager.getResearchBonus('metalEfficiency'), equals(0.10));
      expect(researchManager.getResearchBonus('productionSpeed'), equals(0.15));
    });

    test('Persistance toJson/fromJson', () {
      rareResourcesManager.addPointsInnovation(100);
      
      // Rechercher quelques nœuds
      researchManager.research('prod_efficiency_1');
      researchManager.research('prod_speed_1');
      
      // Sérialiser
      final json = researchManager.toJson();
      
      // Créer nouveau manager et désérialiser
      final newRareResources = RareResourcesManager();
      final newResearchManager = ResearchManager(newRareResources);
      newResearchManager.fromJson(json);
      
      // Vérifier état restauré
      expect(newResearchManager.completedResearchCount, equals(3)); // root + 2
      expect(newResearchManager.getResearchBonus('metalEfficiency'), equals(0.10));
      expect(newResearchManager.getResearchBonus('productionSpeed'), equals(0.15));
    });

    test('getResetBonus calcule correctement', () {
      rareResourcesManager.addPointsInnovation(100);
      
      // Aucun bonus au départ
      expect(researchManager.getResetBonus('quantum'), equals(0.0));
      expect(researchManager.getResetBonus('innovation'), equals(0.0));
      
      // Rechercher META1 (+15% quantum)
      researchManager.research('reset_bonus_1');
      expect(researchManager.getResetBonus('quantum'), equals(0.15));
      
      // Rechercher META3 (+10% innovation)
      researchManager.research('innovation_bonus_1');
      expect(researchManager.getResetBonus('innovation'), equals(0.10));
    });

    test('isAgentUnlocked fonctionne', () {
      rareResourcesManager.addPointsInnovation(200);
      
      expect(researchManager.isAgentUnlocked('production_optimizer'), isFalse);
      
      // Rechercher prérequis et agent
      researchManager.research('prod_efficiency_1');
      researchManager.research('prod_speed_1');
      researchManager.research('prod_efficiency_2');
      researchManager.research('prod_speed_2');
      researchManager.research('prod_mass');
      researchManager.research('unlock_agent_production');
      
      expect(researchManager.isAgentUnlocked('production_optimizer'), isTrue);
    });

    test('isFeatureUnlocked fonctionne', () {
      rareResourcesManager.addPointsInnovation(200);
      
      expect(researchManager.isFeatureUnlocked('research_tree'), isTrue); // ROOT
      expect(researchManager.isFeatureUnlocked('auto_metal_purchase'), isFalse);
      
      // Rechercher prérequis
      researchManager.research('resource_storage_1');
      researchManager.research('resource_procurement_1');
      researchManager.research('resource_storage_2');
      researchManager.research('resource_procurement_2');
      researchManager.research('unlock_agent_metal');
      researchManager.research('resource_auto_buy');
      
      expect(researchManager.isFeatureUnlocked('auto_metal_purchase'), isTrue);
    });
  });
}
