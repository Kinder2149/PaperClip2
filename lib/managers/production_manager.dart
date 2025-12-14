// lib/managers/production_manager.dart
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../constants/game_config.dart' show GameConstants, EventType, EventImportance; // Import des constantes et enums requis
import 'player_manager.dart';
import '../models/statistics_manager.dart';
// MissionSystem (Option A — mise en pause): aucun événement de gameplay n'est branché ici.
import '../models/json_loadable.dart';
import '../models/event_system.dart';
import '../models/level_system.dart'; // Import pour LevelSystem

/// Gestionnaire responsable de toute la logique de production de trombones
/// (production manuelle, automatique, gestion des autoclippeuses, etc.)
class ProductionManager extends ChangeNotifier implements JsonLoadable {
  // Managers requis
  final PlayerManager _playerManager;
  final StatisticsManager _statistics; // Utilise maintenant la version de models/statistics_manager.dart
  final LevelSystem _levelSystem;
  // MissionSystem (Option A — mise en pause): non intégré au runtime.
  double _maintenanceCosts = 0.0;
  bool _isPaused = false;
  DateTime? _lastUpdateTime;

  // Getters publics
  int get totalPaperclipsProduced => _statistics.totalPaperclipsProduced;
  double get maintenanceCosts => _maintenanceCosts;
  bool get isPaused => _isPaused;
  
  // Accesseurs pour faciliter le code
  PlayerManager get player => _playerManager;
  LevelSystem get level => _levelSystem;

  // Constructor avec injection de dépendances
  ProductionManager({
    required PlayerManager playerManager,
    required StatisticsManager statistics, // Utilise maintenant la version de models/statistics_manager.dart
    required LevelSystem levelSystem,
  }) : 
    _playerManager = playerManager,
    _statistics = statistics,
    _levelSystem = levelSystem {
    _lastUpdateTime = DateTime.now();
  }

  /// Traite la production automatique de trombones via les autoclippeuses
  void processProduction() {
    if (_isPaused) {
      if (kDebugMode) print('[ProductionManager] processProduction: Ignoré - La production est en pause');
      return;
    }

    if (kDebugMode) {
      print('===== CYCLE DE PRODUCTION AUTOMATIQUE =====');
      print('[ProductionManager] État initial: ${player.paperclips.toStringAsFixed(1)} trombones, ${player.metal.toStringAsFixed(1)} métal, ${player.autoclippers} autoclippeuses');
    }

    // Calcul des bonus
    double speedBonus = GameConstants.BASE_EFFICIENCY + ((player.upgrades['speed']?.level ?? 0) * GameConstants.SPEED_BONUS_PER_LEVEL);
    double bulkBonus = GameConstants.BASE_EFFICIENCY + ((player.upgrades['bulk']?.level ?? 0) * GameConstants.BULK_BONUS_PER_LEVEL);

    // Nouveau calcul d'efficacité avec 11% par niveau et plafond 85%
    double efficiencyLevel = (player.upgrades['efficiency']?.level ?? 0).toDouble(); 
    double reduction = min(
        efficiencyLevel * GameConstants.EFFICIENCY_UPGRADE_MULTIPLIER,
        GameConstants.EFFICIENCY_MAX_REDUCTION
    );
    double efficiencyBonus = GameConstants.BASE_EFFICIENCY - reduction;

    if (kDebugMode) {
      print('[ProductionManager] Bonus: vitesse: x${speedBonus.toStringAsFixed(2)}, masse: x${bulkBonus.toStringAsFixed(2)}, efficacité: x${efficiencyBonus.toStringAsFixed(2)} (réduction: ${(reduction * 100).toStringAsFixed(1)}%)');
    }

    // Si joueur a des autoclippeuses
    if (player.autoclippers > 0) {
      // Production automatique basée sur le nombre d'autoclippeuses
      double baseProduction = player.autoclippers * GameConstants.BASE_AUTOCLIPPER_PRODUCTION;
      baseProduction *= speedBonus; // Application du bonus de vitesse
      baseProduction *= bulkBonus;  // Application du bonus de production en masse
      
      // Calculer la consommation de métal (avec efficacité)
      double metalPerPaperclip = GameConstants.METAL_PER_PAPERCLIP * efficiencyBonus;
      double metalNeeded = baseProduction * metalPerPaperclip;
      
      if (kDebugMode) {
        print('[ProductionManager] Production potentielle: ${baseProduction.toStringAsFixed(1)} trombones, nécessite ${metalNeeded.toStringAsFixed(1)} métal');
      }
      
      // Vérifier si le joueur a assez de métal
      double availableMetal = player.metal;
      double actualProduction = baseProduction;
      
      // Ajuster la production si pas assez de métal
      if (availableMetal < metalNeeded) {
        actualProduction = availableMetal / metalPerPaperclip;
        if (kDebugMode) {
          print('[ProductionManager] Métal insuffisant! Production ajustée à ${actualProduction.toStringAsFixed(1)} trombones');
        }
      }
      
      // Si on peut produire quelque chose
      if (actualProduction > 0) {
        double metalUsed = actualProduction * metalPerPaperclip;
        double metalSaved = actualProduction * GameConstants.METAL_PER_PAPERCLIP - metalUsed;
        
        player.updateMetal(player.metal - metalUsed);
        player.updatePaperclips(player.paperclips + actualProduction);

        if (kDebugMode) {
          print('[ProductionManager] Production réalisée: ${actualProduction.toStringAsFixed(1)} trombones, ${metalUsed.toStringAsFixed(1)} métal utilisé, ${metalSaved.toStringAsFixed(1)} métal économisé');
          print('[ProductionManager] État après production: ${player.paperclips.toStringAsFixed(1)} trombones, ${player.metal.toStringAsFixed(1)} métal');
        }

        // Mise à jour des statistiques
        _statistics.updateProduction(
          paperclipsProduced: actualProduction.floor().toInt(), // Conversion en int
          metalUsed: metalUsed,
          isAuto: true // Production automatique
        );

        // Expérience pour la production automatique
        level.addAutomaticProduction(actualProduction.floor());
        
        // MissionSystem (Option A — mise en pause): pas de progression de missions.
        
        // Vérifier les jalons pour mises à jour du leaderboard, etc.
        _checkMilestones();
      } else {
        if (kDebugMode) print('[ProductionManager] Pas de production possible - manque de métal');
      }
    } else {
      if (kDebugMode) print('[ProductionManager] Pas de production possible - pas d\'autoclippeuses');
    }

    if (kDebugMode) {
      print('===== FIN CYCLE DE PRODUCTION =====');
    }

    notifyListeners();
  }

  /// Production manuelle d'un trombone
  void producePaperclip() {
    if (player.consumeMetal(GameConstants.METAL_PER_PAPERCLIP)) {
      player.updatePaperclips(player.paperclips + 1);
      level.addManualProduction();
      _statistics.updateProduction(
        paperclipsProduced: 1,
        metalUsed: GameConstants.METAL_PER_PAPERCLIP,
        isAuto: false // Production manuelle
      );
      // Mettre à jour le leaderboard tous les 100 trombones produits
      if (_statistics.totalPaperclipsProduced % 100 == 0) {
        _updateLeaderboard();
      }
      
      // MissionSystem (Option A — mise en pause): pas de progression de missions.
      
      notifyListeners();
    }
  }

  /// Calcul de la production manuelle pendant une période (utilisé pour la production continue)
  double _calculateManualProduction(double elapsed) {
    if (player.metal < GameConstants.METAL_PER_PAPERCLIP) return 0;

    double metalUsed = GameConstants.METAL_PER_PAPERCLIP;
    double efficiencyBonus = GameConstants.BASE_EFFICIENCY + (player.upgrades['efficiency']?.level ?? 0) * GameConstants.EFFICIENCY_UPGRADE_MULTIPLIER;
    metalUsed /= efficiencyBonus;

    player.updateMetal(player.metal - metalUsed);
    return 1.0 * elapsed;
  }

  /// Méthode officielle pour l'achat d'une autoclippeuse
  /// Retourne true si l'achat a été effectué, false sinon.
  bool buyAutoclipperOfficial() {
    if (!canBuyAutoclipper()) {
      return false;
    }

    final double cost = calculateAutoclipperCost();

    player.updateMoney(player.money - cost);
    player.updateAutoclippers(player.autoclippers + 1);
    level.addAutoclipperPurchase();

    // Mise à jour centralisée des statistiques
    _statistics.updateProgression(autoclippersBought: 1);
    _statistics.updateEconomics(moneySpent: cost);

    notifyListeners();
    return true;
  }

  /// Méthode de compatibilité : conserve l'ancienne signature
  /// et délègue vers la méthode officielle.
  void buyAutoclipper() {
    buyAutoclipperOfficial();
  }

  /// Calcule le coût d'achat d'une autoclippeuse supplémentaire
  double calculateAutoclipperCost() {
    double baseCost = GameConstants.BASE_AUTOCLIPPER_COST;
    double discount = (player.upgrades['automation']?.level ?? 0) * 0.10; // 10% de réduction par niveau d'automation
    double costMultiplier = player.autoclippers * 0.1; // 10% d'augmentation par autoclippeuse
    double finalCost = baseCost * (1.0 + costMultiplier) * (1.0 - discount);
    return max(finalCost, GameConstants.BASE_AUTOCLIPPER_COST * 0.5); // Prix minimum
  }

  /// Vérifie si le joueur peut acheter une autoclippeuse
  bool canBuyAutoclipper() {
    return player.money >= calculateAutoclipperCost();
  }

  /// Applique les coûts de maintenance des autoclippeuses
  void applyMaintenanceCosts() {
    if (player.autoclippers == 0) return;

    _maintenanceCosts = player.autoclippers * GameConstants.STORAGE_MAINTENANCE_RATE;

    if (player.money >= _maintenanceCosts) {
      // Coût de maintenance actuellement non enregistré dans les statistiques économiques.
      player.updateMoney(player.money - _maintenanceCosts);
    } else {
      player.updateAutoclippers((player.autoclippers * 0.9).floor());
      EventManager.instance.addEvent(
          EventType.RESOURCE_DEPLETION,
          "Maintenance impayée !",
          description: "Certaines autoclippeuses sont hors service",
          importance: EventImportance.HIGH
      );
    }
    
    notifyListeners();
  }

  /// Met en pause ou reprend la production
  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  /// Vérifie si des jalons de production ont été atteints
  void _checkMilestones() {
    // Non implémenté dans la version actuelle (placeholder pour jalons futurs).
  }

  /// Met à jour les classements (pour version en ligne)
  void _updateLeaderboard() {
    // Non implémenté / désactivé dans la version offline actuelle.
  }

  /// Réinitialise les valeurs de production
  void reset() {
    _maintenanceCosts = 0.0;
    _isPaused = false;
    _lastUpdateTime = DateTime.now();
    notifyListeners();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'maintenanceCosts': _maintenanceCosts,
      'isPaused': _isPaused,
      'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
    };
  }

  @override
  void fromJson(Map<String, dynamic> json) {
    _maintenanceCosts = (json['maintenanceCosts'] as num?)?.toDouble() ?? 0.0;
    _isPaused = json['isPaused'] as bool? ?? false;
    _lastUpdateTime = json['lastUpdateTime'] != null 
        ? DateTime.parse(json['lastUpdateTime']) 
        : DateTime.now();
  }
}
