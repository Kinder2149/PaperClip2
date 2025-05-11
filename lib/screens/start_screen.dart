// lib/screens/start_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../utils/update_manager.dart';
import 'package:provider/provider.dart';
import '../services/save/save_system.dart';


import 'save_load_screen.dart';
import 'introduction_screen.dart';
import 'main_screen.dart';
import '../main.dart';
import '../services/games_services_controller.dart';
import '../widgets/google_profile_button.dart';
import '../services/user/user_manager.dart';
import '../dialogs/nickname_dialog.dart';
import 'settings_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late SaveSystem _saveSystem;
  bool _isLoading = false;
  String? _lastSaveInfo;

  // Variables pour la gestion de la connexion Google Play
  bool _isCheckingSignIn = true;
  bool _isSignedIn = false;
  String? _playerName;

  @override
  void initState() {
    super.initState();
    _saveSystem = Provider.of<SaveSystem>(context, listen: false);
  }


  Future<void> _loadLastSaveInfo() async {
    final lastSave = await _saveSystem.listSaves().then((saves) => saves.isNotEmpty ? saves.first : null);
    if (lastSave != null) {
      setState(() {
        _lastSaveInfo = 'Dernière partie : ${lastSave.name}';
      });
    }
  }

  // Récupérer le nom du joueur
  Future<String?> _getPlayerName() async {
    final userManager = Provider.of<UserManager>(context, listen: false);
    await userManager.initialize();
    return userManager.currentProfile?.displayName;
  }

  // Se connecter à Google Play Games
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

  // Charger une sauvegarde depuis le cloud
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
    final userManager = Provider.of<UserManager>(context, listen: false);

    setState(() {
      _isCheckingSignIn = true;
    });

    try {
      final isSignedIn = await gamesServices.isSignedIn();
      await userManager.initialize();
      final playerName = userManager.currentProfile?.displayName;

      if (mounted) {
        setState(() {
          _isSignedIn = isSignedIn;
          _playerName = playerName;
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
      final lastSave = await _saveSystem.listSaves().then((saves) => saves.isNotEmpty ? saves.first : null);
      if (lastSave != null) {
        await context.read<GameState>().loadGame(lastSave.name);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
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

  void _showNicknameDialog() {
    final userManager = Provider.of<UserManager>(context, listen: false);
    final currentProfile = userManager.currentProfile;

    showDialog(
      context: context,
      builder: (context) => NicknameDialog(
        initialNickname: currentProfile?.displayName,
        onNicknameSet: (nickname) {
          setState(() {
            _playerName = nickname;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Surnom défini : $nickname'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showNewGameDialog(BuildContext context) {
    final controller = TextEditingController(
      text: 'Partie ${DateTime.now().day}/${DateTime.now().month}',
    );

    // Variable pour suivre le mode sélectionné
    GameMode selectedMode = GameMode.INFINITE;
    bool syncToCloud = _isSignedIn; // Activé par défaut si connecté

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

                // Option pour le mode infini
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

                // Option pour le mode compétitif
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
                  FutureBuilder<bool>(
                    future: UserManager().canCreateCompetitiveSave(),
                    builder: (context, snapshot) {
                      bool canCreate = snapshot.data ?? true;

                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: canCreate ? Colors.amber.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: canCreate ? Colors.amber : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              canCreate ? '🏆 Mode Compétitif' : '⚠️ Limite atteinte',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: canCreate ? Colors.amber : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              canCreate
                                  ? 'Optimisez votre production jusqu\'à la crise mondiale de métal pour obtenir le meilleur score. Comparez vos résultats avec vos amis !'
                                  : 'Vous avez atteint la limite de 3 parties compétitives. Veuillez en supprimer une pour en créer une nouvelle.',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                // Option de synchronisation cloud (uniquement si connecté)
                if (_isSignedIn)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SwitchListTile(
                      title: const Text('Synchroniser avec le cloud'),
                      subtitle: const Text('Sauvegardez votre partie sur Google Play Games'),
                      value: syncToCloud,
                      onChanged: (value) {
                        setState(() => syncToCloud = value);
                      },
                      activeColor: Colors.deepPurple,
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
                        content: Text('Le nom ne peut pas être vide')),
                  );
                  return;
                }

                final exists = await _saveSystem.exists(gameName);
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

                // Vérifier si l'utilisateur peut créer une partie compétitive
                if (selectedMode == GameMode.COMPETITIVE) {
                  final userManager = context.read<UserManager>();
                  if (!await userManager.canCreateCompetitiveSave()) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Limite de parties compétitives atteinte (3 maximum)'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    // Utiliser le mode sélectionné lors de la création
                    await context.read<GameState>().startNewGame(gameName, mode: selectedMode, syncToCloud: syncToCloud);

                    if (context.mounted) {
                      // Créer une classe intermédiaire pour la navigation
                      final introScreen = IntroductionScreen(
                        showSkipButton: true,
                        isCompetitiveMode: selectedMode == GameMode.COMPETITIVE,
                        onStart: () {
                          // Utilise le navigatorKey global plutôt que le context
                          navigatorKey.currentState?.pushReplacement(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userManager = Provider.of<UserManager>(context);
    final hasProfile = userManager.hasProfile;
    final profileName = userManager.currentProfile?.displayName;

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
                // Logo et titre (réduits)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.link,
                    size: 80, // Taille réduite
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16), // Espace réduit
                const Text(
                  'ClipFactory Empire',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36, // Taille réduite
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                    letterSpacing: 2, // Espacement réduit
                  ),
                ),
                const SizedBox(height: 4), // Espace réduit
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'v${GameConstants.VERSION}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton de profil/connexion Google
                if (_isCheckingSignIn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Vérification du profil...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (hasProfile && profileName != null)
                  GestureDetector(
                    onTap: _showNicknameDialog,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.deepPurple[300],
                            child: Text(
                              profileName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                profileName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (_isSignedIn)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Connecté à Google',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.edit,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _signInToGooglePlay,
                    icon: const Icon(Icons.games),
                    label: const Text('Se connecter à Google Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Boutons du menu principal
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _lastSaveInfo!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  )
                      : null,
                ),

                const SizedBox(height: 16),

                _buildMenuButton(
                  onPressed: _isLoading ? null : () =>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SaveLoadScreen()),
                      ),
                  icon: Icons.folder_open,
                  label: 'Charger une partie',
                  color: Colors.deepPurple[500],
                  textColor: Colors.white,
                ),

                const SizedBox(height: 16),

                // Nouveau bouton Paramètres
                _buildMenuButton(
                  onPressed: _isLoading ? null : () =>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()),
                      ),
                  icon: Icons.settings,
                  label: 'Paramètres',
                  color: Colors.grey[800],
                  textColor: Colors.white,
                ),

                if (_isLoading) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Chargement...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
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
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
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