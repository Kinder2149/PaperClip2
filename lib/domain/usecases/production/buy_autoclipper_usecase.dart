// lib/domain/usecases/production/buy_autoclipper_usecase.dart
import '../../repositories/player_repository.dart';
import '../../entities/player_entity.dart';
import '../../repositories/level_repository.dart';
import '../../../core/constants/game_constants.dart';
import 'dart:math';

class BuyAutoclipperUseCase {
  final PlayerRepository playerRepository;
  final LevelRepository? levelRepository;

  BuyAutoclipperUseCase({
    required this.playerRepository,
    this.levelRepository,
  });

  Future<bool> execute() async {
    final player = await playerRepository.getPlayer();
    if (player == null) return false;

    final cost = _calculateAutoclipperCost(player);

    if (player.money < cost) return false;

    // Déduire le coût
    await playerRepository.increaseResourcesByAmount(money: -cost);

    // Augmenter le nombre d'autoclippers
    final newPlayer = await playerRepository.getPlayer();
    if (newPlayer != null) {
      await playerRepository.updatePlayer(
          Player(
            paperclips: newPlayer.paperclips,
            metal: newPlayer.metal,
            money: newPlayer.money,
            autoclippers: newPlayer.autoclippers + 1,
            sellPrice: newPlayer.sellPrice,
            maxMetalStorage: newPlayer.maxMetalStorage,
            upgrades: newPlayer.upgrades,
          )
      );
    }

    // Ajouter l'expérience pour l'achat d'un autoclipper
    if (levelRepository != null) {
      await levelRepository!.addAutoclipperPurchase();
    }

    return true;
  }

  double _calculateAutoclipperCost(Player player) {
    double baseCost = GameConstants.BASE_AUTOCLIPPER_COST;
    double automationDiscount = 1.0 - ((player.upgrades['automation']?.level ?? 0) * 0.10);
    return baseCost * pow(1.1, player.autoclippers) * automationDiscount;
  }
}