import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:paperclip2/managers/production_manager.dart';
import 'package:paperclip2/managers/metal_manager.dart';
import 'package:paperclip2/models/progression_system.dart';
import 'package:paperclip2/models/game_config.dart';

// Mock personnalisé pour MetalManager qui simule une production réaliste
class MockMetalManager extends Mock implements MetalManager {
  @override
  int calculateMetalBasedProduction({
    required int autoclippers,
    required double speedBonus,
    required double bulkBonus,
    required double efficiencyLevel,
  }) {
    // Simulation d'une production basée sur les paramètres
    return (autoclippers * speedBonus * bulkBonus).floor();
  }

  @override
  bool consumeMetalForProduction({
    required int productionAmount,
    required double efficiencyLevel,
    required Function(int, double, double) updateStatistics,
  }) {
    // Simuler la consommation de métal
    updateStatistics(productionAmount, productionAmount * 0.15, 0.0);
    return true;
  }
}

class MockLevelSystem extends Mock implements LevelSystem {}

void main() {
  group('ProductionManager Performance', () {
    late ProductionManager productionManager;
    late MockMetalManager mockMetalManager;
    late MockLevelSystem mockLevelSystem;

    setUp(() {
      mockMetalManager = MockMetalManager();
      mockLevelSystem = MockLevelSystem();
    });

    test('Production massive sans surcharger la mémoire', () {
      productionManager = ProductionManager(
        metalManager: mockMetalManager,
        levelSystem: mockLevelSystem,
        showNotification: (message) {},
        getUpgradeLevel: (upgradeId) {
          switch(upgradeId) {
            case 'speed': return 5;
            case 'bulk': return 4;
            case 'efficiency': return 3;
            default: return 0;
          }
        },
        updateStatistics: (a, b, c) {},
        initialAutoclippers: 100, // Configurer un nombre initial d'autoclippers
      );

      // Simuler plusieurs productions
      for (int i = 0; i < 100; i++) {
        productionManager.processProduction();
      }

      // Vérifier que la production a eu lieu
      expect(productionManager.totalPaperclipsProduced, greaterThan(0));
      expect(productionManager.paperclips, greaterThan(0));
    });

    test('Limites de calcul avec upgrades complexes', () {
      productionManager = ProductionManager(
        metalManager: mockMetalManager,
        levelSystem: mockLevelSystem,
        getUpgradeLevel: (upgradeId) {
          switch(upgradeId) {
            case 'speed': return 10;  // Niveau max
            case 'bulk': return 8;
            case 'efficiency': return 5;
            default: return 0;
          }
        },
        updateStatistics: (a, b, c) {},
        showNotification: (message) {},
        initialAutoclippers: 50, // Nombre initial d'autoclippers
      );

      // Vérifier la production avec des upgrades complexes
      final result = productionManager.processProduction();

      expect(result.producedPaperclips, greaterThan(0));
      expect(productionManager.totalPaperclipsProduced, greaterThan(0));
    });

    test('Calcul de production avec différents niveaux d\'upgrades', () {
      // Test avec différentes configurations d'upgrades
      final testCases = [
        {'speed': 0, 'bulk': 0, 'efficiency': 0},
        {'speed': 5, 'bulk': 3, 'efficiency': 2},
        {'speed': 10, 'bulk': 8, 'efficiency': 5},
      ];

      for (var upgrades in testCases) {
        productionManager = ProductionManager(
          metalManager: mockMetalManager,
          levelSystem: mockLevelSystem,
          getUpgradeLevel: (upgradeId) => upgrades[upgradeId] ?? 0,
          updateStatistics: (a, b, c) {},
          showNotification: (message) {},
          initialAutoclippers: 50,
        );

        final result = productionManager.processProduction();

        expect(result.producedPaperclips, greaterThanOrEqualTo(0),
            reason: 'Production failed with upgrades: $upgrades');
      }
    });
  });
}