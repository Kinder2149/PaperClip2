import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './screens/start_screen.dart';
import './screens/production_screen.dart';
import './screens/market_screen.dart';
import './screens/upgrades_screen.dart';
import './models/game_state.dart';
import './utils/update_manager.dart';

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
                onTap: () => _showSaveDialog(context, gameState),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSaveDialog(BuildContext context, GameState gameState) {
    final TextEditingController nameController = TextEditingController(
        text: 'save_${DateTime.now().toString().split('.')[0].replaceAll(RegExp(r'[^0-9]'), '')}'
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sauvegarder la partie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la sauvegarde',
                hintText: 'Entrez un nom pour votre sauvegarde',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Dossier de sauvegarde :\n${gameState.customSaveDirectory ?? "Dossier par défaut"}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await gameState.exportSave(nameController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sauvegarde créée avec succès')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la sauvegarde'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Paperclip - ${_titles[_selectedIndex]}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            iconSize: 32,
            onPressed: () => _showSettingsMenu(context),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.factory),
            label: 'Production',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upgrade),
            label: 'Upgrades',
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
  }
}