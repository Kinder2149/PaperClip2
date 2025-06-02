// lib/screens/social/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart' show serviceLocator;
import '../../services/social/friends_service.dart';
import '../../services/user/user_manager.dart';
import '../../models/social/friend_model.dart';
import '../../models/social/friend_request_model.dart';
import '../../widgets/social/widget_friend_item.dart';
import '../../widgets/social/widget_friend_request_item.dart';
import 'friend_comparison_screen.dart';
import 'friends_search_screen.dart';
import 'social_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  late final FriendsService? _friendsService;

  // Stockage local des données pour éviter les problèmes de stream
  List<FriendModel> _friendsList = [];
  List<FriendRequestModel> _receivedRequests = [];
  List<FriendRequestModel> _sentRequests = [];

  bool _isLoadingFriends = true;
  bool _isLoadingReceivedRequests = true;
  bool _isLoadingSentRequests = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Modifier TabController pour 3 onglets au lieu de 2
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });

    // Initialiser le service d'amis
    _initializeFriendsService();
  }


  void _initializeFriendsService() {
    final userManager = Provider.of<UserManager>(context, listen: false);
    final userId = userManager.currentProfile?.userId;

    if (userId != null) {
      // Utiliser des paramètres nommés pour le constructeur
      _friendsService = FriendsService(
        userId: userId,
        userManager: userManager,
        socialService: serviceLocator.socialService!,
        analyticsService: serviceLocator.analyticsService!,
      );
      _loadData();
    } else {
      setState(() {
        _errorMessage = "Utilisateur non connecté";
        _isLoadingFriends = false;
        _isLoadingReceivedRequests = false;
        _isLoadingSentRequests = false;
      });
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFriendsList,
              child: const Text('Réessayer'),
            ),
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
        return WidgetFriendItem(
          friend: friend,
          onCompare: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FriendComparisonScreen(friendId: friend.userId),
              ),
            );
          },
          onRemove: () async {
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
                SnackBar(
                  content: Text('${friend.displayName} a été retiré de vos amis'),
                ),
              );
              _loadFriendsList(); // Rafraîchir la liste
            }
          },
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
        return WidgetFriendRequestItem(
          request: request,
          onAccept: () async {
            if (_friendsService == null) return;

            final success = await _friendsService!.acceptFriendRequest(request.id);
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Demande de ${request.senderName} acceptée'),
                ),
              );
              _loadData(); // Rafraîchir toutes les listes
            }
          },
          onDecline: () async {
            if (_friendsService == null) return;

            final success = await _friendsService!.declineFriendRequest(request.id);
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Demande de ${request.senderName} refusée'),
                ),
              );
              _loadReceivedRequests(); // Rafraîchir les demandes
            }
          },
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

        switch (request.status) {
          case FriendRequestStatus.accepted:
            status = 'Acceptée';
            statusColor = Colors.green;
            break;
          case FriendRequestStatus.declined:
            status = 'Refusée';
            statusColor = Colors.red;
            break;
          case FriendRequestStatus.pending:
          default:
            status = 'En attente';
            statusColor = Colors.orange;
            break;
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