abstract class StatisticsRepository {
  Future<Statistics> getStatistics();
  Future<void> updateStatistics(Statistics statistics);
  Future<void> updateProduction({
    bool isManual = false,
    int amount = 1,
    required double metalUsed,
    double metalSaved = 0.0,
    double efficiency = 0.0,
  });
  Future<void> updateEconomics({
    double? moneyEarned,
    double? moneySpent,
    double? metalBought,
    int? sales,
    double? price,
  });
  Future<void> updateProgression({
    int? upgradesBought,
    int? autoclippersBought,
    int? maxCombo,
    Duration? playTime,
  });
  Future<Map<String, Map<String, dynamic>>> getAllStats();
}