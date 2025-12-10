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

  Timer? _productionTimer;
  DateTime? _lastProductionTime;

  GameSessionController(this.gameState);

  /// Démarre la session de jeu (timers, etc.).
  /// Implémentation détaillée à venir dans des PR ultérieures.
  void startSession() {
    // Pour l'instant, on démarre uniquement le timer de production
    // de manière expérimentale.
    startProductionTimer();
  }

  /// Démarre le timer de production qui appelle périodiquement
  /// la logique de production automatique.
  void startProductionTimer() {
    _productionTimer?.cancel();

    _lastProductionTime = DateTime.now();
    _productionTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => _handleProductionTick(),
    );

    if (kDebugMode) {
      print('GameSessionController: Timer de production démarré');
    }
  }

  /// Tick de production : reproduit la logique actuelle de
  /// GameState.processProduction, mais pilotée par le contrôleur.
  void _handleProductionTick() {
    if (!gameState.isInitialized || gameState.isPaused) return;

    try {
      final now = DateTime.now();
      final elapsed = _lastProductionTime != null
          ? now.difference(_lastProductionTime!).inMilliseconds / 1000
          : 1.0;
      _lastProductionTime = now;

      if (kDebugMode) {
        print(
          'GameSessionController: cycle de production (elapsed: '
          '${elapsed.toStringAsFixed(2)}s)',
        );
      }

      final paperclipsBefore = gameState.playerManager.paperclips;
      final metalBefore = gameState.playerManager.metal;

      gameState.productionManager.processProduction();

      final paperclipsAfter = gameState.playerManager.paperclips;
      final metalAfter = gameState.playerManager.metal;
      final paperclipsProduced = paperclipsAfter - paperclipsBefore;
      final metalUsed = metalBefore - metalAfter;

      if (paperclipsProduced > 0 && kDebugMode) {
        print(
          'GameSessionController: Production: '
          '+${paperclipsProduced.toStringAsFixed(1)} trombones, '
          '-${metalUsed.toStringAsFixed(1)} métal',
        );
      }

      // Notifier les écouteurs de GameState pour mettre à jour l'UI.
      gameState.notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('GameSessionController: Erreur lors du tick de production: $e');
      }
    }
  }

  /// Méthode exposée pour les tests afin de simuler un tick
  /// de production sans dépendre d'un Timer réel.
  @visibleForTesting
  void runProductionTickForTest() => _handleProductionTick();

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
    _productionTimer?.cancel();
    _productionTimer = null;
  }

  @override
  void dispose() {
    stopSession();
    super.dispose();
  }
}
