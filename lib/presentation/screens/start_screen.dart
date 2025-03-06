// lib/presentation/screens/start_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/router.dart';
import '../../core/constants/game_constants.dart';
import '../../core/utils/update_manager.dart';
import '../widgets/google_profile_button.dart';
import '../viewmodels/game_viewmodel.dart';
import '../../domain/services/config_service.dart';
import '../../domain/services/games_services_controller.dart';
import '../widgets/start/start_header.dart';
import '../widgets/start/start_actions.dart';
import '../widgets/start/recent_games.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({Key? key}) : super(key: key);

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  bool _isLoading = false;
  bool _isFirstLaunch = false;
  List<String> _recentGames = [];
  GamesServicesController? _gamesServices;
  final UpdateManager _updateManager = UpdateManager();

  @override
  void initState() {
    super.initState();

    // Configuration des animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    // Vérifier s'il s'agit du premier lancement
    _checkFirstLaunch();

    // Charger les parties récentes
    _loadRecentGames();

    // Connexion aux services Google Play
    _initGooglePlayServices();

    // Vérification des mises à jour
    _checkForUpdates();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = !prefs.containsKey('has_launched');

    setState(() {
      _isFirstLaunch = isFirstLaunch;
    });

    if (isFirstLaunch) {
      // Marquer que l'application a été lancée
      await prefs.setBool('has_launched', true);
    }
  }

  Future<void> _loadRecentGames() async {
    final configService = Provider.of<ConfigService>(context, listen: false);
    setState(() {
      _recentGames = configService.getRecentGames();
    });
  }

  Future<void> _initGooglePlayServices() async {
    try {
      _gamesServices = GamesServicesController();
      await _gamesServices?.initialize();
    } catch (e) {
      print('Impossible de se connecter aux services Google Play: $e');
    }
  }

  Future<void> _checkForUpdates() async {
    await _updateManager.initialize();
    if (mounted) {
      await _updateManager.checkForUpdates(context);
    }
  }

  Future<void> _startNewGame() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gameViewModel = Provider.of<GameViewModel>(context, listen: false);

      // Générer un nom unique pour la sauvegarde
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final gameName = '${GameConstants.DEFAULT_GAME_NAME_PREFIX}_$timestamp';

      // Démarrer une nouvelle partie
      final success = await gameViewModel.startNewGame(gameName);

      if (success && mounted) {
        if (_isFirstLaunch) {
          // Rediriger vers l'écran d'introduction pour le premier lancement
          Navigator.pushReplacementNamed(context, '/introduction');
        } else {
          // Rediriger vers l'écran principal
          Navigator.pushReplacementNamed(context, AppRouter.mainRoute);
        }
      } else {
        _showErrorSnackBar("Impossible de démarrer une nouvelle partie");
      }
    } catch (e) {
      _showErrorSnackBar("Erreur: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _continueMostRecentGame() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_recentGames.isEmpty) {
        _showErrorSnackBar("Aucune sauvegarde récente disponible");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final gameViewModel = Provider.of<GameViewModel>(context, listen: false);
      final success = await gameViewModel.loadGame(_recentGames[0]);

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.mainRoute);
      } else {
        _showErrorSnackBar("Impossible de charger la partie");
      }
    } catch (e) {
      _showErrorSnackBar("Erreur: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<GameViewModel>(
        builder: (context, gameViewModel, child) {
          if (gameViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (gameViewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    gameViewModel.error!,
                    style: Theme.of(context).textTheme.headline6,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: gameViewModel.retry,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  StartHeader(),
                  SizedBox(height: 24),
                  StartActions(),
                  SizedBox(height: 24),
                  RecentGames(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}