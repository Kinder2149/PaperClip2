import '../../repositories/market_repository.dart';
import '../../repositories/player_repository.dart';
import '../../entities/market_state.dart';
import '../../entities/player_state.dart';
import '../../../core/constants/game_constants.dart';

class SellClipsUseCase {
  final MarketRepository _marketRepository;
  final PlayerRepository _playerRepository;

  SellClipsUseCase(this._marketRepository, this._playerRepository);

  Future<bool> execute(int amount) async {
    final market = await _marketRepository.getMarketState();
    final player = await _playerRepository.getPlayerState();
    
    if (market == null || player == null) return false;

    // Vérification des ressources
    if (player.clips < amount) return false;

    // Calcul du revenu
    final revenue = amount * market.currentMetalPrice;

    // Mise à jour du marché
    final updatedMarket = MarketState(
      currentMetalPrice: market.currentMetalPrice,
      demand: market.demand,
      totalSales: market.totalSales + amount,
      averagePrice: _calculateNewAveragePrice(market, market.currentMetalPrice),
      priceHistory: market.priceHistory,
    );

    // Mise à jour du joueur
    final updatedPlayer = PlayerState(
      clips: player.clips - amount,
      metal: player.metal,
      money: player.money + revenue,
      autoclippers: player.autoclippers,
      autoProduction: player.autoProduction,
      maxMetalStorage: player.maxMetalStorage,
      upgrades: player.upgrades,
      totalClipsProduced: player.totalClipsProduced,
      productionHistory: player.productionHistory,
    );

    // Mise à jour des états
    final marketSuccess = await _marketRepository.updateMarketState(updatedMarket);
    final playerSuccess = await _playerRepository.updatePlayerState(updatedPlayer);

    return marketSuccess && playerSuccess;
  }

  double _calculateNewAveragePrice(MarketState market, double currentPrice) {
    final totalSales = market.totalSales;
    final currentTotal = market.averagePrice * totalSales;
    final newTotal = currentTotal + currentPrice;
    return newTotal / (totalSales + 1);
  }
} 