import 'package:flutter/material.dart';
import 'package:your_project_name/domain/entities/player.dart';
import 'package:paperclip2/presentation/screens/main_screen.dart' as main_screen;
import 'package:paperclip2/presentation/screens/save_load_screen.dart' as save_load_screen;
import 'package:paperclip2/services/games_services_controller.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/presentation/widgets/google_profile_button.dart';
import '../utils/update_manager.dart';
import 'introduction_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _isLoading = false;
  String? _lastSaveInfo;

  // Variables pour la gestion de la connexion Google Play
  bool _isCheckingSignIn = true;
  bool _isSignedIn = false;
  String? _playerName;

  @override
  void initState() {
    super.initState();
    _loadLastSaveInfo();
    _checkGoogleSignIn();
  }

  Future<void> _loadLastSaveInfo() async {
    final lastSave = await SaveManager.getLastSave();
    if (lastSave != null) {
      setState(() {
        _lastSaveInfo = 'Dernière partie : ${lastSave.name}';
      });
    }
  }

  Future<String?> _getPlayerName() async {
    return null;
  }

  Future<void> _signInToGooglePlay() async {
    final gamesServices = GamesServicesController();

    try {
      await gamesServices.signIn();
      final isSignedIn = await gamesServices.isSignedIn();

      if (isSignedIn) {
        final playerName = await _getPlayerName();

        if (mounted) {
          setState(() {
            _isSignedIn = true;
            _playerName = playerName;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion réussie à Google Play Games'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la connexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCloudSave() async {
    final gameState = context.read<GameState>();

    try {
      await gameState.showCloudSaveSelector();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkGoogleSignIn() async {
    final gamesServices = GamesServicesController();

    setState(() {
      _isCheckingSignIn = true;
    });

    try {
      final isSignedIn = await gamesServices.isSignedIn();

      if (mounted) {
        setState(() {
          _isSignedIn = isSignedIn;
          _playerName = isSignedIn ? "Joueur Google Play" : null;
          _isCheckingSignIn = false;
        });
      }
    } catch (e) {
      print('Erreur lors de la vérification de connexion: $e');
      if (mounted) {
        setState(() {
          _isCheckingSignIn = false;
        });
      }
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
            MaterialPageRoute(builder: (context) => const main_screen.MainScreen()),
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

  void _showNewGameDialog(BuildContext context) {
    final controller = TextEditingController(
      text: 'Partie ${DateTime.now().day}/${DateTime.now().month}',
    );

    GameMode selectedMode = GameMode.INFINITE;
    bool syncToCloud = _isSignedIn;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouvelle Partie'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la partie',
                    hintText: 'Entrez un nom pour votre partie',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Mode de jeu',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                RadioListTile<GameMode>(
                  title: const Text('Mode Infini'),
                  subtitle: const Text('Jouez sans limites à votre rythme'),
                  value: GameMode.INFINITE,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    setState(() => selectedMode = value!);
                  },
                  activeColor: Colors.deepPurple,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                ),
                RadioListTile<GameMode>(
                  title: const Text('Mode Compétitif'),
                  subtitle: const Text('Obtenez le meilleur score avant la crise'),
                  value: GameMode.COMPETITIVE,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    setState(() => selectedMode = value!);
                  },
                  activeColor: Colors.deepPurple,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                ),
                if (selectedMode == GameMode.COMPETITIVE)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber, width: 1),
                    ),
                    child: Column(
                      children: [
                        // ...existing code...
                      ],
                    ),
                  ),
                if (_isSignedIn)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SwitchListTile(
                      activeColor: Colors.deepPurple,
                      // ...existing code...
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Cette action créera une nouvelle sauvegarde',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
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
                    const SnackBar(
                      content: Text('Veuillez entrer un nom pour la partie'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final exists = await SaveManager.saveExists(gameName);
                if (exists) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Une partie avec ce nom existe déjà'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    await context.read<GameState>().startNewGame(gameName, mode: selectedMode, syncToCloud: syncToCloud);

                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const main_screen.MainScreen()),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la création de la partie: $e'),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'v${UpdateManager.CURRENT_VERSION}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_isSignedIn && _playerName != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Connecté en tant que $_playerName',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
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
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _lastSaveInfo!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  onPressed: _isLoading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (context) => const save_load_screen.SaveLoadScreen())),
                  icon: Icons.folder_open,
                  label: 'Charger une partie',
                  color: Colors.deepPurple[500],
                  textColor: Colors.white,
                ),
                if (_isSignedIn)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: _buildMenuButton(
                      onPressed: _isLoading ? null : _loadCloudSave,
                      icon: Icons.cloud_download,
                      label: 'Charger depuis le cloud',
                      color: Colors.deepPurple[400],
                      textColor: Colors.white,
                    ),
                  ),
                if (!_isSignedIn && !_isCheckingSignIn)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: _buildMenuButton(
                      onPressed: _isLoading ? null : _signInToGooglePlay,
                      icon: Icons.login,
                      label: 'Se connecter à Google Play',
                      color: Colors.deepPurple[300],
                      textColor: Colors.white,
                    ),
                  ),
                if (_isLoading) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
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
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: textColor,
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: onPressed != null ? 3 : 0,
          disabledBackgroundColor: color?.withOpacity(0.6),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: textColor?.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}






