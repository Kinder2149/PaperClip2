import '../../repositories/player_repository.dart';
import '../../entities/player_state.dart';

class ToggleAutoProductionUseCase {
  final PlayerRepository _playerRepository;

  ToggleAutoProductionUseCase(this._playerRepository);

  Future<bool> execute() async {
    final player = await _playerRepository.getPlayerState();
    if (player == null) return false;

    // Vérification si le joueur a des autoclippers
    if (player.autoclippers <= 0) return false;

    // Mise à jour du joueur
    final updatedPlayer = PlayerState(
      clips: player.clips,
      metal: player.metal,
      money: player.money,
      autoclippers: player.autoclippers,
      autoProduction: !player.autoProduction,
      maxMetalStorage: player.maxMetalStorage,
      upgrades: player.upgrades,
      totalClipsProduced: player.totalClipsProduced,
      productionHistory: player.productionHistory,
    );

    return await _playerRepository.updatePlayerState(updatedPlayer);
  }
} 