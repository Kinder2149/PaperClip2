import '../../repositories/player_repository.dart';
import '../../entities/player_state.dart';
import '../../../core/constants/game_constants.dart';
import 'dart:math' as math;

class BuyAutoclipperUseCase {
  final PlayerRepository _playerRepository;

  BuyAutoclipperUseCase(this._playerRepository);

  Future<bool> execute() async {
    final player = await _playerRepository.getPlayerState();
    if (player == null) return false;

    // Calcul du coût
    final cost = _calculateAutoclipperCost(player.autoclippers);

    // Vérification des ressources
    if (player.money < cost) return false;

    // Mise à jour du joueur
    final updatedPlayer = PlayerState(
      clips: player.clips,
      metal: player.metal,
      money: player.money - cost,
      autoclippers: player.autoclippers + 1,
      autoProduction: player.autoProduction,
      maxMetalStorage: player.maxMetalStorage,
      upgrades: player.upgrades,
      totalClipsProduced: player.totalClipsProduced,
      productionHistory: player.productionHistory,
    );

    return await _playerRepository.updatePlayerState(updatedPlayer);
  }

  double _calculateAutoclipperCost(int currentCount) {
    return GameConstants.AUTOCLIPPER_BASE_COST * 
           math.pow(GameConstants.AUTOCLIPPER_COST_MULTIPLIER, currentCount);
  }
} 