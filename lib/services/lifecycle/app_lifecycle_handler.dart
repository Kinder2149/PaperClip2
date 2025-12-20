import 'package:flutter/widgets.dart';

import 'package:paperclip2/models/game_state.dart';

typedef AppLifecycleNowProvider = DateTime Function();
typedef AppLifecycleSavePort = Future<void> Function({required String reason});
typedef AppLifecycleResumePort = void Function();

class AppLifecycleHandler with WidgetsBindingObserver {
  GameState? _gameState;
  AppLifecycleSavePort _onLifecycleSave;
  AppLifecycleResumePort _onLifecycleResume;
  final AppLifecycleNowProvider _now;

  AppLifecycleHandler({
    AppLifecycleSavePort? onLifecycleSave,
    AppLifecycleNowProvider? now,
    AppLifecycleResumePort? onLifecycleResume,
  })  : _onLifecycleSave = onLifecycleSave ?? (({required String reason}) async {}),
        _now = now ?? DateTime.now,
        _onLifecycleResume = onLifecycleResume ?? (() {});

  void setOnLifecycleResume(AppLifecycleResumePort cb) {
    _onLifecycleResume = cb;
  }

  void setOnLifecycleSave(AppLifecycleSavePort cb) {
    // Permet au Coordinator de gérer la persistance et les métadonnées runtime
    // sans coupler cette classe au domaine.
    _onLifecycleSave = cb;
  }

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
      _onLifecycleSave(reason: 'app_lifecycle_${state.name}');
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _onLifecycleResume();
      return;
    }
  }
}
