// lib/presentation/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../app/router.dart';
import '../../core/constants/imports.dart';
import '../../core/constants/game_constants.dart';
import '../viewmodels/game_viewmodel.dart';
import '../viewmodels/production_viewmodel.dart';
import '../viewmodels/market_viewmodel.dart';
import '../widgets/production_button.dart';
import '../widgets/resource_widgets.dart';
import '../widgets/notification_widgets.dart';
import '../widgets/level_widgets.dart';
import '../widgets/competitive_mode_indicator.dart';
import '../../domain/services/event_manager_service.dart';
import '../../domain/services/background_music_service.dart';
import '../widgets/main/main_header.dart';
import '../widgets/main/production_controls.dart';
import '../widgets/main/market_controls.dart';
import '../widgets/main/market_stats.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late Timer _gameLoopTimer;
  final ValueNotifier<bool> _isMusicPlaying = ValueNotifier<bool>(false);
  EventManager? _eventManager;
  BackgroundMusicService? _musicService;
  NotificationEvent? _activeNotification;

  @override
  void initState() {
    super.initState();

    // Initialisation du gestionnaire d'événements
    _eventManager = Provider.of<EventManager>(context, listen: false);
    _eventManager?.notificationStream.listen(_handleNotification);

    // Initialisation de la musique de fond
    _initializeBackgroundMusic();

    // Démarrage de la boucle de jeu
    _startGameLoop();

    // Vérifier les sauvegardes automatiques
    _scheduleAutoSave();
  }

  @override
  void dispose() {
    _gameLoopTimer.cancel();
    _isMusicPlaying.dispose();
    super.dispose();
  }

  void _initializeBackgroundMusic() async {
    _musicService = Provider.of<BackgroundMusicService>(context, listen: false);
    await _musicService?.initialize();
    // Démarrer la musique après un court délai
    Future.delayed(const Duration(seconds: 1), () {
      _musicService?.play();
      _isMusicPlaying.value = true;
    });
  }

  void _handleNotification(NotificationEvent notification) {
    setState(() {
      _activeNotification = notification;
    });

    // Auto-dismiss notification after duration
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _activeNotification == notification) {
        setState(() {
          _activeNotification = null;
        });
      }
    });
  }

  void _dismissNotification() {
    setState(() {
      _activeNotification = null;
    });
  }

  void _navigateToScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _startGameLoop() {
    _gameLoopTimer = Timer.periodic(GameConstants.GAME_LOOP_INTERVAL, _gameTick);
  }

  void _gameTick(Timer timer) {
    final productionViewModel = Provider.of<ProductionViewModel>(context, listen: false);
    final gameViewModel = Provider.of<GameViewModel>(context, listen: false);

    // Logique du tick de jeu
    productionViewModel.processTick();

    // Mise à jour du temps de jeu
    if (gameViewModel.gameState != null) {
      gameViewModel.incrementPlayTime(GameConstants.GAME_LOOP_INTERVAL.inSeconds);
    }
  }

  void _scheduleAutoSave() {
    Timer.periodic(GameConstants.AUTO_SAVE_INTERVAL, (timer) {
      final gameViewModel = Provider.of<GameViewModel>(context, listen: false);

      if (gameViewModel.gameState != null) {
        gameViewModel.autoSaveGame();

        // Notification subtile
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sauvegarde automatique effectuée'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _toggleMusic() {
    if (_musicService != null) {
      if (_musicService!.isPlaying) {
        _musicService!.pause();
        _isMusicPlaying.value = false;
      } else {
        _musicService!.play();
        _isMusicPlaying.value = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paperclip Factory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // TODO: Implémenter la sauvegarde
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Ouvrir les paramètres
            },
          ),
        ],
      ),
      body: Consumer<GameViewModel>(
        builder: (context, gameViewModel, child) {
          if (gameViewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (gameViewModel.error != null) {
            return Center(
              child: Text(
                gameViewModel.error!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                MainHeader(),
                SizedBox(height: 24),
                ProductionControls(),
                SizedBox(height: 24),
                MarketControls(),
                SizedBox(height: 24),
                MarketStats(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BottomNavigationItem extends BottomNavigationBarItem {
  const BottomNavigationItem({
    required IconData icon,
    String? label,
  }) : super(
    icon: Icon(icon),
    label: label,
  );
}