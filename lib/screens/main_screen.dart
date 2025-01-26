// lib/screens/main_screen.dart

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
import 'start_screen.dart';
import 'introduction_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Corriger l'ordre des écrans
    _screens = [
      const ProductionScreen(),
      const MarketScreen(),        // Index 1
      const UpgradesScreen(),      // Index 2
    ];
    // Retirer PlaceholderLockedScreen de la liste initiale
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

  Widget _getCurrentScreen(Map<String, bool> visibleScreens) {
    switch (_selectedIndex) {
      case 0:
        return _screens[0];  // Production toujours visible
      case 1:
      // Vérifier si le marché est débloqué
        return visibleScreens['market'] == true
            ? _screens[1]
            : const PlaceholderLockedScreen();
      case 2:
      // Vérifier si les améliorations sont débloquées
        return visibleScreens['upgradesSection'] == true
            ? _screens[2]
            : const PlaceholderLockedScreen();
      default:
        return _screens[0];
    }
  }

  List<NavigationDestination> _buildNavigationDestinations(Map<String, bool> visibleScreens) {
    return [
      const NavigationDestination(
        icon: Icon(Icons.factory_outlined),
        selectedIcon: Icon(Icons.factory),
        label: 'Production',
      ),
      NavigationDestination(
        icon: Icon(visibleScreens['market'] == true
            ? Icons.shopping_cart_outlined
            : Icons.lock_outline),
        selectedIcon: Icon(visibleScreens['market'] == true
            ? Icons.shopping_cart
            : Icons.lock),
        label: visibleScreens['market'] == true
            ? 'Marché'
            : 'Niveau ${GameConstants.MARKET_UNLOCK_LEVEL}',
      ),
      NavigationDestination(
        icon: Icon(visibleScreens['upgradesSection'] == true
            ? Icons.upgrade_outlined
            : Icons.lock_outline),
        selectedIcon: Icon(visibleScreens['upgradesSection'] == true
            ? Icons.upgrade
            : Icons.lock),
        label: visibleScreens['upgradesSection'] == true
            ? 'Améliorations'
            : 'Niveau ${GameConstants.UPGRADES_UNLOCK_LEVEL}',
      ),
    ];
  }
  Future<void> _saveGame(BuildContext context) async {
    final gameState = context.read<GameState>();
    if (!gameState.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Le jeu n\'est pas initialisé'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final gameName = gameState.gameName;
      if (gameName == null || gameName.isEmpty) {
        throw SaveError('NO_NAME', 'Aucun nom de partie défini');
      }

      await SaveManager.saveGame(gameState, gameName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partie sauvegardée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _showLevelInfoDialog(BuildContext context, LevelSystem levelSystem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Niveau ${levelSystem.level}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('XP: ${levelSystem.experience}/${levelSystem.experienceForNextLevel}'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: levelSystem.experienceProgress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 16),
            Text('Multiplicateur: x${levelSystem.productionMultiplier.toStringAsFixed(1)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final backgroundMusicService = context.watch<BackgroundMusicService>();
        final visibleScreens = gameState.getVisibleScreenElements();

        return Scaffold(
          appBar: AppBar(
            title: Text(_getTitleForIndex(_selectedIndex),
                style: const TextStyle(color: Colors.white)),
            centerTitle: true,
            backgroundColor: Colors.deepPurple[700],
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildLevelIndicator(gameState.level),
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
              _getCurrentScreen(visibleScreens),
              Consumer<EventManager>(
                builder: (context, eventManager, _) {
                  final notification = eventManager.notificationStream.value;
                  if (notification == null) return const SizedBox.shrink();
                  return AnimatedNotificationOverlay(
                    event: notification,
                    onDismiss: () {
                      eventManager.notificationStream.value = null;
                    },
                  );
                },
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            destinations: _buildNavigationDestinations(visibleScreens),
          ),
        );
      },
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Production';
      case 1:
        return 'Marché';
      case 2:
        return 'Améliorations';
      default:
        return 'PaperClip Game';
    }
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
    return ValueListenableBuilder<int>(
      valueListenable: EventManager.instance.unreadCount,
      builder: (context, unreadCount, child) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventLogScreen()),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
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
                  if (gameState.gameName != null) {
                    await gameState.saveGame(gameState.gameName!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Partie sauvegardée'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Erreur: Aucun nom de partie défini'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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

  void _showAboutInfo(BuildContext context) {
    final notification = NotificationEvent(
      title: 'À propos',
      description: 'Version ${GameConstants.VERSION}',
      detailedDescription: """
PaperClip Game
Version ${GameConstants.VERSION}

Développé avec ❤️ par Kinder2149

Fonctionnalités:
• Production de trombones
• Gestion du marché
• Système d'améliorations
• Événements dynamiques
""",
      icon: Icons.info,
      priority: NotificationPriority.LOW,
      additionalData: {
        'Version': GameConstants.VERSION,
        'Développeur': 'Kinder2149',
        'Date de mise à jour': DateTime.now().toIso8601String(),
      },
      canBeSuppressed: false,
    );

    // Utiliser EventManager au lieu de NotificationManager
    EventManager.instance.notificationStream.value = notification;

    // Ou bien si vous préférez utiliser le système d'événements
    EventManager.instance.addEvent(
      EventType.SPECIAL_ACHIEVEMENT,
      'À propos',
      description: 'Version ${GameConstants.VERSION}',
      importance: EventImportance.LOW,
    );
  }
}




// Widget pour l'écran verrouillé
class PlaceholderLockedScreen extends StatelessWidget {
  const PlaceholderLockedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Débloqué au niveau 7',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}