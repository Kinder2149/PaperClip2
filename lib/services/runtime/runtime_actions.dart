// lib/services/runtime/runtime_actions.dart

import 'package:flutter/foundation.dart';
import 'package:paperclip2/services/game_runtime_coordinator.dart';

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

  Future<void> loadGameByIdAndStartAutoSave(String enterpriseId) =>
      _runtime.loadGameByIdAndStartAutoSave(enterpriseId);

  // CHANTIER-01: Créer une nouvelle entreprise
  Future<void> createNewEnterpriseAndStartAutoSave(String enterpriseName) =>
      _runtime.createNewEnterpriseAndStartAutoSave(enterpriseName);

  // CHANTIER-01: Charger l'entreprise unique
  Future<void> loadEnterpriseAndStartAutoSave() =>
      _runtime.loadEnterpriseAndStartAutoSave();

  // État dérivé minimal
  bool get isPaused => _isPausedReader != null ? _isPausedReader!.call() : false;

  // Intention: démarrer une nouvelle partie et lancer l'autosave
  Future<void> startNewGameAndStartAutoSave(String name) =>
      _runtime.startNewGameAndStartAutoSave(name);
}
