import 'package:flutter/widgets.dart';

import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';

typedef AppLifecycleNowProvider = DateTime Function();

abstract class AppLifecyclePersistencePort {
  Future<void> requestLifecycleSave(GameState state, {String? reason});
}

class _DefaultAppLifecyclePersistencePort implements AppLifecyclePersistencePort {
  final GamePersistenceOrchestrator _inner;

  _DefaultAppLifecyclePersistencePort(this._inner);

  @override
  Future<void> requestLifecycleSave(GameState state, {String? reason}) {
    return _inner.requestLifecycleSave(state, reason: reason);
  }
}

class AppLifecycleHandler with WidgetsBindingObserver {
  GameState? _gameState;
  final AppLifecyclePersistencePort _persistence;
  final AppLifecycleNowProvider _now;

  AppLifecycleHandler({
    AppLifecyclePersistencePort? persistence,
    AppLifecycleNowProvider? now,
  })  : _persistence =
            persistence ?? _DefaultAppLifecyclePersistencePort(GamePersistenceOrchestrator.instance),
        _now = now ?? DateTime.now;

  void register(GameState gameState) {
    _gameState = gameState;
    WidgetsBinding.instance.addObserver(this);
  }

  void unregister() {
    WidgetsBinding.instance.removeObserver(this);
    _gameState = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final gameState = _gameState;
    if (gameState == null || gameState.gameName == null) {
      return;
    }

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      gameState.markLastActiveAt(_now());
      _persistence.requestLifecycleSave(
        gameState,
        reason: 'app_lifecycle_${state.name}',
      );
      return;
    }

    if (state == AppLifecycleState.resumed) {
      gameState.applyOfflineModeAOnResume();
      return;
    }
  }
}
