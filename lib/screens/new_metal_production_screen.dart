import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../widgets/resource_widgets.dart';
import '../widgets/level_widgets.dart';
import '../widgets/chart_widgets.dart';
import 'upgrades_screen.dart';
import '../widgets/production_button.dart';
import '../services/save_manager.dart';
import '../models/event_system.dart';
import '../utils/notification_manager.dart';


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

  void _showDetailDialog(BuildContext context, String title, Widget content) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(child: content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

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
                              // Utiliser le système de notification
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
                    // Liste des missions avec progression
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

                    // Section des statistiques
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Statistiques des Missions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Divider(),
                            _buildStatisticsRow(
                              'Production Manuelle',
                              gameState.statistics.getAllStats()['production']!['Production Manuelle']!.toString(),
                              Icons.touch_app,
                            ),
                            _buildStatisticsRow(
                              'Ventes Totales',
                              gameState.statistics.getAllStats()['economie']!['Ventes Totales']!.toString(),
                              Icons.shopping_cart,
                            ),
                            _buildStatisticsRow(
                              'Autoclippers',
                              gameState.statistics.getAllStats()['progression']!['Autoclippers Achetés']!.toString(),
                              Icons.precision_manufacturing,
                            ),
                            _buildStatisticsRow(
                              'Expérience',
                              gameState.levelSystem.experience.toStringAsFixed(1),
                              Icons.star,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionStat(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetalProductionTab(GameState gameState) {
    bool canProduce = gameState.player.metal + 100 <=
        gameState.player.maxMetalStorage;
    double remainingStorage = gameState.player.maxMetalStorage -
        gameState.player.metal;
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
                    color: possibleProductions > 5 ? Colors.green : Colors
                        .orange,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: canProduce
                      ? () =>
                      gameState.player.updateMetal(gameState.player.metal + 100)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.add_circle_outline, size: 64,
                          color: Colors.white),
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

          // Statistiques de production
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
                      '${formatNumber(gameState.player.metal)}/${formatNumber(
                          gameState.player.maxMetalStorage)}'),
                  _buildStatRow('Coût de Maintenance',
                      '${gameState.player.maintenanceCosts.toStringAsFixed(
                          2)} €/min'),
                  _buildStatRow('Niveau de Production',
                      '${gameState.level}'),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildUpgradesTab(GameState gameState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progression vers le mode crise
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progression vers le Mode Crise',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: gameState.marketManager.marketMetalStock /
                        GameConstants.INITIAL_MARKET_METAL,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getCrisisProgressColor(
                          gameState.marketManager.marketMetalStock),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stock de Métal Mondial: ${(gameState.marketManager
                        .marketMetalStock / GameConstants.INITIAL_MARKET_METAL *
                        100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Statistiques
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistiques Générales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildStatRow('Argent Total',
                      '${gameState.player.money.toStringAsFixed(2)} €'),
                  _buildStatRow('Autoclippers',
                      '${gameState.player.autoclippers}'),
                  _buildStatRow('Niveau',
                      '${gameState.level}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCrisisProgressColor(double stock) {
    if (stock <= GameConstants.METAL_CRISIS_THRESHOLD_0) return Colors.red;
    if (stock <= GameConstants.METAL_CRISIS_THRESHOLD_25) return Colors.orange;
    if (stock <= GameConstants.METAL_CRISIS_THRESHOLD_50) return Colors.yellow;
    return Colors.green;
  }

  Widget _buildRankingItem(String label, dynamic value, IconData icon,
      Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBonusIndicator(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.orange.shade900),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.orange.shade900,
          ),
        ),
      ],
    );
  }

  IconData _getUpgradeIcon(String id) {
    switch (id) {
      case 'efficiency':
        return Icons.eco;
      case 'marketing':
        return Icons.campaign;
      case 'bulk':
        return Icons.inventory;
      case 'speed':
        return Icons.speed;
      case 'storage':
        return Icons.warehouse;
      case 'automation':
        return Icons.precision_manufacturing;
      case 'quality':
        return Icons.grade;
      default:
        return Icons.extension;
    }
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
                  Tab(icon: Icon(Icons.dashboard), text: 'Aperçu'),
                  Tab(icon: Icon(Icons.precision_manufacturing),
                      text: 'Production'),
                  Tab(icon: Icon(Icons.upgrade), text: 'Améliorations'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(
                      child: _buildResourcesTab(gameState),
                    ),
                    SingleChildScrollView(
                      child: _buildMetalProductionTab(gameState),
                    ),
                    SingleChildScrollView(
                      child: _buildUpgradesTab(gameState),
                    ),
                  ],
                ),
              ),
              // Bottom section
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  color: Theme
                      .of(context)
                      .scaffoldBackgroundColor,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (gameState
                          .getVisibleScreenElements()['autoclippersSection'] ==
                          true)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: gameState.player.money >=
                                  gameState.autocliperCost
                                  ? () => gameState.buyAutoclipper()
                                  : null,
                              icon: const Icon(Icons.precision_manufacturing),
                              label: Text(
                                'Acheter Autoclipper (${gameState.autocliperCost
                                    .toStringAsFixed(2)} €)',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
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