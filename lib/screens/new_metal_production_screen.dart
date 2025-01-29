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
      builder: (context) => AlertDialog(
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            title: 'Argent',
            value: '${gameState.player.money.toStringAsFixed(2)} €',
            icon: Icons.attach_money,
            color: Colors.green.shade100,
            onTap: () => _showDetailDialog(
              context,
              'Finances',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Solde actuel: ${gameState.player.money.toStringAsFixed(2)} €'),
                  Text('Dépenses/min: ${gameState.maintenanceCosts.toStringAsFixed(2)} €'),
                  Text('Prix de vente: ${gameState.player.sellPrice.toStringAsFixed(2)} €'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Production Totale et Stock
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'Total Produit',
                  value: formatNumber(gameState.totalPaperclipsProduced.toDouble()),
                  icon: Icons.all_inclusive,
                  color: Colors.purple.shade100,
                  onTap: () => _showDetailDialog(
                    context,
                    'Production Totale',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total produit: ${formatNumber(gameState.totalPaperclipsProduced.toDouble())}'),
                        Text('Production/min: ${(gameState.player.autoclippers * 60).toStringAsFixed(1)}'),
                        Text('Multiplicateur: x${gameState.level.productionMultiplier.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoCard(
                  title: 'Stock',
                  value: formatNumber(gameState.player.paperclips),
                  icon: Icons.inventory_2,
                  color: Colors.blue.shade100,
                  onTap: () => _showDetailDialog(
                    context,
                    'Stock de Trombones',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('En stock: ${formatNumber(gameState.player.paperclips)}'),
                        Text('Prix de vente: ${gameState.player.sellPrice.toStringAsFixed(2)} €'),
                        Text('Valeur totale: ${(gameState.player.paperclips * gameState.player.sellPrice).toStringAsFixed(2)} €'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Métal et Prix de Vente
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'Métal',
                  value: '${formatNumber(gameState.player.metal)}/${gameState.player.maxMetalStorage}',
                  icon: Icons.inventory,
                  color: Colors.grey.shade200,
                  onTap: () => _showDetailDialog(
                    context,
                    'Stock de Métal',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Stock: ${formatNumber(gameState.player.metal)}'),
                        Text('Capacité max: ${gameState.player.maxMetalStorage}'),
                        Text('Efficacité: ${((1 - ((gameState.player.upgrades["efficiency"]?.level ?? 0) * 0.15)) * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoCard(
                  title: 'Prix Vente',
                  value: '${gameState.player.sellPrice.toStringAsFixed(2)} €',
                  icon: Icons.price_change,
                  color: Colors.green.shade100,
                  onTap: () => _showDetailDialog(
                    context,
                    'Prix de Vente',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Prix actuel: ${gameState.player.sellPrice.toStringAsFixed(2)} €'),
                        Text('Prix min: ${GameConstants.MIN_PRICE.toStringAsFixed(2)} €'),
                        Text('Prix max: ${GameConstants.MAX_PRICE.toStringAsFixed(2)} €'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Autoclippers
          if (gameState.player.autoclippers > 0)
            Card(
              color: Colors.orange.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Autoclippers',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        Text(
                          '${gameState.player.autoclippers} actifs',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBonusIndicator(
                          'Production',
                          '${(gameState.player.autoclippers * 60).toStringAsFixed(1)}/min',
                          Icons.speed,
                        ),
                        _buildBonusIndicator(
                          'Efficacité',
                          '${((1 - ((gameState.player.upgrades["efficiency"]?.level ?? 0) * 0.15)) * 100).toStringAsFixed(0)}%',
                          Icons.eco,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),  // Espace supplémentaire avant le bouton de sauvegarde

          // Bouton de sauvegarde
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  if (gameState.gameName == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur: Aucun nom de partie défini'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  await SaveManager.saveGame(gameState, gameState.gameName!);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Partie sauvegardée avec succès'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la sauvegarde: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Sauvegarder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetalProductionTab(GameState gameState) {
    bool canProduce = gameState.player.metal + 100 <= gameState.player.maxMetalStorage;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Production de Métal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: canProduce ? () => gameState.player.updateMetal(gameState.player.metal + 100) : null,
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
                  Text(
                    '+100 Métal',
                    style: const TextStyle(
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
    );
  }

  Widget _buildUpgradesTab(GameState gameState) {
    var availableUpgrades = gameState.player.upgrades.entries
        .where((entry) => entry.value.level < entry.value.maxLevel)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...availableUpgrades.map((entry) => Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: Icon(
                _getUpgradeIcon(entry.key),
                color: Colors.blue,
                size: 32,
              ),
              title: Text(
                entry.value.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.value.description),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: entry.value.level / entry.value.maxLevel,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  Text(
                    'Niveau ${entry.value.level}/${entry.value.maxLevel}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: gameState.player.money >= entry.value.getCost()
                    ? () => gameState.purchaseUpgrade(entry.key)
                    : null,
                child: Text('${entry.value.getCost().toStringAsFixed(1)} €'),
              ),
              isThreeLine: true,
            ),
          )).toList(),
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
        return Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'Aperçu'),
                Tab(icon: Icon(Icons.precision_manufacturing), text: 'Production'),
                Tab(icon: Icon(Icons.upgrade), text: 'Améliorations'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildResourcesTab(gameState),
                  _buildMetalProductionTab(gameState),
                  _buildUpgradesTab(gameState),
                ],
              ),
            ),
            // Ajout des boutons de production
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton Autoclipper
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
                  // Bouton de production de trombone
                  const ProductionButton(), // Ne pas oublier d'importer '../widgets/production_button.dart'
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}