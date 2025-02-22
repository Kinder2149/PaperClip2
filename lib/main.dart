import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'dart:ui' as ui show PlatformDispatcher;

// Imports des écrans
import './screens/start_screen.dart';
import './screens/main_screen.dart';
import './screens/save_load_screen.dart';
import './screens/production_screen.dart';
import './screens/market_screen.dart';
import './screens/upgrades_screen.dart';
import './screens/event_log_screen.dart';
import 'screens/introduction_screen.dart';
import 'env_config.dart';

// Imports des modèles et services
import './models/game_state.dart';
import './models/game_config.dart';
import './models/event_system.dart';
import './models/progression_system.dart';
import './services/save_manager.dart';
import './services/background_music.dart';
import './utils/update_manager.dart';
import './services/firebase_config.dart';
import './widgets/notification_widgets.dart';
import 'services/games_services_controller.dart';

// Export du navigatorKey
export 'package:paperclip2/main.dart' show navigatorKey;

// Clé globale pour la navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Services globaux
final gameState = GameState();
final backgroundMusicService = BackgroundMusicService();
final eventManager = EventManager.instance;

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

    // Initialisation de Firebase avec vérification
    if (kDebugMode) {
      print('Initializing Firebase...');
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialiser les services de jeu
    // Initialisation des services de jeu
    final gamesServices = GamesServicesController();
    await gamesServices.initialize();

    // Configuration de Crashlytics
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        print('Flutter Error: ${details.exception}');
      }
      FirebaseCrashlytics.instance.recordFlutterError(details);
    };

    // Capturer les erreurs non gérées avec plus de contexte
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

    // Vérifier et restaurer les sauvegardes
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
          ChangeNotifierProvider.value(value: EventManager.instance),
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