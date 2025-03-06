// lib/presentation/widgets/google_profile_button.dart
import 'package:flutter/material.dart';
import 'package:paperclip2/domain/services/games_services_controller.dart';

class GoogleProfileButton extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const GoogleProfileButton({
    Key? key,
    this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<GoogleProfileButton> createState() => _GoogleProfileButtonState();
}

class _GoogleProfileButtonState extends State<GoogleProfileButton> {
  bool _isLoading = false;
  bool _isSignedIn = false;
  String? _playerName;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gamesServices = GamesServicesController();
      final isSignedIn = await gamesServices.isSignedIn();

      // Placeholder for player name - in a real app you'd get this from the API
      final playerName = isSignedIn ? "Joueur Google" : null;

      setState(() {
        _isSignedIn = isSignedIn;
        _playerName = playerName;
      });
    } catch (e) {
      print('Error checking sign-in status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gamesServices = GamesServicesController();
      await gamesServices.signIn();
      await _checkSignInStatus();

      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      }
    } catch (e) {
      print('Error signing in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gamesServices = GamesServicesController();
      await gamesServices.switchAccount();
      await _checkSignInStatus();

      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      }
    } catch (e) {
      print('Error signing out: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_isSignedIn) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _playerName ?? 'Joueur Google',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Connecté à Google Play Games',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'show_achievements') {
                        GamesServicesController().showAchievements();
                      } else if (value == 'show_leaderboards') {
                        GamesServicesController().showLeaderboard(
                          leaderboardID: GamesServicesController.generalLeaderboardID,
                        );
                      } else if (value == 'switch_account') {
                        _signOut();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'show_achievements',
                        child: Text('Voir les succès'),
                      ),
                      const PopupMenuItem(
                        value: 'show_leaderboards',
                        child: Text('Voir les classements'),
                      ),
                      const PopupMenuItem(
                        value: 'switch_account',
                        child: Text('Changer de compte'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: InkWell(
          onTap: _signIn,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: Icon(
                    Icons.games,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Play Games',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Connectez-vous pour sauvegarder votre progression',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
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
      );
    }
  }
}