import 'package:flutter/material.dart';
import '../services/games_services_controller.dart';
import '../services/api/auth_service.dart';
import '../config/api_config.dart';
import 'package:provider/provider.dart';

class GoogleProfileButton extends StatefulWidget {
  final Function()? onProfileUpdated;

  const GoogleProfileButton({Key? key, this.onProfileUpdated}) : super(key: key);

  @override
  State<GoogleProfileButton> createState() => _GoogleProfileButtonState();
}

class _GoogleProfileButtonState extends State<GoogleProfileButton> {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String _debugInfo = '';
  bool _isSignedIn = false;
  String? _playerName;
  
  // Services nécessaires
  final AuthService _authService = AuthService();
  final GamesServicesController _gamesServices = GamesServicesController();

  @override
  void initState() {
    super.initState();
    
    // Initialisation asynchrone
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSignInStatus();
    });
  }

  Future<void> _checkSignInStatus() async {
    try {
      // silentSignIn renvoie un booléen et non un objet GooglePlayerInfo
      final bool isSignedIn = await _gamesServices.silentSignIn();
      
      if (isSignedIn) {
        // Si connecté, récupérer les infos du joueur séparément
        final playerInfo = await _gamesServices.getCurrentPlayerInfo();
        
        setState(() {
          _isSignedIn = true;
          _playerName = playerInfo?.displayName ?? "Joueur Google";
        });
        
        if (widget.onProfileUpdated != null) {
          widget.onProfileUpdated!();
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _debugInfo += '\nException: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// Charge les informations du joueur depuis le service de jeu
  Future<void> _checkPlayerInfo() async {
    try {
      final playerInfo = await _gamesServices.getCurrentPlayerInfo();
      
      if (playerInfo != null) {
        setState(() {
          _playerName = playerInfo.displayName;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des infos joueur: $e');
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
        await _loginWithGoogle();
      } else {
        // Si déjà connecté, montrer les options
        _showAccountOptions();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _debugInfo += '\nException: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);

      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _debugInfo = 'Démarrage authentification Google...';
    });
    
    try {
      // Vérification simplifiée - nous ne faisons pas de vérification d'endpoint ici
      // car cela nécessiterait des appels réseau supplémentaires
      final success = await _authService.signInWithGoogle();
      
      if (!success) {
        setState(() {
          _hasError = true;
          _errorMessage = "L'authentification Google a échoué";
          _debugInfo += '\nÉchec de l\'authentification Google';
        });
      } else {
        // Authentification réussie, récupérer le profil
        setState(() {
          _isLoading = false;
          _isSignedIn = true;
          _debugInfo += '\nConnexion Google réussie!';
        });
        
        // Charge le profil après la connexion
        await _checkPlayerInfo();
        
        if (widget.onProfileUpdated != null) {
          widget.onProfileUpdated!();
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _debugInfo += '\nException: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

              try {
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
              } catch (e) {
                setState(() {
                  _hasError = true;
                  _errorMessage = e.toString();
                  _debugInfo += '\nException: ${e.toString()}';
                });
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