// lib/domain/usecases/production/produce_paperclip_usecase.dart
import 'package:equatable/equatable.dart';
import '../../repositories/player_repository.dart';
import '../../repositories/level_repository.dart';
import '../../repositories/statistics_repository.dart';
import '../../../core/constants/game_constants.dart';

class ProducePaperclipUseCase {
  final PlayerRepository playerRepository;
  final LevelRepository? levelRepository;
  final StatisticsRepository? statisticsRepository;

  ProducePaperclipUseCase({
    required this.playerRepository,
    this.levelRepository,
    this.statisticsRepository,
  });

  Future<bool> execute() async {
    // Vérifier si le joueur a assez de métal
    final success = await playerRepository.consumeMetal(GameConstants.METAL_PER_PAPERCLIP);

    if (!success) return false;

    // Augmenter le nombre de trombones
    await playerRepository.increaseResourcesByAmount(paperclips: 1.0);

    // Ajouter l'expérience pour la production manuelle
    if (levelRepository != null) {
      await levelRepository!.addManualProduction();
    }

    // Mettre à jour les statistiques
    if (statisticsRepository != null) {
      await statisticsRepository!.updateProduction(
        isManual: true,
        amount: 1,
        metalUsed: GameConstants.METAL_PER_PAPERCLIP,
      );
    }

    return true;
  }
}