// lib/data/repositories/statistics_repository_impl.dart
import '../../domain/repositories/statistics_repository.dart';
import '../datasources/local/statistics_data_source.dart';
import '../../domain/entities/statistics_entity.dart';
import '../models/statistics_model.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final StatisticsDataSource _dataSource;

  StatisticsRepositoryImpl(this._dataSource);

  @override
  Future<StatisticsEntity> getStatistics() async {
    final statisticsModel = await _dataSource.getStatistics();
    return statisticsModel.toEntity();
  }

  @override
  Future<void> updateStatistics(StatisticsEntity statistics) async {
    final statisticsModel = StatisticsModel.fromEntity(statistics);
    await _dataSource.updateStatistics(statisticsModel);
  }

  @override
  Future<void> updateProduction({
    bool isManual = false,
    int amount = 1,
    required double metalUsed,
    double metalSaved = 0.0,
    double efficiency = 0.0,
  }) async {
    await _dataSource.updateProduction(
      isManual: isManual,
      amount: amount,
      metalUsed: metalUsed,
      metalSaved: metalSaved,
      efficiency: efficiency,
    );
  }

  @override
  Future<void> updateEconomics({
    double? moneyEarned,
    double? moneySpent,
    double? metalBought,
    int? sales,
    double? price,
  }) async {
    await _dataSource.updateEconomics(
      moneyEarned: moneyEarned,
      moneySpent: moneySpent,
      metalBought: metalBought,
      sales: sales,
      price: price,
    );
  }

  @override
  Future<void> updateProgression({
    int? upgradesBought,
    int? autoclippersBought,
    int? maxCombo,
    Duration? playTime,
  }) async {
    await _dataSource.updateProgression(
      upgradesBought: upgradesBought,
      autoclippersBought: autoclippersBought,
      maxCombo: maxCombo,
      playTime: playTime,
    );
  }

  @override
  Future<Map<String, Map<String, dynamic>>> getAllStats() async {
    final statistics = await getStatistics();
    return {
      'production': {
        'Total Trombones': _formatNumber(statistics.totalPaperclipsProduced),
        'Production Manuelle': _formatNumber(statistics.manualPaperclipsProduced),
        'Production Auto': _formatNumber(statistics.autoPaperclipsProduced),
        'Métal Utilisé': _formatNumber(statistics.totalMetalUsed),
      },
      'economie': {
        'Argent Gagné': _formatNumber(statistics.totalMoneyEarned),
        'Argent Dépensé': _formatNumber(statistics.totalMoneySpent),
        'Métal Acheté': _formatNumber(statistics.totalMetalBought),
        'Ventes Totales': _formatNumber(statistics.totalSales),
        'Prix Max': _formatNumber(statistics.highestPrice),
        'Prix Moyen': _formatNumber(statistics.averagePrice),
      },
      'progression': {
        'Améliorations Achetées': statistics.totalUpgradesBought,
        'Autoclippers Achetés': statistics.totalAutoclippersBought,
        'Combo Max': statistics.maxComboAchieved,
        'Temps de Jeu': _formatDuration(statistics.totalPlayTime),
      },
    };
  }

  // Méthodes utilitaires de formatage
  String _formatNumber(dynamic value) {
    if (value is double) {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(2)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(2)}K';
      }
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours}h ${minutes}m ${seconds}s';
  }
}