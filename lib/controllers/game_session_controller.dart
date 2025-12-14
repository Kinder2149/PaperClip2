import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:paperclip2/models/game_state.dart';

/// Contrôleur de session de jeu.
///
/// Cette classe a vocation à piloter les timers, la boucle
/// de jeu et les transitions (pause, reprise, arrêt), afin de
/// décharger progressivement `GameState` de ces responsabilités.
class GameSessionController with ChangeNotifier {
  final GameState gameState;

  Timer? _gameLoopTimer;
  DateTime? _lastTickTime;

  bool _isRunning = false;

  bool get isRunning => _isRunning;

  GameSessionController(this.gameState);

  /// Démarre la session de jeu (timers, etc.).
  /// Implémentation détaillée à venir dans des PR ultérieures.
  void startSession() {
    if (_isRunning) {
      return;
    }
    _isRunning = true;
    startGameLoop();
    // Maintenance (Q1): aucune boucle de maintenance n'est pilotée ici pour le moment.
  }

  void startGameLoop() {
    _gameLoopTimer?.cancel();

    _lastTickTime = DateTime.now();
    _gameLoopTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _handleGameTick(),
    );

    if (kDebugMode) {
      print('GameSessionController: Boucle de jeu démarrée');
    }
  }

  void _handleGameTick() {
    if (!gameState.isInitialized || gameState.isPaused) return;

    try {
      final now = DateTime.now();
      final elapsedSeconds = _lastTickTime != null
          ? now.difference(_lastTickTime!).inMilliseconds / 1000
          : 1.0;
      _lastTickTime = now;

      if (kDebugMode) {
        print(
          'GameSessionController: tick unifié (elapsed: '
          '${elapsedSeconds.toStringAsFixed(2)}s)',
        );
      }

      gameState.tick(elapsedSeconds: elapsedSeconds);
    } catch (e) {
      if (kDebugMode) {
        print('GameSessionController: Erreur lors du tick unifié: $e');
      }
    }
  }

  /// Méthode exposée pour les tests afin de simuler un tick
  /// de jeu sans dépendre d'un Timer réel.
  @visibleForTesting
  void runProductionTickForTest() => _handleGameTick();

  /// Met en pause la session de jeu.
  void pauseSession() {
    // Squelette pour une PR ultérieure.
  }

  /// Reprend une session en pause.
  void resumeSession() {
    // Squelette pour une PR ultérieure.
  }

  /// Arrête proprement la session (timers, ressources).
  void stopSession() {
    _gameLoopTimer?.cancel();
    _gameLoopTimer = null;
    _isRunning = false;
  }

  @override
  void dispose() {
    stopSession();
    super.dispose();
  }
}
