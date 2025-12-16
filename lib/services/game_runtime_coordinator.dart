import '../models/game_state.dart';
import '../constants/game_config.dart';
import 'auto_save_service.dart';
import '../controllers/game_session_controller.dart';
import 'lifecycle/app_lifecycle_handler.dart';

class GameRuntimeCoordinator {
  final GameState _gameState;
  final AppLifecycleHandler _lifecycleHandler;
  final AutoSaveService _autoSaveService;
  final GameSessionController _gameSessionController;

  GameRuntimeCoordinator({
    required GameState gameState,
    required AppLifecycleHandler lifecycleHandler,
    required AutoSaveService autoSaveService,
    required GameSessionController gameSessionController,
  })  : _gameState = gameState,
        _lifecycleHandler = lifecycleHandler,
        _autoSaveService = autoSaveService,
        _gameSessionController = gameSessionController;

  Future<void> register() async {
    _lifecycleHandler.register(_gameState);
  }

  void unregister() {
    _lifecycleHandler.unregister();
  }

  void startSession() {
    _gameSessionController.startSession();
  }

  void stopSession() {
    _gameSessionController.stopSession();
  }

  Future<void> startAutoSave() async {
    await _autoSaveService.start();
  }

  Future<void> stopAutoSave() async {
    _autoSaveService.stop();
  }

  Future<void> loadGameAndStartAutoSave(String name) async {
    _autoSaveService.stop();
    await _gameState.loadGame(name);
    await _autoSaveService.start();
  }

  Future<void> startNewGameAndStartAutoSave(
    String name, {
    GameMode mode = GameMode.INFINITE,
  }) async {
    _autoSaveService.stop();
    await _gameState.startNewGame(name, mode: mode);
    await _autoSaveService.start();
  }
}
