import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';

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
import './widgets/notification_widgets.dart';

// Export du navigatorKey
export 'package:paperclip2/main.dart' show navigatorKey;

// Services globaux
final gameState = GameState();
final backgroundMusicService = BackgroundMusicService();
final eventManager = EventManager.instance;
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

    // Chargement des variables d'environnement
    if (kDebugMode) {
      print('Loading environment variables...');
    }
    try {
      await EnvConfig.load();
    } catch (e) {
      if (kDebugMode) {
        print('Warning: could not load all environment variables: $e');
      }
    }

    // Gestion simple des erreurs
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        print('Flutter Error: ${details.exception}');
      }
    };

    // Vérifier et restaurer les sauvegardes
    await gameState.checkAndRestoreFromBackup();

    // Lancer l'application
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
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('Fatal error during initialization: $e');
      print('Stack trace: $stackTrace');
    }
    rethrow;
  }
}

Future<void> _initializeServices() async {
  try {
    await backgroundMusicService.initialize();
    print('Background music initialized');
  } catch (e) {
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
      if (kDebugMode) {
        print('Error during game initialization: $e');
        print(stack);
      }
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