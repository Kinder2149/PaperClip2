import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  // Charger les variables d'environnement
  await EnvConfig.load();

  // Initialiser Firebase avec les options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final gamesServices = GamesServicesController();
  await gamesServices.initialize();

  // Configurer Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  // Capturer les erreurs non gérées (version corrigée)
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Forcer l'orientation portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialiser Firebase Config
  await FirebaseConfig.initialize();

  // Vérifier les backups
  await gameState.checkAndRestoreFromBackup();

  // Configuration et log de l'analytics
  final analytics = FirebaseAnalytics.instance;
  await analytics.logAppOpen();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gameState),
        Provider<BackgroundMusicService>.value(value: backgroundMusicService),
        ChangeNotifierProvider.value(value: EventManager.instance),
      ],
      child: const MyApp(),
    ),
  );
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