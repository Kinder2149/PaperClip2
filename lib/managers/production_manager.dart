// lib/managers/production_manager.dart
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../constants/game_config.dart' show GameConstants, EventType, EventImportance; // Import des constantes et enums requis
import 'player_manager.dart';
import '../models/statistics_manager.dart';
import 'research_manager.dart';
// MissionSystem (Option A — mise en pause): aucun événement de gameplay n'est branché ici.
import '../models/json_loadable.dart';
import '../models/level_system.dart'; // Import pour LevelSystem
import '../services/upgrades/upgrade_effects_calculator.dart';
import 'package:paperclip2/domain/events/domain_event.dart';
import 'package:paperclip2/domain/events/domain_event_type.dart';
import 'package:paperclip2/domain/ports/domain_event_sink.dart';
import 'package:paperclip2/domain/ports/no_op_domain_event_sink.dart';
import 'package:paperclip2/services/runtime/clock.dart';
import 'package:paperclip2/utils/logger.dart';
import 'package:paperclip2/managers/agent_manager.dart';

/// Gestionnaire responsable de toute la logique de production de trombones
/// (production manuelle, automatique, gestion des autoclippeuses, etc.)
class ProductionManager extends ChangeNotifier implements JsonLoadable {
  final Logger _logger = Logger.forComponent('production');
  // Managers requis
  final PlayerManager _playerManager;
  final StatisticsManager _statistics; // Utilise maintenant la version de models/statistics_manager.dart
  final LevelSystem _levelSystem;
  final ResearchManager _researchManager;
  AgentManager? _agentManager; // CHANTIER-04 : Optionnel pour compatibilité
  DomainEventSink _eventSink = const NoOpDomainEventSink();
  final Clock _clock;
  // Ponts vers le runtime maître (lecture/commande de pause)
  bool Function()? _pauseReader;
  void Function(bool)? _pauseRequest;
  // MissionSystem (Option A — mise en pause): non intégré au runtime.
  double _maintenanceCosts = 0.0;
  double _autoProductionRemainder = 0.0;
  DateTime? _lastUpdateTime;

  // Getters publics
  int get totalPaperclipsProduced => _statistics.totalPaperclipsProduced;
  double get maintenanceCosts => _maintenanceCosts;
  bool get isPaused => _pauseReader != null ? (_pauseReader!.call()) : false;

  /// Production automatique théorique en trombones/s (avec tous les bonus)
  double get currentProductionRatePerSecond {
    if (_playerManager.autoClipperCount == 0) return 0.0;
    final researchSpeedBonus = _researchManager.getResearchBonus('productionSpeed');
    final bulkBonus = 1.0 + _researchManager.getResearchBonus('productionBulk');
    final agentSpeedBonus = _agentManager?.getProductionSpeedBonus() ?? 0.0;
    final totalSpeedBonus = 1.0 + researchSpeedBonus + agentSpeedBonus;
    return _playerManager.autoClipperCount *
        GameConstants.BASE_AUTOCLIPPER_PRODUCTION *
        totalSpeedBonus *
        bulkBonus;
  }
  
  // Accesseurs pour faciliter le code
  PlayerManager get player => _playerManager;
  LevelSystem get level => _levelSystem;

  void setDomainEventSink(DomainEventSink sink) {
    _eventSink = sink;
  }

  // Injection tardive des ponts runtime (composition root)
  void setPauseReader(bool Function()? reader) {
    _pauseReader = reader;
  }

  void setPauseRequest(void Function(bool)? request) {
    _pauseRequest = request;
  }

  void setPauseBridges({bool Function()? reader, void Function(bool)? request}) {
    _pauseReader = reader;
    _pauseRequest = request;
  }
  
  // CHANTIER-04 : Setter pour AgentManager (injection tardive)
  void setAgentManager(AgentManager agentManager) {
    _agentManager = agentManager;
  }

  // Constructor avec injection de dépendances
  ProductionManager({
    required PlayerManager playerManager,
    required StatisticsManager statistics, // Utilise maintenant la version de models/statistics_manager.dart
    required LevelSystem levelSystem,
    required ResearchManager researchManager,
    Clock? clock,
    bool Function()? pauseReader,
    void Function(bool)? pauseRequest,
  }) : 
    _playerManager = playerManager,
    _statistics = statistics,
    _levelSystem = levelSystem,
    _researchManager = researchManager,
    _clock = (clock ?? SystemClock()),
    _pauseReader = pauseReader,
    _pauseRequest = pauseRequest {
    _lastUpdateTime = _clock.now();
  }

  double _metalPerPaperclip() {
    // CHANTIER-03 : Utiliser bonus recherche au lieu d'upgrades
    final efficiencyBonus = _researchManager.getResearchBonus('metalEfficiency');
    final baseConsumption = GameConstants.METAL_PER_PAPERCLIP;
    return baseConsumption * (1.0 - efficiencyBonus);
  }

  /// Traite la production automatique de trombones via les autoclippeuses
  void processProduction({double elapsedSeconds = 1.0}) {
    if (isPaused) {
      if (kDebugMode) _logger.debug('[ProductionManager] processProduction: Ignoré - La production est en pause');
      return;
    }

    final elapsed = elapsedSeconds.isFinite && elapsedSeconds > 0
        ? elapsedSeconds
        : 1.0;

    if (kDebugMode) {
      _logger.debug('===== CYCLE DE PRODUCTION AUTOMATIQUE =====');
      _logger.debug('[ProductionManager] État initial: ${player.paperclips.toStringAsFixed(1)} trombones, ${player.metal.toStringAsFixed(1)} métal, ${player.autoClipperCount} autoclippeuses');
    }

    // CHANTIER-03 : Calcul des bonus via recherches
    final double researchSpeedBonus = _researchManager.getResearchBonus('productionSpeed');
    final double bulkBonus = 1.0 + _researchManager.getResearchBonus('productionBulk');
    final double efficiencyBonus = 1.0 - _researchManager.getResearchBonus('metalEfficiency');
    
    // CHANTIER-04 : Bonus Production Optimizer Agent (+25% si actif)
    final double agentSpeedBonus = _agentManager?.getProductionSpeedBonus() ?? 0.0;
    final double totalSpeedBonus = 1.0 + researchSpeedBonus + agentSpeedBonus;

    if (kDebugMode) {
      final reduction = _researchManager.getResearchBonus('metalEfficiency');
      _logger.debug('[ProductionManager] Bonus: vitesse recherche: +${(researchSpeedBonus * 100).toStringAsFixed(1)}%, agent: +${(agentSpeedBonus * 100).toStringAsFixed(1)}%, total: x${totalSpeedBonus.toStringAsFixed(2)}');
      _logger.debug('[ProductionManager] Bonus: masse: x${bulkBonus.toStringAsFixed(2)}, efficacité: x${efficiencyBonus.toStringAsFixed(2)} (réduction: ${(reduction * 100).toStringAsFixed(1)}%)');
    }

    // Si joueur a des autoclippeuses
    if (player.autoClipperCount > 0) {
      // Production automatique: calcul en delta-temps, mais production en unités entières.
      // GameConstants.BASE_AUTOCLIPPER_PRODUCTION est interprété comme une production "par seconde".
      double productionRatePerSecond =
          player.autoClipperCount * GameConstants.BASE_AUTOCLIPPER_PRODUCTION;
      productionRatePerSecond *= totalSpeedBonus; // Inclut bonus recherche + agent
      productionRatePerSecond *= bulkBonus;

      final metalPerPaperclip = _metalPerPaperclip();

      final desiredUnitsDouble = (productionRatePerSecond * elapsed) +
          _autoProductionRemainder;
      final desiredUnits = desiredUnitsDouble.floor();
      _autoProductionRemainder = desiredUnitsDouble - desiredUnits;

      if (kDebugMode) {
        final desiredMetal = desiredUnits * metalPerPaperclip;
        _logger.debug('[ProductionManager] Production (elapsed=${elapsed.toStringAsFixed(2)}s): ${desiredUnits} trombones demandés, nécessite ${desiredMetal.toStringAsFixed(2)} métal');
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
          _logger.debug('[ProductionManager] Production réalisée: +$actualUnits trombones, -${metalUsed.toStringAsFixed(2)} métal');
          _logger.debug('[ProductionManager] État après production: ${player.paperclips.toStringAsFixed(1)} trombones, ${player.metal.toStringAsFixed(1)} métal');
        }

        _statistics.updateProduction(
          paperclipsProduced: actualUnits,
          metalUsed: metalUsed,
          isAuto: true,
        );

        level.addAutomaticProduction(actualUnits);
        _checkMilestones();
      } else {
        if (kDebugMode) _logger.debug('[ProductionManager] Pas de production possible - manque de métal');
      }
    } else {
      if (kDebugMode) _logger.debug('[ProductionManager] Pas de production possible - pas d\'autoclippeuses');
    }

    if (kDebugMode) {
      _logger.debug('===== FIN CYCLE DE PRODUCTION =====');
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
    player.updateAutoclippers(player.autoClipperCount + 1);
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
    // CHANTIER-03 : Utiliser bonus recherche pour discount autoclippers
    final discount = _researchManager.getResearchBonus('autoclipperDiscount');
    final baseCost = GameConstants.BASE_AUTOCLIPPER_COST;
    final count = player.autoClipperCount;
    // Formule exponentielle : coût augmente avec le nombre
    return baseCost * pow(1.15, count) * (1.0 - discount);
  }

  /// Vérifie si le joueur peut acheter une autoclippeuse
  bool canBuyAutoclipper() {
    return player.money >= calculateAutoclipperCost();
  }

  /// Applique les coûts de maintenance des autoclippeuses
  void applyMaintenanceCosts() {
    if (player.autoClipperCount == 0) return;

    _maintenanceCosts = player.autoClipperCount * GameConstants.STORAGE_MAINTENANCE_RATE;

    if (player.money >= _maintenanceCosts) {
      // Coût de maintenance actuellement non enregistré dans les statistiques économiques.
      player.updateMoney(player.money - _maintenanceCosts);
    } else {
      player.updateAutoclippers((player.autoClipperCount * 0.9).floor());
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
    if (_pauseRequest != null) {
      // Demande au runtime maître de changer d'état
      _pauseRequest!.call(!isPaused);
    }
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
    _lastUpdateTime = DateTime.now();
    notifyListeners();
  }
  
  /// Reset pour progression (prestige)
  /// 
  /// Réinitialise la production automatique mais conserve les recherches
  void resetForProgression() {
    _maintenanceCosts = 0.0;
    _autoProductionRemainder = 0.0;
    _lastUpdateTime = _clock.now();
    notifyListeners();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'maintenanceCosts': _maintenanceCosts,
      'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
    };
  }

  @override
  void fromJson(Map<String, dynamic> json) {
    _maintenanceCosts = (json['maintenanceCosts'] as num?)?.toDouble() ?? 0.0;
    _lastUpdateTime = json['lastUpdateTime'] != null 
        ? DateTime.parse(json['lastUpdateTime']) 
        : DateTime.now();
  }
}
