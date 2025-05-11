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
import './services/background_music.dart';
import './utils/update_manager.dart';
import './services/firebase_config.dart';
import './widgets/notification_widgets.dart';
import 'services/games_services_controller.dart';
import 'services/save/save_system.dart';
import 'services/save/save_types.dart';
import 'services/user/user_manager.dart';
import './dialogs/nickname_dialog.dart';

// Export du navigatorKey
export 'package:paperclip2/main.dart' show navigatorKey;

// Services globaux
final gameState = GameState();
final backgroundMusicService = BackgroundMusicService();
final eventManager = EventManager.instance;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
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
    await EnvConfig.load();

    // Initialisation de Firebase
    if (kDebugMode) {
      print('Initializing Firebase...');
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configuration de Crashlytics
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        print('Flutter Error: ${details.exception}');
      }
      FirebaseCrashlytics.instance.recordFlutterError(details);
    };

    // Capturer les erreurs non gérées
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

    // Initialiser les services de jeu
    final gamesServices = GamesServicesController();
    await gamesServices.initialize();

    // IMPORTANT: Créer et connecter UserManager et SaveSystem correctement
    // pour éviter la dépendance circulaire
    final userManager = UserManager();
    final saveSystem = SaveSystem();

    // Injecter les dépendances
    userManager.setSaveSystem(saveSystem);
    saveSystem.setUserManager(userManager);

    // Vérification en mode debug
    if (kDebugMode) {
      print('UserManager et SaveSystem créés et liés avec succès');
    }

    // Initialiser UserManager
    await userManager.initialize();
    if (kDebugMode) {
      print('UserManager initialisé: ${userManager.hasProfile ? "Profil trouvé" : "Aucun profil"}');
    }

    // Initialiser le système de sauvegarde
    saveSystem.initialize(gameState);
    if (kDebugMode) {
      print('SaveSystem initialisé');
    }

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
          // Ajout des providers pour UserManager et SaveSystem
          Provider<UserManager>.value(value: userManager),
          Provider<SaveSystem>.value(value: saveSystem),
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
      home: const AuthCheckScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _isChecking = true;
  bool _hasProfile = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final userManager = Provider.of<UserManager>(context, listen: false);
      await userManager.initialize();

      if (kDebugMode) {
        print('Vérification du profil: ${userManager.hasProfile ? "Trouvé" : "Non trouvé"}');
      }

      setState(() {
        _hasProfile = userManager.hasProfile;
        _isChecking = false;
      });

      // Si un profil existe, passer à l'écran de démarrage
      if (_hasProfile) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoadingScreen()),
          );
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('Erreur lors de la vérification du profil: $e');
        print('Stack: $stack');
      }
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Profile check error');

      setState(() {
        _errorMessage = 'Erreur lors de la vérification: $e';
        _isChecking = false;
      });
    }
  }

  Future<void> _createLocalProfile() async {
    try {
      final userManager = Provider.of<UserManager>(context, listen: false);

      // Afficher le dialogue de surnom
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => NicknameDialog(
          initialNickname: 'Joueur',
          onNicknameSet: (nickname) async {
            // Créer le profil avec le surnom choisi
            await userManager.createProfile(nickname);
          },
        ),
      );

      if (result == true) {
        // Profil créé avec succès, passer à l'écran de démarrage
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoadingScreen()),
          );
        }
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Create profile error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createGoogleProfile() async {
    try {
      final userManager = Provider.of<UserManager>(context, listen: false);
      final result = await userManager.createProfileWithGoogle();

      if (result) {
        // Profil créé avec succès, passer à l'écran de démarrage
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoadingScreen()),
          );
        }
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Create Google profile error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Vérification du profil...'),
            ],
          ),
        ),
      );
    }

    if (_hasProfile) {
      // Si un profil existe, l'écran de démarrage sera affiché
      // dans _checkProfile, donc ce widget ne sera pas rendu
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Aucun profil n'existe, afficher les options de création
    return Scaffold(
      body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple[400]!,
                Colors.deepPurple[800]!,
              ],
              stops: const [0.3, 1.0],
            ),
          ),
          child: SafeArea(
          child: Padding(
          padding: const EdgeInsets.all(24.0),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
      // Logo et titre
      Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
      ),
      child: const Icon(
        Icons.link,
        size: 120,
        color: Colors.white,
      ),
    ),
    const SizedBox(height: 20),
            const Text(
              'ClipFactory Empire',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Orbitron',
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'v${GameConstants.VERSION}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 40),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              'Bienvenue dans ClipFactory Empire !',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            const Text(
              'Créez votre profil pour commencer votre aventure',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createGoogleProfile,
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text(
                  'Se connecter avec Google',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createLocalProfile,
                icon: const Icon(Icons.person_add),
                label: const Text(
                  'Jouer sans se connecter',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'La connexion avec Google permet de sauvegarder vos parties dans le cloud et de participer aux classements',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
      ),
          ),
          ),
      ),
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