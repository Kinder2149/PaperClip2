// lib/data/models/statistics_model.dart
import '../../domain/entities/statistics_entity.dart';

class StatisticsModel {
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

  StatisticsModel({
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

  factory StatisticsModel.fromJson(Map<String, dynamic> json) {
    return StatisticsModel(
      totalPaperclipsProduced: (json['totalPaperclipsProduced'] as num?)?.toInt() ?? 0,
      manualPaperclipsProduced: (json['manualPaperclipsProduced'] as num?)?.toInt() ?? 0,
      autoPaperclipsProduced: (json['autoPaperclipsProduced'] as num?)?.toInt() ?? 0,
      totalMetalUsed: (json['totalMetalUsed'] as num?)?.toDouble() ?? 0.0,
      totalMetalSaved: (json['totalMetalSaved'] as num?)?.toDouble() ?? 0.0,
      currentEfficiency: (json['currentEfficiency'] as num?)?.toDouble() ?? 0.0,
      totalMoneyEarned: (json['totalMoneyEarned'] as num?)?.toDouble() ?? 0.0,
      totalMoneySpent: (json['totalMoneySpent'] as num?)?.toDouble() ?? 0.0,
      totalMetalBought: (json['totalMetalBought'] as num?)?.toDouble() ?? 0.0,
      totalSales: (json['totalSales'] as num?)?.toInt() ?? 0,
      highestPrice: (json['highestPrice'] as num?)?.toDouble() ?? 0.0,
      averagePrice: (json['averagePrice'] as num?)?.toDouble() ?? 0.0,
      totalUpgradesBought: (json['totalUpgradesBought'] as num?)?.toInt() ?? 0,
      totalAutoclippersBought: (json['totalAutoclippersBought'] as num?)?.toInt() ?? 0,
      maxComboAchieved: (json['maxComboAchieved'] as num?)?.toInt() ?? 0,
      totalPlayTime: Duration(seconds: (json['totalPlayTimeInSeconds'] as num?)?.toInt() ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'totalPaperclipsProduced': totalPaperclipsProduced,
    'manualPaperclipsProduced': manualPaperclipsProduced,
    'autoPaperclipsProduced': autoPaperclipsProduced,
    'totalMetalUsed': totalMetalUsed,
    'totalMetalSaved': totalMetalSaved,
    'currentEfficiency': currentEfficiency,
    'totalMoneyEarned': totalMoneyEarned,
    'totalMoneySpent': totalMoneySpent,
    'totalMetalBought': totalMetalBought,
    'totalSales': totalSales,
    'highestPrice': highestPrice,
    'averagePrice': averagePrice,
    'totalUpgradesBought': totalUpgradesBought,
    'totalAutoclippersBought': totalAutoclippersBought,
    'maxComboAchieved': maxComboAchieved,
    'totalPlayTimeInSeconds': totalPlayTime.inSeconds,
  };

  StatisticsEntity toEntity() {
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
      totalUpgradesBought: totalUpgradesBought,
      totalAutoclippersBought: totalAutoclippersBought,
      maxComboAchieved: maxComboAchieved,
      totalPlayTime: totalPlayTime,
    );
  }

  static StatisticsModel fromEntity(StatisticsEntity entity) {
    return StatisticsModel(
      totalPaperclipsProduced: entity.totalPaperclipsProduced,
      manualPaperclipsProduced: entity.manualPaperclipsProduced,
      autoPaperclipsProduced: entity.autoPaperclipsProduced,
      totalMetalUsed: entity.totalMetalUsed,
      totalMetalSaved: entity.totalMetalSaved,
      currentEfficiency: entity.currentEfficiency,
      totalMoneyEarned: entity.totalMoneyEarned,
      totalMoneySpent: entity.totalMoneySpent,
      totalMetalBought: entity.totalMetalBought,
      totalSales: entity.totalSales,
      highestPrice: entity.highestPrice,
      averagePrice: entity.averagePrice,
      totalUpgradesBought: entity.totalUpgradesBought,
      totalAutoclippersBought: entity.totalAutoclippersBought,
      maxComboAchieved: entity.maxComboAchieved,
      totalPlayTime: entity.totalPlayTime,
    );
  }

  StatisticsModel copyWith({
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
    return StatisticsModel(
      totalPaperclipsProduced: totalPaperclipsProduced ?? this.totalPaperclipsProduced,
      manualPaperclipsProduced: manualPaperclipsProduced ?? this.manualPaperclipsProduced,
      autoPaperclipsProduced: autoPaperclipsProduced ?? this.autoPaperclipsProduced,
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
      totalAutoclippersBought: totalAutoclippersBought ?? this.totalAutoclippersBought,
      maxComboAchieved: maxComboAchieved ?? this.maxComboAchieved,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
    );
  }
}