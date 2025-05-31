// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui show PlatformDispatcher;

// Imports des services API
import 'package:paperclip2/services/api/api_services.dart';

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
import 'screens/user_profile_screen.dart';
import 'package:paperclip2/services/user/user_manager.dart';

// Imports des modèles et services
import './models/game_state.dart';
import './models/game_config.dart';
import './models/event_system.dart';
import './models/progression_system.dart';
import './services/background_music.dart';
import './utils/update_manager.dart';
// Services de configuration remplacés par ConfigService
import './widgets/notification_widgets.dart';
import 'services/games_services_controller.dart';
import 'services/save/save_system.dart';
import 'services/save/save_types.dart';
import 'services/user/user_manager.dart';
import 'services/social/friends_service.dart';
import 'services/social/user_stats_service.dart';
import './dialogs/nickname_dialog.dart';

// Export du navigatorKey
export 'package:paperclip2/main.dart' show navigatorKey;

// Services globaux
final gameState = GameState();
final backgroundMusicService = BackgroundMusicService();
final eventManager = EventManager.instance;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Classe pour gérer les services sociaux globalement
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._private();
  factory ServiceLocator() => _instance;

  ServiceLocator._private();

  // Services API
  ApiClient? apiClient;
  AuthService? authService;
  AnalyticsService? analyticsService;
  StorageService? storageService;
  ConfigService? configService;
  SocialService? socialService;
  SaveService? saveService;
  
  // Services sociaux
  FriendsService? friendsService;
  UserStatsService? userStatsService;

  Future<void> initializeSocialServices(UserManager userManager) async {
    try {
      final profile = userManager.currentProfile;

      if (profile != null) {
        // Tenter d'initialiser avec le profil local
        debugPrint('Initialisation des services sociaux pour l\'utilisateur: ${profile.userId}');

        // Initialiser les services sociaux avec l'ID du profil local
        friendsService = FriendsService(profile.userId, userManager);
        userStatsService = UserStatsService(profile.userId, userManager);

        return;
      }

      debugPrint('Impossible d\'initialiser les services sociaux: utilisateur non authentifié');
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'initialisation des services sociaux: $e');
      analyticsService?.recordError(e, stack, reason: 'Social services init error');
    }
  }
}

// Créer une instance du localisateur de service
final serviceLocator = ServiceLocator();

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

        // Initialisation des services API
    final apiClient = ApiClient();
    await apiClient.initialize();
    
    final authService = AuthService();
    await authService.initialize();
    
    final analyticsService = AnalyticsService();
    await analyticsService.initialize();
    
    final storageService = StorageService();
    await storageService.initialize();
    
    final configService = ConfigService();
    await configService.initialize();
    
    final socialService = SocialService();
    await socialService.initialize();
    
    final saveService = SaveService();
    await saveService.initialize();

    // Ajouter les services au ServiceLocator
    serviceLocator.apiClient = apiClient;
    serviceLocator.authService = authService;
    serviceLocator.analyticsService = analyticsService;
    serviceLocator.storageService = storageService;
    serviceLocator.configService = configService;
    serviceLocator.socialService = socialService;
    serviceLocator.saveService = saveService;

    // Configuration de la gestion d'erreurs
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        print('Flutter Error: ${details.exception}');
      }
      analyticsService.recordFlutterError(details);
    };

    // Capturer les erreurs non gérées
    ui.PlatformDispatcher.instance.onError = (error, stack) {
      analyticsService.recordError(
        error,
        stack,
        fatal: true,
        reason: 'Unhandled platform error',
      );
      return true;
    };

    // Initialiser les services de jeu
    final gamesServices = GamesServicesController();
    await gamesServices.initialize();

    // Créer le service de musique de fond
    final backgroundMusicService = BackgroundMusicService();

    // Créer GameState
    final gameState = GameState();

    // IMPORTANT: Créer et connecter UserManager et SaveSystem correctement
    // pour éviter la dépendance circulaire
    final userManager = UserManager(
      authService: authService,
      storageService: storageService,
      analyticsService: analyticsService,
      socialService: socialService,
      saveService: saveService
    );
    final saveSystem = SaveSystem();

    // Injecter les dépendances
    userManager.setSaveSystem(saveSystem);
    saveSystem.setUserManager(userManager);

    // Injecter SaveSystem dans GameState
    gameState.setSaveSystem(saveSystem);
    gameState.setSocialUserManager(userManager);

    // Vérification en mode debug
    if (kDebugMode) {
      print('UserManager et SaveSystem créés et liés avec succès');
    }

    // Initialiser UserManager
    await userManager.initialize();
    if (kDebugMode) {
      print('UserManager initialisé: ${userManager.hasProfile ? "Profil trouvé" : "Aucun profil"}');
    }

    // Initialiser explicitement GameState avant d'initialiser SaveSystem
    await gameState.initialize();
    if (kDebugMode) {
      print('GameState initialisé avec succès');
    }

    // Initialiser le système de sauvegarde avec GameState
    await saveSystem.initialize(gameState);
    if (kDebugMode) {
      print('SaveSystem initialisé');
    }

    // Initialiser les services sociaux
    await serviceLocator.initializeSocialServices(userManager);
    if (kDebugMode) {
      print('Services sociaux initialisés');
    }

    // Maintenant que tout est correctement initialisé, vérifier et restaurer les sauvegardes
    if (gameState.isInitialized && saveSystem != null) {
      await gameState.checkAndRestoreFromBackup();
    }

    // Configurer et logger l'analytics
    await analyticsService.logAppOpen();
    await analyticsService.setAnalyticsCollectionEnabled(true);

    // Lancer l'application avec la gestion d'erreur
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: gameState),
          Provider<BackgroundMusicService>.value(value: backgroundMusicService),
          ChangeNotifierProvider.value(value: EventManager.instance),
          // Remplacer ChangeNotifierProvider par Provider pour UserManager
          Provider<UserManager>.value(value: userManager),
          Provider<SaveSystem>.value(value: saveSystem),
          // Conservez ChangeNotifierProvider pour GamesServicesController
          ChangeNotifierProvider<GamesServicesController>.value(
            value: gamesServices,
          ),
          // Provider pour ServiceLocator
          Provider<ServiceLocator>.value(value: serviceLocator),
          // Providers pour les services API
          Provider<ApiClient>.value(value: apiClient),
          Provider<AuthService>.value(value: authService),
          Provider<AnalyticsService>.value(value: analyticsService),
          Provider<StorageService>.value(value: storageService),
          Provider<ConfigService>.value(value: configService),
          Provider<SocialService>.value(value: socialService),
          Provider<SaveService>.value(value: saveService),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('Fatal error during initialization: $e');
      print('Stack trace: $stackTrace');
    }
    serviceLocator.analyticsService?.recordError(
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
    serviceLocator.analyticsService?.recordError(e, StackTrace.current);
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
      routes: {
        '/profile': (context) => const UserProfileScreen(),
      },
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
  int _retryCount = 0;
  static const int MAX_RETRIES = 3;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    if (!mounted) return;

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

      if (!mounted) return;

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
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Profile check error');

      // Implémenter un mécanisme de retry
      if (_retryCount < MAX_RETRIES && mounted) {
        _retryCount++;
        setState(() {
          _errorMessage = 'Tentative $_retryCount/$MAX_RETRIES...';
          _isChecking = false;
        });

        // Attendre un peu avant de réessayer
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _checkProfile();
        }
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Problème de connexion. Vérifiez votre connexion internet.';
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _createLocalProfile(String initialNickname) async {
    if (!mounted) return;

    try {
      setState(() {
        _isChecking = true;
        _errorMessage = null;
      });

      final userManager = Provider.of<UserManager>(context, listen: false);

      // Afficher le dialogue de surnom avec un nom par défaut
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => NicknameDialog(
          initialNickname: initialNickname,
          onNicknameSet: (nickname) async {
            try {
              // Créer le profil avec le surnom choisi
              await userManager.createProfile(nickname);
              return true;
            } catch (e) {
              debugPrint('Erreur lors de la création du profil: $e');
              return false;
            }
          },
        ),
      );

      setState(() {
        _isChecking = false;
      });

      if (result == true && mounted) {
        // Profil créé avec succès, passer à l'écran de démarrage
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoadingScreen()),
          );
        }
      } else {
        // Échec ou annulation
        if (mounted) {
          setState(() {
            _errorMessage = 'Création de profil annulée ou échouée.';
          });
        }
      }
    } catch (e, stack) {
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Create profile error');

      if (mounted) {
        setState(() {
          _isChecking = false;
          _errorMessage = 'Erreur: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: () => _createLocalProfile(initialNickname),
            ),
          ),
        );
      }
    }
  }

  Future<void> _createGoogleProfile() async {
    if (!mounted) return;

    try {
      setState(() {
        _isChecking = true;
        _errorMessage = 'Connexion à Google en cours...';
      });

      final userManager = Provider.of<UserManager>(context, listen: false);
      final result = await userManager.signInWithGoogle();

      if (!mounted) return;

      setState(() {
        _isChecking = false;
      });

      if (result) {
        // Profil créé avec succès, passer à l'écran de démarrage
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoadingScreen()),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Échec de la connexion à Google. Essayez en mode local.';
          });
        }
      }
    } catch (e, stack) {
      serviceLocator.analyticsService.recordError(e, stack, reason: 'Create Google profile error');

      if (mounted) {
        setState(() {
          _isChecking = false;
          _errorMessage = 'Erreur de connexion: $e';
        });

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
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Vérification du profil...'),
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
                    child: Column(
                      children: [
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        if (_retryCount >= MAX_RETRIES) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Vous pouvez créer un profil sans connexion à Google',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
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
                    onPressed: () => _createLocalProfile('Joueur'),
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
      serviceLocator.analyticsService.recordError(e, stack);
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