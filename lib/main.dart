import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './screens/start_screen.dart';
import './screens/save_load_screen.dart';
import './screens/production_screen.dart';
import './screens/market_screen.dart';
import './screens/upgrades_screen.dart';
import './models/game_state.dart';
import './utils/update_manager.dart';
import './models/level_system.dart';
import './services/save_manager.dart';
import './services/background_music.dart';
import './screens/event_log_screen.dart';
import 'widgets/GlobalNotificationOverlay.dart';


void main() {
  runApp(
    GlobalNotificationOverlay(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => GameState()),
          Provider(create: (_) => BackgroundMusicService()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => BackgroundMusicService()),
      ],
      child: MaterialApp(
        title: 'Paperclip Game',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
        ),
        home: const StartScreen(),
      ),
    );
  }
}

class MainGame extends StatefulWidget {
  const MainGame({super.key});

  @override
  State<MainGame> createState() => _MainGameState();
}

class _MainGameState extends State<MainGame> {
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
    await Future.delayed(Duration.zero); // Permet d'avoir le contexte
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

  Future<void> _saveGame(BuildContext context, GameState gameState) async {
    try {
      if (gameState.gameName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Aucun nom de partie défini'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await SaveManager.saveGame(gameState, gameState.gameName!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partie sauvegardée avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showSettingsMenu(BuildContext context) {
    final gameState = context.read<GameState>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
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
                  title: const Text('Version'),
                  subtitle: Text(UpdateManager.CURRENT_VERSION),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _showChangelogDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('Temps de jeu'),
                  subtitle: Text(_formatTimePlayed(gameState.totalTimePlayed)),
                ),
                ListTile(
                  leading: const Icon(Icons.save),
                  title: const Text('Sauvegarder'),
                  subtitle: const Text('Sauvegarder la partie en cours'),
                  onTap: () => _saveGame(context, gameState),
                ),
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: const Text('Charger une partie'),
                  subtitle: const Text('Gérer les sauvegardes'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SaveLoadScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangelogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Version ${UpdateManager.CURRENT_VERSION}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Dernières mises à jour :',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(UpdateManager.getChangelogForVersion(UpdateManager.CURRENT_VERSION)),
              const Divider(height: 24),
              const Text(
                'Historique des versions :',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(UpdateManager.getFullChangelog()),
            ],
          ),
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

  void _showLevelInfoDialog(BuildContext context, LevelSystem levelSystem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.stars, color: Colors.amber),
              const SizedBox(width: 8),
              Text('Niveau ${levelSystem.level}'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: levelSystem.experienceProgress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'XP: ${(levelSystem.experience).toStringAsFixed(0)} / ${levelSystem.experienceForNextLevel.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bonus actuels :',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              _buildBonusItem(
                'Production',
                '+${((levelSystem.productionMultiplier - 1) * 100).toStringAsFixed(1)}%',
                Icons.precision_manufacturing,
              ),
              _buildBonusItem(
                'Ventes',
                '+${((levelSystem.salesMultiplier - 1) * 100).toStringAsFixed(1)}%',
                Icons.trending_up,
              ),
              const Divider(height: 24),
              const Text(
                'Paliers de niveau :',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              ...levelSystem.levelUnlocks.entries.map((entry) {
                bool isUnlocked = levelSystem.level >= entry.key;
                return ListTile(
                  leading: Icon(
                    isUnlocked ? Icons.check_circle : Icons.lock,
                    color: isUnlocked ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    'Niveau ${entry.key}',
                    style: TextStyle(
                      color: isUnlocked ? Colors.black : Colors.grey,
                      fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    entry.value,
                    style: TextStyle(
                      color: isUnlocked ? Colors.black87 : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBonusItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
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
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _titles[_selectedIndex],
              style: const TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: Colors.deepPurple[700],
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildLevelIndicator(gameState.levelSystem),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EventLogScreen()),
                      );
                    },
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Consumer<GameState>(
                      builder: (context, gameState, child) {
                        final notificationCount = EventManager.getEvents()
                            .where((event) => event.importance >= EventImportance.HIGH)
                            .length;

                        return notificationCount > 0
                            ? Container(
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
                        )
                            : const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
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
          body: _screens[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.factory_outlined),
                selectedIcon: Icon(Icons.factory),
                label: 'Production',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart),
                label: 'Marché',
              ),
              NavigationDestination(
                icon: Icon(Icons.upgrade_outlined),
                selectedIcon: Icon(Icons.upgrade),
                label: 'Améliorations',
              ),
            ],
          ),
        );
      },
    );
  }
}