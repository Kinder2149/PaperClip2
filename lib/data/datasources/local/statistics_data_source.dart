// lib/data/datasources/local/statistics_data_source.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/statistics_model.dart';
import '../../../core/constants/game_constants.dart';

abstract class StatisticsDataSource {
  Future<StatisticsModel> getStatistics();
  Future<void> updateStatistics(StatisticsModel statistics);
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
}

class StatisticsDataSourceImpl implements StatisticsDataSource {
  final SharedPreferences _prefs;
  static const String _statisticsKey = 'game_statistics';

  StatisticsDataSourceImpl(this._prefs);

  @override
  Future<StatisticsModel> getStatistics() async {
    final jsonString = _prefs.getString(_statisticsKey);

    if (jsonString == null) {
      // Retourne un modèle de statistiques par défaut
      return StatisticsModel(
        totalPaperclipsProduced: 0,
        manualPaperclipsProduced: 0,
        autoPaperclipsProduced: 0,
        totalMetalUsed: 0.0,
        totalMetalSaved: 0.0,
        currentEfficiency: 0.0,
        totalMoneyEarned: 0.0,
        totalMoneySpent: 0.0,
        totalMetalBought: 0.0,
        totalSales: 0,
        highestPrice: 0.0,
        averagePrice: 0.0,
        totalUpgradesBought: 0,
        totalAutoclippersBought: 0,
        maxComboAchieved: 0,
        totalPlayTime: Duration.zero,
      );
    }

    return StatisticsModel.fromJson(json.decode(jsonString));
  }

  @override
  Future<void> updateStatistics(StatisticsModel statistics) async {
    await _prefs.setString(
        _statisticsKey,
        json.encode(statistics.toJson())
    );
  }

  @override
  Future<void> updateProduction({
    bool isManual = false,
    int amount = 1,
    required double metalUsed,
    double metalSaved = 0.0,
    double efficiency = 0.0,
  }) async {
    final currentStats = await getStatistics();

    final updatedStats = currentStats.copyWith(
      totalPaperclipsProduced: currentStats.totalPaperclipsProduced + amount,
      manualPaperclipsProduced: isManual
          ? currentStats.manualPaperclipsProduced + amount
          : currentStats.manualPaperclipsProduced,
      autoPaperclipsProduced: !isManual
          ? currentStats.autoPaperclipsProduced + amount
          : currentStats.autoPaperclipsProduced,
      totalMetalUsed: currentStats.totalMetalUsed + metalUsed,
      totalMetalSaved: currentStats.totalMetalSaved + metalSaved,
      currentEfficiency: efficiency,
    );

    await updateStatistics(updatedStats);
  }

  @override
  Future<void> updateEconomics({
    double? moneyEarned,
    double? moneySpent,
    double? metalBought,
    int? sales,
    double? price,
  }) async {
    final currentStats = await getStatistics();

    final updatedStats = currentStats.copyWith(
      totalMoneyEarned: moneyEarned != null
          ? currentStats.totalMoneyEarned + moneyEarned
          : currentStats.totalMoneyEarned,
      totalMoneySpent: moneySpent != null
          ? currentStats.totalMoneySpent + moneySpent
          : currentStats.totalMoneySpent,
      totalMetalBought: metalBought != null
          ? currentStats.totalMetalBought + metalBought
          : currentStats.totalMetalBought,
      totalSales: sales != null
          ? currentStats.totalSales + sales
          : currentStats.totalSales,
      highestPrice: price != null
          ? (price > currentStats.highestPrice ? price : currentStats.highestPrice)
          : currentStats.highestPrice,
      averagePrice: price != null
          ? ((currentStats.averagePrice * currentStats.totalSales) + price) / (currentStats.totalSales + 1)
          : currentStats.averagePrice,
    );

    await updateStatistics(updatedStats);
  }

  @override
  Future<void> updateProgression({
    int? upgradesBought,
    int? autoclippersBought,
    int? maxCombo,
    Duration? playTime,
  }) async {
    final currentStats = await getStatistics();

    final updatedStats = currentStats.copyWith(
      totalUpgradesBought: upgradesBought != null
          ? currentStats.totalUpgradesBought + upgradesBought
          : currentStats.totalUpgradesBought,
      totalAutoclippersBought: autoclippersBought != null
          ? currentStats.totalAutoclippersBought + autoclippersBought
          : currentStats.totalAutoclippersBought,
      maxComboAchieved: maxCombo != null
          ? (maxCombo > currentStats.maxComboAchieved ? maxCombo : currentStats.maxComboAchieved)
          : currentStats.maxComboAchieved,
      totalPlayTime: playTime != null
          ? currentStats.totalPlayTime + playTime
          : currentStats.totalPlayTime,
    );

    await updateStatistics(updatedStats);
  }
}