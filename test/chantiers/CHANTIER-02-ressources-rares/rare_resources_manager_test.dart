import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/managers/rare_resources_manager.dart';

void main() {
  group('RareResourcesManager', () {
    late RareResourcesManager manager;
    
    setUp(() {
      manager = RareResourcesManager();
    });
    
    // ========================================================================
    // Tests État Initial
    // ========================================================================
    
    test('État initial - toutes les valeurs à zéro', () {
      expect(manager.quantum, equals(0));
      expect(manager.pointsInnovation, equals(0));
      expect(manager.totalResets, equals(0));
      expect(manager.quantumLifetime, equals(0));
      expect(manager.innovationPointsLifetime, equals(0));
      expect(manager.quantumSpent, equals(0));
      expect(manager.innovationPointsSpent, equals(0));
    });
    
    // ========================================================================
    // Tests Quantum
    // ========================================================================
    
    test('addQuantum augmente quantum et quantumLifetime', () {
      manager.addQuantum(10);
      
      expect(manager.quantum, equals(10));
      expect(manager.quantumLifetime, equals(10));
      
      manager.addQuantum(5);
      
      expect(manager.quantum, equals(15));
      expect(manager.quantumLifetime, equals(15));
    });
    
    test('addQuantum avec montant négatif ou zéro ne fait rien', () {
      manager.addQuantum(0);
      expect(manager.quantum, equals(0));
      
      manager.addQuantum(-5);
      expect(manager.quantum, equals(0));
    });
    
    test('spendQuantum diminue quantum et augmente quantumSpent', () {
      manager.addQuantum(20);
      final success = manager.spendQuantum(8);
      
      expect(success, isTrue);
      expect(manager.quantum, equals(12));
      expect(manager.quantumSpent, equals(8));
      expect(manager.quantumLifetime, equals(20)); // Inchangé
    });
    
    test('spendQuantum échoue si solde insuffisant', () {
      manager.addQuantum(5);
      final success = manager.spendQuantum(10);
      
      expect(success, isFalse);
      expect(manager.quantum, equals(5));
      expect(manager.quantumSpent, equals(0));
    });
    
    test('spendQuantum échoue si montant négatif ou zéro', () {
      manager.addQuantum(10);
      
      expect(manager.spendQuantum(0), isFalse);
      expect(manager.spendQuantum(-5), isFalse);
      expect(manager.quantum, equals(10));
    });
    
    test('canSpendQuantum vérifie correctement le solde', () {
      manager.addQuantum(15);
      
      expect(manager.canSpendQuantum(10), isTrue);
      expect(manager.canSpendQuantum(15), isTrue);
      expect(manager.canSpendQuantum(16), isFalse);
      expect(manager.canSpendQuantum(0), isFalse);
      expect(manager.canSpendQuantum(-5), isFalse);
    });
    
    test('Quantum - dépenses multiples', () {
      manager.addQuantum(100);
      
      manager.spendQuantum(30);
      expect(manager.quantum, equals(70));
      expect(manager.quantumSpent, equals(30));
      
      manager.spendQuantum(20);
      expect(manager.quantum, equals(50));
      expect(manager.quantumSpent, equals(50));
      
      expect(manager.quantumLifetime, equals(100));
    });
    
    // ========================================================================
    // Tests Points Innovation
    // ========================================================================
    
    test('addPointsInnovation augmente pointsInnovation et innovationPointsLifetime', () {
      manager.addPointsInnovation(30);
      
      expect(manager.pointsInnovation, equals(30));
      expect(manager.innovationPointsLifetime, equals(30));
      
      manager.addPointsInnovation(10);
      
      expect(manager.pointsInnovation, equals(40));
      expect(manager.innovationPointsLifetime, equals(40));
    });
    
    test('addPointsInnovation avec montant négatif ou zéro ne fait rien', () {
      manager.addPointsInnovation(0);
      expect(manager.pointsInnovation, equals(0));
      
      manager.addPointsInnovation(-10);
      expect(manager.pointsInnovation, equals(0));
    });
    
    test('spendPointsInnovation diminue pointsInnovation et augmente innovationPointsSpent', () {
      manager.addPointsInnovation(50);
      final success = manager.spendPointsInnovation(20);
      
      expect(success, isTrue);
      expect(manager.pointsInnovation, equals(30));
      expect(manager.innovationPointsSpent, equals(20));
      expect(manager.innovationPointsLifetime, equals(50)); // Inchangé
    });
    
    test('spendPointsInnovation échoue si solde insuffisant', () {
      manager.addPointsInnovation(10);
      final success = manager.spendPointsInnovation(15);
      
      expect(success, isFalse);
      expect(manager.pointsInnovation, equals(10));
      expect(manager.innovationPointsSpent, equals(0));
    });
    
    test('canSpendPointsInnovation vérifie correctement le solde', () {
      manager.addPointsInnovation(25);
      
      expect(manager.canSpendPointsInnovation(10), isTrue);
      expect(manager.canSpendPointsInnovation(25), isTrue);
      expect(manager.canSpendPointsInnovation(26), isFalse);
      expect(manager.canSpendPointsInnovation(0), isFalse);
    });
    
    // ========================================================================
    // Tests Total Resets
    // ========================================================================
    
    test('recordReset augmente le compteur et enregistre l\'historique', () {
      expect(manager.totalResets, equals(0));
      expect(manager.resetHistory.length, equals(0));
      
      manager.recordReset(
        quantumGained: 50,
        innovationPointsGained: 20,
        levelReached: 25,
        paperclipsProduced: 1000000,
        moneyEarned: 50000,
        autoclippersOwned: 10,
        playTimeHours: 5.5,
      );
      expect(manager.totalResets, equals(1));
      expect(manager.resetHistory.length, equals(1));
      
      manager.recordReset(
        quantumGained: 75,
        innovationPointsGained: 30,
        levelReached: 30,
        paperclipsProduced: 2000000,
        moneyEarned: 100000,
        autoclippersOwned: 15,
        playTimeHours: 8.0,
      );
      expect(manager.totalResets, equals(2));
      expect(manager.resetHistory.length, equals(2));
    });
    
    // ========================================================================
    // Tests Reset Ressources
    // ========================================================================
    
    test('resetResources avec keepRareResources=true conserve les ressources', () {
      manager.addQuantum(50);
      manager.addPointsInnovation(30);
      manager.recordReset(
        quantumGained: 50,
        innovationPointsGained: 30,
        levelReached: 20,
        paperclipsProduced: 500000,
        moneyEarned: 25000,
        autoclippersOwned: 5,
        playTimeHours: 3.0,
      );
      
      manager.resetResources(keepRareResources: true);
      
      expect(manager.quantum, equals(50));
      expect(manager.pointsInnovation, equals(30));
      expect(manager.totalResets, equals(1));
    });
    
    test('resetResources avec keepRareResources=false réinitialise tout', () {
      manager.addQuantum(50);
      manager.spendQuantum(10);
      manager.addPointsInnovation(30);
      manager.recordReset(
        quantumGained: 40,
        innovationPointsGained: 30,
        levelReached: 20,
        paperclipsProduced: 500000,
        moneyEarned: 25000,
        autoclippersOwned: 5,
        playTimeHours: 3.0,
      );
      
      manager.resetResources(keepRareResources: false);
      
      expect(manager.quantum, equals(0));
      expect(manager.pointsInnovation, equals(0));
      expect(manager.totalResets, equals(0));
      expect(manager.quantumLifetime, equals(0));
      expect(manager.innovationPointsLifetime, equals(0));
      expect(manager.quantumSpent, equals(0));
      expect(manager.innovationPointsSpent, equals(0));
      expect(manager.resetHistory.length, equals(0));
    });
    
    // ========================================================================
    // Tests Persistence (JSON)
    // ========================================================================
    
    test('toJson sérialise toutes les données correctement', () {
      manager.addQuantum(50);
      manager.spendQuantum(10);
      manager.addPointsInnovation(30);
      manager.spendPointsInnovation(5);
      manager.recordReset(
        quantumGained: 40,
        innovationPointsGained: 25,
        levelReached: 20,
        paperclipsProduced: 500000,
        moneyEarned: 25000,
        autoclippersOwned: 5,
        playTimeHours: 3.0,
      );
      
      final json = manager.toJson();
      
      expect(json['quantum'], equals(40));
      expect(json['quantumLifetime'], equals(50));
      expect(json['quantumSpent'], equals(10));
      expect(json['pointsInnovation'], equals(25));
      expect(json['innovationPointsLifetime'], equals(30));
      expect(json['innovationPointsSpent'], equals(5));
      expect(json['totalResets'], equals(1));
      expect(json['resetHistory'], isA<List>());
      expect((json['resetHistory'] as List).length, equals(1));
    });
    
    test('fromJson restaure toutes les données correctement', () {
      final json = {
        'quantum': 40,
        'quantumLifetime': 50,
        'quantumSpent': 10,
        'pointsInnovation': 25,
        'innovationPointsLifetime': 30,
        'innovationPointsSpent': 5,
        'totalResets': 2,
      };
      
      manager.fromJson(json);
      
      expect(manager.quantum, equals(40));
      expect(manager.quantumLifetime, equals(50));
      expect(manager.quantumSpent, equals(10));
      expect(manager.pointsInnovation, equals(25));
      expect(manager.innovationPointsLifetime, equals(30));
      expect(manager.innovationPointsSpent, equals(5));
      expect(manager.totalResets, equals(2));
    });
    
    test('fromJson avec données manquantes utilise valeurs par défaut', () {
      final json = {
        'quantum': 20,
        // Autres champs manquants
      };
      
      manager.fromJson(json);
      
      expect(manager.quantum, equals(20));
      expect(manager.pointsInnovation, equals(0));
      expect(manager.totalResets, equals(0));
      expect(manager.quantumLifetime, equals(0));
    });
    
    test('Cycle complet toJson -> fromJson préserve les données', () {
      manager.addQuantum(100);
      manager.spendQuantum(25);
      manager.addPointsInnovation(60);
      manager.spendPointsInnovation(15);
      manager.recordReset(
        quantumGained: 75,
        innovationPointsGained: 45,
        levelReached: 25,
        paperclipsProduced: 1000000,
        moneyEarned: 50000,
        autoclippersOwned: 10,
        playTimeHours: 5.0,
      );
      manager.recordReset(
        quantumGained: 100,
        innovationPointsGained: 60,
        levelReached: 30,
        paperclipsProduced: 2000000,
        moneyEarned: 100000,
        autoclippersOwned: 15,
        playTimeHours: 8.0,
      );
      
      final json = manager.toJson();
      final newManager = RareResourcesManager();
      newManager.fromJson(json);
      
      expect(newManager.quantum, equals(manager.quantum));
      expect(newManager.quantumLifetime, equals(manager.quantumLifetime));
      expect(newManager.quantumSpent, equals(manager.quantumSpent));
      expect(newManager.pointsInnovation, equals(manager.pointsInnovation));
      expect(newManager.innovationPointsLifetime, equals(manager.innovationPointsLifetime));
      expect(newManager.innovationPointsSpent, equals(manager.innovationPointsSpent));
      expect(newManager.totalResets, equals(manager.totalResets));
      expect(newManager.resetHistory.length, equals(manager.resetHistory.length));
    });
  });
}
