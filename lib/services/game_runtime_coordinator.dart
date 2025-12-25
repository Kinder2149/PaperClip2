import 'dart:async' show unawaited;
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/game_state.dart';
import '../constants/game_config.dart';
import 'auto_save_service.dart';
import '../controllers/game_session_controller.dart';
import 'lifecycle/app_lifecycle_handler.dart';
import '../gameplay/events/bus/game_event_bus.dart';
import '../gameplay/events/game_event.dart';
import 'persistence/game_persistence_orchestrator.dart';
import 'metrics/runtime_metrics.dart';
import 'metrics/runtime_watchdog.dart';
import 'runtime/runtime_meta.dart';
import 'audio/game_audio_port.dart';
import 'runtime/clock.dart';
import 'runtime/runtime_orchestrator.dart';
import 'offline_progress_service.dart';

class GameRuntimeCoordinator implements RuntimeOrchestrator {
  final GameState _gameState;
  final AppLifecycleHandler _lifecycleHandler;
  final AutoSaveService _autoSaveService;
  final GameSessionController _gameSessionController;
  final Clock _clock;
  bool _isRecoveringOffline = false;
  GameEventListener? _eventListener;
  GameAudioPort? _audioPort;

  GameRuntimeCoordinator({
    required GameState gameState,
    required AppLifecycleHandler lifecycleHandler,
    required AutoSaveService autoSaveService,
    required GameSessionController gameSessionController,
    Clock? clock,
  })  : _gameState = gameState,
        _lifecycleHandler = lifecycleHandler,
        _autoSaveService = autoSaveService,
        _gameSessionController = gameSessionController,
        _clock = clock ?? SystemClock();

  Future<void> register() async {
    _lifecycleHandler.setOnLifecycleResume(_onAppResumed);
    _lifecycleHandler.setOnLifecycleSave(({required String reason}) async {
      // Met la session en pause pour garantir aucune progression pendant la sauvegarde
      _gameSessionController.pauseSession();
      // Met à jour le runtime meta et déclenche une sauvegarde de cycle de vie
      final now = _clock.now();
      RuntimeMetaRegistry.instance.setLastActiveAt(now);
      // Propage aussi vers GameState pour que toSnapshot() reflète les métadonnées
      _gameState.markLastActiveAt(now);
      await GamePersistenceOrchestrator.instance.requestLifecycleSave(
        _gameState,
        reason: reason,
      );
    });
    _lifecycleHandler.register(_gameState);
    _attachEventListeners();
  }

  void unregister() {
    _lifecycleHandler.unregister();
    _detachEventListeners();
  }

  void startSession() {
    _gameSessionController.startSession();
  }

  void stopSession() {
    _gameSessionController.stopSession();
  }

  @override
  void start() {
    startSession();
    unawaited(startAutoSave());
  }

  @override
  void stop() {
    unawaited(stopAutoSave());
    stopSession();
  }

  @override
  void pause() {
    // Log simple pour observabilité
    // ignore: avoid_print
    print('[Runtime] pause() called');
    RuntimeMetrics.recordPause();
    _gameSessionController.pauseSession();
  }

  @override
  void resume() {
    // ignore: avoid_print
    print('[Runtime] resume() called');
    RuntimeMetrics.recordResume();
    _gameSessionController.resumeSession();
  }

  @override
  Future<void> recoverOffline() async {
    if (_isRecoveringOffline) {
      // ignore: avoid_print
      print('[Runtime] recoverOffline() skipped (already running)');
      return;
    }
    _isRecoveringOffline = true;
    try {
      final start = _clock.now();
      final result = _applyOfflineProgress(now: start);
      final end = _clock.now();
      // ignore: avoid_print
      print('[Runtime] recoverOffline() completed in ${end.difference(start).inMilliseconds} ms');
      RuntimeMetrics.recordRecoverOffline(
        durationMs: end.difference(start).inMilliseconds,
        didSimulate: result.didSimulate,
      );
    } finally {
      _isRecoveringOffline = false;
    }
  }

  Future<void> startAutoSave() async {
    await _autoSaveService.start();
  }

  Future<void> stopAutoSave() async {
    _autoSaveService.stop();
  }

  // Legacy supprimé: loadGameAndStartAutoSave(name) retiré (ID-first uniquement)

  Future<void> loadGameByIdAndStartAutoSave(String id) async {
    _autoSaveService.stop();
    await GamePersistenceOrchestrator.instance.loadGameById(_gameState, id);
    await _autoSaveService.start();
    final audio = _audioPort;
    if (audio != null) {
      // Charger l'état audio associé à la partie (utiliser le nom résolu après chargement)
      final name = _gameState.gameName ?? '';
      if (name.isNotEmpty) {
        unawaited(audio.loadGameMusicState(name));
      }
    }
  }

  Future<void> startNewGameAndStartAutoSave(
    String name, {
    GameMode mode = GameMode.INFINITE,
  }) async {
    _autoSaveService.stop();
    await _gameState.startNewGame(name, mode: mode);
    // Invariant identité: une partie doit posséder un partieId unique dès sa création
    final newPartieId = _gameState.partieId;
    if (newPartieId == null || newPartieId.isEmpty) {
      // Verrouillage strict: interdire toute suite (autosave/sync) sans identité
      throw StateError('[IdentityInvariant] partieId manquant après startNewGame("'+name+'"): création invalide');
    }
    await _autoSaveService.start();
    final audio = _audioPort;
    if (audio != null) {
      unawaited(audio.loadGameMusicState(name));
    }

    // Mission 4: Cloud obligatoire si connecté (sous drapeau)
    try {
      final enableCloud = (dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true';
      final partieId = _gameState.partieId;
      if (enableCloud && partieId != null && partieId.isNotEmpty) {
        // Forcer une première sauvegarde par ID pour garantir un snapshot à pousser
        try {
          await GamePersistenceOrchestrator.instance.saveGameById(_gameState);
        } catch (_) {}
        // Push best-effort, non bloquant pour l'UI (sans playerId ici)
        unawaited(
          GamePersistenceOrchestrator.instance
              .pushCloudFromSaveId(partieId: partieId)
              .catchError((_) {}),
        );
      }
    } catch (_) {
      // Best-effort: ne pas perturber le flux de création si le cloud n'est pas prêt
    }
  }

  // Legacy supprimé: manualSave(name) retiré (ID-first uniquement)

  void _attachEventListeners() {
    _eventListener ??= (event) => _onGameEvent(event);
    _gameState.addEventListener(_eventListener!);
  }

  void _detachEventListeners() {
    final listener = _eventListener;
    if (listener != null) {
      _gameState.removeEventListener(listener);
    }
  }

  // Injection tardive du port audio depuis le bootstrap
  void setAudioPort(GameAudioPort port) {
    _audioPort = port;
  }

  void _onGameEvent(GameEvent event) {
    switch (event.type) {
      case GameEventType.autoclipperPurchased:
        // Post-frame + coalescing: déclenche une autosave légère pour éviter un freeze UI au clic
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(
            GamePersistenceOrchestrator.instance.requestAutoSave(
              _gameState,
              reason: 'autoclipper_purchased',
            ),
          );
        });
        return;
      case GameEventType.importantEventOccurred:
        final reason = event.data['reason'] as String?;
        if (reason == 'offline_progress_request') {
          final nowOverrideIso = event.data['nowOverride'] as String?;
          final now = nowOverrideIso != null ? DateTime.tryParse(nowOverrideIso) ?? _clock.now() : _clock.now();
          _applyOfflineProgress(now: now);
        } else {
          // Déclenche l'autosave via l'orchestrateur (fire-and-forget) + métriques
          final sw = Stopwatch()..start();
          RuntimeMetrics.recordAutosaveTriggered();
          unawaited(
            GamePersistenceOrchestrator.instance.saveOnImportantEvent(_gameState).then((_) {
              sw.stop();
              final dur = sw.elapsedMilliseconds;
              RuntimeMetrics.recordAutosaveCompleted(durationMs: dur, success: true);
              RuntimeWatchdog.evaluateAutosave(durationMs: dur, success: true);
            }).catchError((_) {
              sw.stop();
              final dur = sw.elapsedMilliseconds;
              RuntimeMetrics.recordAutosaveCompleted(durationMs: dur, success: false);
              RuntimeWatchdog.evaluateAutosave(durationMs: dur, success: false);
            }),
          );
        }
        return;
      default:
        return;
    }
  }

  void _onAppResumed() {
    // Applique d'abord l'offline, puis reprend la session
    unawaited(recoverOffline());
    try {
      final enableCloud = (dotenv.env['FEATURE_CLOUD_PER_PARTIE'] ?? 'false').toLowerCase() == 'true';
      final pid = _gameState.partieId;
      if (enableCloud && pid != null && pid.isNotEmpty) {
        unawaited(
          GamePersistenceOrchestrator.instance.checkCloudAndPullIfNeeded(
            state: _gameState,
            partieId: pid,
          ),
        );
        // Tentative de sync montante si une sauvegarde locale a eu lieu en mode avion
        unawaited(
          GamePersistenceOrchestrator.instance.pushCloudById(
            partieId: pid,
            state: _gameState,
          ),
        );
      }
    } catch (_) {}
    _gameSessionController.resumeSession();
  }

  OfflineProgressResult _applyOfflineProgress({required DateTime now}) {
    // Lire les métadonnées actuelles depuis le registre runtime (hors GameState)
    final meta = RuntimeMetaRegistry.instance;
    final lastActiveAt = meta.lastActiveAt;
    final lastOfflineAppliedAt = meta.lastOfflineAppliedAt;

    // Délègue le calcul/simulation à OfflineProgressService via GameState
    final result = _gameState.applyOfflineWithService(
      now: now,
      lastActiveAt: lastActiveAt,
      lastOfflineAppliedAt: lastOfflineAppliedAt,
    );

    // Met à jour les métadonnées runtime et domaine à partir du résultat
    meta.setLastActiveAt(result.lastActiveAt);
    meta.setLastOfflineAppliedAt(result.lastOfflineAppliedAt);
    meta.setOfflineSpecVersion(result.offlineSpecVersion);
    _gameState.markLastActiveAt(result.lastActiveAt);
    _gameState.markLastOfflineAppliedAt(result.lastOfflineAppliedAt);
    _gameState.markOfflineSpecVersion(result.offlineSpecVersion);

    // Best-effort: sauvegarde si une simulation a été effectuée
    if (result.didSimulate) {
      unawaited(
        GamePersistenceOrchestrator.instance.saveOnImportantEvent(_gameState),
      );
    }
    return result;
  }
}
