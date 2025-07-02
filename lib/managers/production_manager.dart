// lib/managers/production_manager.dart
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/game_config.dart';
import '../models/player_manager.dart';
import '../models/statistics_manager.dart';
import '../models/progression_system.dart';
import '../models/mission_system.dart';
import '../models/json_loadable.dart';
import '../models/event_system.dart';

/// Gestionnaire responsable de toute la logique de production de trombones
/// (production manuelle, automatique, gestion des autoclippeuses, etc.)
class ProductionManager extends ChangeNotifier implements JsonLoadable {
  // Dépendances
  final PlayerManager _playerManager;
  final StatisticsManager _statistics;
  final LevelSystem _levelSystem;
  final MissionSystem _missionSystem;

  // État de la production
  int _totalPaperclipsProduced = 0;
  double _maintenanceCosts = 0.0;
  bool _isPaused = false;
  DateTime? _lastUpdateTime;

  // Getters publics
  int get totalPaperclipsProduced => _totalPaperclipsProduced;
  double get maintenanceCosts => _maintenanceCosts;
  bool get isPaused => _isPaused;
  
  // Accesseurs pour faciliter le code
  PlayerManager get player => _playerManager;
  LevelSystem get level => _levelSystem;
  MissionSystem get missionSystem => _missionSystem;

  // Constructor avec injection de dépendances
  ProductionManager({
    required PlayerManager playerManager,
    required StatisticsManager statistics,
    required LevelSystem levelSystem,
    required MissionSystem missionSystem,
  }) : 
    _playerManager = playerManager,
    _statistics = statistics,
    _levelSystem = levelSystem,
    _missionSystem = missionSystem {
    _lastUpdateTime = DateTime.now();
  }

  /// Traite la production automatique de trombones via les autoclippeuses
  void processProduction() {
    if (_isPaused) return;

    // Calcul des bonus
    double speedBonus = 1.0 + ((player.upgrades['speed']?.level ?? 0) * 0.20);
    double bulkBonus = 1.0 + ((player.upgrades['bulk']?.level ?? 0) * 0.35);

    // Nouveau calcul d'efficacité avec 11% par niveau et plafond 85%
    double efficiencyLevel = (player.upgrades['efficiency']?.level ?? 0).toDouble(); 
    double reduction = min(
        efficiencyLevel * GameConstants.EFFICIENCY_UPGRADE_MULTIPLIER,
        GameConstants.EFFICIENCY_MAX_REDUCTION
    );
    double efficiencyBonus = 1.0 - reduction;

    // Si joueur a des autoclippeuses
    if (player.autoclippers > 0) {
      // Production automatique basée sur le nombre d'autoclippeuses
      double baseProduction = player.autoclippers * GameConstants.AUTOCLIPPER_BASE_RATE;
      baseProduction *= speedBonus; // Application du bonus de vitesse
      baseProduction *= bulkBonus;  // Application du bonus de production en masse
      
      // Calculer la consommation de métal (avec efficacité)
      double metalPerPaperclip = GameConstants.METAL_PER_PAPERCLIP * efficiencyBonus;
      double metalNeeded = baseProduction * metalPerPaperclip;
      
      // Vérifier si le joueur a assez de métal
      double availableMetal = player.metal;
      double actualProduction = baseProduction;
      
      // Ajuster la production si pas assez de métal
      if (availableMetal < metalNeeded) {
        actualProduction = availableMetal / metalPerPaperclip;
      }
      
      // Si on peut produire quelque chose
      if (actualProduction > 0) {
        double metalUsed = actualProduction * metalPerPaperclip;
        double metalSaved = actualProduction * GameConstants.METAL_PER_PAPERCLIP - metalUsed;
        
        player.updateMetal(player.metal - metalUsed);
        player.updatePaperclips(player.paperclips + actualProduction);
        _totalPaperclipsProduced += actualProduction.floor();

        // Mise à jour des statistiques
        _statistics.updateProduction(
          isManual: false,
          amount: actualProduction,
          metalUsed: metalUsed,
          metalSaved: metalSaved,
          efficiency: reduction * 100
        );

        // Expérience pour la production automatique
        level.addAutomaticProduction(actualProduction.floor());
        
        // Mise à jour des missions
        missionSystem.updateMissions(
          MissionType.PRODUCE_PAPERCLIPS,
          actualProduction
        );
        
        // Vérifier les jalons pour mises à jour du leaderboard, etc.
        _checkMilestones();
      }
    }

    notifyListeners();
  }

  /// Production manuelle d'un trombone
  void producePaperclip() {
    if (player.consumeMetal(GameConstants.METAL_PER_PAPERCLIP)) {
      player.updatePaperclips(player.paperclips + 1);
      _totalPaperclipsProduced++;

      // Mettre à jour le leaderboard tous les 100 trombones
      if (_totalPaperclipsProduced % 100 == 0) {
        _updateLeaderboard();
      }

      level.addManualProduction();
      _statistics.updateProduction(
        isManual: true,
        amount: 1,
        metalUsed: GameConstants.METAL_PER_PAPERCLIP,
      );
      
      // Mise à jour des missions
      missionSystem.updateMissions(
        MissionType.PRODUCE_PAPERCLIPS,
        1
      );
      
      notifyListeners();
    }
  }

  /// Calcul de la production manuelle pendant une période (utilisé pour la production continue)
  double _calculateManualProduction(double elapsed) {
    if (player.metal < GameConstants.METAL_PER_PAPERCLIP) return 0;

    double metalUsed = GameConstants.METAL_PER_PAPERCLIP;
    double efficiencyBonus = 1.0 + (player.upgrades['efficiency']?.level ?? 0) * 0.1;
    metalUsed /= efficiencyBonus;

    player.updateMetal(player.metal - metalUsed);
    return 1.0 * elapsed;
  }

  /// Acheter une autoclippeuse
  void buyAutoclipper() {
    double cost = calculateAutoclipperCost();
    if (player.money >= cost) {
      player.updateMoney(player.money - cost);
      player.updateAutoclippers(player.autoclippers + 1);
      level.addAutoclipperPurchase();

      // Ajout statistiques
      _statistics.updateProgression(autoclippersBought: 1);  
      _statistics.updateEconomics(moneySpent: cost);
      
      notifyListeners();
    }
  }

  /// Calcule le coût d'achat d'une autoclippeuse supplémentaire
  double calculateAutoclipperCost() {
    double baseCost = GameConstants.BASE_AUTOCLIPPER_COST;
    double discount = (player.upgrades['automation']?.level ?? 0) * 0.10; // 10% de réduction par niveau d'automation
    double costMultiplier = player.autoclippers * GameConstants.AUTOCLIPPER_COST_MULTIPLIER;
    double finalCost = baseCost * (1.0 + costMultiplier) * (1.0 - discount);
    return max(finalCost, GameConstants.MIN_AUTOCLIPPER_COST);
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
    // Implémentation future pour vérifier des jalons importants
    // de production (ex: premiers 1000 trombones, etc.)
  }

  /// Met à jour les classements (pour version en ligne)
  void _updateLeaderboard() {
    // Fonctionnalité désactivée dans la version offline
  }

  /// Réinitialise les valeurs de production
  void reset() {
    _totalPaperclipsProduced = 0;
    _maintenanceCosts = 0.0;
    _isPaused = false;
    _lastUpdateTime = DateTime.now();
    notifyListeners();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'totalPaperclipsProduced': _totalPaperclipsProduced,
      'maintenanceCosts': _maintenanceCosts,
      'isPaused': _isPaused,
      'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
    };
  }

  @override
  void fromJson(Map<String, dynamic> json) {
    _totalPaperclipsProduced = (json['totalPaperclipsProduced'] as num?)?.toInt() ?? 0;
    _maintenanceCosts = (json['maintenanceCosts'] as num?)?.toDouble() ?? 0.0;
    _isPaused = json['isPaused'] as bool? ?? false;
    _lastUpdateTime = json['lastUpdateTime'] != null 
        ? DateTime.parse(json['lastUpdateTime']) 
        : DateTime.now();
  }
}
