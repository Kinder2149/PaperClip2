// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
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
import 'screens/user_profile_screen.dart';
import 'package:paperclip2/services/user/user_manager.dart';

// Imports des services API
import 'package:paperclip2/services/api/api_services.dart';

// Imports des modèles et services
import './models/game_state.dart';
import './models/game_config.dart';
import './models/event_system.dart';
import './models/progression_system.dart';
import './services/background_music.dart';
import './utils/update_manager.dart';
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

  FriendsService? friendsService;
  UserStatsService? userStatsService;
  AnalyticsService? analyticsService;
  ConfigService? configService;

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
    final authService = AuthService(apiClient);
    final analyticsService = AnalyticsService(apiClient);
    final storageService = StorageService(apiClient);
    final configService = ConfigService(apiClient);
    final socialService = SocialService(apiClient);
    final saveService = SaveService(apiClient);

    // Ajouter les services au ServiceLocator
    serviceLocator.analyticsService = analyticsService;
    serviceLocator.configService = configService;

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
      final result = await showDialog<UserProfile>(
        context: context,
        barrierDismissible: false,
        builder: (context) => NicknameDialog(
          initialNickname: initialNickname,
          onNicknameSet: (nickname) async {
            try {
              // Créer le profil avec le surnom choisi
              final profile = await userManager.createProfile(nickname);
              return profile;
            } catch (e) {
              debugPrint('Erreur lors de la création du profil: $e');
              return null;
            }
          },
        ),
      );

      setState(() {
        _isChecking = false;
      });

      if (result != null && mounted) {
        // Profil créé avec succès, passer à l'écran de démarrage
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoadingScreen()),
          );
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('Erreur lors de la création du profil: $e');
      }
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Create profile error');

      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de la création du profil. Veuillez réessayer.';
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _createGoogleProfile() async {
    if (!mounted) return;

    try {
      setState(() {
        _isChecking = true;
        _errorMessage = null;
      });

      final userManager = Provider.of<UserManager>(context, listen: false);
      final result = await userManager.signInWithGoogle();

      if (!mounted) return;

      setState(() {
        _isChecking = false;
      });

      if (result != null && mounted) {
        // Connexion Google réussie, passer à l'écran de démarrage
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoadingScreen()),
          );
        }
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Échec de la connexion avec Google. Veuillez réessayer.';
        });
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('Erreur lors de la création du profil Google: $e');
      }
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Create Google profile error');

      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de la connexion avec Google. Veuillez réessayer.';
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade800,
              Colors.deepPurple.shade500,
            ],
          ),
        ),
        child: Center(
          child: _isChecking
              ? const CircularProgressIndicator(color: Colors.white)
              : _hasProfile
                  ? const CircularProgressIndicator(color: Colors.white)
                  : _buildAuthOptions(),
        ),
      ),
    );
  }

  Widget _buildAuthOptions() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Bienvenue dans PaperClip',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Créez un profil pour commencer à jouer',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Créer un profil local'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.deepPurple.shade800,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
            onPressed: () => _createLocalProfile('Joueur${DateTime.now().millisecondsSinceEpoch % 10000}'),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            icon: Image.asset('assets/images/google_logo.png', height: 24),
            label: const Text('Continuer avec Google'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
            onPressed: _createGoogleProfile,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _checkProfile,
              child: const Text(
                'Réessayer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
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
  bool _isLoading = true;
  String _loadingMessage = 'Chargement du jeu...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      if (!mounted) return;

      // Récupérer les services
      final gameState = Provider.of<GameState>(context, listen: false);
      final userManager = Provider.of<UserManager>(context, listen: false);
      final saveSystem = Provider.of<SaveSystem>(context, listen: false);

      // Vérifier si le jeu est déjà initialisé
      if (!gameState.isInitialized) {
        setState(() {
          _loadingMessage = 'Initialisation du jeu...';
        });
        await gameState.initialize();
      }

      // Vérifier si l'utilisateur a une sauvegarde
      setState(() {
        _loadingMessage = 'Recherche de sauvegardes...';
      });

      final hasSaves = await saveSystem.hasSaves();

      if (hasSaves) {
        setState(() {
          _loadingMessage = 'Chargement de la dernière sauvegarde...';
        });
        
        // Charger la dernière sauvegarde
        final loaded = await saveSystem.loadLastSave();
        
        if (loaded) {
          setState(() {
            _loadingMessage = 'Sauvegarde chargée avec succès!';
          });
        } else {
          setState(() {
            _loadingMessage = 'Démarrage d\'une nouvelle partie...';
          });
          await gameState.startNewGame();
        }
      } else {
        setState(() {
          _loadingMessage = 'Démarrage d\'une nouvelle partie...';
        });
        await gameState.startNewGame();
      }

      // Naviguer vers l'écran principal ou d'introduction
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;

        if (hasSeenIntro) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const IntroductionScreen()),
          );
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('Erreur lors de l\'initialisation du jeu: $e');
      }
      serviceLocator.analyticsService?.recordError(e, stack);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Une erreur est survenue lors du chargement du jeu. Veuillez réessayer.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade800,
              Colors.deepPurple.shade500,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 150,
                ),
                const SizedBox(height: 40),
                if (_isLoading) ...[
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    _loadingMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ] else if (_errorMessage != null) ...[
                  Icon(Icons.error_outline, color: Colors.red.shade300, size: 50),
                  const SizedBox(height: 20),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade300, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _initializeGame();
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.deepPurple.shade800,
                      backgroundColor: Colors.white,
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
