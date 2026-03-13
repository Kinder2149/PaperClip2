import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import './screens/start_screen.dart';
import './screens/bootstrap_screen.dart';
// Imports des modèles et services
import './models/game_state.dart';
import './models/event_system.dart';
import './services/background_music.dart';
import './services/audio/flutter_game_audio_facade.dart';
import './services/theme_service.dart';
import './controllers/game_session_controller.dart';
import './services/ui/flutter_game_ui_facade.dart';
import './services/lifecycle/app_lifecycle_handler.dart';
import './services/navigation_service.dart';
import './services/notification_manager.dart';
import './services/app_bootstrap_controller.dart';
import './services/game_runtime_coordinator.dart';
import './services/game_actions.dart';
import './presentation/adapters/event_manager_domain_event_adapter.dart';
import './services/google/google_bootstrap.dart';
import './services/google/achievements/achievements_event_adapter.dart';
import './services/google/leaderboards/leaderboards_event_adapter.dart';
import './screens/auth_choice_screen.dart';
import 'services/persistence/game_persistence_orchestrator.dart';
import 'services/persistence/sync_result.dart';
// Cloud ports legacy retirés
import 'services/google/identity/google_identity_service.dart';
import 'services/google/identity/identity_status.dart';

// Adapters UI/Audio (hors domaine)
import './services/ui/game_ui_event_adapter.dart';
import './services/audio/audio_event_adapter.dart';
import './services/analytics/analytics_event_adapter.dart';
import './services/analytics/analytics_port.dart';
// HTTP analytics retiré (Firebase-only Callable): utiliser NoOp ou Callable ultérieurement
import 'services/runtime/runtime_actions.dart' as runtime_facade;
import 'package:paperclip2/services/cloud/cloud_persistence_adapter.dart';
import 'package:paperclip2/services/cloud/cloud_port_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Auth Firebase utilisée directement par le client HTTP (pas de JWT backend dédié)
import 'services/auth/firebase_auth_service.dart';
// HTTP analytics désactivé (NoOp)
import 'utils/logger.dart';

// Services globaux
final gameState = GameState();
final gameSessionController = GameSessionController(gameState);
final backgroundMusicService = BackgroundMusicService();
final themeService = ThemeService();
final eventManager = EventManager.instance;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final navigationService = NavigationService(navigatorKey);
final _gameUiFacade = FlutterGameUiFacade(navigationService);
final FlutterGameAudioFacade _gameAudioFacade = FlutterGameAudioFacade(backgroundMusicService);
final _appLifecycleHandler = AppLifecycleHandler(
  onLifecycleSave: ({required String reason}) =>
      gameState.autoSaveService.requestLifecycleSave(reason: reason),
);

final _runtimeCoordinator = GameRuntimeCoordinator(
  gameState: gameState,
  lifecycleHandler: _appLifecycleHandler,
  autoSaveService: gameState.autoSaveService,
  gameSessionController: gameSessionController,
);

// Facade runtime (UI intentions uniquement)

final _domainEventSink = EventManagerDomainEventAdapter(eventManager: eventManager);

// Adapters événementiels (frontière domaine -> présentation)
final _uiEventAdapter = GameUiEventAdapter.withListeners(
  addListener: gameState.addEventListener,
  removeListener: gameState.removeEventListener,
  ui: _gameUiFacade,
);

final _audioEventAdapter = AudioEventAdapter.withListeners(
  addListener: gameState.addEventListener,
  removeListener: gameState.removeEventListener,
  audioPort: _gameAudioFacade,
);

// Analytics wiring (adapter bus -> analytics port)
AnalyticsPort _buildAnalyticsPort() {
  // HTTP supprimé: par défaut NoOp (remplaçable par une version Callable ultérieurement)
  return const NoOpAnalyticsPort();
}

final _analyticsEventAdapter = AnalyticsEventAdapter.withListeners(
  addListener: gameState.addEventListener,
  removeListener: gameState.removeEventListener,
  port: _buildAnalyticsPort(),
);

// Google Services wiring (identité, succès, classements) + adapters événementiels
final _googleServices = createGoogleServices(enableOnAndroid: true);
final _achievementsEventAdapter = AchievementsEventAdapter.withListeners(
  addListener: gameState.addEventListener,
  removeListener: gameState.removeEventListener,
  service: _googleServices.achievements,
);
final _leaderboardsEventAdapter = LeaderboardsEventAdapter.withListeners(
  addListener: gameState.addEventListener,
  removeListener: gameState.removeEventListener,
  service: _googleServices.leaderboards,
);

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    await dotenv.load(fileName: '.env');
    
    // Log de démarrage propre
    appLogger.info('Application démarrée', code: 'app_start', ctx: {
      'version': '2.2.0',
      'environment': kReleaseMode ? 'production' : 'debug',
    });
    final _functionsApiBase = dotenv.env['FUNCTIONS_API_BASE'] ?? '';
    
    if (_functionsApiBase.isEmpty) {
      throw Exception('Configuration manquante: FUNCTIONS_API_BASE');
    }
    // Activer le filtre de logs mission par défaut en debug, sauf opt-out explicite
    try {
      bool enableMission = kDebugMode; // défaut: ON en debug
      final missionEnv = (dotenv.env['MISSION_LOG'] ?? '').toLowerCase();
      if (missionEnv == 'off' || missionEnv == 'false' || missionEnv == '0') {
        enableMission = false;
      } else if (missionEnv == 'on' || missionEnv == 'true' || missionEnv == '1') {
        enableMission = true;
      }
      if (enableMission) {
        Logger.enableMissionMode(true);
        // Filtrer au maximum les sorties Dart: ne laisser passer que les logs "mission"
        try {
          final original = debugPrint;
          debugPrint = (String? message, {int? wrapWidth}) {
            if (message == null) return;
            final m = message;
            final hasEmoji = m.startsWith('🆕') || m.startsWith('🔀') || m.startsWith('🧳') || m.startsWith('▶️') || m.startsWith('💾') || m.startsWith('☁️') || m.startsWith('🌐') || m.startsWith('📃') || m.startsWith('🚀') || m.startsWith('⚠️') || m.startsWith('❌') || m.startsWith('✅') || m.startsWith('🗄️') || m.startsWith('🧹') || m.startsWith('🩹') || m.startsWith('📤') || m.startsWith('📥') || m.startsWith('🔥') || m.startsWith('🔐');
            final hasTag = m.contains('[runtime]') || m.contains('[persist]') || m.contains('[cloud-http]');
            if (hasEmoji || hasTag) {
              original(message, wrapWidth: wrapWidth);
            }
          };
        } catch (_) {}
      }
    } catch (_) {}
    FlutterError.onError = (FlutterErrorDetails details) {
      appLogger.error(
        'Flutter error: ${details.exceptionAsString()}',
        code: 'flutter_error',
        ctx: {'stack': kReleaseMode ? '<hidden>' : (details.stack?.toString() ?? '')},
      );
    };
    if (kDebugMode) {
      appLogger.debug('Flutter binding initialized');
    }

    // Clean Architecture: injection des ports (domain -> presentation)
    gameState.levelSystem.setDomainEventSink(_domainEventSink);
    gameState.productionManager.setDomainEventSink(_domainEventSink);
    gameState.autoSaveService.setDomainEventSink(_domainEventSink);

    // Raccordement explicite au runtime maître (pause autoritaire)
    gameState.productionManager.setPauseBridges(
      reader: () => gameState.isPaused,
      request: (paused) => paused ? _runtimeCoordinator.pause() : _runtimeCoordinator.resume(),
    );

    // Init audio (chargement asset / loop) avant démarrage des adapters
    await backgroundMusicService.initialize();


    // Wiring des adapters événementiels (écoute des événements du domaine)
    _uiEventAdapter.start();
    _audioEventAdapter.start();
    _analyticsEventAdapter.start();
    // Activer les adapters événements Achievements/Leaderboards
    _achievementsEventAdapter.start();
    _leaderboardsEventAdapter.start();

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    if (kDebugMode) {
      appLogger.debug('Orientation set to portrait');
    }

    NotificationManager.instance.setScaffoldMessengerKey(scaffoldMessengerKey);

    // Initialisation du port Cloud selon la préférence persistée + auto-activation si Google déjà signé
    try {
      final prefs = await SharedPreferences.getInstance();
      // SavesFacade supprimé - utilisation directe GamePersistenceOrchestrator

      // Rafraîchir l'identité Google Play Games
      try { await _googleServices.identity.refresh(); } catch (_) {}
      final isSignedIn = _googleServices.identity.status == IdentityStatus.signedIn;

      var cloudEnabled = prefs.getBool('cloud_enabled') ?? false;
      // Filtre mission depuis préférences utilisateur (priorité aux prefs si activées)
      try {
        final missionPref = prefs.getBool('mission_logging');
        if (missionPref != null) {
          Logger.enableMissionMode(missionPref == true);
        }
      } catch (_) {}
      if (!cloudEnabled && isSignedIn) {
        cloudEnabled = true;
        await prefs.setBool('cloud_enabled', true);
      }
      // CORRECTION AUDIT #1: Simplifier activation CloudPort au boot
      // Si cloud_enabled=true, TOUJOURS activer le CloudPort
      // La vérification auth se fera au moment des requêtes via ensureAuthenticatedForCloud()
      print('🔥🔥🔥 [MAIN] CloudPort activation | cloudEnabled=$cloudEnabled isSignedIn=$isSignedIn 🔥🔥🔥');
      
      if (cloudEnabled) {
        final activated = await CloudPortManager.instance.activate(reason: 'boot_user_preference');
        print('🔥🔥🔥 [MAIN] CloudPort.activate() result: $activated 🔥🔥🔥');
      } else {
        print('🔥🔥🔥 [MAIN] CloudPort NOT activated (cloud disabled) 🔥🔥🔥');
        await CloudPortManager.instance.deactivate(reason: 'boot_user_disabled');
      }
      
      // P0-1: Provider playerId SUPPRIMÉ - utiliser directement FirebaseAuthService.instance.currentUser?.uid
      // Firebase UID = identité canonique unique (source de vérité)
      print('🔥🔥🔥 [MAIN] Firebase Auth configured 🔥🔥🔥');
      
      if (kDebugMode) {
        final user = FirebaseAuthService.instance.currentUser;
        if (user != null) {
          appLogger.info('[INIT] Firebase user ready | uid=${user.uid}', code: 'init_firebase_ready');
        } else {
          appLogger.warn('[INIT] Firebase user not authenticated', code: 'init_firebase_no_user');
        }
      }
      
      // 2) Listener Google Play Games pour achievements uniquement (pas pour identité cloud)
      // L'identité cloud est gérée exclusivement par Firebase UID
      _googleServices.identity.addListener(() async {
        try {
          final status = _googleServices.identity.status;
          if (status == IdentityStatus.signedIn) {
            if (kDebugMode) { appLogger.debug('[GPG] Google Play Games connecté (achievements disponibles)'); }
            // Note: La sync cloud est déclenchée par le listener Firebase dans AppBootstrapController
          }
        } catch (_) {}
      });
      
      // CORRECTION CRITIQUE: Le listener Firebase Auth est maintenant installé DANS AppBootstrapController
      // Ceci garantit que la sync cloud démarre AVANT l'affichage de WorldsScreen
      // Voir: lib/services/app_bootstrap_controller.dart:_installFirebaseAuthListener()
    } catch (_) {
      // En cas d'erreur de prefs, désactiver par défaut
      // SavesFacade supprimé - CloudPortManager utilisé directement
    }

    // Lancer l'application
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: gameState),
          ChangeNotifierProvider.value(value: gameSessionController),
          // Exposer l'identité comme ChangeNotifier pour propager les changements de connexion à l'UI
          ChangeNotifierProvider<GoogleIdentityService>.value(value: _googleServices.identity),
          Provider<GameActions>(
            create: (_) => GameActions(gameState: gameState),
          ),
          Provider<GameRuntimeCoordinator>.value(value: _runtimeCoordinator),
          Provider<runtime_facade.RuntimeActions>(
            create: (_) => runtime_facade.RuntimeActions(
              runtimeCoordinator: _runtimeCoordinator,
              isPausedReader: () => gameState.isPaused,
            ),
          ),
          // SavesFacade supprimé - plus nécessaire
          Provider<NavigationService>.value(value: navigationService),
          Provider<BackgroundMusicService>.value(value: backgroundMusicService),
          ChangeNotifierProvider.value(value: themeService),
          ChangeNotifierProvider.value(value: EventManager.instance),
          Provider<GoogleServicesBundle>.value(value: _googleServices),
          ChangeNotifierProvider<AppBootstrapController>(
            create: (_) => AppBootstrapController(
              gameState: gameState,
              uiPort: _gameUiFacade,
              audioPort: _gameAudioFacade,
              backgroundMusicService: backgroundMusicService,
              themeService: themeService,
              lifecycleHandler: _appLifecycleHandler,
              runtimeCoordinator: _runtimeCoordinator,
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    if (kDebugMode) {
      appLogger.error('Fatal error during initialization: $e', code: 'init_fatal', ctx: {
        'stack': stackTrace.toString(),
      });
    }
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeServiceProvider = Provider.of<ThemeService>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'PaperClip Game',
      theme: themeServiceProvider.getLightTheme(),
      darkTheme: themeServiceProvider.getDarkTheme(),
      themeMode: themeServiceProvider.themeMode,
      home: BootstrapScreen(
        startScreenBuilder: (context) => const StartScreen(),
      ),
      routes: {
        '/auth': (_) => const AuthChoiceScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

Widget _startScreenBuilder(BuildContext context) => const StartScreen();