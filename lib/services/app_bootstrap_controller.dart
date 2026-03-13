import 'dart:async';

import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperclip2/services/cloud/cloud_port_manager.dart';
import 'package:paperclip2/services/notification_manager.dart';

import '../env_config.dart';
import '../models/game_state.dart';
import '../services/background_music.dart';
import '../services/game_runtime_coordinator.dart';
import '../services/lifecycle/app_lifecycle_handler.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/persistence/sync_result.dart';
import 'package:paperclip2/services/notification_manager.dart';
import '../services/save_system/local_save_game_manager.dart';
import '../services/theme_service.dart';
import '../services/ui/game_ui_port.dart';
import '../services/audio/game_audio_port.dart';
import '../services/auth/firebase_auth_service.dart';

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
  
  // CORRECTION CRITIQUE: Variables pour le listener Firebase Auth
  String? _lastSyncedUid;
  Timer? _syncDebounceTimer;
  StreamSubscription<dynamic>? _authSubscription;
  
  // P0-5: Flag pour éviter double installation listener
  bool _firebaseListenerInstalled = false;

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
    print('🔥🔥🔥 [BOOTSTRAP] bootstrap() method CALLED 🔥🔥🔥');
    
    if (_status == AppBootstrapStatus.bootstrapping || _status == AppBootstrapStatus.ready) {
      print('🔥🔥🔥 [BOOTSTRAP] Already bootstrapping or ready, returning 🔥🔥🔥');
      return;
    }

    print('🔥🔥🔥 [BOOTSTRAP] Starting bootstrap process 🔥🔥🔥');
    
    // P0-5: INSTALLER LISTENER FIREBASE EN TOUT PREMIER
    // Ceci garantit que la sync cloud démarre AVANT l'affichage de WorldsScreen
    print('🔥🔥🔥 [BOOTSTRAP] Installing Firebase listener BEFORE bootstrap 🔥🔥🔥');
    await _installFirebaseAuthListener();
    
    _status = AppBootstrapStatus.bootstrapping;
    _currentStep = 'bootstrap_start';
    _lastError = null;
    _lastStack = null;
    _bootStartedAt = DateTime.now();
    _lastBootDuration = null;
    _lastStepDurationsMs.clear();

    if (kDebugMode) {
      appLogger.debug('[STATE] [AppBootstrap] start');
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
            appLogger.warn('[STATE] Warning: could not load all environment variables: $e');
          }
        }
      });

      await _step('persistence_backup_check', () async {
        final fn = _persistenceBackupCheck;
        if (fn != null) {
          await fn();
          return;
        }

        // Garantir l'initialisation du gestionnaire de sauvegarde local
        try {
          await LocalSaveGameManager.getInstance();
        } catch (_) {}

        await GamePersistenceOrchestrator.instance.checkAndRestoreLastSaveFromBackupIfNeeded();
      });

      // CORRECTION CRITIQUE: Sync cloud RETIRÉE du bootstrap
      // Raison: Le bootstrap s'exécute trop tôt, avant que Firebase soit complètement prêt
      // La synchronisation cloud est maintenant gérée UNIQUEMENT par le listener Firebase
      // dans main.dart, qui garantit que l'utilisateur est authentifié avant de sync.
      // 
      // Note: Cette étape est conservée pour vérifier que Firebase est initialisé,
      // mais ne déclenche PLUS de synchronisation automatique.
      await _step('firebase_auth_check', () async {
        try {
          // Vérification silencieuse que Firebase est initialisé
          final isUserReady = await FirebaseAuthService.instance.ensureUserReady();
          
          if (kDebugMode) {
            appLogger.debug('[BOOTSTRAP] Firebase auth check: ${isUserReady ? "ready" : "not ready"}');
          }
        } catch (e) {
          if (kDebugMode) {
            appLogger.warn('[BOOTSTRAP] Firebase auth check error (non bloquant): $e');
          }
        }
      });

      // P0-5: Étape install_firebase_listener RETIRÉE
      // Le listener est maintenant installé AVANT le début du bootstrap (ligne 121-123)

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
        appLogger.debug('[STATE] [AppBootstrap] ready (totalMs='+ (totalMs?.toString() ?? 'null') +')');
        if (_lastStepDurationsMs.isNotEmpty) {
          appLogger.debug('[STATE] [AppBootstrap] stepDurationsMs='+_lastStepDurationsMs.toString());
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
        appLogger.warn('[STATE] [AppBootstrap] error at step='+(_currentStep ?? '-')+' (totalMs='+ (totalMs?.toString() ?? 'null') +'): '+e.toString());
      }
      notifyListeners();

      if (!(_readyCompleter?.isCompleted ?? true)) {
        _readyCompleter!.completeError(e, st);
      }

      if (kDebugMode) {
        appLogger.warn('[STATE] App bootstrap failed at step='+(_currentStep ?? '-')+': '+e.toString());
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
      appLogger.debug('[STATE] [AppBootstrap] step_start '+stepName);
    }
    await fn();
    sw.stop();
    _lastStepDurationsMs[stepName] = sw.elapsedMilliseconds;
    if (kDebugMode) {
      appLogger.debug('[STATE] [AppBootstrap] step_done '+stepName+' ('+sw.elapsedMilliseconds.toString()+'ms)');
    }
  }

  /// CORRECTION CRITIQUE: Installation du listener Firebase Auth pendant le bootstrap
  /// Cette méthode garantit que la sync cloud démarre AVANT l'affichage de l'UI
  /// 
  /// CORRECTION DÉFINITIVE (18/01/2026):
  /// - Sync IMMÉDIATE au bootstrap (sans debounce) pour utilisateur déjà connecté
  /// - Logs INCONDITIONNELS pour diagnostic
  /// - Gestion d'erreurs EXPLICITE (pas d'exceptions avalées)
  /// - Suppression du filtre .distinct() qui bloquait l'émission
  Future<void> _installFirebaseAuthListener() async {
    // P0-5: Vérifier si déjà installé pour éviter double installation
    if (_firebaseListenerInstalled) {
      if (kDebugMode) {
        appLogger.debug('[BOOTSTRAP] Firebase listener already installed, skipping');
      }
      return;
    }
    
    // DIAGNOSTIC: print() direct pour vérifier l'exécution
    print('🔥🔥🔥 [BOOTSTRAP] _installFirebaseAuthListener() CALLED 🔥🔥🔥');
    
    // Log INCONDITIONNEL pour diagnostic
    appLogger.info('[BOOTSTRAP] Installing Firebase Auth listener', code: 'bootstrap_listener_install');
    
    try {
      // Vérifier l'état initial AVANT d'installer le listener
      final initialUser = FirebaseAuthService.instance.currentUser;
      
      if (initialUser != null) {
        print('🔥🔥🔥 [BOOTSTRAP] User detected: ${initialUser.uid} 🔥🔥🔥');
        
        appLogger.info('[BOOTSTRAP] User already connected, triggering IMMEDIATE sync | uid=${initialUser.uid}', 
          code: 'bootstrap_initial_user_detected');
        
        // CORRECTION CRITIQUE: Sync IMMÉDIATE sans debounce pour utilisateur existant
        // Raison: WorldsScreen s'affiche rapidement et l'utilisateur peut cliquer avant la fin du debounce
        await _syncUserImmediately(initialUser.uid, 'BOOTSTRAP-INITIAL');
      } else {
        print('🔥🔥🔥 [BOOTSTRAP] No user initially 🔥🔥🔥');
        appLogger.info('[BOOTSTRAP] No user connected initially', code: 'bootstrap_no_initial_user');
      }

      // Installer le listener pour les changements futurs (connexion/déconnexion)
      // CORRECTION: Suppression du filtre .distinct() qui empêchait l'émission
      _authSubscription = FirebaseAuthService.instance.authStateChanges()
        .listen((user) async {
          final uid = user?.uid;
          appLogger.info('[AUTH-LISTENER] Auth state changed | uid=${uid ?? "null"} lastSyncedUid=$_lastSyncedUid', 
            code: 'auth_state_changed');
          
          // Sync uniquement si nouvel utilisateur (éviter double sync au boot)
          if (uid != null && uid != _lastSyncedUid) {
            appLogger.info('[AUTH-LISTENER] New user detected, triggering sync | uid=$uid', 
              code: 'auth_new_user');
            await _syncUserImmediately(uid, 'AUTH-LISTENER');
          } else if (uid == null && _lastSyncedUid != null) {
            appLogger.info('[AUTH-LISTENER] User disconnected | previousUid=$_lastSyncedUid', 
              code: 'auth_user_disconnected');
            _lastSyncedUid = null;
          } else {
            appLogger.info('[AUTH-LISTENER] Skipping sync | reason=${uid == null ? "no user" : "already synced"}', 
              code: 'auth_sync_skip');
          }
        });

      // P0-5: Marquer comme installé
      _firebaseListenerInstalled = true;
      
      appLogger.info('[BOOTSTRAP] Firebase Auth listener installed successfully', 
        code: 'bootstrap_listener_installed');
    } catch (e, stack) {
      // CORRECTION: Log INCONDITIONNEL + rethrow pour ne pas avaler l'exception
      appLogger.error('[BOOTSTRAP] CRITICAL: Error installing Firebase listener', 
        code: 'bootstrap_listener_error',
        ctx: {'error': e.toString(), 'stack': stack.toString()});
      
      // Ne PAS avaler l'exception - la propager pour diagnostic
      rethrow;
    }
  }

  /// CORRECTION DÉFINITIVE: Synchronisation immédiate d'un utilisateur
  /// Cette méthode centralise la logique de sync et garantit des logs complets
  Future<void> _syncUserImmediately(String uid, String source) async {
    print('🔥🔥🔥 [$source] _syncUserImmediately() CALLED | uid=$uid 🔥🔥🔥');
    
    appLogger.info('[$source] Starting IMMEDIATE sync | uid=$uid', code: 'sync_start');
    
    try {
      // Marquer comme synchronisé AVANT de démarrer (éviter double sync)
      _lastSyncedUid = uid;
      
      // Activer cloud automatiquement
      final prefs = await SharedPreferences.getInstance();
      final cloudEnabled = prefs.getBool('cloud_enabled') ?? false;
      
      appLogger.info('[$source] Cloud preference | enabled=$cloudEnabled', code: 'sync_cloud_pref');
      
      if (!cloudEnabled) {
        appLogger.info('[$source] Auto-enabling cloud (Firebase user detected)', code: 'sync_auto_enable');
        await prefs.setBool('cloud_enabled', true);
      }
      
      // Activer CloudPort
      appLogger.info('[$source] Activating CloudPort...', code: 'sync_cloudport_start');
      
      final activationSuccess = await CloudPortManager.instance.activate(
        reason: '${source}_uid=$uid'
      );
      
      appLogger.info('[$source] CloudPort activation | success=$activationSuccess', 
        code: 'sync_cloudport_result');
      
      if (!activationSuccess) {
        // Retry une fois après délai
        appLogger.warn('[$source] CloudPort activation failed, retrying in 2s...', 
          code: 'sync_cloudport_retry');
        
        await Future.delayed(const Duration(seconds: 2));
        
        final retrySuccess = await CloudPortManager.instance.activate(
          reason: '${source}_retry_uid=$uid'
        );
        
        if (!retrySuccess) {
          appLogger.error('[$source] CloudPort activation FAILED after retry', 
            code: 'sync_cloudport_failed');
          
          NotificationManager.instance.showNotification(
            message: '⚠️ Erreur configuration cloud - Réessayez',
            level: NotificationLevel.ERROR,
            duration: const Duration(seconds: 5),
          );
          return;
        }
        
        appLogger.info('[$source] CloudPort activation succeeded on retry', 
          code: 'sync_cloudport_retry_success');
      }
      
      // Synchronisation cloud
      appLogger.info('[$source] Calling onPlayerConnected()...', code: 'sync_orchestrator_start');
      
      final syncResult = await GamePersistenceOrchestrator.instance.onPlayerConnected(playerId: uid);
      
      appLogger.info('[$source] onPlayerConnected() completed | success=${syncResult.isSuccess}', 
        code: 'sync_orchestrator_result');
      
      if (!syncResult.isSuccess) {
        appLogger.warn('[$source] Sync failed | message=${syncResult.userMessage}', 
          code: 'sync_failed');
        
        NotificationManager.instance.showNotification(
          message: syncResult.userMessage,
          level: NotificationLevel.WARNING,
          duration: const Duration(seconds: 5),
        );
      } else {
        appLogger.info('[$source] Sync completed successfully', code: 'sync_success');
      }
    } catch (e, stack) {
      // CORRECTION: Log INCONDITIONNEL + notification utilisateur
      appLogger.error('[$source] CRITICAL: Sync error', 
        code: 'sync_error',
        ctx: {'error': e.toString(), 'stack': stack.toString()});
      
      NotificationManager.instance.showNotification(
        message: '⚠️ Erreur synchronisation cloud - Vérifiez votre connexion',
        level: NotificationLevel.ERROR,
        duration: const Duration(seconds: 5),
      );
      
      // Ne PAS rethrow ici - la sync est optionnelle, l'app doit continuer
    }
  }

  @override
  void dispose() {
    _syncDebounceTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
