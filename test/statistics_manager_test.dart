import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/statistics_manager.dart';

void main() {
  group('StatisticsManager', () {
    test('reset initializes counters to zero and updates listeners', () {
      final stats = StatisticsManager();
      stats.updateProduction(paperclipsProduced: 10, metalUsed: 1.5, isAuto: true);
      expect(stats.totalPaperclipsProduced, 10);
      expect(stats.totalMetalUsed, 1.5);

      stats.reset();
      expect(stats.totalPaperclipsProduced, 0);
      expect(stats.totalMetalUsed, 0.0);
      expect(stats.manualPaperclipsProduced, 0);
      expect(stats.autoPaperclipsProduced, 0);
      expect(stats.totalMoneyEarned, 0.0);
      expect(stats.totalMoneySpent, 0.0);
    });

    test('updateProduction distributes between manual and auto reasonably', () {
      final stats = StatisticsManager();
      stats.updateProduction(paperclipsProduced: 5, metalUsed: 0.5, isAuto: true);
      expect(stats.totalPaperclipsProduced, 5);
      expect(stats.autoPaperclipsProduced, 5);
      expect(stats.manualPaperclipsProduced, 0);

      stats.updateProduction(isManual: true, amount: 3, metalUsed: 0.3);
      expect(stats.totalPaperclipsProduced, 8);
      expect(stats.manualPaperclipsProduced, 3);
    });

    test('updateEconomics aggregates earnings and spending', () {
      final stats = StatisticsManager();
      stats.updateEconomics(moneyEarned: 10.0);
      stats.updateEconomics(moneySpent: 4.0);
      expect(stats.totalMoneyEarned, 10.0);
      expect(stats.totalMoneySpent, 4.0);
      final all = stats.getAllStats();
      expect(all['economy']!['netProfit'], 6.0);
    });

    test('updateResources aggregates resource counters', () {
      final stats = StatisticsManager();
      stats.updateResources(metalPurchased: 100.0, ironMined: 5.0);
      expect(stats.totalMetalPurchased, 100.0);
      expect(stats.totalIronMined, 5.0);
    });

    test('time setters update total play time', () {
      final stats = StatisticsManager();
      stats.setTotalGameTimeSec(120);
      expect(stats.totalPlayTimeSeconds, 120);
      stats.updateGameTime(30);
      expect(stats.totalPlayTimeSeconds, 150);
    });
  });
}
