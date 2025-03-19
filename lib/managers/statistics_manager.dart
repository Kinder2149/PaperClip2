// lib/managers/statistics_manager.dart

import 'package:flutter/foundation.dart';
import 'dart:math' show max, min;
import '../models/game_config.dart';
import '../models/market.dart';

class StatisticsManagerException implements Exception {
  final String message;
  StatisticsManagerException(this.message);
}

/// Manager responsable de la collecte et de l'analyse des statistiques du jeu
class StatisticsManager extends ChangeNotifier {
  // ===== STATISTIQUES DE PRODUCTION =====
  int _totalPaperclipsProduced = 0;
  int _manualPaperclipsProduced = 0;
  int _autoPaperclipsProduced = 0;
  double _totalMetalUsed = 0.0;
  double _totalMetalSaved = 0.0;
  double _currentEfficiency = 0.0;
  int _maxProductionPerSecond = 0;

  // ===== STATISTIQUES ÉCONOMIQUES =====
  double _totalMoneyEarned = 0.0;
  double _totalMoneySpent = 0.0;
  double _totalMetalBought = 0.0;
  int _totalSales = 0;
  int _totalTransactions = 0;
  double _highestPrice = 0.0;
  double _lowestPrice = double.infinity;
  double _averagePrice = 0.0;
  double _highestProfit = 0.0;
  double _maxMoneyOwned = 0.0;

  // ===== STATISTIQUES DE PROGRESSION =====
  int _totalUpgradesBought = 0;
  int _totalAutoclippersBought = 0;
  int _maxComboAchieved = 0;
  Duration _totalPlayTime = Duration.zero;
  int _restarts = 0;
  int _highestLevelReached = 1;
  Map<String, int> _upgradesByType = {};
  DateTime _gameStartTime = DateTime.now();
  List<SaleRecord> _recentSales = [];
  int _maxRecentSales = 100;

  // ===== STATISTIQUES DE CRISE =====
  bool _hasSurvivedCrisis = false;
  int _crisisCounter = 0;
  DateTime? _firstCrisisTime;
  double _metalProducedDuringCrisis = 0.0;

  // ===== GETTERS =====
  int get totalPaperclipsProduced => _totalPaperclipsProduced;
  double get totalMetalUsed => _totalMetalUsed;
  double get currentEfficiency => _currentEfficiency;
  double get totalMoneyEarned => _totalMoneyEarned;
  Duration get totalPlayTime => _totalPlayTime;
  int get highestLevelReached => _highestLevelReached;
  List<SaleRecord> get recentSales => List.unmodifiable(_recentSales);


  // Méthodes de validation statiques
  static int _validatePaperclips(int value) {
    if (value < 0) throw StatisticsManagerException('Paperclips cannot be negative');
    return value;
  }

  static double _validateMetalAmount(double value) {
    if (value < 0) throw StatisticsManagerException('Metal amount cannot be negative');
    return value;
  }

  static double _validateEfficiency(double value) {
    if (value < 0 || value > 1) throw StatisticsManagerException('Efficiency must be between 0 and 1');
    return value;
  }

  // ===== MÉTHODES DE MISE À JOUR =====

  /// Met à jour les statistiques de production
  void updateProduction({
    bool isManual = false,
    required int amount,
    required double metalUsed,
    double metalSaved = 0.0,
    double efficiency = 0.0,
  }) {
    amount = _validatePaperclips(amount);
    metalUsed = _validateMetalAmount(metalUsed);
    metalSaved = _validateMetalAmount(metalSaved);
    efficiency = _validateEfficiency(efficiency);

    if (isManual) {
      _manualPaperclipsProduced += amount;
    } else {
      _autoPaperclipsProduced += amount;
    }
    _totalPaperclipsProduced += amount;
    _totalMetalUsed += metalUsed;
    _totalMetalSaved += metalSaved;
    _currentEfficiency = efficiency;

    // Mise à jour du record de production
    _maxProductionPerSecond = max(_maxProductionPerSecond, amount);

    notifyListeners();
  }

  /// Met à jour les statistiques économiques
  void updateEconomics({
    double? moneyEarned,
    double? moneySpent,
    double? metalBought,
    int? sales,
    double? price,
    SaleRecord? saleRecord,
  }) {
    if (moneyEarned != null && moneyEarned > 0) {
      _totalMoneyEarned += moneyEarned;
      _maxMoneyOwned = max(_maxMoneyOwned, _totalMoneyEarned - _totalMoneySpent);
    }

    if (moneySpent != null && moneySpent > 0) {
      _totalMoneySpent += moneySpent;
    }

    if (metalBought != null && metalBought > 0) {
      _totalMetalBought += metalBought;
    }

    if (sales != null && sales > 0) {
      _totalSales += sales;
      _totalTransactions++;
    }

    if (price != null) {
      if (price > _highestPrice) _highestPrice = price;
      if (price < _lowestPrice) _lowestPrice = price;
      _averagePrice = (_averagePrice * _totalTransactions + price) / (_totalTransactions + 1);

      // Calculer le profit potentiel
      if (sales != null && sales > 0) {
        double profit = sales * price;
        if (profit > _highestProfit) _highestProfit = profit;
      }
    }

    // Enregistrer la vente dans l'historique récent
    if (saleRecord != null) {
      _recentSales.add(saleRecord);
      // Limiter la taille de l'historique
      if (_recentSales.length > _maxRecentSales) {
        _recentSales.removeAt(0);
      }
    }

    notifyListeners();
  }

  /// Met à jour les statistiques de progression
  void updateProgression({
    int? upgradesBought,
    String? upgradeType,
    int? autoclippersBought,
    int? maxCombo,
    Duration? playTime,
    int? level,
  }) {
    if (upgradesBought != null && upgradesBought > 0) {
      _totalUpgradesBought += upgradesBought;

      // Suivi par type d'amélioration
      if (upgradeType != null) {
        _upgradesByType[upgradeType] = (_upgradesByType[upgradeType] ?? 0) + 1;
      }
    }

    if (autoclippersBought != null && autoclippersBought > 0) {
      _totalAutoclippersBought += autoclippersBought;
    }

    if (maxCombo != null && maxCombo > _maxComboAchieved) {
      _maxComboAchieved = maxCombo;
    }

    if (playTime != null) {
      _totalPlayTime += playTime;
    }

    if (level != null && level > _highestLevelReached) {
      _highestLevelReached = level;
    }

    notifyListeners();
  }

  /// Mise à jour des statistiques liées à la crise
  void updateCrisisStats({
    bool? survivedCrisis,
    double? metalProducedInCrisis,
    bool? newCrisisStarted,
  }) {
    if (survivedCrisis == true) {
      _hasSurvivedCrisis = true;
    }

    if (metalProducedInCrisis != null && metalProducedInCrisis > 0) {
      _metalProducedDuringCrisis += metalProducedInCrisis;
    }

    if (newCrisisStarted == true) {
      _crisisCounter++;
      if (_firstCrisisTime == null) {
        _firstCrisisTime = DateTime.now();
      }
    }

    notifyListeners();
  }

  /// Met à jour le temps de jeu total
  void updatePlayTime(Duration elapsed) {
    _totalPlayTime += elapsed;
    notifyListeners();
  }

  /// Mise à jour en fonction d'un nouveau record
  void updateRecord(String recordType, dynamic value) {
    switch (recordType) {
      case 'maxMoney':
        if (value is double && value > _maxMoneyOwned) {
          _maxMoneyOwned = value;
        }
        break;
      case 'maxProduction':
        if (value is int && value > _maxProductionPerSecond) {
          _maxProductionPerSecond = value;
        }
        break;
      case 'highestLevel':
        if (value is int && value > _highestLevelReached) {
          _highestLevelReached = value;
        }
        break;
    // Autres types de records...
    }
    notifyListeners();
  }

  // ===== MÉTHODES D'ANALYSE =====

  /// Calcule le taux d'efficacité global de la production
  double calculateOverallEfficiency() {
    if (_totalMetalUsed + _totalMetalSaved <= 0) return 0.0;
    return _totalMetalSaved / (_totalMetalUsed + _totalMetalSaved);
  }

  /// Calcule le retour sur investissement des autoclippers
  double calculateAutoclipperROI(double clipperCost, double productionRate, double sellPrice) {
    double revenuePerMinute = productionRate * sellPrice * 60;
    if (revenuePerMinute <= 0) return double.infinity;
    return clipperCost / revenuePerMinute;
  }

  /// Analyse les tendances de vente récentes
  Map<String, dynamic> analyzeSalesTrends() {
    if (_recentSales.isEmpty) {
      return {
        'trend': 'undefined',
        'averagePrice': 0.0,
        'averageQuantity': 0,
        'revenueGrowth': 0.0,
      };
    }

    // Calculer les moyennes des 10 dernières et 10 avant-dernières ventes
    int midPoint = min(10, _recentSales.length ~/ 2);
    List<SaleRecord> recentBatch = _recentSales.sublist(max(0, _recentSales.length - midPoint));
    List<SaleRecord> previousBatch = _recentSales.sublist(
        max(0, _recentSales.length - 2 * midPoint),
        max(0, _recentSales.length - midPoint)
    );

    double recentAvgRevenue = recentBatch.isEmpty
        ? 0
        : recentBatch.map((s) => s.revenue).reduce((a, b) => a + b) / recentBatch.length;

    double previousAvgRevenue = previousBatch.isEmpty
        ? 0
        : previousBatch.map((s) => s.revenue).reduce((a, b) => a + b) / previousBatch.length;

    double growth = previousAvgRevenue == 0
        ? 0
        : ((recentAvgRevenue - previousAvgRevenue) / previousAvgRevenue) * 100;

    return {
      'trend': growth > 5 ? 'up' : (growth < -5 ? 'down' : 'stable'),
      'averagePrice': recentBatch.isEmpty
          ? 0
          : recentBatch.map((s) => s.price).reduce((a, b) => a + b) / recentBatch.length,
      'averageQuantity': recentBatch.isEmpty
          ? 0
          : recentBatch.map((s) => s.quantity).reduce((a, b) => a + b) ~/ recentBatch.length,
      'revenueGrowth': growth,
    };
  }
// Getters avec validation
  double getTotalMoneyEarned() {
    return max(_totalMoneyEarned, 0.0);
  }

  double getTotalMetalUsed() {
    return max(_totalMetalUsed, 0.0);
  }
  // ===== MÉTHODES DE RÉCUPÉRATION DE TOUTES LES STATS =====

  /// Récupère toutes les statistiques organisées par catégorie
  Map<String, Map<String, dynamic>> getAllStats() {
    return {
      'production': {
        'Total produit': _formatNumber(_totalPaperclipsProduced),
        'Production Manuelle': _formatNumber(_manualPaperclipsProduced),
        'Production Auto': _formatNumber(_autoPaperclipsProduced),
        'Métal Utilisé': _formatNumber(_totalMetalUsed),
        'Efficacité': '${(_currentEfficiency * 100).toStringAsFixed(1)}%',
        'Record Production/sec': _maxProductionPerSecond,
      },
      'economie': {
        'Argent Gagné': _formatNumber(_totalMoneyEarned),
        'Argent Dépensé': _formatNumber(_totalMoneySpent),
        'Métal Acheté': _formatNumber(_totalMetalBought),
        'Ventes Totales': _formatNumber(_totalSales),
        'Prix Max': _formatNumber(_highestPrice),
        'Prix Min': _lowestPrice == double.infinity ? 'N/A' : _formatNumber(_lowestPrice),
        'Prix Moyen': _formatNumber(_averagePrice),
        'Profit Max': _formatNumber(_highestProfit),
      },
      'progression': {
        'Améliorations Achetées': _totalUpgradesBought,
        'Autoclippers Achetés': _totalAutoclippersBought,
        'Combo Max': _maxComboAchieved,
        'Niveau Max': _highestLevelReached,
        'Temps de Jeu': _formatDuration(_totalPlayTime),
        'Restarts': _restarts,
      },
      'crise': {
        'Crise Survécue': _hasSurvivedCrisis ? 'Oui' : 'Non',
        'Nombre de Crises': _crisisCounter,
        'Métal Produit en Crise': _formatNumber(_metalProducedDuringCrisis),
        'Première Crise': _firstCrisisTime?.toString() ?? 'Jamais',
      },
    };
  }

  // ===== MÉTHODES UTILITAIRES =====

  /// Formate un nombre pour l'affichage
  String _formatNumber(dynamic value) {
    if (value == null) return '0';

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

  /// Formate une durée pour l'affichage
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours}h ${minutes}m ${seconds}s';
  }

  // ===== SÉRIALISATION =====

  /// Convertit l'état en JSON
  Map<String, dynamic> toJson() {
    return {
      'totalPaperclipsProduced': _totalPaperclipsProduced,
      'manualPaperclipsProduced': _manualPaperclipsProduced,
      'autoPaperclipsProduced': _autoPaperclipsProduced,
      'totalMetalUsed': _totalMetalUsed,
      'totalMetalSaved': _totalMetalSaved,
      'currentEfficiency': _currentEfficiency,
      'totalMoneyEarned': _totalMoneyEarned,
      'totalMoneySpent': _totalMoneySpent,
      'totalMetalBought': _totalMetalBought,
      'totalSales': _totalSales,
      'highestPrice': _highestPrice,
      'lowestPrice': _lowestPrice == double.infinity ? null : _lowestPrice,
      'averagePrice': _averagePrice,
      'totalUpgradesBought': _totalUpgradesBought,
      'totalAutoclippersBought': _totalAutoclippersBought,
      'maxComboAchieved': _maxComboAchieved,
      'totalPlayTime': _totalPlayTime.inSeconds,
      'highestLevelReached': _highestLevelReached,
      'hasSurvivedCrisis': _hasSurvivedCrisis,
      'crisisCounter': _crisisCounter,
      'metalProducedDuringCrisis': _metalProducedDuringCrisis,
      'firstCrisisTime': _firstCrisisTime?.toIso8601String(),
      'restarts': _restarts,
      'maxProductionPerSecond': _maxProductionPerSecond,
      'maxMoneyOwned': _maxMoneyOwned,
      'highestProfit': _highestProfit,
      'gameStartTime': _gameStartTime.toIso8601String(),
      'upgradesByType': _upgradesByType,
    };
  }

  /// Charge l'état depuis JSON
  void fromJson(Map<String, dynamic> json) {
    try {
      _totalPaperclipsProduced = _safeIntConversion(json['totalPaperclipsProduced']);
      _manualPaperclipsProduced = _safeIntConversion(json['manualPaperclipsProduced']);
      _autoPaperclipsProduced = _safeIntConversion(json['autoPaperclipsProduced']);
      _totalMetalUsed = _safeDoubleConversion(json['totalMetalUsed']);
      _totalMetalSaved = _safeDoubleConversion(json['totalMetalSaved']);
      _currentEfficiency = _safeDoubleConversion(json['currentEfficiency']);
      _totalMoneyEarned = _safeDoubleConversion(json['totalMoneyEarned']);
      _totalMoneySpent = _safeDoubleConversion(json['totalMoneySpent']);
      _totalMetalBought = _safeDoubleConversion(json['totalMetalBought']);
      _totalSales = _safeIntConversion(json['totalSales']);
      _highestPrice = _safeDoubleConversion(json['highestPrice']);
      _lowestPrice = json['lowestPrice'] != null ? _safeDoubleConversion(json['lowestPrice']) : double.infinity;
      _averagePrice = _safeDoubleConversion(json['averagePrice']);
      _totalUpgradesBought = _safeIntConversion(json['totalUpgradesBought']);
      _totalAutoclippersBought = _safeIntConversion(json['totalAutoclippersBought']);
      _maxComboAchieved = _safeIntConversion(json['maxComboAchieved']);
      _totalPlayTime = Duration(seconds: _safeIntConversion(json['totalPlayTime']));
      _highestLevelReached = _safeIntConversion(json['highestLevelReached']);
      _hasSurvivedCrisis = json['hasSurvivedCrisis'] as bool? ?? false;
      _crisisCounter = _safeIntConversion(json['crisisCounter']);
      _metalProducedDuringCrisis = _safeDoubleConversion(json['metalProducedDuringCrisis']);

      if (json['firstCrisisTime'] != null) {
        _firstCrisisTime = DateTime.parse(json['firstCrisisTime'] as String);
      }

      _restarts = _safeIntConversion(json['restarts']);
      _maxProductionPerSecond = _safeIntConversion(json['maxProductionPerSecond']);
      _maxMoneyOwned = _safeDoubleConversion(json['maxMoneyOwned']);
      _highestProfit = _safeDoubleConversion(json['highestProfit']);

      if (json['gameStartTime'] != null) {
        _gameStartTime = DateTime.parse(json['gameStartTime'] as String);
      } else {
        _gameStartTime = DateTime.now();
      }

      if (json['upgradesByType'] != null) {
        _upgradesByType = Map<String, int>.from(json['upgradesByType'] as Map);
      }

      print('Statistiques chargées avec succès');
    } catch (e, stack) {
      print('Erreur lors du chargement des statistiques: $e');
      print('Stack trace: $stack');
      _resetToDefaults();
    }
    notifyListeners();
  }

  // ===== MÉTHODES UTILITAIRES POUR CONVERSION SÉCURISÉE =====

  /// Convertit une valeur en double de manière sécurisée
  double _safeDoubleConversion(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    try {
      return double.parse(value.toString());
    } catch (_) {
      return 0.0;
    }
  }

  /// Convertit une valeur en int de manière sécurisée
  int _safeIntConversion(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    try {
      return int.parse(value.toString());
    } catch (_) {
      return 0;
    }
  }

  /// Réinitialise toutes les statistiques à leurs valeurs par défaut
  void _resetToDefaults() {
    _totalPaperclipsProduced = 0;
    _manualPaperclipsProduced = 0;
    _autoPaperclipsProduced = 0;
    _totalMetalUsed = 0.0;
    _totalMetalSaved = 0.0;
    _currentEfficiency = 0.0;
    _totalMoneyEarned = 0.0;
    _totalMoneySpent = 0.0;
    _totalMetalBought = 0.0;
    _totalSales = 0;
    _totalTransactions = 0;
    _highestPrice = 0.0;
    _lowestPrice = double.infinity;
    _averagePrice = 0.0;
    _highestProfit = 0.0;
    _maxMoneyOwned = 0.0;
    _totalUpgradesBought = 0;
    _totalAutoclippersBought = 0;
    _maxComboAchieved = 0;
    _totalPlayTime = Duration.zero;
    _restarts = 0;
    _highestLevelReached = 1;
    _upgradesByType = {};
    _gameStartTime = DateTime.now();
    _recentSales = [];
    _hasSurvivedCrisis = false;
    _crisisCounter = 0;
    _firstCrisisTime = null;
    _metalProducedDuringCrisis = 0.0;
    _maxProductionPerSecond = 0;
  }


  /// Méthode pour la compatibilité avec le code existant
  double getTotalMoneySpent() {
    return _totalMoneySpent;
  }

  /// Méthode pour la compatibilité avec le code existant
  int getTotalSales() {
    return _totalSales;
  }

  /// Méthode pour la compatibilité avec le code existant
  double getCurrentEfficiency() {
    return _currentEfficiency;
  }
  /// Réinitialise les statistiques pour une nouvelle partie
  void resetForNewGame() {
    _resetToDefaults();
    _restarts++;
    _gameStartTime = DateTime.now();
    notifyListeners();
  }
}