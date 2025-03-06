// lib/domain/usecases/game/load_game_usecase.dart
import '../../repositories/game_repository.dart';
import '../../entities/game_state_entity.dart';

class LoadGameUseCase {
  final GameRepository gameRepository;

  LoadGameUseCase({required this.gameRepository});

  Future<GameState?> execute(String name) async {
    try {
      return await gameRepository.loadGame(name);
    } catch (e) {
      print('Error loading game: $e');
      return null;
    }
  }
}