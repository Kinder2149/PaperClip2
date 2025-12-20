import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/services/metrics/runtime_metrics.dart';
import 'package:paperclip2/services/metrics/runtime_watchdog.dart';
import 'package:paperclip2/services/runtime/clock.dart';

/// Contrôleur de session de jeu.
///
/// Cette classe a vocation à piloter les timers, la boucle
/// de jeu et les transitions (pause, reprise, arrêt), afin de
/// décharger progressivement `GameState` de ces responsabilités.
class GameSessionController with ChangeNotifier {
  final GameState gameState;
  final Clock _clock;

  Timer? _gameLoopTimer;
  DateTime? _lastTickTime;

  bool _isRunning = false;

  bool get isRunning => _isRunning;

  GameSessionController(this.gameState, {Clock? clock}) : _clock = clock ?? SystemClock();

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

    _lastTickTime = _clock.now();
    _gameLoopTimer = Timer.periodic(
      GameConstants.PRODUCTION_INTERVAL,
      (_) => _handleGameTick(),
    );

    if (kDebugMode) {
      print('GameSessionController: Boucle de jeu démarrée');
    }
  }

  void _handleGameTick() {
    if (!gameState.isInitialized || gameState.isPaused) return;

    try {
      final now = _clock.now();
      final expectedIntervalMs = GameConstants.PRODUCTION_INTERVAL.inMilliseconds;
      final actualIntervalMs = _lastTickTime != null
          ? now.difference(_lastTickTime!).inMilliseconds
          : expectedIntervalMs;
      final elapsedSeconds = actualIntervalMs / 1000;
      _lastTickTime = now;

      final sw = Stopwatch()..start();
      gameState.tick(elapsedSeconds: elapsedSeconds);
      sw.stop();

      final driftMs = actualIntervalMs - expectedIntervalMs;
      RuntimeMetrics.recordTick(
        driftMs: driftMs,
        durationMs: sw.elapsedMilliseconds,
      );
      RuntimeWatchdog.evaluateTick(driftMs: driftMs);
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
    // Annule la boucle de jeu et met en pause le domaine.
    _gameLoopTimer?.cancel();
    _gameLoopTimer = null;
    gameState.pause();
  }

  /// Reprend une session en pause.
  void resumeSession() {
    // Redémarre la boucle et remet le domaine en exécution.
    if (!_isRunning) {
      _isRunning = true;
    }
    gameState.resume();
    startGameLoop();
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
