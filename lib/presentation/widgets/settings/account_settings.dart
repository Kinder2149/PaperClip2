import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/game_viewmodel.dart';
import '../../../domain/services/games_services_controller.dart';

class AccountSettings extends StatelessWidget {
  const AccountSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compte et Services',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 16),
            Consumer<GameViewModel>(
              builder: (context, gameViewModel, child) {
                return Column(
                  children: [
                    _buildGooglePlaySection(context),
                    const Divider(),
                    _buildCloudSaveSection(context),
                    const Divider(),
                    _buildAchievementsSection(context),
                    const Divider(),
                    _buildLeaderboardsSection(context),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGooglePlaySection(BuildContext context) {
    return FutureBuilder<bool>(
      future: GamesServicesController().isSignedIn(),
      builder: (context, snapshot) {
        final isSignedIn = snapshot.data ?? false;
        return ListTile(
          leading: const Icon(Icons.account_circle),
          title: Text(isSignedIn ? 'Compte Google Play' : 'Non connecté'),
          subtitle: Text(isSignedIn ? 'Connecté aux services Google Play' : 'Connectez-vous pour accéder aux fonctionnalités en ligne'),
          trailing: ElevatedButton(
            onPressed: () => _handleGooglePlaySignIn(context, isSignedIn),
            child: Text(isSignedIn ? 'Changer de compte' : 'Se connecter'),
          ),
        );
      },
    );
  }

  Widget _buildCloudSaveSection(BuildContext context) {
    return FutureBuilder<bool>(
      future: GamesServicesController().isSignedIn(),
      builder: (context, snapshot) {
        final isSignedIn = snapshot.data ?? false;
        return ListTile(
          leading: const Icon(Icons.cloud),
          title: const Text('Sauvegarde Cloud'),
          subtitle: Text(isSignedIn ? 'Synchroniser avec le cloud' : 'Connectez-vous pour activer la sauvegarde cloud'),
          trailing: ElevatedButton(
            onPressed: isSignedIn ? () => _syncCloudSaves(context) : null,
            child: const Text('Synchroniser'),
          ),
        );
      },
    );
  }

  Widget _buildAchievementsSection(BuildContext context) {
    return FutureBuilder<bool>(
      future: GamesServicesController().isSignedIn(),
      builder: (context, snapshot) {
        final isSignedIn = snapshot.data ?? false;
        return ListTile(
          leading: const Icon(Icons.emoji_events),
          title: const Text('Succès'),
          subtitle: const Text('Voir vos succès et récompenses'),
          trailing: ElevatedButton(
            onPressed: isSignedIn ? () => _showAchievements(context) : null,
            child: const Text('Voir'),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardsSection(BuildContext context) {
    return FutureBuilder<bool>(
      future: GamesServicesController().isSignedIn(),
      builder: (context, snapshot) {
        final isSignedIn = snapshot.data ?? false;
        return ListTile(
          leading: const Icon(Icons.leaderboard),
          title: const Text('Classements'),
          subtitle: const Text('Voir les classements mondiaux'),
          trailing: ElevatedButton(
            onPressed: isSignedIn ? () => _showLeaderboards(context) : null,
            child: const Text('Voir'),
          ),
        );
      },
    );
  }

  Future<void> _handleGooglePlaySignIn(BuildContext context, bool isSignedIn) async {
    try {
      if (isSignedIn) {
        final success = await GamesServicesController().switchAccount();
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compte changé avec succès')),
          );
        }
      } else {
        final success = await GamesServicesController().signIn();
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connecté avec succès')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _syncCloudSaves(BuildContext context) async {
    try {
      final success = await GamesServicesController().syncSaves();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Synchronisation réussie' : 'Échec de la synchronisation'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _showAchievements(BuildContext context) async {
    try {
      await GamesServicesController().showAchievements();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _showLeaderboards(BuildContext context) async {
    try {
      await GamesServicesController().showGeneralLeaderboard();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
} 