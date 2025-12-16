import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
import './presentation/adapters/event_manager_domain_event_adapter.dart';

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

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (kDebugMode) {
      print('Flutter binding initialized');
    }

    // Clean Architecture: injection des ports (domain -> presentation)
    gameState.levelSystem.setDomainEventSink(_domainEventSink);
    gameState.productionManager.setDomainEventSink(_domainEventSink);
    gameState.autoSaveService.setDomainEventSink(_domainEventSink);

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
          Provider<GameRuntimeCoordinator>.value(value: _runtimeCoordinator),
          Provider<NavigationService>.value(value: navigationService),
          Provider<BackgroundMusicService>.value(value: backgroundMusicService),
          ChangeNotifierProvider.value(value: themeService),
          ChangeNotifierProvider.value(value: EventManager.instance),
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
      debugShowCheckedModeBanner: false,
    );
  }
}