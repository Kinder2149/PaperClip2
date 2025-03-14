import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/env_config.dart';
import 'core/config/firebase_options.dart';
import 'core/constants/game_constants.dart';
import 'core/utils/update_manager.dart';
import 'data/datasources/local/save_datasource.dart';
import 'data/datasources/remote/firebase_config.dart';
import 'domain/entities/event_system.dart';
import 'domain/entities/game_state.dart';
import 'domain/entities/progression.dart';
import 'domain/services/background_music_service.dart';
import 'domain/services/event_manager.dart';
import 'domain/services/games_services_controller.dart';
import 'presentation/screens/event_log_screen.dart';
import 'presentation/screens/introduction_screen.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/market_screen.dart';
import 'presentation/screens/production_screen.dart';
import 'presentation/screens/save_load_screen.dart';
import 'presentation/screens/start_screen.dart';
import 'presentation/screens/upgrades_screen.dart';
import 'presentation/widgets/notification_widgets.dart';

// Export du navigatorKey
export 'main.dart' show navigatorKey;

// Services globaux
final GameState gameState = GameState();
final backgroundMusicService = BackgroundMusicService())))));
final eventManager = EventManager();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (kDebugMode) {
      print('Flutter binding initialized');
    }

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    if (kDebugMode) {
      print('Orientation set to portrait');
    }

    // Chargement des variables d'environnement avec plus de contexte
    if (kDebugMode) {
      print('Loading environment variables...');
    }
    await EnvConfig.load();

    // Initialisation de Firebase avec vÃ©rification
    if (kDebugMode) {
      print('Initializing Firebase...');
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialiser les services de jeu
    // Initialisation des services de jeu
    final gamesServices = GamesServicesController())))));
    await gamesServices.initialize();

    // Configuration de Crashlytics
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        print('Flutter Error: ${details.exception}');
      }
      FirebaseCrashlytics.instance.recordFlutterError(details);
    };

    // Capturer les erreurs non gÃ©rÃ©es avec plus de contexte
    ui.PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: true,
        reason: 'Unhandled platform error',
      );
      return true;
    };

    // Initialiser Firebase Config
    await FirebaseConfig.initialize();

    // VÃ©rifier et restaurer les sauvegardes
    await gameState.checkAndRestoreFromBackup();

    // Configurer et logger l'analytics
    await FirebaseAnalytics.instance.logAppOpen();
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

    // Lancer l'application avec la gestion d'erreur
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: gameState),
          Provider<BackgroundMusicService>.value(value: backgroundMusicService),
          ChangeNotifierProvider.value(value: EventManager()),
          Provider<GamesServicesController>(
            create: (context) => gamesServices,
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
    FirebaseCrashlytics.instance.recordError(
      e,
      stackTrace,
      reason: 'Error during app initialization',
      fatal: true,
    );
    rethrow;
  }
}

Future<void> _initializeServices() async {
  try {
    await backgroundMusicService.initialize();
    print('Background music initialized');
  } catch (e) {
    FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    print('Error initializing background music: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'PaperClip Game',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoadingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      await _initializeServices();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StartScreen()),
        );
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}






