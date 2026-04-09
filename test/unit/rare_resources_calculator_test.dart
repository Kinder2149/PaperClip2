import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/rare_resources/rare_resources_calculator.dart';
import 'package:paperclip2/constants/rare_resources_constants.dart';

void main() {
  group('RareResourcesCalculator - Quantum', () {
    // ========================================================================
    // Tests Calculs Basiques
    // ========================================================================
    
    test('Calcul débutant (500k trombones, niveau 15)', () {
      final quantum = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 500000,
        totalMoneyEarned: 2000,
        autoClipperCount: 10,
        playerLevel: 15,
        playTimeHours: 3.0,
        resetCount: 0, // Premier reset
      );
      
      // Attendu : ~84 Q (avec bonus ×1.5 premier reset)
      expect(quantum, greaterThanOrEqualTo(70));
      expect(quantum, lessThanOrEqualTo(100));
    });
    
    test('Calcul intermédiaire (5M trombones, niveau 25)', () {
      final quantum = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 5000000,
        totalMoneyEarned: 25000,
        autoClipperCount: 30,
        playerLevel: 25,
        playTimeHours: 5.0,
        resetCount: 1,
      );
      
      // Attendu : ~124 Q
      expect(quantum, greaterThanOrEqualTo(110));
      expect(quantum, lessThanOrEqualTo(140));
    });
    
    test('Calcul avancé (50M trombones, niveau 35)', () {
      final quantum = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 50000000,
        totalMoneyEarned: 200000,
        autoClipperCount: 60,
        playerLevel: 35,
        playTimeHours: 8.0,
        resetCount: 2,
      );
      
      // Attendu : ~195 Q
      expect(quantum, greaterThanOrEqualTo(150));
      expect(quantum, lessThanOrEqualTo(230));
    });
    
    // ========================================================================
    // Tests Bonus Premier Reset
    // ========================================================================
    
    test('Bonus premier reset (×1.5) appliqué correctement', () {
      final params = {
        'totalPaperclipsProduced': 5000000,
        'totalMoneyEarned': 25000.0,
        'autoClipperCount': 30,
        'playerLevel': 25,
        'playTimeHours': 5.0,
      };
      
      final firstReset = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: params['totalPaperclipsProduced'] as int,
        totalMoneyEarned: params['totalMoneyEarned'] as double,
        autoClipperCount: params['autoClipperCount'] as int,
        playerLevel: params['playerLevel'] as int,
        playTimeHours: params['playTimeHours'] as double,
        resetCount: 0,
      );
      
      final secondReset = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: params['totalPaperclipsProduced'] as int,
        totalMoneyEarned: params['totalMoneyEarned'] as double,
        autoClipperCount: params['autoClipperCount'] as int,
        playerLevel: params['playerLevel'] as int,
        playTimeHours: params['playTimeHours'] as double,
        resetCount: 1,
      );
      
      expect(firstReset, greaterThan(secondReset));
      // Ratio devrait être proche de 1.5
      expect(firstReset / secondReset, closeTo(1.5, 0.2));
    });
    
    test('Bonus premier reset ne s\'applique qu\'au reset 0', () {
      final quantum2 = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 5000000,
        totalMoneyEarned: 25000,
        autoClipperCount: 30,
        playerLevel: 25,
        playTimeHours: 5.0,
        resetCount: 1,
      );
      
      final quantum3 = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 5000000,
        totalMoneyEarned: 25000,
        autoClipperCount: 30,
        playerLevel: 25,
        playTimeHours: 5.0,
        resetCount: 2,
      );
      
      // Pas de bonus, donc même résultat
      expect(quantum2, equals(quantum3));
    });
    
    // ========================================================================
    // Tests Plafonds
    // ========================================================================
    
    test('Plafond maximum (500 Q) respecté', () {
      final quantum = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 1000000000000,
        totalMoneyEarned: 100000000,
        autoClipperCount: 1000,
        playerLevel: 100,
        playTimeHours: 1000.0,
        resetCount: 5,
      );
      
      expect(quantum, equals(RareResourcesConstants.QUANTUM_MAX_CAP));
    });
    
    test('Minimum garanti (20 Q) même avec progression nulle', () {
      final quantum = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 0,
        totalMoneyEarned: 0,
        autoClipperCount: 0,
        playerLevel: 1,
        playTimeHours: 0.1,
        resetCount: 1,
      );
      
      expect(quantum, equals(RareResourcesConstants.QUANTUM_BASE_RESET));
    });
    
    test('Minimum garanti même avec bonus premier reset', () {
      final quantum = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 0,
        totalMoneyEarned: 0,
        autoClipperCount: 0,
        playerLevel: 1,
        playTimeHours: 0.1,
        resetCount: 0,
      );
      
      // BASE × 1.5 = 30 Q
      expect(quantum, greaterThanOrEqualTo(RareResourcesConstants.QUANTUM_BASE_RESET));
    });
    
    // ========================================================================
    // Tests Composants Individuels
    // ========================================================================
    
    test('Composant PRODUCTION - sous seuil ne contribue pas', () {
      final quantumSousSeuil = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 500000, // < 1M
        totalMoneyEarned: 0,
        autoClipperCount: 0,
        playerLevel: 1,
        playTimeHours: 0,
        resetCount: 1,
      );
      
      final quantumAuSeuil = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 1000000, // = 1M
        totalMoneyEarned: 0,
        autoClipperCount: 0,
        playerLevel: 1,
        playTimeHours: 0,
        resetCount: 1,
      );
      
      // Au seuil, log(1) = 0, donc pas de contribution non plus
      expect(quantumSousSeuil, equals(quantumAuSeuil));
      expect(quantumSousSeuil, equals(RareResourcesConstants.QUANTUM_BASE_RESET));
    });
    
    test('Composant PRODUCTION - échelle logarithmique', () {
      final quantum10M = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 10000000, // 10M
        totalMoneyEarned: 0,
        autoClipperCount: 0,
        playerLevel: 1,
        playTimeHours: 0,
        resetCount: 1,
      );
      
      final quantum100M = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 100000000, // 100M
        totalMoneyEarned: 0,
        autoClipperCount: 0,
        playerLevel: 1,
        playTimeHours: 0,
        resetCount: 1,
      );
      
      // log10(10) = 1, log10(100) = 2
      // Différence devrait être ~15 Q (1 ordre de grandeur × 15)
      expect(quantum100M - quantum10M, closeTo(15, 5));
    });
    
    test('Composant REVENUS - sous seuil ne contribue pas', () {
      final quantumSousSeuil = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 0,
        totalMoneyEarned: 5000, // < 10k
        autoClipperCount: 0,
        playerLevel: 1,
        playTimeHours: 0,
        resetCount: 1,
      );
      
      expect(quantumSousSeuil, equals(RareResourcesConstants.QUANTUM_BASE_RESET));
    });
    
    test('Composant AUTOCLIPPERS - linéaire', () {
      final quantum10AC = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 0,
        totalMoneyEarned: 0,
        autoClipperCount: 10,
        playerLevel: 1,
        playTimeHours: 0,
        resetCount: 1,
      );
      
      final quantum20AC = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 0,
        totalMoneyEarned: 0,
        autoClipperCount: 20,
        playerLevel: 1,
        playTimeHours: 0,
        resetCount: 1,
      );
      
      // Différence = 10 × 0.8 = 8 Q
      expect(quantum20AC - quantum10AC, equals(8));
    });
    
    test('Composant TEMPS - plafonné à 50', () {
      final quantum100h = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 0,
        totalMoneyEarned: 0,
        autoClipperCount: 0,
        playerLevel: 1,
        playTimeHours: 100.0,
        resetCount: 1,
      );
      
      final quantum1000h = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 0,
        totalMoneyEarned: 0,
        autoClipperCount: 0,
        playerLevel: 1,
        playTimeHours: 1000.0,
        resetCount: 1,
      );
      
      // Les deux devraient être plafonnés à BASE + 50
      expect(quantum100h, equals(quantum1000h));
      expect(quantum100h, equals(RareResourcesConstants.QUANTUM_BASE_RESET + 
                                  RareResourcesConstants.QUANTUM_TIME_CAP));
    });
  });
  
  // ==========================================================================
  // Tests Points Innovation
  // ==========================================================================
  
  group('RareResourcesCalculator - Innovation Points', () {
    test('Calcul basique', () {
      final points = RareResourcesCalculator.calculateInnovationPointsReward(
        researchesCompleted: 8,
        playerLevel: 30,
        quantumGained: 85,
      );
      
      // BASE(10) + RECHERCHES(16) + NIVEAU(15) + QUANTUM(8.5) = ~49 PI
      expect(points, greaterThanOrEqualTo(40));
      expect(points, lessThanOrEqualTo(55));
    });
    
    test('Bonus Quantum appliqué correctement', () {
      final lowQuantum = RareResourcesCalculator.calculateInnovationPointsReward(
        researchesCompleted: 10,
        playerLevel: 30,
        quantumGained: 50,
      );
      
      final highQuantum = RareResourcesCalculator.calculateInnovationPointsReward(
        researchesCompleted: 10,
        playerLevel: 30,
        quantumGained: 200,
      );
      
      expect(highQuantum, greaterThan(lowQuantum));
      // Différence = (200-50)/10 = 15 PI
      expect(highQuantum - lowQuantum, equals(15));
    });
    
    test('Plafond maximum (100 PI) respecté', () {
      final points = RareResourcesCalculator.calculateInnovationPointsReward(
        researchesCompleted: 100,
        playerLevel: 100,
        quantumGained: 500,
      );
      
      expect(points, equals(RareResourcesConstants.INNOVATION_MAX_CAP));
    });
    
    test('Minimum garanti (10 PI) même avec progression nulle', () {
      final points = RareResourcesCalculator.calculateInnovationPointsReward(
        researchesCompleted: 0,
        playerLevel: 1,
        quantumGained: 20,
      );
      
      // BASE(10) + NIVEAU(0.5) + QUANTUM(2) = 12 PI
      expect(points, greaterThanOrEqualTo(10));
      expect(points, lessThanOrEqualTo(15));
    });
    
    test('Composant RECHERCHES - linéaire', () {
      final points5 = RareResourcesCalculator.calculateInnovationPointsReward(
        researchesCompleted: 5,
        playerLevel: 20,
        quantumGained: 50,
      );
      
      final points10 = RareResourcesCalculator.calculateInnovationPointsReward(
        researchesCompleted: 10,
        playerLevel: 20,
        quantumGained: 50,
      );
      
      // Différence = 5 × 2 = 10 PI
      expect(points10 - points5, equals(10));
    });
    
    test('Composant NIVEAU - linéaire', () {
      final points20 = RareResourcesCalculator.calculateInnovationPointsReward(
        researchesCompleted: 5,
        playerLevel: 20,
        quantumGained: 50,
      );
      
      final points40 = RareResourcesCalculator.calculateInnovationPointsReward(
        researchesCompleted: 5,
        playerLevel: 40,
        quantumGained: 50,
      );
      
      // Différence = 20 × 0.5 = 10 PI
      expect(points40 - points20, equals(10));
    });
    
    test('Progression typique - Reset 1', () {
      final points = RareResourcesCalculator.calculateInnovationPointsReward(
        researchesCompleted: 0,
        playerLevel: 20,
        quantumGained: 30,
      );
      
      // BASE(10) + RECHERCHES(0) + NIVEAU(10) + QUANTUM(3) = 23 PI
      expect(points, greaterThanOrEqualTo(20));
      expect(points, lessThanOrEqualTo(25));
    });
    
    test('Progression typique - Reset 2', () {
      final points = RareResourcesCalculator.calculateInnovationPointsReward(
        researchesCompleted: 8,
        playerLevel: 30,
        quantumGained: 85,
      );
      
      // BASE(10) + RECHERCHES(16) + NIVEAU(15) + QUANTUM(8.5) = ~49 PI
      expect(points, greaterThanOrEqualTo(45));
      expect(points, lessThanOrEqualTo(52));
    });
    
    test('Progression typique - Reset 3', () {
      final points = RareResourcesCalculator.calculateInnovationPointsReward(
        researchesCompleted: 15,
        playerLevel: 40,
        quantumGained: 195,
      );
      
      // BASE(10) + RECHERCHES(30) + NIVEAU(20) + QUANTUM(19.5) = ~79 PI
      expect(points, greaterThanOrEqualTo(75));
      expect(points, lessThanOrEqualTo(82));
    });
  });
  
  // ==========================================================================
  // Tests Intégration Quantum + Innovation
  // ==========================================================================
  
  group('RareResourcesCalculator - Intégration', () {
    test('Scénario complet Reset 1 (débutant)', () {
      final quantum = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 500000,
        totalMoneyEarned: 2000,
        autoClipperCount: 10,
        playerLevel: 15,
        playTimeHours: 3.0,
        resetCount: 0,
      );
      
      final points = RareResourcesCalculator.calculateInnovationPointsReward(
        researchesCompleted: 0,
        playerLevel: 15,
        quantumGained: quantum,
      );
      
      expect(quantum, greaterThanOrEqualTo(70));
      expect(quantum, lessThanOrEqualTo(100));
      expect(points, greaterThanOrEqualTo(15));
      expect(points, lessThanOrEqualTo(25));
    });
    
    test('Scénario complet Reset 2 (intermédiaire)', () {
      final quantum = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 5000000,
        totalMoneyEarned: 25000,
        autoClipperCount: 30,
        playerLevel: 25,
        playTimeHours: 5.0,
        resetCount: 1,
      );
      
      final points = RareResourcesCalculator.calculateInnovationPointsReward(
        researchesCompleted: 8,
        playerLevel: 25,
        quantumGained: quantum,
      );
      
      expect(quantum, greaterThanOrEqualTo(110));
      expect(quantum, lessThanOrEqualTo(140));
      expect(points, greaterThanOrEqualTo(35));
      expect(points, lessThanOrEqualTo(55));
    });
    
    test('Scénario complet Reset 3 (avancé)', () {
      final quantum = RareResourcesCalculator.calculateQuantumReward(
        totalPaperclipsProduced: 50000000,
        totalMoneyEarned: 200000,
        autoClipperCount: 60,
        playerLevel: 35,
        playTimeHours: 8.0,
        resetCount: 2,
      );
      
      final points = RareResourcesCalculator.calculateInnovationPointsReward(
        researchesCompleted: 15,
        playerLevel: 35,
        quantumGained: quantum,
      );
      
      expect(quantum, greaterThanOrEqualTo(150));
      expect(quantum, lessThanOrEqualTo(230));
      expect(points, greaterThanOrEqualTo(60));
      expect(points, lessThanOrEqualTo(85));
    });
  });
}
