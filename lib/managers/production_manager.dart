// lib/managers/production_manager.dart
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../constants/game_config.dart' show GameConstants, EventType, EventImportance; // Import des constantes et enums requis
import 'player_manager.dart';
import '../models/statistics_manager.dart';
// MissionSystem (Option A — mise en pause): aucun événement de gameplay n'est branché ici.
import '../models/json_loadable.dart';
import '../models/level_system.dart'; // Import pour LevelSystem
import '../services/upgrades/upgrade_effects_calculator.dart';
import 'package:paperclip2/domain/events/domain_event.dart';
import 'package:paperclip2/domain/events/domain_event_type.dart';
import 'package:paperclip2/domain/ports/domain_event_sink.dart';
import 'package:paperclip2/domain/ports/no_op_domain_event_sink.dart';

/// Gestionnaire responsable de toute la logique de production de trombones
/// (production manuelle, automatique, gestion des autoclippeuses, etc.)
class ProductionManager extends ChangeNotifier implements JsonLoadable {
  // Managers requis
  final PlayerManager _playerManager;
  final StatisticsManager _statistics; // Utilise maintenant la version de models/statistics_manager.dart
  final LevelSystem _levelSystem;
  DomainEventSink _eventSink = const NoOpDomainEventSink();
  // MissionSystem (Option A — mise en pause): non intégré au runtime.
  double _maintenanceCosts = 0.0;
  double _autoProductionRemainder = 0.0;
  bool _isPaused = false;
  DateTime? _lastUpdateTime;

  // Getters publics
  int get totalPaperclipsProduced => _statistics.totalPaperclipsProduced;
  double get maintenanceCosts => _maintenanceCosts;
  bool get isPaused => _isPaused;
  
  // Accesseurs pour faciliter le code
  PlayerManager get player => _playerManager;
  LevelSystem get level => _levelSystem;

  void setDomainEventSink(DomainEventSink sink) {
    _eventSink = sink;
  }

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

  double _metalPerPaperclip() {
    final efficiencyLevel = player.upgrades['efficiency']?.level ?? 0;
    return UpgradeEffectsCalculator.metalPerPaperclip(
      efficiencyLevel: efficiencyLevel,
    );
  }

  /// Traite la production automatique de trombones via les autoclippeuses
  void processProduction({double elapsedSeconds = 1.0}) {
    if (_isPaused) {
      if (kDebugMode) print('[ProductionManager] processProduction: Ignoré - La production est en pause');
      return;
    }

    final elapsed = elapsedSeconds.isFinite && elapsedSeconds > 0
        ? elapsedSeconds
        : 1.0;

    if (kDebugMode) {
      print('===== CYCLE DE PRODUCTION AUTOMATIQUE =====');
      print('[ProductionManager] État initial: ${player.paperclips.toStringAsFixed(1)} trombones, ${player.metal.toStringAsFixed(1)} métal, ${player.autoclippers} autoclippeuses');
    }

    // Calcul des bonus (source unique)
    final int speedLevel = player.upgrades['speed']?.level ?? 0;
    final int bulkLevel = player.upgrades['bulk']?.level ?? 0;
    final int efficiencyLevel = player.upgrades['efficiency']?.level ?? 0;

    final double speedBonus = UpgradeEffectsCalculator.speedMultiplier(level: speedLevel);
    final double bulkBonus = UpgradeEffectsCalculator.bulkMultiplier(level: bulkLevel);

    final double reduction = UpgradeEffectsCalculator.efficiencyReduction(level: efficiencyLevel);
    final double efficiencyBonus = 1.0 - reduction;

    if (kDebugMode) {
      print('[ProductionManager] Bonus: vitesse: x${speedBonus.toStringAsFixed(2)}, masse: x${bulkBonus.toStringAsFixed(2)}, efficacité: x${efficiencyBonus.toStringAsFixed(2)} (réduction: ${(reduction * 100).toStringAsFixed(1)}%)');
    }

    // Si joueur a des autoclippeuses
    if (player.autoclippers > 0) {
      // Production automatique: calcul en delta-temps, mais production en unités entières.
      // GameConstants.BASE_AUTOCLIPPER_PRODUCTION est interprété comme une production "par seconde".
      double productionRatePerSecond =
          player.autoclippers * GameConstants.BASE_AUTOCLIPPER_PRODUCTION;
      productionRatePerSecond *= speedBonus;
      productionRatePerSecond *= bulkBonus;

      final metalPerPaperclip = _metalPerPaperclip();

      final desiredUnitsDouble = (productionRatePerSecond * elapsed) +
          _autoProductionRemainder;
      final desiredUnits = desiredUnitsDouble.floor();
      _autoProductionRemainder = desiredUnitsDouble - desiredUnits;

      if (kDebugMode) {
        final desiredMetal = desiredUnits * metalPerPaperclip;
        print(
          '[ProductionManager] Production (elapsed=${elapsed.toStringAsFixed(2)}s): '
          '${desiredUnits} trombones demandés, nécessite ${desiredMetal.toStringAsFixed(2)} métal',
        );
      }

      final availableMetal = player.metal;
      final maxUnitsByMetal = metalPerPaperclip > 0
          ? (availableMetal / metalPerPaperclip).floor()
          : 0;

      final actualUnits = min(desiredUnits, maxUnitsByMetal);

      // Si on ne peut pas produire le volume demandé à cause du métal,
      // on remet les unités non produites dans le remainder.
      if (actualUnits < desiredUnits) {
        _autoProductionRemainder += (desiredUnits - actualUnits);
      }

      if (actualUnits > 0) {
        final metalUsed = actualUnits * metalPerPaperclip;

        player.updateMetal(player.metal - metalUsed);
        player.updatePaperclips(player.paperclips + actualUnits);

        if (kDebugMode) {
          print(
            '[ProductionManager] Production réalisée: +$actualUnits trombones, '
            '-${metalUsed.toStringAsFixed(2)} métal',
          );
          print(
            '[ProductionManager] État après production: '
            '${player.paperclips.toStringAsFixed(1)} trombones, '
            '${player.metal.toStringAsFixed(1)} métal',
          );
        }

        _statistics.updateProduction(
          paperclipsProduced: actualUnits,
          metalUsed: metalUsed,
          isAuto: true,
        );

        level.addAutomaticProduction(actualUnits);
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
    final metalPerPaperclip = _metalPerPaperclip();
    if (player.consumeMetal(metalPerPaperclip)) {
      player.updatePaperclips(player.paperclips + 1);
      level.addManualProduction();
      _statistics.updateProduction(
        paperclipsProduced: 1,
        metalUsed: metalPerPaperclip,
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

    final metalUsed = _metalPerPaperclip();
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
    return UpgradeEffectsCalculator.autoclipperCost(
      autoclippersOwned: player.autoclippers,
      automationLevel: player.upgrades['automation']?.level ?? 0,
    );
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
      _eventSink.publish(
        const DomainEvent(
          type: DomainEventType.resourceDepletion,
          data: <String, Object?>{
            'title': 'Maintenance impayée !',
            'description': 'Certaines autoclippeuses sont hors service',
          },
        ),
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
    _autoProductionRemainder = 0.0;
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
