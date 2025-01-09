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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paperclip Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const StartScreen(),
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
  final List<String> _titles = [
    'Production',
    'Marché',
    'Améliorations',
  ];

  final List<Widget> _screens = [
    const ProductionScreen(),
    const MarketScreen(),
    const UpgradesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameState>().startAutoSave(context);
    });
  }

  String _formatTimePlayed(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours}h ${minutes}m ${remainingSeconds}s';
  }

  void _showSettingsMenu(BuildContext context) {
    final gameState = context.read<GameState>();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Version'),
                subtitle: Text(UpdateManager.CURRENT_VERSION),
                onTap: () => _showChangelogDialog(context),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Partie sauvegardée')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('Charger une partie'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SaveLoadScreen()),
                  );
                },
              ),
            ],
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
                'Derniers changements :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(UpdateManager.getChangelogForVersion(UpdateManager.CURRENT_VERSION)),
              const Divider(),
              const Text(
                'Historique complet :',
                style: TextStyle(fontWeight: FontWeight.bold),
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
          title: const Text('Informations sur les niveaux'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Niveau actuel : ${levelSystem.level}'),
              const SizedBox(height: 16),
              const Text(
                'Paliers d\'améliorations:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...levelSystem.levelUnlocks.entries.map((entry) {
                return ListTile(
                  leading: Icon(
                    levelSystem.level >= entry.key ? Icons.check_circle : Icons.lock,
                    color: levelSystem.level >= entry.key ? Colors.green : Colors.grey,
                  ),
                  title: Text('Niveau ${entry.key}: ${entry.value}'),
                );
              }).toList()
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

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Paperclip - ${_titles[_selectedIndex]}',
              style: const TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: Colors.deepPurple[700],
            leadingWidth: 80, // Pour décaler le bouton vers le centre
            leading: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    _showLevelInfoDialog(context, gameState.levelSystem);
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          value: gameState.levelSystem.experienceProgress,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ),
                      Text(
                        '${gameState.levelSystem.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                iconSize: 32,
                tooltip: 'Paramètres',
                onPressed: () => _showSettingsMenu(context),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: _screens[_selectedIndex]),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.factory),
                label: 'Production',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart),
                label: 'Marché',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.upgrade),
                label: 'Améliorations',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}