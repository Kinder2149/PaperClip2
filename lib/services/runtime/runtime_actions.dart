// lib/services/runtime/runtime_actions.dart

import 'package:flutter/foundation.dart';
import 'package:paperclip2/services/game_runtime_coordinator.dart';
import 'package:paperclip2/constants/game_config.dart' show GameMode;

/// Façade légère exposant uniquement des intentions runtime à l'UI.
/// - Ne divulgue pas le GameRuntimeCoordinator
/// - Pas d'état interne brut; expose seulement un état dérivé minimal
class RuntimeActions {
  final GameRuntimeCoordinator _runtime;
  final bool Function()? _isPausedReader;

  RuntimeActions({
    required GameRuntimeCoordinator runtimeCoordinator,
    bool Function()? isPausedReader,
  })  : _runtime = runtimeCoordinator,
        _isPausedReader = isPausedReader;

  // Intentions runtime
  void startSession() => _runtime.startSession();
  void stopSession() => _runtime.stopSession();
  void pause() => _runtime.pause();
  void resume() => _runtime.resume();
  Future<void> recoverOffline() => _runtime.recoverOffline();

  Future<void> loadGameByIdAndStartAutoSave(String partieId) =>
      _runtime.loadGameByIdAndStartAutoSave(partieId);

  // État dérivé minimal
  bool get isPaused => _isPausedReader != null ? _isPausedReader!.call() : false;

  // Intention: démarrer une nouvelle partie et lancer l'autosave
  Future<void> startNewGameAndStartAutoSave(String name, {GameMode mode = GameMode.INFINITE}) =>
      _runtime.startNewGameAndStartAutoSave(name, mode: mode);
}
