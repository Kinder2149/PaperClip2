import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';

// Imports des écrans
import './screens/start_screen.dart';
import './screens/main_screen.dart';
import './screens/save_load_screen_improved.dart';
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
import './services/save_manager_improved.dart';
import './services/save_migration_service.dart';
import './services/background_music.dart';
import './services/theme_service.dart';
import './utils/update_manager.dart';
import './widgets/indicators/notification_widgets.dart';

// Export du navigatorKey
export 'package:paperclip2/main.dart' show navigatorKey;

// Services globaux
final gameState = GameState();
final backgroundMusicService = BackgroundMusicService();
final themeService = ThemeService();
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

    // Migration de toutes les sauvegardes vers le nouveau format
    if (kDebugMode) {
      print('Migrating all saves to format version ${SaveManager.CURRENT_SAVE_FORMAT_VERSION}...');
    }
    try {
      await SaveMigrationService.migrateAllSaves();
      if (kDebugMode) {
        print('Save migration completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during save migration: $e');
      }
    }
    
    // Vérifier et restaurer les sauvegardes
    await gameState.checkAndRestoreFromBackup();

    // Initialiser le service de thème
    await themeService.initialize();

    // Lancer l'application
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: gameState),
          Provider<BackgroundMusicService>.value(value: backgroundMusicService),
          ChangeNotifierProvider.value(value: themeService),
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
    // Initialisation du service de musique
    await backgroundMusicService.initialize();
    print('Background music initialized');

    // Charger les préférences de son globales
    final prefs = await SharedPreferences.getInstance();
    final isMusicEnabled = prefs.getBool('global_music_enabled');
    
    // Si une préférence existe, l'utiliser, sinon activer le son par défaut
    if (isMusicEnabled != null) {
      if (isMusicEnabled) {
        await backgroundMusicService.play();
      } else {
        // S'assurer que l'état interne reflète la réalité même si le son est désactivé
        backgroundMusicService.setPlayingState(false);
      }
    } else {
      // Par défaut, le son est activé
      await backgroundMusicService.play();
    }
  } catch (e) {
    print('Error initializing background music: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeServiceProvider = Provider.of<ThemeService>(context);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'PaperClip Game',
      theme: themeServiceProvider.getLightTheme(),
      darkTheme: themeServiceProvider.getDarkTheme(),
      themeMode: themeServiceProvider.themeMode,
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
    // Utiliser un court délai puis lancer la navigation directement
    Future.delayed(const Duration(milliseconds: 500), () {
      if (kDebugMode) {
        print('Tentative de navigation après délai...');
      }
      _goToStartScreen();
    });
  }
  
  void _goToStartScreen() {
    if (kDebugMode) {
      print('_goToStartScreen appelé');
    }
    if (mounted && context.mounted) {
      if (kDebugMode) {
        print('Widget monté, navigation vers StartScreen');
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StartScreen()),
      );
    } else {
      if (kDebugMode) {
        print('Widget non monté, impossible de naviguer');
      }
    }
  }

  Future<void> _initializeGame() async {
    try {
      if (kDebugMode) {
        print('Démarrage de l\'initialisation du jeu en mode de dépannage...');
      }
      
      // CONTOURNEMENT DU PROBLÈME: Navigation directe sans initialisation complète
      if (kDebugMode) {
        print('Transition directe vers StartScreen pour contourner le blocage...');
      }

      // Note: On ne force plus l'initialisation de GameState ici car la méthode est privée
      // Le GameState sera initialisé normalement plus tard dans le cycle de vie de l'application
      if (!gameState.isInitialized) {
        if (kDebugMode) {
          print('GameState n\'est pas encore initialisé, mais sera initialisé plus tard');
        }
      }
      
      // Délai pour s'assurer que tout est prêt
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (kDebugMode) {
        print('Tentative de navigation vers StartScreen...');
      }
      
      // Navigation directe et synchrone vers StartScreen
      if (mounted) {
        try {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const StartScreen()),
                );
                if (kDebugMode) {
                  print('Navigation vers StartScreen réussie');
                }
              } else {
                if (kDebugMode) {
                  print('Context non monté, navigation impossible');
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('Erreur lors de la navigation: $e');
              }
            }
          });
        } catch (e) {
          if (kDebugMode) {
            print('Erreur lors de l\'ajout du callback: $e');
          }
        }
      } else {
        if (kDebugMode) {
          print('Widget non monté, impossible de naviguer');
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('ERREUR CRITIQUE lors de l\'initialisation du jeu: $e');
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