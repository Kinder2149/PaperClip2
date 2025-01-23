// lib/screens/main_screen.dart - Partie 1

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports des modèles
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../models/event_system.dart';
import '../models/progression_system.dart';

// Imports des services
import '../services/save_manager.dart';
import '../services/background_music.dart';

// Imports des widgets
import '../widgets/level_widgets.dart';
import '../widgets/resource_widgets.dart';
import '../widgets/notification_widgets.dart';
import '../widgets/chart_widgets.dart';

// Imports des écrans
import 'production_screen.dart';
import 'market_screen.dart';
import 'upgrades_screen.dart';
import 'event_log_screen.dart';
import 'save_load_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<String> _titles = ['Production', 'Marché', 'Améliorations'];
  final List<Widget> _screens = [
    const ProductionScreen(),
    const MarketScreen(),
    const UpgradesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _playBackgroundMusic();
  }

  Future<void> _initializeGame() async {
    final gameState = context.read<GameState>();
    await Future.delayed(Duration.zero);
    gameState.setContext(context);
  }

  Future<void> _playBackgroundMusic() async {
    final backgroundMusicService = context.read<BackgroundMusicService>();
    await backgroundMusicService.initialize();
    await backgroundMusicService.play();
  }

  Future<void> _toggleMusic() async {
    final backgroundMusicService = context.read<BackgroundMusicService>();
    if (backgroundMusicService.isPlaying) {
      await backgroundMusicService.pause();
    } else {
      await backgroundMusicService.play();
    }
    setState(() {});
  }

  @override
  void dispose() {
    final backgroundMusicService = context.read<BackgroundMusicService>();
    backgroundMusicService.dispose();
    super.dispose();
  }

  String _formatTimePlayed(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours}h ${minutes}m ${remainingSeconds}s';
  }
  // lib/screens/main_screen.dart - Partie 2

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final backgroundMusicService = context.watch<BackgroundMusicService>();
        return Scaffold(
          appBar: AppBar(
            title: Text(_titles[_selectedIndex], style: const TextStyle(color: Colors.white)),
            centerTitle: true,
            backgroundColor: Colors.deepPurple[700],
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildLevelIndicator(gameState.levelSystem),
            ),
            actions: [
              _buildNotificationButton(),
              IconButton(
                icon: Icon(
                  backgroundMusicService.isPlaying ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                ),
                onPressed: _toggleMusic,
                tooltip: 'Activer/Désactiver la musique',
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => _showSettingsMenu(context),
                tooltip: 'Paramètres',
              ),
            ],
          ),
          body: Stack(
            children: [
              _screens[_selectedIndex],
              const EventNotificationOverlay(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            destinations: _buildNavigationDestinations(gameState.getVisibleScreenElements()),
          ),
        );
      },
    );
  }

  List<NavigationDestination> _buildNavigationDestinations(Map<String, bool> visibleScreens) {
    final List<NavigationDestination> destinations = [];

    // Production toujours visible
    destinations.add(const NavigationDestination(
      icon: Icon(Icons.factory_outlined),
      selectedIcon: Icon(Icons.factory),
      label: 'Production',
    ));

    if (visibleScreens['market'] == true) {
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.shopping_cart_outlined),
        selectedIcon: Icon(Icons.shopping_cart),
        label: 'Marché',
      ));
    }

    if (visibleScreens['upgrades'] == true) {
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.upgrade_outlined),
        selectedIcon: Icon(Icons.upgrade),
        label: 'Améliorations',
      ));
    }

    return destinations;
  }

  Widget _buildLevelIndicator(LevelSystem levelSystem) {
    return GestureDetector(
      onTap: () => _showLevelInfoDialog(context, levelSystem),
      child: Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: levelSystem.experienceProgress,
                backgroundColor: Colors.grey[700],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                strokeWidth: 3,
              ),
            ),
            Text(
              '${levelSystem.level}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EventLogScreen()),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Consumer<GameState>(
            builder: (context, gameState, child) {
              final notificationCount = EventManager.getEvents()
                  .where((event) => event.importance >= EventImportance.HIGH)
                  .length;

              if (notificationCount == 0) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$notificationCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAboutInfo(BuildContext context) {
    final now = DateTime(2025, 1, 23, 15, 26, 21); // Current timestamp
    final notification = NotificationEvent(
      title: 'À propos',
      description: 'Version ${GameConstants.VERSION}',
      detailedDescription: """
PaperClip Game
Version ${GameConstants.VERSION}

Développé avec ❤️ par ${'Kinder2149'}

Fonctionnalités:
• Production de trombones
• Gestion du marché
• Système d'améliorations
• Événements dynamiques

Dernière mise à jour: ${now.toIso8601String()}
""",
      icon: Icons.info,
      priority: NotificationPriority.LOW,
      additionalData: {
        'Version': GameConstants.VERSION,
        'Développeur': 'Kinder2149',
        'Date de mise à jour': now.toIso8601String(),
      },
      canBeSuppressed: false,
    );

    NotificationManager.showGameNotification(
      context,
      event: notification,
    );
  }

  void _showSettingsMenu(BuildContext context) {
    final gameState = context.read<GameState>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: Text('Version ${GameConstants.VERSION}'),
                onTap: () => _showAboutInfo(context),
              ),
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Temps de jeu'),
                subtitle: Text(_formatTimePlayed(gameState.totalTimePlayed)),
              ),
              ListTile(
                leading: const Icon(Icons.save),
                title: const Text('Sauvegarder'),
                onTap: () async {
                  await gameState.saveGame();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('Charger'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SaveLoadScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}