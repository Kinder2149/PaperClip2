import 'package:flutter/material.dart';
import 'package:paperclip2/services/games_services_controller.dart';

class GoogleProfileButton extends StatefulWidget {
  final Function()? onProfileUpdated;

  const GoogleProfileButton({Key? key, this.onProfileUpdated}) : super(key: key);

  @override
  State<GoogleProfileButton> createState() => _GoogleProfileButtonState();
}

class _GoogleProfileButtonState extends State<GoogleProfileButton> {
  bool _isSignedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    setState(() => _isLoading = true);

    final gamesServices = GamesServicesController();
    final isSignedIn = await gamesServices.isSignedIn();

    setState(() {
      _isSignedIn = isSignedIn;
      _isLoading = false;
    });
  }

  Future<void> _handleTap() async {
    if (_isLoading) return;

    final gamesServices = GamesServicesController();

    if (!_isSignedIn) {
      // Si pas de profil connecté, se connecter
      await gamesServices.signIn();
    } else {
      // Si déjà connecté, montrer le menu pour changer de compte
      _showAccountOptions();
    }

    await _checkSignInStatus();

    if (widget.onProfileUpdated != null) {
      widget.onProfileUpdated!();
    }
  }

  void _showAccountOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Joueur Google Play'),
            subtitle: const Text('Compte connecté'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.switch_account),
            title: const Text('Changer de compte'),
            onTap: () async {
              Navigator.pop(context);
              final gamesServices = GamesServicesController();
              await gamesServices.switchAccount();
              await _checkSignInStatus();
              if (widget.onProfileUpdated != null) {
                widget.onProfileUpdated!();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Déconnexion'),
            onTap: () async {
              Navigator.pop(context);
              // Comme signOut n'est pas disponible, on peut simplement réinitialiser l'état
              final gamesServices = GamesServicesController();
              // On appelle signIn et l'utilisateur peut choisir de ne pas se connecter
              await gamesServices.signIn();
              await _checkSignInStatus();
              if (widget.onProfileUpdated != null) {
                widget.onProfileUpdated!();
              }
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  child: const Text('Fermer'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: _isSignedIn ? Colors.green.shade600 : Colors.blue.shade700,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _isLoading
                ? const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(color: Colors.white),
            )
                : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_circle,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isSignedIn
                        ? 'Compte Google Play'
                        : 'Se connecter',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _isSignedIn
                        ? 'Synchronisation activée'
                        : 'Synchroniser vos parties',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _isSignedIn ? Icons.settings : Icons.login,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}