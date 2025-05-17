// lib/screens/social/friend_comparison_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/social/user_stats_model.dart';
import '../../services/social/user_stats_service.dart';
import '../../services/user/user_manager.dart';
import '../../models/game_state.dart';
import '../../widgets/social/widget_stat_comparison.dart';

class FriendComparisonScreen extends StatefulWidget {
  final String friendId;

  const FriendComparisonScreen({
    Key? key,
    required this.friendId,
  }) : super(key: key);

  @override
  State<FriendComparisonScreen> createState() => _FriendComparisonScreenState();
}

class _FriendComparisonScreenState extends State<FriendComparisonScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _comparisonData;
  String? _errorMessage;
  late final UserStatsService _userStatsService;

  @override
  void initState() {
    super.initState();
    _loadComparison();
  }

  Future<void> _loadComparison() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userManager = Provider.of<UserManager>(context, listen: false);
      final gameState = Provider.of<GameState>(context, listen: false);
      final userId = userManager.currentProfile?.userId;

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      _userStatsService = UserStatsService(userId, userManager);

      // Mettre à jour nos statistiques avant la comparaison
      await _userStatsService.updatePublicStats(gameState);

      // Récupérer la comparaison
      final comparisonData = await _userStatsService.compareWithFriend(
        widget.friendId,
        gameState,
      );

      if (comparisonData == null) {
        throw Exception('Impossible de récupérer les statistiques');
      }

      setState(() {
        _comparisonData = comparisonData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_comparisonData != null
            ? 'Comparaison avec ${_comparisonData!['friend']['displayName']}'
            : 'Comparaison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadComparison,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Récupération des statistiques...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erreur: $_errorMessage',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadComparison,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_comparisonData == null) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    final comparison = _comparisonData!['comparison'];
    final me = _comparisonData!['me'];
    final friend = _comparisonData!['friend'];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPlayersInfo(me, friend),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Comparaison des performances',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),

          WidgetStatComparison(
            title: 'Trombones produits',
            myValue: comparison['totalPaperclips']['me'],
            friendValue: comparison['totalPaperclips']['friend'],
            difference: comparison['totalPaperclips']['diff'],
            icon: Icons.construction,
            useCompactMode: false,
          ),

          WidgetStatComparison(
            title: 'Niveau',
            myValue: comparison['level']['me'],
            friendValue: comparison['level']['friend'],
            difference: comparison['level']['diff'],
            icon: Icons.trending_up,
          ),

          WidgetStatComparison(
            title: 'Argent',
            myValue: comparison['money']['me'],
            friendValue: comparison['money']['friend'],
            difference: comparison['money']['diff'],
            icon: Icons.attach_money,
            valueFormatter: (value) => '${value.toStringAsFixed(2)} \$',
          ),

          WidgetStatComparison(
            title: 'Meilleur score',
            myValue: comparison['bestScore']['me'],
            friendValue: comparison['bestScore']['friend'],
            difference: comparison['bestScore']['diff'],
            icon: Icons.score,
            higherIsBetter: true,
          ),

          WidgetStatComparison(
            title: 'Efficacité',
            myValue: comparison['efficiency']['me'],
            friendValue: comparison['efficiency']['friend'],
            difference: comparison['efficiency']['diff'],
            icon: Icons.speed,
            valueFormatter: (value) => '${(value * 100).toStringAsFixed(1)}%',
            higherIsBetter: true,
          ),

          WidgetStatComparison(
            title: 'Améliorations achetées',
            myValue: comparison['upgradesBought']['me'],
            friendValue: comparison['upgradesBought']['friend'],
            difference: comparison['upgradesBought']['diff'],
            icon: Icons.upgrade,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPlayersInfo(Map<String, dynamic> me, Map<String, dynamic> friend) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildPlayerCard(
            me['displayName'],
            me['photoUrl'],
            'Vous',
            Colors.blue.shade100,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Center(
              child: Text(
                'VS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildPlayerCard(
            friend['displayName'],
            null,
            'Ami',
            Colors.orange.shade100,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(String name, String? photoUrl, String label, Color color) {
    return Expanded(
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 30,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null ? const Icon(Icons.person, size: 30) : null,
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}