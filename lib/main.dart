import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'firebase_options.dart';
import 'dart:ui' as ui show PlatformDispatcher;
import 'services/service_container.dart';
import 'game_state.dart';
import 'screens/home_screen.dart';

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

// Imports des composants
import 'components/components.dart';

// Imports des utilitaires
import 'utils/utils.dart';

// Configuration
import 'config/app_config.dart';
import 'config/theme_config.dart';
import 'config/routes_config.dart';

// Export du navigatorKey
export 'package:paperclip2/main.dart' show navigatorKey;

// Services globaux
final getIt = GetIt.instance;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configuration de Firebase Crashlytics
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  
  // Initialisation des services
  await initializeServices();
  
  runApp(const MyApp());
}

Future<void> initializeServices() async {
  // Enregistrement des services dans GetIt
  getIt.registerSingleton<SaveService>(SaveService());
  getIt.registerSingleton<NotificationService>(NotificationService());
  getIt.registerSingleton<AchievementService>(AchievementService());
  getIt.registerSingleton<LeaderboardService>(LeaderboardService());
  getIt.registerSingleton<AnalyticsService>(AnalyticsService());
  getIt.registerSingleton<BackgroundMusicService>(BackgroundMusicService());
  getIt.registerSingleton<GamesServicesController>(GamesServicesController());

  // Initialisation des services
  await getIt<SaveService>().initialize();
  await getIt<NotificationService>().initialize();
  await getIt<BackgroundMusicService>().initialize();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameState()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        theme: ThemeConfig.lightTheme,
        darkTheme: ThemeConfig.darkTheme,
        themeMode: ThemeMode.system,
        navigatorKey: navigatorKey,
        initialRoute: RoutesConfig.initial,
        routes: RoutesConfig.routes,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

Future<void> _initializeServices() async {
  try {
    await getIt<BackgroundMusicService>().initialize();
    print('Background music initialized');
  } catch (e) {
    FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    print('Error initializing background music: $e');
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