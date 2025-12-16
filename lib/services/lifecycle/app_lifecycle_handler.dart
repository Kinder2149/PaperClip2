import 'package:flutter/widgets.dart';

import 'package:paperclip2/models/game_state.dart';

typedef AppLifecycleNowProvider = DateTime Function();
typedef AppLifecycleSavePort = Future<void> Function({required String reason});

class AppLifecycleHandler with WidgetsBindingObserver {
  GameState? _gameState;
  final AppLifecycleSavePort _onLifecycleSave;
  final AppLifecycleNowProvider _now;

  AppLifecycleHandler({
    AppLifecycleSavePort? onLifecycleSave,
    AppLifecycleNowProvider? now,
  })  : _onLifecycleSave = onLifecycleSave ?? (({required String reason}) async {}),
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
      _onLifecycleSave(reason: 'app_lifecycle_${state.name}');
      return;
    }

    if (state == AppLifecycleState.resumed) {
      gameState.applyOfflineProgressV2();
      return;
    }
  }
}
