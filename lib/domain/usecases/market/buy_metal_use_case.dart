import '../../repositories/market_repository.dart';
import '../../repositories/player_repository.dart';
import '../../entities/market_state.dart';
import '../../entities/player_state.dart';
import '../../../core/constants/game_constants.dart';

class BuyMetalUseCase {
  final MarketRepository _marketRepository;
  final PlayerRepository _playerRepository;

  BuyMetalUseCase(this._marketRepository, this._playerRepository);

  Future<bool> execute(int amount) async {
    final market = await _marketRepository.getMarketState();
    final player = await _playerRepository.getPlayerState();
    
    if (market == null || player == null) return false;

    // Calcul du coût
    final cost = amount * market.currentMetalPrice;

    // Vérification des ressources
    if (player.money < cost) return false;

    // Vérification de la capacité de stockage
    if (player.metal + amount > player.maxMetalStorage) return false;

    // Mise à jour du joueur
    final updatedPlayer = PlayerState(
      clips: player.clips,
      metal: player.metal + amount,
      money: player.money - cost,
      autoclippers: player.autoclippers,
      autoProduction: player.autoProduction,
      maxMetalStorage: player.maxMetalStorage,
      upgrades: player.upgrades,
      totalClipsProduced: player.totalClipsProduced,
      productionHistory: player.productionHistory,
    );

    // Mise à jour du marché
    final updatedMarket = MarketState(
      currentMetalPrice: market.currentMetalPrice,
      demand: market.demand,
      totalSales: market.totalSales,
      averagePrice: market.averagePrice,
      priceHistory: market.priceHistory,
    );

    // Mise à jour des états
    final marketSuccess = await _marketRepository.updateMarketState(updatedMarket);
    final playerSuccess = await _playerRepository.updatePlayerState(updatedPlayer);

    return marketSuccess && playerSuccess;
  }
} 