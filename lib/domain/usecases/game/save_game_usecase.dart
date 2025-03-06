// lib/domain/usecases/game/save_game_usecase.dart
import '../../repositories/game_repository.dart';
import '../../entities/game_state_entity.dart';

class SaveGameUseCase {
  final GameRepository gameRepository;

  SaveGameUseCase({required this.gameRepository});

  Future<bool> execute(GameState gameState) async {
    try {
      await gameRepository.saveGame(gameState);
      return true;
    } catch (e) {
      print('Error saving game: $e');
      return false;
    }
  }
}