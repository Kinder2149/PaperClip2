// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui show PlatformDispatcher;

// Import de l'écran de débogage
import 'debug_auth.dart';

// Imports des écrans
import './screens/start_screen.dart';
import './screens/main_screen.dart';
import './screens/save_load_screen.dart';
import './screens/production_screen.dart';
import './screens/market_screen.dart';
import './screens/upgrades_screen.dart';
import './screens/event_log_screen.dart';
import 'screens/introduction_screen.dart';
import 'screens/user_profile_screen.dart';

// Imports des configurations
import 'env_config.dart';
import 'config/api_config.dart';

// Imports des services utilisateur
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

      if (profile != null && socialService != null && analyticsService != null) {
        // Tenter d'initialiser avec le profil local
        debugPrint('Initialisation des services sociaux pour l\'utilisateur: ${profile.userId}');

        // Initialiser les services sociaux avec les services requis et les paramètres userId et userManager
        friendsService = FriendsService(
          userId: profile.userId,
          userManager: userManager,
          socialService: socialService!, 
          analyticsService: analyticsService!
        );
        
        userStatsService = UserStatsService(
          userId: profile.userId,
          userManager: userManager,
          socialService: socialService!,
          analyticsService: analyticsService!
        );

        return;
      }

      debugPrint('Impossible d\'initialiser les services sociaux: utilisateur non authentifié ou services manquants');
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
    
    // Obtenir la configuration API pour cette plateforme
    final apiConfig = ApiConfig.currentPlatform;
    if (kDebugMode) {
      print('API configuration loaded: ${apiConfig.baseUrl}');
    }
    
    // Initialisation des services API
    final apiClient = ApiClient();
    await apiClient.initialize();
    
    final authService = AuthService();
    final analyticsService = AnalyticsService();
    final storageService = StorageService();
    final configService = ConfigService();
    final socialService = SocialService();
    final saveService = SaveService();

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
  print('Initializing services...');
  
  try {
    // Initialiser l'ApiClient (doit être fait en premier)
    final apiClient = serviceLocator.apiClient;
    await apiClient?.initialize();
    print('API Client initialized');
    
    // Initialiser les services API
    final authService = serviceLocator.authService;
    await authService?.initialize();
    print('Auth Service initialized');
    
    final analyticsService = serviceLocator.analyticsService;
    await analyticsService?.initialize();
    print('Analytics Service initialized');
    
    final storageService = serviceLocator.storageService;
    await storageService?.initialize();
    print('Storage Service initialized');
    
    final configService = serviceLocator.configService;
    await configService?.initialize();
    print('Config Service initialized');
    
    final socialService = serviceLocator.socialService;
    await socialService?.initialize();
    print('Social Service initialized');
    
    final saveService = serviceLocator.saveService;
    await saveService?.initialize();
    print('Save Service initialized');
    
    // Le UserManager sera initialisé ailleurs car il n'est pas dans serviceLocator
    // mais est accessible directement comme singleton via UserManager.instance
    await UserManager.instance.initialize();
    print('User Manager initialized');
    
    // Initialiser la musique de fond
    await backgroundMusicService.initialize();
    print('Background music initialized');
    
    print('All services initialized successfully');
  } catch (e, stack) {
    // Utiliser directement analyticsService si disponible
    // (si l'erreur se produit avant l'initialisation de analyticsService,
    // cela va échouer silencieusement)
    try {
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Service initialization error');
    } catch (_) {}
    
    print('Error initializing services: $e');
    print(stack);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Gérer le cycle de vie de l'application
    switch (state) {
      case AppLifecycleState.paused:
        // L'application est en arrière-plan mais toujours visible
        backgroundMusicService.pause();
        // Sauvegarder l'état actuel du jeu
        if (gameState.isInitialized) {
          gameState.saveOnImportantEvent();
        }
        break;
      case AppLifecycleState.detached:
        // L'application est fermée complètement
        _cleanupResources();
        break;
      case AppLifecycleState.inactive:
        // L'application est temporairement inactive (ex: appel téléphonique)
        backgroundMusicService.pause();
        break;
      case AppLifecycleState.resumed:
        // L'application revient au premier plan
        // Ne pas reprendre la musique automatiquement car elle dépend du contexte du jeu
        break;
      default:
        break;
    }
  }
  
  // Méthode pour nettoyer les ressources lorsque l'application est fermée
  void _cleanupResources() {
    try {
      // Sauvegarde finale
      if (gameState.isInitialized) {
        gameState.saveOnImportantEvent();
      }
      // Arrêter la musique
      backgroundMusicService.stop();
      backgroundMusicService.dispose();
      // Autres nettoyages si nécessaire
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      analyticsService.logEvent('app_close');
    } catch (e) {
      // Ignorer les erreurs lors du nettoyage
      print('Erreur lors du nettoyage des ressources: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PaperClip Game',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _isLoading = true;
  bool _isCreateLocalProfile = false;
  bool _debugMode = true; // Activer le mode débogage par défaut
  final UserManager _userManager = UserManager();
  final TextEditingController _nicknameController = TextEditingController();
  int _retryCount = 0;
  static const int MAX_RETRIES = 3;
  
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userManager = Provider.of<UserManager>(context, listen: false);
      await userManager.initialize();

      if (kDebugMode) {
        print('Vérification du profil: ${userManager.hasProfile ? "Trouvé" : "Non trouvé"}');
      }

      if (!mounted) return;

      setState(() {
        _isCreateLocalProfile = !userManager.hasProfile;
        _isLoading = false;
      });

      // Si un profil existe, passer à l'écran de démarrage
      if (!userManager.hasProfile) {
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
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Application error');

      // Implémenter un mécanisme de retry
      if (_isLoading && mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de la vérification du profil';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createLocalProfile(String initialNickname) async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
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
        _isLoading = false;
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
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Application error');

      if (mounted) {
        setState(() {
          _isLoading = false;
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
        _isLoading = true;
        _errorMessage = 'Connexion à Google en cours...';
      });
      
      // Vérification des variables d'environnement
      if (kDebugMode) {
        print('=== VÉRIFICATION ENVIRONNEMENT ===');
        print('Google Client ID: ${EnvConfig.googleClientId}');
        print('API Base URL: ${EnvConfig.apiBaseUrl}');
        
        if (EnvConfig.googleClientId.isEmpty) {
          print('ERREUR: Google Client ID non défini dans .env');
        }
        
        if (EnvConfig.apiBaseUrl.isEmpty) {
          print('ERREUR: API Base URL non définie dans .env');
        }
      }

      final userManager = Provider.of<UserManager>(context, listen: false);
      if (kDebugMode) print('Tentative de connexion Google via UserManager...');
      
      final result = await userManager.signInWithGoogle();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result != null) {
        if (kDebugMode) {
  final userId = userManager.authService?.userId;
  print('Connexion Google réussie. ID utilisateur: $userId');
}
        // En mode debug, naviguer vers l'écran de débogage d'authentification
        if (kDebugMode && mounted) {
          // Afficher un menu de choix pour le développeur
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Connexion réussie'),
              content: const Text('Où voulez-vous aller?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoadingScreen()),
                    );
                  },
                  child: const Text('Application principale'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AuthDebugScreen()),
                    );
                  },
                  child: const Text('Écran de débogage'),
                ),
              ],
            ),
          );
        } else if (mounted) {
          // En production, aller directement à l'écran principal
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoadingScreen()),
          );
        }
      } else {
        if (kDebugMode) print('Échec de la connexion Google: résultat null');
        if (mounted) {
          setState(() {
            _errorMessage = 'Échec de la connexion à Google. Essayez en mode local.';
          });
          
          // En mode debug, proposer d'aller à l'écran de débogage
          if (kDebugMode) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Erreur de connexion'),
                content: const Text('Voulez-vous aller à l\'écran de débogage?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Non'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuthDebugScreen()),
                      );
                    },
                    child: const Text('Oui'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('Erreur détaillée de connexion: $e');
        print('Stack trace: $stack');
      }
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Google auth error');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur de connexion: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            action: kDebugMode ? SnackBarAction(
              label: 'Débogage',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthDebugScreen()),
                );
              },
            ) : null,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_debugMode) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A2A72), Color(0xFF009FFD)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                const SizedBox(height: 24),
                Text(
                  _isLoading ? 'Chargement du profil...' : 'Bienvenue dans le mode débogage',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AuthDebugScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade900,
                  ),
                  child: const Text('Ouvrir l\'écran de débogage'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _debugMode = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('Continuer normalement'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A2A72), Color(0xFF009FFD)],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 24),
                Text(
                  'Chargement du profil...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
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
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Application error');
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