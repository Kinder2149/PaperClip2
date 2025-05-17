// lib/screens/social/friends_search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../services/social/friends_service.dart';
import '../../services/user/user_manager.dart';

class FriendsSearchScreen extends StatefulWidget {
  const FriendsSearchScreen({Key? key}) : super(key: key);

  @override
  State<FriendsSearchScreen> createState() => _FriendsSearchScreenState();
}

class _FriendsSearchScreenState extends State<FriendsSearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _idSearchController = TextEditingController();
  late TabController _tabController;

  // Variables pour l'onglet "Par nom"
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  // Variables pour l'onglet "Par ID"
  bool _isSearchingById = false;
  Map<String, dynamic>? _foundUserById;

  // Variables pour l'onglet "Suggestions"
  List<Map<String, dynamic>> _suggestedUsers = [];
  bool _isLoadingSuggestions = false;

  // Variables communes
  late final FriendsService _friendsService;
  Set<String> _pendingRequests = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialiser le service d'amis
    final userManager = Provider.of<UserManager>(context, listen: false);
    final userId = userManager.currentProfile?.userId;

    if (userId != null) {
      _friendsService = FriendsService(userId, userManager);
      // Charger automatiquement les suggestions au démarrage
      _loadSuggestions();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _idSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Méthode pour rechercher par nom
  Future<void> _search(String query) async {
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _friendsService.searchUsers(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de recherche: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode pour rechercher par ID
  Future<void> _searchById(String userId) async {
    if (userId.trim().isEmpty) {
      setState(() {
        _foundUserById = null;
        _isSearchingById = false;
      });
      return;
    }

    setState(() {
      _isSearchingById = true;
      _foundUserById = null;
    });

    try {
      // Normaliser l'ID (supprimer les espaces, etc.)
      final normalizedId = userId.trim();

      final result = await _friendsService.findUserById(normalizedId);

      setState(() {
        _foundUserById = result;
        _isSearchingById = false;
      });

      if (result == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur non trouvé avec cet identifiant'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSearchingById = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de recherche: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Méthode pour charger des suggestions d'amis
  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      // Utiliser la méthode getSuggestedUsers du FriendsService
      final suggestions = await _friendsService.getSuggestedUsers();

      setState(() {
        _suggestedUsers = suggestions;
        _isLoadingSuggestions = false;
      });
    } catch (e, stack) {
      debugPrint('Erreur lors du chargement des suggestions: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error loading friend suggestions');

      setState(() {
        _isLoadingSuggestions = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des suggestions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendFriendRequest(String targetUserId, String targetName) async {
    // Éviter les demandes multiples
    if (_pendingRequests.contains(targetUserId)) {
      return;
    }

    setState(() {
      _pendingRequests.add(targetUserId);
    });

    try {
      final success = await _friendsService.sendFriendRequest(targetUserId, targetName);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demande envoyée à $targetName'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi de la demande'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingRequests.remove(targetUserId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userManager = Provider.of<UserManager>(context);
    final userId = userManager.currentProfile?.userId;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rechercher des amis'),
        ),
        body: const Center(
          child: Text('Connectez-vous pour accéder aux fonctionnalités sociales'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher des amis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Par nom'),
            Tab(text: 'Par ID'),
            Tab(text: 'Suggestions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Premier onglet: recherche par nom
          _buildNameSearchTab(),

          // Deuxième onglet: recherche par ID
          _buildIdSearchTab(userId),

          // Troisième onglet: suggestions
          _buildSuggestionsTab(),
        ],
      ),
    );
  }

  // Widget pour l'onglet "Par nom"
  Widget _buildNameSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
            ),
            onChanged: (value) {
              if (value.length >= 3) {
                _search(value);
              } else if (value.isEmpty) {
                setState(() {
                  _searchResults = [];
                });
              }
            },
          ),
        ),

        if (_isSearching)
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (_searchResults.isEmpty && _searchController.text.length >= 3)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun résultat trouvé',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_searchController.text.length < 3 && _searchController.text.isNotEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Entrez au moins 3 caractères',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else if (_searchController.text.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Recherchez des amis par leur nom',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Vous pourrez ensuite comparer vos performances',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    final isRequesting = _pendingRequests.contains(user['userId']);

                    return _buildUserListItem(
                      user: user,
                      isRequesting: isRequesting,
                    );
                  },
                ),
              ),
      ],
    );
  }

  // Widget pour l'onglet "Par ID"
  Widget _buildIdSearchTab(String userId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _idSearchController,
            decoration: InputDecoration(
              labelText: 'ID de l\'utilisateur',
              hintText: 'Entrez l\'identifiant complet...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _searchById(_idSearchController.text),
              ),
            ),
            onSubmitted: (value) => _searchById(value),
          ),
          const SizedBox(height: 24),

          if (_isSearchingById)
            const Center(child: CircularProgressIndicator())
          else if (_foundUserById != null)
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Utilisateur trouvé',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: _foundUserById!['photoUrl'] != null
                              ? NetworkImage(_foundUserById!['photoUrl'])
                              : null,
                          child: _foundUserById!['photoUrl'] == null
                              ? const Icon(Icons.person, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _foundUserById!['displayName'] ?? 'Utilisateur',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'ID: ${_foundUserById!['userId']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pendingRequests.contains(_foundUserById!['userId'])
                          ? null
                          : () => _sendFriendRequest(
                        _foundUserById!['userId'],
                        _foundUserById!['displayName'] ?? 'Utilisateur',
                      ),
                      icon: const Icon(Icons.person_add),
                      label: Text(_pendingRequests.contains(_foundUserById!['userId'])
                          ? 'Demande en cours...'
                          : 'Envoyer une demande d\'ami'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Entrez l\'identifiant complet d\'un utilisateur',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Format: 00000000-0000-0000-0000-000000000000',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Votre ID: $userId',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copier mon ID'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: userId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ID copié dans le presse-papier'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget pour l'onglet "Suggestions"
  Widget _buildSuggestionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: const Text(
                  'Suggestions d\'amis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadSuggestions,
                tooltip: 'Actualiser',
              ),
            ],
          ),
        ),

        if (_isLoadingSuggestions)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_suggestedUsers.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune suggestion disponible pour le moment',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Revenez plus tard lorsque la communauté se sera agrandie',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _suggestedUsers.length,
              itemBuilder: (context, index) {
                final user = _suggestedUsers[index];
                final isRequesting = _pendingRequests.contains(user['userId']);

                // Construire l'élément de liste avec une information sur la raison de la suggestion
                return _buildUserListItem(
                  user: user,
                  isRequesting: isRequesting,
                  reason: _getSuggestionReason(user),
                );
              },
            ),
          ),
      ],
    );
  }

  // Helper pour obtenir la raison d'une suggestion
  String _getSuggestionReason(Map<String, dynamic> user) {
    if (user.containsKey('reason')) {
      switch (user['reason']) {
        case 'recent':
          return 'Récemment actif';
        case 'similar_level':
          return 'Niveau similaire au vôtre';
        case 'popular':
          return 'Joueur populaire';
        default:
          return 'Suggestion pour vous';
      }
    }
    return 'Suggestion pour vous';
  }

  // Widget commun pour afficher un utilisateur dans une liste
  Widget _buildUserListItem({
    required Map<String, dynamic> user,
    required bool isRequesting,
    String? reason,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.deepPurple.shade50,
                  backgroundImage: user['photoUrl'] != null
                      ? NetworkImage(user['photoUrl'])
                      : null,
                  child: user['photoUrl'] == null
                      ? Text(
                    user['displayName'] != null && user['displayName'].isNotEmpty
                        ? user['displayName'][0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['displayName'] ?? 'Utilisateur inconnu',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (reason != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.deepPurple.shade800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isRequesting
                      ? null
                      : () => _sendFriendRequest(
                    user['userId'],
                    user['displayName'] ?? 'Utilisateur inconnu',
                  ),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: Text(isRequesting ? 'En cours...' : 'Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}