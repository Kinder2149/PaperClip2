// lib/screens/social/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/social/friends_service.dart';
import '../../services/user/user_manager.dart';
import '../../services/api/analytics_service.dart';
import '../../services/api/auth_service.dart';
import '../../services/api/social_service.dart'; // Ajout de l'import pour SocialService
import '../../services/games_services_controller.dart';

import 'friends_search_screen.dart';
import 'social_profile_screen.dart';
import '../../models/social/friend_model.dart';
import '../../models/social/friend_request_model.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  // Clé pour le scaffold, utilisée pour afficher des snackbars
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  int _selectedIndex = 0;
  FriendsService? _friendsService;
  
  // Écouteurs pour les changements d'état d'authentification
  late ValueNotifier<bool> _signInStatusListener;
  late ValueNotifier<GooglePlayerInfo?> _playerInfoListener;

  // États de chargement
  bool _isLoadingFriends = true;
  bool _isLoadingReceivedRequests = true;
  bool _isLoadingSentRequests = true;
  String? _errorMessage;

  // Données
  List<FriendModel> _friendsList = [];
  List<FriendRequestModel> _receivedRequests = [];
  List<FriendRequestModel> _sentRequests = [];

  @override
  void initState() {
    super.initState();
    
    // Initialiser TabController
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
    
    // Écouter les changements d'état d'authentification
    _signInStatusListener = GamesServicesController().signInStatusChanged;
    _playerInfoListener = GamesServicesController().playerInfoChanged;
    
    // Configurer les écouteurs
    _signInStatusListener.addListener(_onAuthStateChanged);
    _playerInfoListener.addListener(_onPlayerInfoChanged);
    
    _initializeFriendsService();
  }
  
  @override
  void dispose() {
    // Supprimer les écouteurs
    _signInStatusListener.removeListener(_onAuthStateChanged);
    _playerInfoListener.removeListener(_onPlayerInfoChanged);
    _tabController.dispose();
    super.dispose();
  }
  
  // Réagir aux changements d'état d'authentification
  void _onAuthStateChanged() {
    debugPrint('_FriendsScreenState: État d\'authentification changé ${_signInStatusListener.value}');
    // Si connecté, réinitialiser
    if (_signInStatusListener.value) {
      setState(() {
        _errorMessage = null;
        _isLoadingFriends = true;
        _isLoadingReceivedRequests = true;
        _isLoadingSentRequests = true;
      });
      _initializeFriendsService();
    } else {
      // Si déconnecté, afficher un message
      setState(() {
        _errorMessage = "Connectez-vous pour accéder aux fonctionnalités sociales";
        _isLoadingFriends = false;
        _isLoadingReceivedRequests = false;
        _isLoadingSentRequests = false;
        _friendsService = null;
      });
    }
  }
  
  // Réagir aux changements d'informations du joueur
  void _onPlayerInfoChanged() {
    // Si les infos du joueur sont mises à jour, on réinitialise le service
    if (_playerInfoListener.value != null) {
      _initializeFriendsService();
    }
  }

  Future<void> _initializeFriendsService() async {
    final userManager = Provider.of<UserManager>(context, listen: false);
    final userId = userManager.currentProfile?.userId;
    final isSignedIn = await GamesServicesController().isSignedIn();
    
    debugPrint('_FriendsScreenState.initializeFriendsService - isSignedIn: $isSignedIn, userId: $userId');

    // Vérifier si l'utilisateur est authentifié via isSignedIn et userId
    if (!isSignedIn || userId == null) {
      // Tenter de rafraîchir l'état d'authentification si connecté mais pas de profil
      if (isSignedIn && userId == null) {
        debugPrint('_FriendsScreenState: Authentifié mais pas de profil, rafraîchissement du UserManager');
        await userManager.refreshAuthState();
        // Révérifier après rafraîchissement
        final refreshedUserId = userManager.currentProfile?.userId;
        if (refreshedUserId != null) {
          debugPrint('_FriendsScreenState: Profil utilisateur récupéré après rafraîchissement: $refreshedUserId');
        } else {
          // Toujours pas de profil
          setState(() {
            _errorMessage = "Connecté, mais profil utilisateur non disponible. Veuillez réessayer.";
            _isLoadingFriends = false;
            _isLoadingReceivedRequests = false;
            _isLoadingSentRequests = false;
          });
          return;
        }
      } else {
        // Pas connecté
        setState(() {
          _errorMessage = "Connectez-vous pour accéder aux fonctionnalités sociales";
          _isLoadingFriends = false;
          _isLoadingReceivedRequests = false;
          _isLoadingSentRequests = false;
        });
        return;
      }
    }

    // Essayer de créer le FriendsService
    try {
      // Créer des instances de services
      final socialServiceInstance = SocialService(); 
      final analyticsServiceInstance = AnalyticsService();
      
      // Initialiser FriendsService (userId est non-null à ce point du code)
      _friendsService = FriendsService(
        userId: userId!, // Le point d'exclamation ici car on a déjà vérifié que userId n'est pas null
        userManager: userManager,
        socialService: socialServiceInstance,
        analyticsService: analyticsServiceInstance,
      );
      
      // Charger toutes les données
      _loadData();
    } catch (e) {
      print('Erreur lors de l\'initialisation du service d\'amis: $e');
      setState(() {
        _errorMessage = "Fonctionnalités sociales temporairement indisponibles";
        _isLoadingFriends = false;
        _isLoadingReceivedRequests = false;
        _isLoadingSentRequests = false;
      });
      return;
    }
  }

  // Charger toutes les données nécessaires
  void _loadData() {
    _loadFriendsList();
    _loadReceivedRequests();
    _loadSentRequests();
  }

  // Charger la liste des amis
  void _loadFriendsList() {
    if (_friendsService == null) {
      setState(() {
        _isLoadingFriends = false;
        _errorMessage = "Service d'amis non disponible";
      });
      return;
    }

    setState(() {
      _isLoadingFriends = true;
    });

    _friendsService!.friendsStream().listen(
            (friends) {
          if (mounted) {
            setState(() {
              _friendsList = friends;
              _isLoadingFriends = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = "Erreur: $error";
              _isLoadingFriends = false;
            });
          }
        }
    );
  }

  // Charger les demandes reçues
  void _loadReceivedRequests() {
    if (_friendsService == null) {
      setState(() {
        _isLoadingReceivedRequests = false;
      });
      return;
    }

    setState(() {
      _isLoadingReceivedRequests = true;
    });

    _friendsService!.receivedRequestsStream().listen(
            (requests) {
          if (mounted) {
            setState(() {
              _receivedRequests = requests;
              _isLoadingReceivedRequests = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = "Erreur: $error";
              _isLoadingReceivedRequests = false;
            });
          }
        }
    );
  }

  // Charger les demandes envoyées
  void _loadSentRequests() {
    if (_friendsService == null) {
      setState(() {
        _isLoadingSentRequests = false;
      });
      return;
    }

    setState(() {
      _isLoadingSentRequests = true;
    });

    _friendsService!.sentRequestsStream().listen(
            (requests) {
          if (mounted) {
            setState(() {
              _sentRequests = requests;
              _isLoadingSentRequests = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = "Erreur: $error";
              _isLoadingSentRequests = false;
            });
          }
        }
    );
  }

  // La méthode dispose() est déjà définie plus haut dans la classe

  // Méthode pour afficher le dialogue de connexion
  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text('Vous devez vous connecter pour accéder aux fonctionnalités sociales.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Tenter de se connecter via Games Services
              final success = await GamesServicesController().signIn();
              if (success && mounted) {
                // Réinitialiser et recharger si l'utilisateur s'est connecté
                setState(() {
                  _errorMessage = null;
                  _isLoadingFriends = true;
                  _isLoadingReceivedRequests = true;
                  _isLoadingSentRequests = true;
                });
                _initializeFriendsService();
              }
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userManager = Provider.of<UserManager>(context);
    final userId = userManager.currentProfile?.userId;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Amis'),
        ),
        body: const Center(
          child: Text('Connectez-vous pour accéder aux fonctionnalités sociales'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendsSearchScreen(),
                ),
              ).then((_) => _loadData()); // Rafraîchir après la recherche
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Rafraîchir',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mes Amis'),
            Tab(text: 'Demandes'),
            Tab(text: 'Profil'), // Nouvel onglet
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(),
          _buildRequestsTab(),
          const SocialProfileScreen(), // Nouvel onglet
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _errorMessage!.contains("Connectez-vous") ? Icons.login : Icons.cloud_off,
              size: 64,
              color: _errorMessage!.contains("Connectez-vous") ? Colors.orange : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            if (_errorMessage!.contains("Connectez-vous")) ...[  
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Rediriger vers l'écran de connexion ou ouvrir le dialogue de connexion
                  _showLoginDialog();
                },
                icon: const Icon(Icons.login),
                label: const Text("Se connecter"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
            if (_errorMessage!.contains("Fonctionnalités sociales temporairement")) ...[  
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Réessayer d'initialiser le service
                  setState(() {
                    _errorMessage = null;
                    _isLoadingFriends = true;
                    _isLoadingReceivedRequests = true;
                    _isLoadingSentRequests = true;
                  });
                  _initializeFriendsService();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Réessayer"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_isLoadingFriends) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friendsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Vous n\'avez pas encore d\'amis',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Rechercher des amis'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FriendsSearchScreen(),
                  ),
                ).then((_) => _loadData()); // Rafraîchir après la recherche
              },
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _friendsList.length,
      itemBuilder: (context, index) {
        final friend = _friendsList[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              child: Text(friend.displayName?.substring(0, 1) ?? '?'),
            ),
            title: Text(friend.displayName ?? 'Ami'),
            subtitle: Text('Ami depuis le ${friend.createdAt?.toString().split(' ')[0] ?? 'récemment'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.compare_arrows),
                  onPressed: () {
                    // Navigation vers l'écran de comparaison a été remplacée
                    // car FriendComparisonScreen n'existe pas
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Comparaison avec ${friend.displayName}'))
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () async {
                    // Confirmation avant suppression
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Supprimer cet ami'),
                        content: Text('Voulez-vous vraiment supprimer ${friend.displayName} de vos amis ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && _friendsService != null) {
                      await _friendsService!.removeFriend(friend.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${friend.displayName} a été retiré de vos amis')),
                      );
                      _loadFriendsList(); // Rafraîchir la liste
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Reçues'),
              Tab(text: 'Envoyées'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildReceivedRequestsList(),
                _buildSentRequestsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedRequestsList() {
    if (_isLoadingReceivedRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_receivedRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune demande d\'amitié',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _receivedRequests.length,
      itemBuilder: (context, index) {
        final request = _receivedRequests[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(request.senderName?.substring(0, 1) ?? '?'),
            ),
            title: Text(request.senderName ?? 'Utilisateur'),
            subtitle: Text('Demande reçue le ${request.timestamp.toString().split(' ')[0]}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check_circle_outline, color: Colors.green),
                  onPressed: () async {
                    if (_friendsService == null) return;

                    final success = await _friendsService!.acceptFriendRequest(request.id);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Demande d\'amitié de ${request.senderName} acceptée'),
                        ),
                      );
                      _loadReceivedRequests(); // Rafraîchir les demandes reçues
                      _loadSentRequests(); // Rafraîchir les demandes envoyées
                      _loadFriendsList(); // Rafraîchir la liste des amis
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.cancel_outlined, color: Colors.red),
                  onPressed: () async {
                    if (_friendsService == null) return;

                    // Utiliser directement l'ID de la demande d'ami
                    final requestId = request.id;
                    final success = await _friendsService?.declineFriendRequest(requestId) ?? false;
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Demande d\'amitié de ${request.senderName ?? ''} refusée'),
                        ),
                      );
                      _loadReceivedRequests(); // Rafraîchir les demandes reçues
                      _loadSentRequests(); // Rafraîchir les demandes envoyées
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentRequestsList() {
    if (_isLoadingSentRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sentRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune demande envoyée',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _sentRequests.length,
      itemBuilder: (context, index) {
        final request = _sentRequests[index];

        // Calculer le statut d'affichage
        String status;
        Color statusColor;
        
        // Utiliser des comparaisons directes plutôt qu'un switch/case
        if (request.status == FriendRequestStatus.accepted) {
          status = 'Acceptée';
          statusColor = Colors.green;
        } else if (request.status == FriendRequestStatus.declined) {
          status = 'Refusée';
          statusColor = Colors.red;
        } else {
          status = 'En attente';
          statusColor = Colors.orange;
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: request.senderPhotoUrl != null
                ? NetworkImage(request.senderPhotoUrl!)
                : null,
            child: request.senderPhotoUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(request.senderName),
          subtitle: Text('Envoyée le ${_formatDate(request.timestamp)}'),
          trailing: Chip(
            label: Text(status),
            backgroundColor: statusColor.withOpacity(0.2),
            labelStyle: TextStyle(color: statusColor),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} jours';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours} heures';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes} minutes';
    } else {
      return 'à l\'instant';
    }
  }
}