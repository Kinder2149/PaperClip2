import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../widgets/resource_widgets.dart';
import '../widgets/level_widgets.dart';
import '../widgets/chart_widgets.dart';
import '../widgets/production_button.dart';
import 'upgrades_screen.dart';

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

  Widget _buildResourcesTab(GameState gameState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Vue d'ensemble des ressources avec détails
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const ResourceOverview(),
                  const SizedBox(height: 12),
                  // Détails de production actuelle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Production/min', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${(gameState.player.autoclippers * 60).toStringAsFixed(1)}'),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Efficacité', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${(gameState.player.upgrades['efficiency']?.level ?? 0) * 10}%'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Niveau et XP avec bonus
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const LevelDisplay(),
                  const SizedBox(height: 8),
                  // Affichage des bonus actifs
                  Wrap(
                    spacing: 8,
                    children: [
                      if (gameState.levelSystem.totalXpMultiplier > 1)
                        Chip(
                          avatar: const Icon(Icons.star, size: 16),
                          label: Text('XP x${gameState.levelSystem.totalXpMultiplier.toStringAsFixed(1)}'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status du marché et statistiques
          const ResourceStatusWidget(),
          const SizedBox(height: 16),
          const StatsOverview(),
        ],
      ),
    );
  }

  Widget _buildProductionTab(GameState gameState) {
    bool canBuyBasic = gameState.player.metal + 100 <= gameState.player.maxMetalStorage;
    bool canBuyPremium = gameState.player.money >= 50 &&
        gameState.player.metal + 250 <= gameState.player.maxMetalStorage;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Status des Autoclippers
          if (gameState.player.autoclippers > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status Autoclippers',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${gameState.player.autoclippers} actifs',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Production: ${(gameState.player.autoclippers * 60).toStringAsFixed(1)}/min'),
                        Text('Coût: ${gameState.maintenanceCosts.toStringAsFixed(2)} €/min'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.7,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Production alternative
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Production Alternative de Métal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const XPStatusDisplay(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildProductionButton(
                        title: 'Production Basique',
                        metal: 100,
                        cost: 0,
                        time: '5s',
                        color: Colors.blue,
                        enabled: canBuyBasic,
                        onPressed: () {
                          if (canBuyBasic) {
                            gameState.player.updateMetal(
                              gameState.player.metal + 100,
                            );
                          }
                        },
                      ),
                      _buildProductionButton(
                        title: 'Production Avancée',
                        metal: 250,
                        cost: 50,
                        time: '10s',
                        color: Colors.green,
                        enabled: canBuyPremium,
                        onPressed: () {
                          if (canBuyPremium) {
                            gameState.player.updateMoney(
                              gameState.player.money - 50,
                            );
                            gameState.player.updateMetal(
                              gameState.player.metal + 250,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Graphiques et performances
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performances de Production',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: SalesChart(salesHistory: gameState.market.salesHistory),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradesTab() {
    return const UpgradesScreen();
  }

  Widget _buildProductionButton({
    required String title,
    required int metal,
    required double cost,
    required String time,
    required Color color,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '$metal Métal',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              cost > 0 ? '${cost.toStringAsFixed(0)} €' : 'Gratuit',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              time,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Column(
          children: [
            // TabBar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.query_stats), text: 'Ressources'),
                Tab(icon: Icon(Icons.factory), text: 'Production'),
                Tab(icon: Icon(Icons.upgrade), text: 'Améliorations'),
              ],
            ),
            // Contenu principal
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildResourcesTab(gameState),
                  _buildProductionTab(gameState),
                  _buildUpgradesTab(),
                ],
              ),
            ),
            // Zone de production fixe en bas
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton d'achat d'autoclippers
                  if (gameState.getVisibleScreenElements()['autoclippersSection'] == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: gameState.player.money >= gameState.autocliperCost
                              ? () => gameState.buyAutoclipper()
                              : null,
                          icon: const Icon(Icons.precision_manufacturing),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Acheter Autoclipper'),
                              const SizedBox(width: 8),
                              Text(
                                '(${gameState.autocliperCost.toStringAsFixed(2)} €)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),

                  // Bouton de production classique
                  const ProductionButton(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}