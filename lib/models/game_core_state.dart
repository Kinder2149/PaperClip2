import 'package:paperclip2/managers/player_manager.dart' as managers;
import 'package:paperclip2/managers/market_manager.dart';
import 'package:paperclip2/managers/production_manager.dart';
import 'package:paperclip2/managers/resource_manager.dart';
import 'package:paperclip2/models/level_system.dart';
import 'package:paperclip2/models/statistics_manager.dart';

/// Représente le "coeur" du jeu : l'ensemble des managers
/// qui portent l'état métier, sans timers ni logique UI.
class GameCoreState {
  final managers.PlayerManager playerManager;
  final MarketManager marketManager;
  final ResourceManager resourceManager;
  final LevelSystem levelSystem;
  final ProductionManager productionManager;
  final StatisticsManager statistics;

  const GameCoreState({
    required this.playerManager,
    required this.marketManager,
    required this.resourceManager,
    required this.levelSystem,
    required this.productionManager,
    required this.statistics,
  });
}
