import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../widgets/resource_widgets.dart';
import '../widgets/level_widgets.dart';
import '../widgets/chart_widgets.dart';
import '../widgets/production_button.dart';
import '../services/save_manager.dart';
import '../models/event_system.dart';
import '../utils/notification_manager.dart';
import 'package:paperclip2/services/games_services_controller.dart';

class NewMetalProductionScreen extends StatefulWidget {
  const NewMetalProductionScreen({Key? key}) : super(key: key);

  @override
  State<NewMetalProductionScreen> createState() => _NewMetalProductionScreenState();
}

class _NewMetalProductionScreenState extends State<NewMetalProductionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  // Gardons votre onglet Aperçu (Missions Journalières) intact
  Widget _buildResourcesTab(GameState gameState) {
    bool allMissionsCompleted = gameState.missionSystem.dailyMissions
        .every((mission) => mission.isCompleted);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Missions Journalières',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.deepPurple,
                          ),
                        ),
                        if (allMissionsCompleted)
                          ElevatedButton.icon(
                            onPressed: () {
                              gameState.levelSystem.gainExperience(
                                  GameConstants.DAILY_BONUS_AMOUNT * 2
                              );
                              gameState.missionSystem.onMissionSystemRefresh?.call();
                            },
                            icon: const Icon(Icons.stars, color: Colors.amber),
                            label: const Text('Réclamer Bonus'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    const Divider(),
                    ...gameState.missionSystem.dailyMissions.map((mission) =>
                        Card(
                          color: mission.isCompleted ? Colors.green.shade50 : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  leading: Icon(
                                    mission.isCompleted ? Icons.check_circle : Icons.pending,
                                    color: mission.isCompleted ? Colors.green : Colors.orange,
                                    size: 32,
                                  ),
                                  title: Text(
                                    mission.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(mission.description),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${mission.experienceReward} XP',
                                        style: const TextStyle(
                                          color: Colors.deepPurple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(mission.progress / mission.target * 100).toInt()}%',
                                        style: TextStyle(
                                          color: mission.isCompleted ? Colors.green : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                LinearProgressIndicator(
                                  value: mission.progress / mission.target,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    mission.isCompleted ? Colors.green : Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gardons votre onglet Production intact
  Widget _buildMetalProductionTab(GameState gameState) {
    bool canProduce = gameState.player.metal + 100 <= gameState.player.maxMetalStorage;
    double remainingStorage = gameState.player.maxMetalStorage - gameState.player.metal;
    int possibleProductions = (remainingStorage / 100).floor();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Productions restantes : $possibleProductions',
                  style: TextStyle(
                    fontSize: 16,
                    color: possibleProductions > 5 ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: canProduce
                      ? () => gameState.player.updateMetal(gameState.player.metal + 100)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.add_circle_outline, size: 64, color: Colors.white),
                      const SizedBox(height: 16),
                      const Text(
                        '+100 Métal',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Gratuit',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[100],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistiques de Production',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildStatRow('Métal Stocké',
                      '${formatNumber(gameState.player.metal)}/${formatNumber(gameState.player.maxMetalStorage)}'),
                  _buildStatRow('Coût de Maintenance',
                      '${gameState.player.maintenanceCosts.toStringAsFixed(2)} €/min'),
                  _buildStatRow('Niveau de Production', '${gameState.level}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Nouvel onglet des classements
  Widget _buildLeaderboardsTab(GameState gameState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Classements Mondiaux',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const Divider(),
                  _buildLeaderboardCard(
                    title: 'Classement Général',
                    icon: Icons.leaderboard,
                    mainValue: gameState.totalPaperclipsProduced.toString(),
                    subtitle: 'Trombones Produits',
                    secondaryValue: gameState.formattedPlayTime,
                    secondaryLabel: 'Temps de jeu',
                    color: Colors.blue.shade100,
                    leaderboardId: 'CgkI-ICryvIBEAIQAg',
                    onTap: (bool friendsOnly) async {
                      final controller = GamesServicesController();
                      if (await controller.isSignedIn()) {
                        controller.showLeaderboard(friendsOnly: friendsOnly);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLeaderboardCard(
                    title: 'Machine de Production',
                    icon: Icons.precision_manufacturing,
                    mainValue: formatNumber(gameState.totalPaperclipsProduced.toDouble()),
                    subtitle: 'Production Totale',
                    secondaryValue: '${gameState.player.autoclippers}',
                    secondaryLabel: 'Autoclippers',
                    color: Colors.green.shade100,
                    leaderboardId: 'CgkI-ICryvIBEAIQAw', // Ajouter cet ID
                    onTap: (bool friendsOnly) async {
                      final controller = GamesServicesController();
                      if (await controller.isSignedIn()) {
                        controller.showProductionLeaderboard(friendsOnly: friendsOnly);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLeaderboardCard(
                    title: 'Banquier Hors Pair',
                    icon: Icons.attach_money,
                    mainValue: formatNumber(gameState.statistics.getTotalMoneyEarned()),
                    subtitle: 'Argent Total Gagné',
                    secondaryValue: formatNumber(gameState.player.money),
                    secondaryLabel: 'Fortune Actuelle',
                    color: Colors.amber.shade100,
                    leaderboardId: 'CgkI-ICryvIBEAIQBA', // Ajouter cet ID
                    onTap: (bool friendsOnly) async {
                      final controller = GamesServicesController();
                      if (await controller.isSignedIn()) {
                        controller.showBankerLeaderboard(friendsOnly: friendsOnly);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('Synchroniser les scores'),
                    subtitle: const Text('Mettre à jour tous les classements'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      gameState.updateLeaderboard();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Scores synchronisés !'),
                          duration: Duration(seconds: 2),
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
  Widget _buildAchievementSection() {
    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progression des succès',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Divider(),
            FutureBuilder<double?>(
              // Utilisez la constante du contrôleur pour l'ID
              future: GamesServicesController().getAchievementProgress('CgkI-ICryvIBEAIQAQ'),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final progress = snapshot.data ?? 0.0;
                  return Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ],
        ),
      ),
    );
  }
  // Dans new_metal_production_screen.dart

  Widget _buildLeaderboardCard({
    required String title,
    required IconData icon,
    required String mainValue,
    required String subtitle,
    required String secondaryValue,
    required String secondaryLabel,
    required Color color,
    required Function(bool) onTap,
    required String leaderboardId,
  }) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<LeaderboardInfo?>(
              future: GamesServicesController().getLeaderboardInfo(leaderboardId, title),
              builder: (context, snapshot) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Score actuel',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        Text(
                          mainValue,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Meilleur score',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        Text(
                          snapshot.hasData && snapshot.data != null
                              ? formatNumber(snapshot.data!.bestScore.toDouble())
                              : mainValue,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (snapshot.hasData && snapshot.data?.rank != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Rang mondial',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          Text(
                            '#${snapshot.data!.rank}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.public),
                  label: const Text('Global'),
                  onPressed: () => onTap(false),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.people),
                  label: const Text('Amis'),
                  onPressed: () => onTap(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Scaffold(
          body: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard), text: 'Missions'),
                  Tab(icon: Icon(Icons.precision_manufacturing), text: 'Production'),
                  Tab(icon: Icon(Icons.leaderboard), text: 'Classements'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(child: _buildResourcesTab(gameState)),
                    SingleChildScrollView(child: _buildMetalProductionTab(gameState)),
                    SingleChildScrollView(child: _buildLeaderboardsTab(gameState)),
                  ],
                ),
              ),
              // Bottom section
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (gameState.getVisibleScreenElements()['autoclippersSection'] == true)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: gameState.player.money >= gameState.autocliperCost
                                  ? () => gameState.buyAutoclipper()
                                  : null,
                              icon: const Icon(Icons.precision_manufacturing),
                              label: Text(
                                'Acheter Autoclipper (${gameState.autocliperCost.toStringAsFixed(2)} €)',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      const ProductionButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}