import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../utils/update_manager.dart';
import '../services/save_manager.dart';
import 'save_load_screen.dart';
import 'introduction_screen.dart';
import 'main_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _isLoading = false;
  String? _lastSaveInfo;

  @override
  void initState() {
    super.initState();
    _loadLastSaveInfo();
  }

  Future<void> _loadLastSaveInfo() async {
    final lastSave = await SaveManager.getLastSave();
    if (lastSave != null) {
      setState(() {
        _lastSaveInfo = 'Dernière partie : ${lastSave.name}';
      });
    }
  }

  Future<void> _continueLastGame() async {
    setState(() => _isLoading = true);
    try {
      final lastSave = await SaveManager.getLastSave();
      if (lastSave != null) {
        await context.read<GameState>().loadGame(lastSave.name);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),  // MainGame -> MainScreen
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune sauvegarde trouvée'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNewGameDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: 'Partie ${DateTime.now().day}/${DateTime.now().month}',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle Partie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nom de la partie',
                hintText: 'Entrez un nom pour votre partie',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cette action créera une nouvelle sauvegarde',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
              final gameName = controller.text.trim();
              if (gameName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le nom ne peut pas être vide')),
                );
                return;
              }

              final exists = await SaveManager.saveExists(gameName);
              if (exists) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Une partie avec ce nom existe déjà'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              if (context.mounted) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await context.read<GameState>().startNewGame(gameName);
                  if (context.mounted) {
                    // Créer une classe intermédiaire pour la navigation
                    final introScreen = IntroductionScreen(
                      showSkipButton: true,
                      onStart: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MainScreen()),
                        );
                      },
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => introScreen),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la création: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              }
            },
            child: const Text('Commencer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple[400]!,
              Colors.deepPurple[700]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icone.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Paperclip Game',
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
                Text(
                  'v${UpdateManager.CURRENT_VERSION}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                _buildMenuButton(
                  onPressed: () => _showNewGameDialog(context),
                  icon: Icons.add,
                  label: 'Nouvelle Partie',
                  color: Colors.white,
                  textColor: Colors.deepPurple[700],
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  onPressed: _isLoading ? null : _continueLastGame,
                  icon: Icons.play_arrow,
                  label: 'Continuer',
                  color: Colors.deepPurple[600],
                  textColor: Colors.white,
                  trailing: _lastSaveInfo != null
                      ? Text(
                    _lastSaveInfo!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  )
                      : null,
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  onPressed: _isLoading ? null : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SaveLoadScreen()),
                  ),
                  icon: Icons.folder_open,
                  label: 'Charger une partie',
                  color: Colors.deepPurple[500],
                  textColor: Colors.white,
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color? color,
    required Color? textColor,
    Widget? trailing,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            if (trailing != null) trailing,
          ],
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: textColor,
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          disabledBackgroundColor: color?.withOpacity(0.6),
        ),
      ),
    );
  }
}