import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/models/statistics_manager.dart';

void main() {
  group('StatisticsManager', () {
    test('updateProduction: mode auto incrémente totals + autoPaperclipsProduced', () {
      final stats = StatisticsManager();

      stats.updateProduction(paperclipsProduced: 2, metalUsed: 1.5, isAuto: true);

      expect(stats.totalPaperclipsProduced, 2);
      expect(stats.totalMetalUsed, 1.5);
      expect(stats.autoPaperclipsProduced, 2);
      expect(stats.manualPaperclipsProduced, 0);
    });

    test('updateProduction: mode manuel via isManual+amount incrémente manualPaperclipsProduced', () {
      final stats = StatisticsManager();

      stats.updateProduction(isManual: true, amount: 3, metalUsed: 2.0);

      expect(stats.totalPaperclipsProduced, 3);
      expect(stats.totalMetalUsed, 2.0);
      expect(stats.manualPaperclipsProduced, 3);
      expect(stats.autoPaperclipsProduced, 0);
    });

    test('updateProduction: si auto/manual ambigu, compte en auto par défaut', () {
      final stats = StatisticsManager();

      stats.updateProduction(paperclipsProduced: 4, metalUsed: 4.0);

      expect(stats.totalPaperclipsProduced, 4);
      expect(stats.autoPaperclipsProduced, 4);
      expect(stats.manualPaperclipsProduced, 0);
    });

    test('updateEconomics cumule moneyEarned et moneySpent + netProfit via getAllStats', () {
      final stats = StatisticsManager();

      stats.updateEconomics(moneyEarned: 10, moneySpent: 4);

      expect(stats.totalMoneyEarned, 10);
      expect(stats.totalMoneySpent, 4);

      final all = stats.getAllStats();
      expect(all['economy']!['netProfit'], 6);
    });

    test('updateGameTime incrémente totalGameTimeSec', () {
      final stats = StatisticsManager();

      stats.updateGameTime(5);
      stats.updateGameTime(7);

      expect(stats.totalGameTimeSec, 12);
      expect(stats.totalPlayTimeSeconds, 12);
    });

    test('toJson/loadFromJson roundtrip restaure les compteurs clés', () {
      final stats = StatisticsManager();

      stats.updateProduction(paperclipsProduced: 5, metalUsed: 2.5, isAuto: true);
      stats.updateEconomics(moneyEarned: 7, moneySpent: 3);
      stats.updateResources(metalPurchased: 12);
      stats.setTotalGameTimeSec(42);

      final json = stats.toJson();

      final restored = StatisticsManager();
      restored.loadFromJson(json);

      expect(restored.totalPaperclipsProduced, stats.totalPaperclipsProduced);
      expect(restored.totalMetalUsed, stats.totalMetalUsed);
      expect(restored.totalMoneyEarned, stats.totalMoneyEarned);
      expect(restored.totalMoneySpent, stats.totalMoneySpent);
      expect(restored.totalMetalPurchased, stats.totalMetalPurchased);
      expect(restored.totalGameTimeSec, stats.totalGameTimeSec);
    });
  });
}
