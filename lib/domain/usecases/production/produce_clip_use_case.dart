import '../../repositories/player_repository.dart';
import '../../entities/player_state.dart';
import '../../../core/constants/game_constants.dart';

class ProduceClipUseCase {
  final PlayerRepository _playerRepository;

  ProduceClipUseCase(this._playerRepository);

  Future<bool> execute() async {
    final player = await _playerRepository.getPlayerState();
    if (player == null) return false;

    // Calcul du coût en métal
    final efficiencyLevel = player.upgrades['efficiency']?.level ?? 0;
    final efficiencyMultiplier = 1.0 - (efficiencyLevel * 0.11).clamp(0.0, 0.85);
    final metalCost = GameConstants.METAL_PER_PAPERCLIP * efficiencyMultiplier;

    // Vérification des ressources
    if (player.metal < metalCost) return false;

    // Mise à jour du joueur
    final updatedPlayer = PlayerState(
      clips: player.clips + 1,
      metal: player.metal - metalCost,
      money: player.money,
      autoclippers: player.autoclippers,
      autoProduction: player.autoProduction,
      maxMetalStorage: player.maxMetalStorage,
      upgrades: player.upgrades,
      totalClipsProduced: player.totalClipsProduced + 1,
      productionHistory: player.productionHistory,
    );

    return await _playerRepository.updatePlayerState(updatedPlayer);
  }
} 