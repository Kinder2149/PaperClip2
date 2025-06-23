// Créer un nouveau fichier lib/screens/competitive_result_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../widgets/resources/resource_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'start_screen.dart';
import 'main_screen.dart';

// Modèle pour les scores des amis
class FriendScore {
  final String name;
  final int score;
  final bool isCurrentPlayer;

  FriendScore({
    required this.name,
    required this.score,
    this.isCurrentPlayer = false,
  });
}

class CompetitiveResultScreen extends StatefulWidget {
  final int score;
  final int paperclips;
  final double money;
  final Duration playTime;
  final int level;
  final double efficiency;
  final VoidCallback onNewGame;
  final VoidCallback onShowLeaderboard;

  const CompetitiveResultScreen({
    Key? key,
    required this.score,
    required this.paperclips,
    required this.money,
    required this.playTime,
    required this.level,
    required this.efficiency,
    required this.onNewGame,
    required this.onShowLeaderboard,
  }) : super(key: key);

  @override
  State<CompetitiveResultScreen> createState() => _CompetitiveResultScreenState();
}

class _CompetitiveResultScreenState extends State<CompetitiveResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnimation;
  List<FriendScore> _friendScores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Configurer l'animation
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scoreAnimation = Tween<double>(
      begin: 0,
      end: widget.score.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Charger les scores des amis
    _loadFriendScores();
  }

  Future<void> _loadFriendScores() async {
    setState(() {
      _isLoading = true;
    });

    // Simuler un chargement (remplacer par l'appel réel aux scores des amis)
    await Future.delayed(const Duration(seconds: 1));

    // Données de test - à remplacer par des données réelles
    final mockScores = [
      FriendScore(name: 'Vous', score: widget.score, isCurrentPlayer: true),
      FriendScore(name: 'Alex', score: 87500),
      FriendScore(name: 'Marie', score: 76200),
      FriendScore(name: 'Thomas', score: 62400),
      FriendScore(name: 'Sophie', score: 58700),
    ];

    // Trier par score décroissant
    mockScores.sort((a, b) => b.score.compareTo(a.score));

    setState(() {
      _friendScores = mockScores;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête avec effet parallaxe
              _buildHeader(),

              const SizedBox(height: 24),

              // Détails de la partie
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TabBar(
                            labelColor: Colors.deepPurple,
                            unselectedLabelColor: Colors.grey,
                            tabs: [
                              Tab(text: 'Résumé'),
                              Tab(text: 'Classement'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: TabBarView(
                              children: [
                                // Onglet Résumé
                                _buildSummaryTab(),

                                // Onglet Classement
                                _buildLeaderboardTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.replay),
                      label: const Text('Nouvelle partie'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: widget.onNewGame,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.leaderboard),
                      label: const Text('Classement'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: widget.onShowLeaderboard,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              TextButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Retourner à l\'accueil'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const StartScreen()),
                        (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.amber.shade700, Colors.deepOrange.shade900],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Éléments décoratifs
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.star,
              size: 100,
              color: Colors.yellow.withOpacity(0.3),
            ),
          ),

          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Partie Terminée !',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mode Compétitif',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Score final: ',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _scoreAnimation,
                        builder: (context, child) {
                          return Text(
                            _scoreAnimation.value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques de partie',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Cartes pour les principales statistiques
          _buildStatCard(
            icon: Icons.timer,
            title: 'Temps de jeu',
            value: _formatDuration(widget.playTime),
            detail: 'Jusqu\'à la crise de métal',
          ),

          _buildStatCard(
            icon: Icons.link,
            title: 'Trombones produits',
            value: widget.paperclips.toString(),
            detail: 'Avec une efficacité de ${widget.efficiency.toStringAsFixed(2)}',
          ),

          _buildStatCard(
            icon: Icons.euro,
            title: 'Argent accumulé',
            value: MoneyDisplay.formatNumber(widget.money),
            detail: 'Le nerf de la guerre !',
          ),

          _buildStatCard(
            icon: Icons.trending_up,
            title: 'Niveau atteint',
            value: widget.level.toString(),
            detail: 'Plus de niveaux = plus de fonctionnalités',
          ),

          const SizedBox(height: 16),

          // Graphique pour décomposer le score
          _buildScoreBreakdownChart(),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comparaison avec les amis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Liste des scores
        Expanded(
          child: ListView.builder(
            itemCount: _friendScores.length,
            itemBuilder: (context, index) {
              final score = _friendScores[index];
              final rank = index + 1;

              return Card(
                elevation: score.isCurrentPlayer ? 4 : 1,
                color: score.isCurrentPlayer ? Colors.amber.shade50 : null,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getRankColor(rank),
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    score.name,
                    style: TextStyle(
                      fontWeight: score.isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    score.score.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Actualiser'),
          onPressed: _loadFriendScores,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String detail,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.deepPurple,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBreakdownChart() {
    // Calculer les pourcentages approximatifs pour la décomposition du score
    double productionPct = widget.paperclips * 10 / widget.score * 100;
    double moneyPct = widget.money * 5 / widget.score * 100;
    double levelPct = widget.level * 1000 / widget.score * 100;
    double efficiencyPct = widget.efficiency * 500 / widget.score * 100;

    // Ajuster pour que le total soit 100%
    final total = productionPct + moneyPct + levelPct + efficiencyPct;
    if (total > 0) {
      productionPct = productionPct / total * 100;
      moneyPct = moneyPct / total * 100;
      levelPct = levelPct / total * 100;
      efficiencyPct = efficiencyPct / total * 100;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Décomposition du score',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: Colors.blue,
                  value: productionPct,
                  title: '${productionPct.round()}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.green,
                  value: moneyPct,
                  title: '${moneyPct.round()}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.purple,
                  value: levelPct,
                  title: '${levelPct.round()}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.orange,
                  value: efficiencyPct,
                  title: '${efficiencyPct.round()}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegendItem(Colors.blue, 'Production (Trombones)'),
        _buildLegendItem(Colors.green, 'Argent accumulé'),
        _buildLegendItem(Colors.purple, 'Niveau atteint'),
        _buildLegendItem(Colors.orange, 'Efficacité'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    int seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade700; // Or
      case 2:
        return Colors.blueGrey.shade300; // Argent
      case 3:
        return Colors.brown.shade300; // Bronze
      default:
        return Colors.blueGrey.shade700; // Autres rangs
    }
  }
}