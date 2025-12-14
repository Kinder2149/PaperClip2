import 'package:flutter/widgets.dart';

import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';

class AppLifecycleHandler with WidgetsBindingObserver {
  GameState? _gameState;

  void register(GameState gameState) {
    _gameState = gameState;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final gameState = _gameState;
      if (gameState == null || gameState.gameName == null) {
        return;
      }

      GamePersistenceOrchestrator.instance.requestLifecycleSave(
        gameState,
        reason: 'app_lifecycle_${state.name}',
      );
    }
  }
}
