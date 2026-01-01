import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

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
import './services/google/cloudsave/cloud_save_service.dart';
import './services/google/cloudsave/cloud_save_bootstrap.dart';
import './screens/auth_choice_screen.dart';
import 'services/persistence/game_persistence_orchestrator.dart';
// Cloud ports legacy retirés
import 'services/google/identity/google_identity_service.dart';

// Adapters UI/Audio (hors domaine)
import './services/ui/game_ui_event_adapter.dart';
import './services/audio/audio_event_adapter.dart';
import './services/analytics/analytics_event_adapter.dart';
import './services/analytics/analytics_port.dart';
// HTTP analytics désactivé (NoOp)

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
  // Analytics HTTP legacy désactivé → NoOp uniquement
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
    if (kDebugMode) {
      print('Flutter binding initialized');
    }

    // Clean Architecture: injection des ports (domain -> presentation)
    gameState.levelSystem.setDomainEventSink(_domainEventSink);
    gameState.productionManager.setDomainEventSink(_domainEventSink);
    gameState.autoSaveService.setDomainEventSink(_domainEventSink);

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
      print('Orientation set to portrait');
    }

    NotificationManager.instance.setScaffoldMessengerKey(scaffoldMessengerKey);

    // Lancer l'application
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: gameState),
          ChangeNotifierProvider.value(value: gameSessionController),
          Provider<GameActions>(
            create: (_) => GameActions(gameState: gameState),
          ),
          Provider<GameRuntimeCoordinator>.value(value: _runtimeCoordinator),
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
      print('Fatal error during initialization: $e');
      print('Stack trace: $stackTrace');
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
      home: const BootstrapScreen(),
      routes: {
        '/auth': (_) => const AuthChoiceScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}