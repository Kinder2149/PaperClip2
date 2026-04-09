// lib/widgets/appbar/settings_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/screens/start_screen.dart';
import 'package:paperclip2/screens/profile_screen.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import 'package:paperclip2/services/auth/firebase_auth_service.dart';
import 'package:paperclip2/widgets/save_button.dart';

// Bottom sheet Paramètres réutilisable pour l'interface principale
Future<void> showSettingsBottomSheet(BuildContext context) async {
  final gameState = context.read<GameState>();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: const [
                        Icon(Icons.settings, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Paramètres',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Card(
                    elevation: 0,
                    color: Colors.grey[50],
                    child: ExpansionTile(
                      leading: const Icon(Icons.save_outlined),
                      title: const Text('Sauvegardes'),
                      initiallyExpanded: true,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.refresh),
                          title: const Text('Nouveau monde'),
                          onTap: () => _showNewGameConfirmation(context),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.save),
                          title: const Text('Sauvegarder'),
                          subtitle: Builder(builder: (context) {
                            final enterpriseId = gameState.enterpriseId;
                            if (enterpriseId == null || enterpriseId.isEmpty) {
                              return const Text('Dernière sauvegarde: Jamais');
                            }
                            return FutureBuilder(
                              future: LocalSaveGameManager.getInstance().then((mgr) => mgr.loadSave(enterpriseId)),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Text('Dernière sauvegarde: …');
                                }
                                final save = snapshot.data;
                                if (save == null) {
                                  return const Text('Dernière sauvegarde: Jamais');
                                }
                                final dt = save.lastSaveTime;
                                final diff = DateTime.now().difference(dt);
                                String humanized;
                                if (diff.inSeconds < 60) {
                                  humanized = 'il y a ${diff.inSeconds}s';
                                } else if (diff.inMinutes < 60) {
                                  humanized = 'il y a ${diff.inMinutes}m';
                                } else if (diff.inHours < 24) {
                                  humanized = 'il y a ${diff.inHours}h';
                                } else {
                                  final d = dt.toLocal();
                                  humanized = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
                                }
                                return Text('Dernière sauvegarde: $humanized');
                              },
                            );
                          }),
                          onTap: () {
                            Navigator.pop(context);
                            SaveButton.saveGame(context);
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.home),
                          title: const Text('Retour au menu principal'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const StartScreen()),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Section Compte (visible si connecté)
                  StreamBuilder(
                    stream: FirebaseAuthService.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      final isConnected = FirebaseAuthService.instance.currentUser != null;
                      
                      if (!isConnected) return const SizedBox.shrink();
                      
                      return Column(
                        children: [
                          Card(
                            elevation: 0,
                            color: Colors.deepPurple[50],
                            child: ListTile(
                              leading: const Icon(Icons.person, color: Colors.deepPurple),
                              title: const Text(
                                'Mon Profil',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                FirebaseAuthService.instance.currentUser?.email ?? '',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                  Card(
                    elevation: 0,
                    color: Colors.grey[50],
                    child: ExpansionTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Informations'),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.timer_outlined),
                          title: const Text('Temps de jeu'),
                          subtitle: Text(gameState.formattedPlayTime),
                        ),
                        ListTile(
                          leading: const Icon(Icons.stars_outlined),
                          title: const Text('Niveau'),
                          subtitle: Text('${gameState.level.level}'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showNewGameConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning),
          SizedBox(width: 8),
          Text('Nouveau monde'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Êtes-vous sûr de vouloir créer un nouveau monde ?'),
          SizedBox(height: 8),
          Text(
            'La progression du monde actuel sera perdue s\'il n\'est pas sauvegardé.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.red),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context); // ferme le dialogue
            Navigator.pop(context); // ferme la bottom sheet
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const StartScreen(continueOpensWorlds: true)),
              (route) => false,
            );
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Nouveau monde'),
        ),
      ],
    ),
  );
}
