// test/statistics_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/managers/statistics_manager.dart';

void main() {
  group('StatisticsManager', () {
    late StatisticsManager statisticsManager;

    setUp(() {
      statisticsManager = StatisticsManager();
    });

    test('Initialisation correcte', () {
      expect(statisticsManager.getTotalMoneyEarned(), 0.0);
      expect(statisticsManager.getTotalMetalUsed(), 0.0);
    });

    test('Mise à jour de la production manuelle', () {
      statisticsManager.updateProduction(
        isManual: true,
        amount: 10,
        metalUsed: 5.0,
        metalSaved: 1.0,
        efficiency: 0.5,
      );

      // Ajoutez des assertions pour vérifier les valeurs mises à jour
    });

    test('Validation des exceptions', () {
      expect(
            () => statisticsManager.updateProduction(
          amount: -1,
          metalUsed: 5.0,
        ),
        throwsA(isA<StatisticsManagerException>()),
      );

      expect(
            () => statisticsManager.updateProduction(
          amount: 10,
          metalUsed: -5.0,
        ),
        throwsA(isA<StatisticsManagerException>()),
      );
    });

    test('Analyse des tendances de vente', () {
      final trends = statisticsManager.analyzeSalesTrends();
      expect(trends['trend'], 'undefined');
    });
  });
}