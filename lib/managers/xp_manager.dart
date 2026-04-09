// lib/managers/xp_manager.dart

import 'package:flutter/foundation.dart';
import 'dart:math';
import '../constants/game_config.dart';
import '../services/xp/xp_config.dart';
import '../services/xp/xp_formulas.dart';

/// Manager central pour la gestion de l'XP
/// 
/// Responsabilités:
/// - Calcul et attribution de l'XP pour toutes les sources
/// - Application des multiplicateurs (combo, chemin, temporaires, reset)
/// - Tracking progression par chemin
/// - Interface avec LevelSystem pour level-up
class XPManager extends ChangeNotifier {
  // Référence au système de niveau (pour notifier des gains XP)
  final Function(double amount, ExperienceType type) _onXPGained;
  final Function() _getCurrentLevel;
  final Function() _getCurrentPath;
  final Function() _getResetCount;
  
  // Système de combo
  final XPComboSystem comboSystem;
  
  // Bonus quotidien
  final DailyXPBonus dailyBonus;
  
  // Multiplicateur temporaire
  double _temporaryMultiplier = 1.0;
  DateTime? _temporaryMultiplierExpiry;
  
  XPManager({
    required Function(double, ExperienceType) onXPGained,
    required Function() getCurrentLevel,
    required Function() getCurrentPath,
    required Function() getResetCount,
    required this.comboSystem,
    required this.dailyBonus,
  })  : _onXPGained = onXPGained,
        _getCurrentLevel = getCurrentLevel,
        _getCurrentPath = getCurrentPath,
        _getResetCount = getResetCount;
  
  // ============================================================================
  // Getters
  // ============================================================================
  
  int get currentLevel => _getCurrentLevel();
  ProgressionPath get currentPath => _getCurrentPath();
  int get resetCount => _getResetCount();
  
  double get totalXpMultiplier {
    double multiplier = 1.0;
    
    // Combo
    multiplier *= comboSystem.comboMultiplier;
    
    // Temporaire
    if (_temporaryMultiplierExpiry != null && 
        DateTime.now().isBefore(_temporaryMultiplierExpiry!)) {
      multiplier *= _temporaryMultiplier;
    }
    
    return multiplier;
  }
  
  // ============================================================================
  // Méthodes principales d'attribution XP
  // ============================================================================
  
  /// Accorde de l'XP avec tous les multiplicateurs appliqués
  void grantExperience(double baseAmount, ExperienceType type) {
    if (baseAmount <= 0) return;
    
    // 1. Appliquer multiplicateurs globaux (combo + temporaire)
    double amount = baseAmount * totalXpMultiplier;
    
    // 2. Appliquer bonus de niveau
    final levelBonus = ProgressionBonus.getTotalBonus(currentLevel);
    amount *= levelBonus;
    
    // 3. Appliquer bonus de reset permanent
    final resetMultiplier = getResetXPMultiplier();
    amount *= resetMultiplier;
    
    // 4. Appliquer scaling par niveau (diminution)
    final levelScale = 1.0 + ((currentLevel - 1) * XPConfig.LEVEL_SCALING_FACTOR);
    amount /= levelScale;
    
    // 5. Bonus pour bas niveaux
    if (currentLevel < XPConfig.LOW_LEVEL_THRESHOLD) {
      amount *= XPConfig.LOW_LEVEL_BONUS;
    }
    
    // 6. Bonus si le type correspond au chemin actuel
    amount *= _currentPathBonusMultiplier(type);
    
    // 7. Minimum garanti
    amount = max(amount, 0.05);
    
    // 8. Notifier le LevelSystem
    _onXPGained(amount, type);
    
    // 9. Incrémenter combo si applicable
    if (type != ExperienceType.DAILY_BONUS && type != ExperienceType.COMBO_BONUS) {
      comboSystem.incrementCombo();
    }
    
    notifyListeners();
  }
  
  /// Production manuelle
  void grantManualProductionXP() {
    final baseXP = XPFormulas.calculateManualProductionXP();
    grantExperience(baseXP, ExperienceType.PRODUCTION);
  }
  
  /// Production automatique
  void grantAutoProductionXP(int amount) {
    final baseXP = XPFormulas.calculateAutoProductionXP(amount);
    grantExperience(baseXP, ExperienceType.PRODUCTION);
  }
  
  /// Vente de trombones
  void grantSaleXP(int quantity, double price) {
    final baseXP = XPFormulas.calculateSaleXP(quantity, price);
    grantExperience(baseXP, ExperienceType.SALE);
  }
  
  /// Achat d'autoclipper
  void grantAutoclipperPurchaseXP() {
    final baseXP = XPFormulas.calculateAutoclipperPurchaseXP();
    grantExperience(baseXP, ExperienceType.UPGRADE);
  }
  
  /// Achat d'amélioration
  void grantUpgradePurchaseXP(int upgradeLevel) {
    final baseXP = XPFormulas.calculateUpgradePurchaseXP(upgradeLevel);
    grantExperience(baseXP, ExperienceType.UPGRADE);
  }
  
  /// Recherche débloquée
  void grantResearchXP({
    double moneyCost = 0.0,
    double innovationPointsCost = 0.0,
    double quantumCost = 0.0,
  }) {
    final baseXP = XPFormulas.calculateResearchXP(
      moneyCost: moneyCost,
      innovationPointsCost: innovationPointsCost,
      quantumCost: quantumCost,
    );
    grantExperience(baseXP, ExperienceType.UPGRADE);
  }
  
  /// Mission complétée
  void grantMissionXP({
    required double baseXP,
    required double difficulty,
    required double typeMultiplier,
  }) {
    final xp = XPFormulas.calculateMissionXP(
      baseXP: baseXP,
      difficulty: difficulty,
      typeMultiplier: typeMultiplier,
    );
    grantExperience(xp, ExperienceType.GENERAL);
  }
  
  /// Bonus quotidien
  void grantDailyBonusXP() {
    if (dailyBonus.canClaim()) {
      final baseXP = XPFormulas.calculateDailyBonusXP();
      dailyBonus.claim();
      grantExperience(baseXP, ExperienceType.DAILY_BONUS);
    }
  }
  
  // ============================================================================
  // Multiplicateurs
  // ============================================================================
  
  /// Calcule le multiplicateur de bonus permanent basé sur le nombre de resets
  /// 
  /// Formule: 1.0 + (resetCount × 0.05), plafonné à 2.0
  double getResetXPMultiplier() {
    final count = resetCount;
    if (count <= 0) return 1.0;
    
    final multiplier = 1.0 + (count * XPConfig.RESET_XP_BONUS_PER_RESET);
    return min(multiplier, XPConfig.RESET_XP_BONUS_MAX);
  }
  
  /// Calcule le bonus si le type d'XP correspond au chemin actuel
  double _currentPathBonusMultiplier(ExperienceType type) {
    final path = _mapExperienceTypeToPath(type);
    if (path == currentPath) {
      return XPConfig.PATH_MATCH_MULTIPLIER;
    }
    return 1.0;
  }
  
  /// Mappe un type d'expérience vers un chemin de progression
  ProgressionPath _mapExperienceTypeToPath(ExperienceType type) {
    switch (type) {
      case ExperienceType.PRODUCTION:
        return ProgressionPath.PRODUCTION;
      case ExperienceType.SALE:
        return ProgressionPath.MARKETING;
      case ExperienceType.UPGRADE:
        return ProgressionPath.INNOVATION;
      case ExperienceType.GENERAL:
      case ExperienceType.DAILY_BONUS:
      case ExperienceType.COMBO_BONUS:
        return currentPath;
    }
  }
  
  /// Applique un boost temporaire d'XP
  void applyXPBoost(double multiplier, Duration duration) {
    _temporaryMultiplier = multiplier;
    _temporaryMultiplierExpiry = DateTime.now().add(duration);
    notifyListeners();
  }
  
  // ============================================================================
  // Reset
  // ============================================================================
  
  /// Reset pour progression (prestige)
  /// 
  /// Réinitialise combo et bonus quotidien, mais conserve le bonus de reset permanent
  void resetForProgression() {
    comboSystem.setComboCount(0);
    dailyBonus.setClaimed(false);
    _temporaryMultiplier = 1.0;
    _temporaryMultiplierExpiry = null;
    notifyListeners();
  }
  
  // ============================================================================
  // Sérialisation
  // ============================================================================
  
  Map<String, dynamic> toJson() {
    return {
      'temporaryMultiplier': _temporaryMultiplier,
      'temporaryMultiplierExpiry': _temporaryMultiplierExpiry?.toIso8601String(),
      'comboSystem': comboSystem.toJson(),
      'dailyBonus': dailyBonus.toJson(),
    };
  }
  
  void fromJson(Map<String, dynamic> json) {
    _temporaryMultiplier = (json['temporaryMultiplier'] as num?)?.toDouble() ?? 1.0;
    
    if (json['temporaryMultiplierExpiry'] != null) {
      _temporaryMultiplierExpiry = DateTime.parse(json['temporaryMultiplierExpiry']);
    }
    
    if (json['comboSystem'] != null) {
      comboSystem.fromJson(json['comboSystem']);
    }
    
    if (json['dailyBonus'] != null) {
      dailyBonus.fromJson(json['dailyBonus']);
    }
    
    notifyListeners();
  }
}

/// Système de combo XP (extrait de LevelSystem)
class XPComboSystem {
  int _comboCount = 0;
  DateTime? _lastActionTime;
  static const Duration _comboTimeout = Duration(seconds: 5);
  
  int get comboCount => _comboCount;
  
  double get comboMultiplier {
    return 1.0 + (_comboCount * XPConfig.COMBO_INCREMENT);
  }
  
  void incrementCombo() {
    final now = DateTime.now();
    
    if (_lastActionTime == null || 
        now.difference(_lastActionTime!).compareTo(_comboTimeout) > 0) {
      _comboCount = 1;
    } else {
      _comboCount = min(_comboCount + 1, XPConfig.COMBO_MAX);
    }
    
    _lastActionTime = now;
  }
  
  void setComboCount(int count) {
    _comboCount = count;
    _lastActionTime = null;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'comboCount': _comboCount,
      'lastActionTime': _lastActionTime?.toIso8601String(),
    };
  }
  
  void fromJson(Map<String, dynamic> json) {
    _comboCount = json['comboCount'] ?? 0;
    if (json['lastActionTime'] != null) {
      _lastActionTime = DateTime.parse(json['lastActionTime']);
    }
  }
}

/// Système de bonus quotidien XP (extrait de LevelSystem)
class DailyXPBonus {
  bool _claimed = false;
  DateTime? _lastClaimDate;
  
  bool get isClaimed => _claimed;
  
  bool canClaim() {
    if (!_claimed) return true;
    
    if (_lastClaimDate == null) return true;
    
    final now = DateTime.now();
    final lastClaim = _lastClaimDate!;
    
    return now.year != lastClaim.year ||
           now.month != lastClaim.month ||
           now.day != lastClaim.day;
  }
  
  void claim() {
    _claimed = true;
    _lastClaimDate = DateTime.now();
  }
  
  void setClaimed(bool claimed) {
    _claimed = claimed;
    if (!claimed) {
      _lastClaimDate = null;
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'claimed': _claimed,
      'lastClaimDate': _lastClaimDate?.toIso8601String(),
    };
  }
  
  void fromJson(Map<String, dynamic> json) {
    _claimed = json['claimed'] ?? false;
    if (json['lastClaimDate'] != null) {
      _lastClaimDate = DateTime.parse(json['lastClaimDate']);
    }
  }
}
