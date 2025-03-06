import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/game_viewmodel.dart';

class GameSettings extends StatelessWidget {
  const GameSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres de Jeu',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 16),
            Consumer<GameViewModel>(
              builder: (context, gameViewModel, child) {
                return Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Sauvegarde Automatique'),
                      subtitle: const Text('Sauvegarder automatiquement la partie'),
                      value: gameViewModel.autoSaveEnabled,
                      onChanged: (value) => gameViewModel.setAutoSave(value),
                    ),
                    SwitchListTile(
                      title: const Text('Notifications'),
                      subtitle: const Text('Recevoir des notifications du jeu'),
                      value: gameViewModel.notificationsEnabled,
                      onChanged: (value) => gameViewModel.setNotifications(value),
                    ),
                    SwitchListTile(
                      title: const Text('Mode Sombre'),
                      subtitle: const Text('Activer le thème sombre'),
                      value: gameViewModel.darkModeEnabled,
                      onChanged: (value) => gameViewModel.setDarkMode(value),
                    ),
                    SwitchListTile(
                      title: const Text('Son'),
                      subtitle: const Text('Activer les effets sonores'),
                      value: gameViewModel.soundEnabled,
                      onChanged: (value) => gameViewModel.setSound(value),
                    ),
                    SwitchListTile(
                      title: const Text('Musique'),
                      subtitle: const Text('Activer la musique de fond'),
                      value: gameViewModel.musicEnabled,
                      onChanged: (value) => gameViewModel.setMusic(value),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 