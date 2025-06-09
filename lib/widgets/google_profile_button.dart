import 'package:flutter/material.dart';
import '../services/games_services_controller.dart';
import '../services/api/auth_service.dart';
import 'package:provider/provider.dart';

class GoogleProfileButton extends StatefulWidget {
  final Function()? onProfileUpdated;

  const GoogleProfileButton({Key? key, this.onProfileUpdated}) : super(key: key);

  @override
  State<GoogleProfileButton> createState() => _GoogleProfileButtonState();
}

class _GoogleProfileButtonState extends State<GoogleProfileButton> {
  bool _isSignedIn = false;
  bool _isLoading = true;
  String? _playerName;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    setState(() => _isLoading = true);

    try {
      final gamesServices = GamesServicesController();
      final isSignedIn = await gamesServices.isSignedIn();

      // Essayer de récupérer les informations du joueur si connecté
      String? displayName;
      if (isSignedIn) {
        final playerInfo = await gamesServices.getCurrentPlayerInfo();
        displayName = playerInfo?.displayName;
      }

      setState(() {
        _isSignedIn = isSignedIn;
        _playerName = displayName ?? "Joueur Google";
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur lors de la vérification du statut: $e");
      setState(() {
        _isSignedIn = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleTap() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final gamesServices = GamesServicesController();
      final authService = Provider.of<AuthService>(context, listen: false);

      if (!_isSignedIn) {
        // Si pas connecté, tenter de se connecter via notre service d'authentification Google
        debugPrint('Tentative d\'authentification via AuthService.signInWithGoogle()...');
        final success = await authService.signInWithGoogle();

        if (success) {
          // Si connecté avec succès, récupérer les infos du joueur
          final playerInfo = await gamesServices.getCurrentPlayerInfo();
          setState(() {
            _isSignedIn = true;
            _playerName = playerInfo?.displayName ?? "Joueur Google";
          });
          
          // Afficher un message de succès
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion Google réussie'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Afficher un message d'erreur
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Échec de l\'authentification Google'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Si déjà connecté, montrer les options
        _showAccountOptions();
      }
    } catch (e) {
      print("Erreur lors de la gestion du tap: $e");
      // Montrer message d'erreur si nécessaire
    } finally {
      setState(() => _isLoading = false);

      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      }
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
            title: Text(_playerName ?? 'Joueur Google Play'),
            subtitle: const Text('Compte connecté'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.switch_account),
            title: const Text('Changer de compte'),
            onTap: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);

              final gamesServices = GamesServicesController();
              final success = await gamesServices.switchAccount();

              if (success) {
                final playerInfo = await gamesServices.getCurrentPlayerInfo();
                setState(() {
                  _playerName = playerInfo?.displayName ?? "Joueur Google";
                });
              }

              setState(() => _isLoading = false);

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
              setState(() => _isLoading = true);

              try {
                // Utiliser AuthService pour déconnecter l'utilisateur
                final authService = Provider.of<AuthService>(context, listen: false);
                
                // Déconnexion complète
                await authService.logout();
                
                await _checkSignInStatus();
                
                // Notification de déconnexion réussie
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Déconnexion réussie'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Erreur lors de la déconnexion: $e');
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la déconnexion: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                setState(() => _isLoading = false);
                
                if (widget.onProfileUpdated != null) {
                  widget.onProfileUpdated!();
                }
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
                        ? _playerName ?? 'Joueur Google Play'
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