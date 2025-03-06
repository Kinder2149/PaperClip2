// lib/domain/usecases/market/buy_metal_usecase.dart
import '../../repositories/player_repository.dart';
import '../../repositories/market_repository.dart';
import '../../repositories/statistics_repository.dart';
import '../../../core/constants/game_constants.dart';

class BuyMetalUseCase {
  final PlayerRepository playerRepository;
  final MarketRepository? marketRepository;
  final StatisticsRepository? statisticsRepository;

  BuyMetalUseCase({
    required this.playerRepository,
    this.marketRepository,
    this.statisticsRepository,
  });

  Future<bool> execute() async {
    final player = await playerRepository.getPlayer();
    if (player == null) return false;

    double metalPrice = 0.0;
    if (marketRepository != null) {
      metalPrice = await marketRepository!.getCurrentMetalPrice();
    } else {
      metalPrice = GameConstants.MIN_METAL_PRICE;
    }

    // Vérifier si le joueur peut acheter du métal
    if (player.money < metalPrice) return false;
    if (player.metal + GameConstants.METAL_PACK_AMOUNT > player.maxMetalStorage) return false;

    // Acheter du métal
    await playerRepository.increaseResourcesByAmount(
      money: -metalPrice,
      metal: GameConstants.METAL_PACK_AMOUNT,
    );

    // Mettre à jour le stock du marché
    if (marketRepository != null) {
      await marketRepository!.updateMarketStock(-GameConstants.METAL_PACK_AMOUNT);
    }

    // Mettre à jour les statistiques
    if (statisticsRepository != null) {
      await statisticsRepository!.updateEconomics(
        moneySpent: metalPrice,
        metalBought: GameConstants.METAL_PACK_AMOUNT,
      );
    }

    return true;
  }
}