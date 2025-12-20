import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../env_config.dart';
import '../models/game_state.dart';
import '../services/background_music.dart';
import '../services/game_runtime_coordinator.dart';
import '../services/lifecycle/app_lifecycle_handler.dart';
import '../services/persistence/game_persistence_orchestrator.dart';
import '../services/theme_service.dart';
import '../services/ui/game_ui_port.dart';
import '../services/audio/game_audio_port.dart';

enum AppBootstrapStatus {
  idle,
  bootstrapping,
  ready,
  error,
}

class AppBootstrapController extends ChangeNotifier {
  final GameState _gameState;
  final GameUiPort _uiPort;
  final GameAudioPort _audioPort;
  final BackgroundMusicService _backgroundMusicService;
  final ThemeService _themeService;
  final AppLifecycleHandler _lifecycleHandler;
  final GameRuntimeCoordinator? _runtimeCoordinator;
  

  final Future<void> Function()? _envConfigLoad;
  final Future<void> Function()? _persistenceBackupCheck;
  final Future<void> Function()? _wireUiAudioPorts;
  final Future<void> Function()? _registerLifecycle;
  final Future<void> Function()? _themeInit;
  final Future<void> Function()? _backgroundMusicInit;
  final Future<void> Function()? _backgroundMusicPreferences;

  AppBootstrapStatus _status = AppBootstrapStatus.idle;
  String? _currentStep;
  Object? _lastError;
  StackTrace? _lastStack;

  DateTime? _bootStartedAt;
  Duration? _lastBootDuration;
  final Map<String, int> _lastStepDurationsMs = <String, int>{};

  Completer<void>? _readyCompleter;

  AppBootstrapController({
    required GameState gameState,
    required GameUiPort uiPort,
    required GameAudioPort audioPort,
    required BackgroundMusicService backgroundMusicService,
    required ThemeService themeService,
    required AppLifecycleHandler lifecycleHandler,
    GameRuntimeCoordinator? runtimeCoordinator,
    Future<void> Function()? envConfigLoad,
    Future<void> Function()? persistenceBackupCheck,
    Future<void> Function()? wireUiAudioPorts,
    Future<void> Function()? registerLifecycle,
    Future<void> Function()? themeInit,
    Future<void> Function()? backgroundMusicInit,
    Future<void> Function()? backgroundMusicPreferences,
  })  : _gameState = gameState,
        _uiPort = uiPort,
        _audioPort = audioPort,
        _backgroundMusicService = backgroundMusicService,
        _themeService = themeService,
        _lifecycleHandler = lifecycleHandler,
        _runtimeCoordinator = runtimeCoordinator,
        _envConfigLoad = envConfigLoad,
        _persistenceBackupCheck = persistenceBackupCheck,
        _wireUiAudioPorts = wireUiAudioPorts,
        _registerLifecycle = registerLifecycle,
        _themeInit = themeInit,
        _backgroundMusicInit = backgroundMusicInit,
        _backgroundMusicPreferences = backgroundMusicPreferences {
    _readyCompleter = Completer<void>();
  }

  AppBootstrapStatus get status => _status;
  String? get currentStep => _currentStep;
  Object? get lastError => _lastError;
  StackTrace? get lastStackTrace => _lastStack;

  DateTime? get bootStartedAt => _bootStartedAt;
  Duration? get lastBootDuration => _lastBootDuration;
  Map<String, int> get lastStepDurationsMs => Map<String, int>.unmodifiable(_lastStepDurationsMs);

  bool get isReady => _status == AppBootstrapStatus.ready;
  bool get hasError => _status == AppBootstrapStatus.error;

  Future<void> waitUntilReady() {
    if (isReady) return Future.value();
    return (_readyCompleter ??= Completer<void>()).future;
  }

  Future<void> bootstrap() async {
    if (_status == AppBootstrapStatus.bootstrapping || _status == AppBootstrapStatus.ready) {
      return;
    }

    _status = AppBootstrapStatus.bootstrapping;
    _currentStep = 'bootstrap_start';
    _lastError = null;
    _lastStack = null;
    _bootStartedAt = DateTime.now();
    _lastBootDuration = null;
    _lastStepDurationsMs.clear();

    if (kDebugMode) {
      print('[AppBootstrap] start');
    }
    notifyListeners();

    try {
      await _step('env_config', () async {
        final fn = _envConfigLoad;
        if (fn != null) {
          await fn();
          return;
        }

        try {
          await EnvConfig.load();
        } catch (e) {
          if (kDebugMode) {
            print('Warning: could not load all environment variables: $e');
          }
        }
      });

      await _step('persistence_backup_check', () async {
        final fn = _persistenceBackupCheck;
        if (fn != null) {
          await fn();
          return;
        }

        await GamePersistenceOrchestrator.instance.checkAndRestoreLastSaveFromBackupIfNeeded();
      });

      await _step('wire_ui_audio_ports', () async {
        final fn = _wireUiAudioPorts;
        if (fn != null) {
          await fn();
          return;
        }

        // Branche le port audio au RuntimeCoordinator pour déporter l'audio hors du domaine
        final coordinator = _runtimeCoordinator;
        if (coordinator != null) {
          coordinator.setAudioPort(_audioPort);
        }
      });

      await _step('game_state_healthcheck', () async {
        if (!_gameState.isInitialized) {
          final err = _gameState.initializationError;
          throw StateError(
            'GameState non initialisé${err != null ? ": $err" : ""}',
          );
        }

        final err = _gameState.initializationError;
        if (err != null) {
          throw StateError('GameState initialisé avec erreur: $err');
        }
      });

      await _step('register_lifecycle', () async {
        final fn = _registerLifecycle;
        if (fn != null) {
          await fn();
          return;
        }

        final coordinator = _runtimeCoordinator;
        if (coordinator != null) {
          await coordinator.register();
          return;
        }

        _lifecycleHandler.register(_gameState);
      });

      await _step('theme_init', () async {
        final fn = _themeInit;
        if (fn != null) {
          await fn();
          return;
        }

        await _themeService.initialize();
      });

      await _step('background_music_init', () async {
        final fn = _backgroundMusicInit;
        if (fn != null) {
          await fn();
          return;
        }

        await _backgroundMusicService.initialize();
      });

      await _step('background_music_preferences', () async {
        final fn = _backgroundMusicPreferences;
        if (fn != null) {
          await fn();
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        final isMusicEnabled = prefs.getBool('global_music_enabled');
        if (isMusicEnabled == null) {
          // Sur le web, l'autoplay est bloqué sans geste utilisateur.
          // On évite de tenter un play() qui peut rester bloqué.
          if (kIsWeb) {
            await _backgroundMusicService.setPlayingState(false);
            // L'utilisateur pourra activer la musique via l'UI (MusicControlAction)
            // Optionnel: persister la préférence par défaut
            await prefs.setBool('global_music_enabled', false);
          } else {
            // Fire-and-forget: on déclenche la lecture sans bloquer le bootstrap
            unawaited(_backgroundMusicService.play());
            await prefs.setBool('global_music_enabled', true);
          }
          return;
        }
        // Fire-and-forget: on applique la préférence sans bloquer
        unawaited(_backgroundMusicService.setPlayingState(isMusicEnabled));
      });

      _status = AppBootstrapStatus.ready;
      _currentStep = 'ready';
      final startedAt = _bootStartedAt;
      if (startedAt != null) {
        _lastBootDuration = DateTime.now().difference(startedAt);
      }

      if (kDebugMode) {
        final totalMs = _lastBootDuration?.inMilliseconds;
        print('[AppBootstrap] ready (totalMs=$totalMs)');
        if (_lastStepDurationsMs.isNotEmpty) {
          print('[AppBootstrap] stepDurationsMs=$_lastStepDurationsMs');
        }
      }
      notifyListeners();

      if (!(_readyCompleter?.isCompleted ?? true)) {
        _readyCompleter!.complete();
      }
    } catch (e, st) {
      _status = AppBootstrapStatus.error;
      _lastError = e;
      _lastStack = st;

      final startedAt = _bootStartedAt;
      if (startedAt != null) {
        _lastBootDuration = DateTime.now().difference(startedAt);
      }

      if (kDebugMode) {
        final totalMs = _lastBootDuration?.inMilliseconds;
        print('[AppBootstrap] error at step=$_currentStep (totalMs=$totalMs): $e');
      }
      notifyListeners();

      if (!(_readyCompleter?.isCompleted ?? true)) {
        _readyCompleter!.completeError(e, st);
      }

      if (kDebugMode) {
        print('App bootstrap failed at step=$_currentStep: $e');
      }
    }
  }

  Future<void> retry() async {
    _status = AppBootstrapStatus.idle;
    _currentStep = null;
    _lastError = null;
    _lastStack = null;
    _readyCompleter = Completer<void>();
    notifyListeners();
    await bootstrap();
  }

  Future<void> _step(String stepName, Future<void> Function() fn) async {
    _currentStep = stepName;
    notifyListeners();
    final sw = Stopwatch()..start();
    if (kDebugMode) {
      print('[AppBootstrap] step_start $stepName');
    }
    await fn();
    sw.stop();
    _lastStepDurationsMs[stepName] = sw.elapsedMilliseconds;
    if (kDebugMode) {
      print('[AppBootstrap] step_done $stepName (${sw.elapsedMilliseconds}ms)');
    }
  }
}
