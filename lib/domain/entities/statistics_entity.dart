// lib/domain/entities/statistics_entity.dart

class StatisticsEntity {
  final int totalPaperclipsProduced;
  final int manualPaperclipsProduced;
  final int autoPaperclipsProduced;
  final double totalMetalUsed;
  final double totalMetalSaved;
  final double currentEfficiency;
  final double totalMoneyEarned;
  final double totalMoneySpent;
  final double totalMetalBought;
  final int totalSales;
  final double highestPrice;
  final double averagePrice;
  final int totalUpgradesBought;
  final int totalAutoclippersBought;
  final int maxComboAchieved;
  final Duration totalPlayTime;

  StatisticsEntity({
    required this.totalPaperclipsProduced,
    required this.manualPaperclipsProduced,
    required this.autoPaperclipsProduced,
    required this.totalMetalUsed,
    required this.totalMetalSaved,
    required this.currentEfficiency,
    required this.totalMoneyEarned,
    required this.totalMoneySpent,
    required this.totalMetalBought,
    required this.totalSales,
    required this.highestPrice,
    required this.averagePrice,
    required this.totalUpgradesBought,
    required this.totalAutoclippersBought,
    required this.maxComboAchieved,
    required this.totalPlayTime,
  });

  StatisticsEntity updateProduction({
    bool isManual = false,
    int amount = 1,
    required double metalUsed,
    double metalSaved = 0.0,
    double efficiency = 0.0,
  }) {
    return StatisticsEntity(
      totalPaperclipsProduced: totalPaperclipsProduced + amount,
      manualPaperclipsProduced: isManual
          ? manualPaperclipsProduced + amount
          : manualPaperclipsProduced,
      autoPaperclipsProduced: !isManual
          ? autoPaperclipsProduced + amount
          : autoPaperclipsProduced,
      totalMetalUsed: totalMetalUsed + metalUsed,
      totalMetalSaved: totalMetalSaved + metalSaved,
      currentEfficiency: efficiency,
      totalMoneyEarned: totalMoneyEarned,
      totalMoneySpent: totalMoneySpent,
      totalMetalBought: totalMetalBought,
      totalSales: totalSales,
      highestPrice: highestPrice,
      averagePrice: averagePrice,
      totalUpgradesBought: totalUpgradesBought,
      totalAutoclippersBought: totalAutoclippersBought,
      maxComboAchieved: maxComboAchieved,
      totalPlayTime: totalPlayTime,
    );
  }

  StatisticsEntity updateEconomics({
    double? moneyEarned,
    double? moneySpent,
    double? metalBought,
    int? sales,
    double? price,
  }) {
    return StatisticsEntity(
      totalPaperclipsProduced: totalPaperclipsProduced,
      manualPaperclipsProduced: manualPaperclipsProduced,
      autoPaperclipsProduced: autoPaperclipsProduced,
      totalMetalUsed: totalMetalUsed,
      totalMetalSaved: totalMetalSaved,
      currentEfficiency: currentEfficiency,
      totalMoneyEarned: moneyEarned != null
          ? totalMoneyEarned + moneyEarned
          : totalMoneyEarned,
      totalMoneySpent: moneySpent != null
          ? totalMoneySpent + moneySpent
          : totalMoneySpent,
      totalMetalBought: metalBought != null
          ? totalMetalBought + metalBought
          : totalMetalBought,
      totalSales: sales != null
          ? totalSales + sales
          : totalSales,
      highestPrice: price != null
          ? (price > highestPrice ? price : highestPrice)
          : highestPrice,
      averagePrice: price != null
          ? ((averagePrice * totalSales) + price) / (totalSales + 1)
          : averagePrice,
      totalUpgradesBought: totalUpgradesBought,
      totalAutoclippersBought: totalAutoclippersBought,
      maxComboAchieved: maxComboAchieved,
      totalPlayTime: totalPlayTime,
    );
  }

  StatisticsEntity updateProgression({
    int? upgradesBought,
    int? autoclippersBought,
    int? maxCombo,
    Duration? playTime,
  }) {
    return StatisticsEntity(
      totalPaperclipsProduced: totalPaperclipsProduced,
      manualPaperclipsProduced: manualPaperclipsProduced,
      autoPaperclipsProduced: autoPaperclipsProduced,
      totalMetalUsed: totalMetalUsed,
      totalMetalSaved: totalMetalSaved,
      currentEfficiency: currentEfficiency,
      totalMoneyEarned: totalMoneyEarned,
      totalMoneySpent: totalMoneySpent,
      totalMetalBought: totalMetalBought,
      totalSales: totalSales,
      highestPrice: highestPrice,
      averagePrice: averagePrice,
      totalUpgradesBought: upgradesBought != null
          ? totalUpgradesBought + upgradesBought
          : totalUpgradesBought,
      totalAutoclippersBought: autoclippersBought != null
          ? totalAutoclippersBought + autoclippersBought
          : totalAutoclippersBought,
      maxComboAchieved: maxCombo != null
          ? (maxCombo > maxComboAchieved ? maxCombo : maxComboAchieved)
          : maxComboAchieved,
      totalPlayTime: playTime != null
          ? totalPlayTime + playTime
          : totalPlayTime,
    );
  }

  Map<String, Map<String, dynamic>> getAllStats() {
    return {
      'production': {
        'Total Trombones': _formatNumber(totalPaperclipsProduced),
        'Production Manuelle': _formatNumber(manualPaperclipsProduced),
        'Production Auto': _formatNumber(autoPaperclipsProduced),
        'Métal Utilisé': _formatNumber(totalMetalUsed),
      },
      'economie': {
        'Argent Gagné': _formatNumber(totalMoneyEarned),
        'Argent Dépensé': _formatNumber(totalMoneySpent),
        'Métal Acheté': _formatNumber(totalMetalBought),
        'Ventes Totales': _formatNumber(totalSales),
        'Prix Max': _formatNumber(highestPrice),
        'Prix Moyen': _formatNumber(averagePrice),
      },
      'progression': {
        'Améliorations Achetées': totalUpgradesBought,
        'Autoclippers Achetés': totalAutoclippersBought,
        'Combo Max': maxComboAchieved,
        'Temps de Jeu': _formatDuration(totalPlayTime),
      },
    };
  }

  String _formatNumber(dynamic value) {
    if (value is double) {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(2)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(2)}K';
      }
      return value.toStringAsFixed(2);
    } else if (value is int) {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(2)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(2)}K';
      }
    }
    return value.toString();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours}h ${minutes}m ${seconds}s';
  }

  StatisticsEntity copyWith({
    int? totalPaperclipsProduced,
    int? manualPaperclipsProduced,
    int? autoPaperclipsProduced,
    double? totalMetalUsed,
    double? totalMetalSaved,
    double? currentEfficiency,
    double? totalMoneyEarned,
    double? totalMoneySpent,
    double? totalMetalBought,
    int? totalSales,
    double? highestPrice,
    double? averagePrice,
    int? totalUpgradesBought,
    int? totalAutoclippersBought,
    int? maxComboAchieved,
    Duration? totalPlayTime,
  }) {
    return StatisticsEntity(
      totalPaperclipsProduced: totalPaperclipsProduced ??
          this.totalPaperclipsProduced,
      manualPaperclipsProduced: manualPaperclipsProduced ??
          this.manualPaperclipsProduced,
      autoPaperclipsProduced: autoPaperclipsProduced ??
          this.autoPaperclipsProduced,
      totalMetalUsed: totalMetalUsed ?? this.totalMetalUsed,
      totalMetalSaved: totalMetalSaved ?? this.totalMetalSaved,
      currentEfficiency: currentEfficiency ?? this.currentEfficiency,
      totalMoneyEarned: totalMoneyEarned ?? this.totalMoneyEarned,
      totalMoneySpent: totalMoneySpent ?? this.totalMoneySpent,
      totalMetalBought: totalMetalBought ?? this.totalMetalBought,
      totalSales: totalSales ?? this.totalSales,
      highestPrice: highestPrice ?? this.highestPrice,
      averagePrice: averagePrice ?? this.averagePrice,
      totalUpgradesBought: totalUpgradesBought ?? this.totalUpgradesBought,
      totalAutoclippersBought: totalAutoclippersBought ??
          this.totalAutoclippersBought,
      maxComboAchieved: maxComboAchieved ?? this.maxComboAchieved,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
    );
  }

  // Méthode pour obtenir le total d'argent gagné
  double getTotalMoneyEarned() {
    return totalMoneyEarned;
  }

  // Méthode pour obtenir le total de trombones produits
  int getTotalPaperclipsProduced() {
    return totalPaperclipsProduced;
  }
}