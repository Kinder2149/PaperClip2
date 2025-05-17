// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// Import des widgets personnalisés
import '../widgets/app_bar/widget_appbar_jeu.dart';
import '../widgets/google_profile_button.dart';

// Import des modèles et services
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../services/games_services_controller.dart';
import '../services/background_music.dart';


import '../services/save/save_types.dart';
import '../services/save/save_system.dart';
import '../services/user/user_manager.dart';

// Import des écrans
import 'save_load_screen.dart';
import 'event_log_screen.dart';
import 'user_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  bool _isLoadingSync = false;

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final backgroundMusicService = Provider.of<BackgroundMusicService>(context);
    final userManager = Provider.of<UserManager>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: WidgetAppBarJeu(
        titleBuilder: (context) => const Text(
          'Paramètres',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        showLevelIndicator: false,
        showSettings: false,
        showNotifications: false,
        backgroundColor: Colors.deepPurple[700],
        elevation: 0,
        onSettingsPressed: () {
          // Action pour le bouton paramètres
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              color: Colors.deepPurple[700],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.white, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        'Configuration',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Personnalisez votre expérience de jeu',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Section Informations
            _buildSection(
              title: 'Informations',
              icon: Icons.info_outline,
              children: [
                _buildInfoTile(
                  icon: Icons.timer_outlined,
                  title: 'Temps de jeu',
                  value: gameState.formattedPlayTime,
                ),
                _buildInfoTile(
                  icon: Icons.stars_outlined,
                  title: 'Niveau',
                  value: '${gameState.level.level}',
                ),
                _buildInfoTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Trombones produits',
                  value: '${gameState.totalPaperclipsProduced}',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Section Statistiques
            _buildActionCard(
              icon: Icons.analytics,
              title: 'Statistiques',
              subtitle: 'Voir les statistiques détaillées',
              onTap: () => _showStatistics(context, gameState),
            ),

            const SizedBox(height: 16),

            // Section Profil & Connexion
            FutureBuilder<bool>(
              future: GamesServicesController().isSignedIn(),
              builder: (context, snapshot) {
                final isSignedIn = snapshot.data ?? false;

                return _buildSection(
                  title: 'Profil & Synchronisation',
                  icon: Icons.account_circle,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSignedIn ? Colors.green[100] : Colors.grey[200],
                        child: Icon(
                          isSignedIn ? Icons.check_circle : Icons.person_outline,
                          color: isSignedIn ? Colors.green[700] : Colors.grey[700],
                        ),
                      ),
                      title: Text(
                        isSignedIn
                            ? 'Connecté à Google Play Games'
                            : 'Connexion à Google Play Games',
                      ),
                      subtitle: Text(
                        isSignedIn
                            ? 'Vos parties peuvent être synchronisées'
                            : 'Connectez-vous pour sauvegarder vos parties',
                      ),
                      trailing: isSignedIn
                          ? PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 'switch') {
                            await _switchGoogleAccount();
                          } else if (value == 'profile') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const UserProfileScreen()
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person),
                                SizedBox(width: 8),
                                Text('Voir mon profil'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'switch',
                            child: Row(
                              children: [
                                Icon(Icons.switch_account),
                                SizedBox(width: 8),
                                Text('Changer de compte'),
                              ],
                            ),
                          ),
                        ],
                      )
                          : TextButton(
                        onPressed: _signInToGoogle,
                        child: const Text('Se connecter'),
                      ),
                    ),

                    if (isSignedIn) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: _isLoadingSync
                            ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2)
                        )
                            : const Icon(Icons.cloud_sync),
                        title: const Text('Synchroniser les sauvegardes'),
                        subtitle: const Text('Mettre à jour vos sauvegardes dans le cloud'),
                        onTap: _isLoadingSync ? null : () => _syncSavesToCloud(gameState, context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.cloud_download),
                        title: const Text('Charger depuis le cloud'),
                        subtitle: const Text('Sélectionner une sauvegarde cloud'),
                        onTap: () => _loadFromCloud(gameState, context),
                      ),
                    ],
                  ],
                );
              },
            ),
// Section Confidentialité
            const SizedBox(height: 16),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Paramètres de confidentialité',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            Builder(
              builder: (context) {
                final userManager = Provider.of<UserManager>(context);
                final profile = userManager.currentProfile;

                if (profile == null) {
                  return const Text('Connectez-vous pour gérer vos paramètres de confidentialité');
                }

                final privacySettings = profile.privacySettings;

                return Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Afficher le nombre de trombones'),
                      subtitle: const Text('Visible par vos amis'),
                      value: privacySettings['showTotalPaperclips'] ?? true,
                      onChanged: (value) async {
                        final updatedProfile = profile.copyWith(
                          privacySettings: {
                            ...privacySettings,
                            'showTotalPaperclips': value,
                          },
                        );
                        await userManager.updateProfile(updatedProfile);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Afficher le niveau'),
                      subtitle: const Text('Visible par vos amis'),
                      value: privacySettings['showLevel'] ?? true,
                      onChanged: (value) async {
                        final updatedProfile = profile.copyWith(
                          privacySettings: {
                            ...privacySettings,
                            'showLevel': value,
                          },
                        );
                        await userManager.updateProfile(updatedProfile);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Afficher l\'argent'),
                      subtitle: const Text('Visible par vos amis'),
                      value: privacySettings['showMoney'] ?? true,
                      onChanged: (value) async {
                        final updatedProfile = profile.copyWith(
                          privacySettings: {
                            ...privacySettings,
                            'showMoney': value,
                          },
                        );
                        await userManager.updateProfile(updatedProfile);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Afficher l\'efficacité'),
                      subtitle: const Text('Visible par vos amis'),
                      value: privacySettings['showEfficiency'] ?? true,
                      onChanged: (value) async {
                        final updatedProfile = profile.copyWith(
                          privacySettings: {
                            ...privacySettings,
                            'showEfficiency': value,
                          },
                        );
                        await userManager.updateProfile(updatedProfile);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Afficher les améliorations'),
                      subtitle: const Text('Visible par vos amis'),
                      value: privacySettings['showUpgrades'] ?? true,
                      onChanged: (value) async {
                        final updatedProfile = profile.copyWith(
                          privacySettings: {
                            ...privacySettings,
                            'showUpgrades': value,
                          },
                        );
                        await userManager.updateProfile(updatedProfile);
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Section Sauvegarde
            _buildSection(
              title: 'Sauvegarde',
              icon: Icons.save,
              children: [
                ListTile(
                  leading: const Icon(Icons.save),
                  title: const Text('Sauvegarder'),
                  subtitle: Text(
                    'Dernière sauvegarde: ${_getLastSaveTimeText(gameState)}',
                  ),
                  onTap: () => _saveGame(context, gameState),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: const Text('Charger une partie'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SaveLoadScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Section Audio
            _buildSection(
              title: 'Audio',
              icon: Icons.music_note,
              children: [
                SwitchListTile(
                  secondary: Icon(
                    backgroundMusicService.isPlaying ? Icons.volume_up : Icons.volume_off,
                  ),
                  title: const Text('Musique'),
                  value: backgroundMusicService.isPlaying,
                  onChanged: (value) => _toggleMusic(backgroundMusicService),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Section Google Play Games
            FutureBuilder<bool>(
              future: GamesServicesController().isSignedIn(),
              builder: (context, snapshot) {
                final isSignedIn = snapshot.data ?? false;

                return _buildSection(
                  title: 'Services de jeux',
                  icon: Icons.games,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.leaderboard),
                      title: const Text('Classement Général'),
                      subtitle: Text('Score global: ${gameState.totalPaperclipsProduced}'),
                      onTap: () => _showLeaderboard(gameState),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.precision_manufacturing),
                      title: const Text('Meilleurs Producteurs'),
                      subtitle: Text('Production totale: ${gameState.totalPaperclipsProduced}'),
                      onTap: () => gameState.showProductionLeaderboard(),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.attach_money),
                      title: const Text('Plus Grandes Fortunes'),
                      subtitle: Text('Argent gagné: ${gameState.statistics.getTotalMoneyEarned().toInt()}'),
                      onTap: () => gameState.showBankerLeaderboard(),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.emoji_events),
                      title: const Text('Succès'),
                      subtitle: const Text('Voir vos accomplissements'),
                      onTap: () => _showAchievements(),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text('Synchroniser les scores'),
                      subtitle: const Text('Mettre à jour tous les classements'),
                      onTap: () => _updateLeaderboard(gameState, context),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Section À propos
            _buildSection(
              title: 'À propos',
              icon: Icons.info,
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: Text('Version ${GameConstants.VERSION}'),
                  onTap: () => _showAboutInfo(context),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${GameConstants.APP_NAME}'),
                      const SizedBox(height: 8),
                      const Text('Un jeu de gestion incrémentale de production de trombones.'),
                      const SizedBox(height: 8),
                      const Text('Développé avec ❤️ par Kinder2149'),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Fonction utilitaire pour créer une section
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: Colors.deepPurple[700], size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.deepPurple[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  // Widget pour afficher une carte d'action
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.deepPurple[700]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget pour afficher une tuile d'information
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes d'action
  void _toggleMusic(BackgroundMusicService musicService) async {
    if (musicService.isPlaying) {
      await musicService.pause();
    } else {
      await musicService.play();
    }
    setState(() {});
  }

  String _getLastSaveTimeText(GameState gameState) {
    final lastSave = gameState.lastSaveTime;
    if (lastSave == null) return 'Jamais';

    final now = DateTime.now();
    final difference = now.difference(lastSave);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    }
    return '${lastSave.day}/${lastSave.month} ${lastSave.hour}:${lastSave.minute}';
  }

  Future<void> _saveGame(BuildContext context, GameState gameState) async {
    try {
      setState(() => _isLoading = true);

      if (gameState.gameName == null) {
        throw SaveError('NO_NAME', 'Aucun nom de partie défini');
      }

      await gameState.saveGame(gameState.gameName!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partie sauvegardée'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de sauvegarde: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncSavesToCloud(GameState gameState, BuildContext context) async {
    if (_isLoadingSync) return;

    try {
      setState(() => _isLoadingSync = true);

      final success = await gameState.syncSavesToCloud();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success ? 'Synchronisation réussie' : 'Échec de la synchronisation'
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSync = false);
      }
    }
  }

  Future<void> _loadFromCloud(GameState gameState, BuildContext context) async {
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

  Future<void> _signInToGoogle() async {
    try {
      setState(() => _isLoading = true);

      final gamesServices = GamesServicesController();
      await gamesServices.signIn();

      setState(() {});
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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _switchGoogleAccount() async {
    try {
      setState(() => _isLoading = true);

      final gamesServices = GamesServicesController();
      await gamesServices.switchAccount();

      setState(() {});
    } catch (e) {
      print('Erreur lors du changement de compte: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showLeaderboard(GameState gameState) async {
    final controller = GamesServicesController();
    if (await controller.isSignedIn()) {
      gameState.updateLeaderboard();
      controller.showLeaderboard(leaderboardID: GamesServicesController.generalLeaderboardID);
    } else {
      await controller.signIn();
      if (await controller.isSignedIn()) {
        controller.showLeaderboard(leaderboardID: GamesServicesController.generalLeaderboardID);
      }
    }
  }

  Future<void> _showAchievements() async {
    final controller = GamesServicesController();
    if (await controller.isSignedIn()) {
      controller.showAchievements();
    } else {
      await controller.signIn();
      if (await controller.isSignedIn()) {
        controller.showAchievements();
      }
    }
  }

  void _updateLeaderboard(GameState gameState, BuildContext context) async {
    final controller = GamesServicesController();
    if (await controller.isSignedIn()) {
      gameState.updateLeaderboard();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scores synchronisés !'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez vous connecter aux services de jeux'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showStatistics(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Statistiques',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Consumer<GameState>(
                  builder: (context, gameState, _) {
                    final stats = gameState.statistics.getAllStats();
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildStatSection('Production', stats['production']!),
                          const SizedBox(height: 16),
                          _buildStatSection('Économie', stats['economie']!),
                          const SizedBox(height: 16),
                          _buildStatSection('Progression', stats['progression']!),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatSection(String title, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Divider(),
            ...stats.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showAboutInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 8),
            const Text('À propos'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version ${GameConstants.VERSION}'),
            const SizedBox(height: 8),
            const Text('Un jeu incrémental de production de trombones.'),
            const SizedBox(height: 16),
            const Text('Fonctionnalités:'),
            const Text('• Production de trombones'),
            const Text('• Gestion du marché'),
            const Text('• Système d\'améliorations'),
            const Text('• Événements dynamiques'),
            const SizedBox(height: 16),
            const Text('Développé avec ❤️ par Kinder2149'),
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
}