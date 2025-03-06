// lib/presentation/screens/new_metal_production_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../core/constants/imports.dart';
import '../../core/constants/game_constants.dart';
import '../viewmodels/market_viewmodel.dart';
import '../viewmodels/production_viewmodel.dart';
import '../widgets/chart_widgets.dart';
import '../widgets/resource_widgets.dart';

class NewMetalProductionScreen extends StatefulWidget {
  const NewMetalProductionScreen({Key? key}) : super(key: key);

  @override
  State<NewMetalProductionScreen> createState() => _NewMetalProductionScreenState();
}

class _NewMetalProductionScreenState extends State<NewMetalProductionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<double> _priceHistory = [];
  Timer? _priceUpdateTimer;
  bool _isRefreshing = false;
  double _simulatedEfficiency = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialiser l'historique des prix
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final marketViewModel = Provider.of<MarketViewModel>(context, listen: false);
      if (marketViewModel.marketState != null) {
        setState(() {
          _priceHistory.add(marketViewModel.marketState!.currentMetalPrice);
        });
      }
    });

    // Simuler les mises à jour des prix pour le graphique
    _startPriceUpdateSimulation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _priceUpdateTimer?.cancel();
    super.dispose();
  }

  void _startPriceUpdateSimulation() {
    _priceUpdateTimer = Timer.periodic(
      GameConstants.METAL_PRICE_UPDATE_INTERVAL,
          (_) => _updatePriceHistory(),
    );
  }

  void _updatePriceHistory() {
    final marketViewModel = Provider.of<MarketViewModel>(context, listen: false);
    if (marketViewModel.marketState != null) {
      setState(() {
        if (_priceHistory.length >= 20) {
          _priceHistory.removeAt(0);
        }

        // Ajouter un peu de variation aléatoire pour la simulation
        double currentPrice = marketViewModel.marketState!.currentMetalPrice;
        double variationFactor = 0.02; // 2% de variation max
        double variation = (math.Random().nextDouble() * 2 - 1) * variationFactor;
        double newPrice = currentPrice * (1 + variation);
        newPrice = math.max(GameConstants.MIN_METAL_PRICE,
            math.min(GameConstants.MAX_METAL_PRICE, newPrice));

        _priceHistory.add(newPrice);
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simuler une opération de rafraîchissement
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Production de Métal'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Achat de Métal'),
            Tab(text: 'Statistiques'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMetalPurchaseTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildMetalPurchaseTab() {
    return Consumer2<MarketViewModel, ProductionViewModel>(
      builder: (context, marketViewModel, productionViewModel, child) {
        if (marketViewModel.isLoading || productionViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (marketViewModel.error != null) {
          return Center(child: Text('Erreur: ${marketViewModel.error}'));
        }

        if (marketViewModel.marketState == null || productionViewModel.playerState == null) {
          return const Center(child: Text('Données non disponibles'));
        }

        final market = marketViewModel.marketState!;
        final player = productionViewModel.playerState!;

        // Calculer le coût et vérifier si l'achat est possible
        final metalPrice = market.currentMetalPrice;
        final canBuyMetal = player.money >= metalPrice &&
            player.metal + GameConstants.METAL_PACK_AMOUNT <= player.maxMetalStorage;

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations sur les ressources
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vos Ressources',
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ResourceDisplay(
                                label: 'Métal',
                                value: player.metal,
                                icon: Icons.inventory_2,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ResourceDisplay(
                                label: 'Argent',
                                value: player.money,
                                icon: Icons.attach_money,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ProgressBar(
                          progress: player.metal / player.maxMetalStorage,
                          color: Colors.blue,
                          label: 'Capacité de stockage: ${player.metal.toStringAsFixed(1)}/${player.maxMetalStorage.toStringAsFixed(1)}',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Graphique du prix du métal
                if (_priceHistory.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: MetalPriceHistoryChart(
                        priceHistory: _priceHistory,
                        currentPrice: market.currentMetalPrice,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Section d'achat de métal
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acheter du Métal',
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Prix actuel du métal:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    '${metalPrice.toStringAsFixed(2)} €',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: _isPriceGood(metalPrice) ? Colors.green[700] : Colors.orange[700],
                                    ),
                                  ),
                                  Text(
                                    _getPriceComment(metalPrice),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Quantité:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  '${GameConstants.METAL_PACK_AMOUNT.toStringAsFixed(1)} unités',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: canBuyMetal
                                ? () => _buyMetal(marketViewModel)
                                : null,
                            icon: const Icon(Icons.shopping_cart),
                            label: Text(
                              'Acheter pour ${metalPrice.toStringAsFixed(2)} €',
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),

                        if (!canBuyMetal)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              player.money < metalPrice
                                  ? 'Fonds insuffisants pour l\'achat'
                                  : 'Stockage insuffisant pour plus de métal',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Section de marché
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marché de Métal',
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stock disponible:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    '${market.marketMetalStock.toStringAsFixed(0)} unités',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tendance:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        _priceHistory.length >= 2
                                            ? _priceHistory.last > _priceHistory[_priceHistory.length - 2]
                                            ? Icons.trending_up
                                            : Icons.trending_down
                                            : Icons.trending_flat,
                                        color: _priceHistory.length >= 2
                                            ? _priceHistory.last > _priceHistory[_priceHistory.length - 2]
                                            ? Colors.red
                                            : Colors.green
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getTrendText(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Jauge de stock de marché
                        ProgressBar(
                          progress: market.marketMetalStock / GameConstants.INITIAL_MARKET_METAL,
                          color: _getStockColor(market.marketMetalStock),
                          label: 'Réserves mondiales: ${(market.marketMetalStock / GameConstants.INITIAL_MARKET_METAL * 100).toStringAsFixed(1)}%',
                        ),

                        if (market.marketMetalStock < GameConstants.MARKET_DEPLETION_THRESHOLD)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Alerte: Les réserves mondiales de métal diminuent!',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontStyle: FontStyle.italic,
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
      },
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer<ProductionViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.playerState == null) {
          return const Center(child: Text('Données non disponibles'));
        }

        final player = viewModel.playerState!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Efficacité de la Production',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      const SizedBox(height: 16),

                      // Calcul de l'efficacité
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Métal par trombone:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  _calculateMetalPerClip(player).toStringAsFixed(3),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Économie:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  _getEfficiencyPercentage(player),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Slider d'efficacité simulée
                      Text(
                        'Simulation d\'amélioration:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      Slider(
                        value: _simulatedEfficiency,
                        onChanged: (value) {
                          setState(() {
                            _simulatedEfficiency = value;
                          });
                        },
                        min: 0.0,
                        max: 0.85, // Maximum d'efficacité possible
                        divisions: 17,
                        label: '${(_simulatedEfficiency * 100).toStringAsFixed(0)}%',
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Baseline',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Max (85%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Résultats de simulation
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Simulation des résultats:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Métal par trombone:'),
                                Text(
                                  _calculateSimulatedMetalPerClip(_simulatedEfficiency).toStringAsFixed(3),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Économie par trombone:'),
                                Text(
                                  (GameConstants.METAL_PER_PAPERCLIP - _calculateSimulatedMetalPerClip(_simulatedEfficiency)).toStringAsFixed(3),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Niveau d\'amélioration requis:'),
                                Text(
                                  _getRequiredUpgradeLevel(_simulatedEfficiency).toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Graphique des coûts de production
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analyse des Coûts',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      const SizedBox(height: 16),

                      // Tableau des coûts
                      Table(
                        border: TableBorder.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                            ),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Production',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Coût unitaire',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Coût / 100',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          _buildCostTableRow('Standard', GameConstants.METAL_PER_PAPERCLIP, GameConstants.METAL_PER_PAPERCLIP * 100),
                          _buildCostTableRow('Actuelle', _calculateMetalPerClip(player), _calculateMetalPerClip(player) * 100),
                          _buildCostTableRow('Simulée', _calculateSimulatedMetalPerClip(_simulatedEfficiency), _calculateSimulatedMetalPerClip(_simulatedEfficiency) * 100),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Économies potentielles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Calcul des économies
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Économie par 1000 trombones:'),
                                Text(
                                  '${((GameConstants.METAL_PER_PAPERCLIP - _calculateSimulatedMetalPerClip(_simulatedEfficiency)) * 1000).toStringAsFixed(1)} métal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Coût économisé (prix actuel):'),
                                Consumer<MarketViewModel>(
                                  builder: (context, marketViewModel, child) {
                                    double currentPrice = marketViewModel.marketState?.currentMetalPrice ?? 20.0;
                                    double savings = (GameConstants.METAL_PER_PAPERCLIP - _calculateSimulatedMetalPerClip(_simulatedEfficiency)) * 1000 * currentPrice;

                                    return Text(
                                      '${savings.toStringAsFixed(2)} €',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  TableRow _buildCostTableRow(String label, double unitCost, double bulkCost) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(unitCost.toStringAsFixed(3)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(bulkCost.toStringAsFixed(1)),
        ),
      ],
    );
  }

  void _buyMetal(MarketViewModel marketViewModel) async {
    final result = await marketViewModel.buyMetal();

    if (result != null && result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Achat de métal réussi!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec de l\'achat de métal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _calculateMetalPerClip(PlayerEntity player) {
    final efficiencyLevel = player.upgrades['efficiency']?.level ?? 0;
    final metalReduction = efficiencyLevel * 0.11; // 11% de réduction par niveau
    final reduction = metalReduction.clamp(0.0, 0.85); // Maximum 85% de réduction
    return GameConstants.METAL_PER_PAPERCLIP * (1.0 - reduction);
  }

  double _calculateSimulatedMetalPerClip(double efficiencyRate) {
    return GameConstants.METAL_PER_PAPERCLIP * (1.0 - efficiencyRate);
  }

  int _getRequiredUpgradeLevel(double efficiency) {
    // Calculer quel niveau d'amélioration serait nécessaire pour atteindre cette efficacité
    return (efficiency / 0.11).ceil();
  }

  String _getEfficiencyPercentage(PlayerEntity player) {
    final efficiencyLevel = player.upgrades['efficiency']?.level ?? 0;
    final metalReduction = efficiencyLevel * 0.11;
    final reduction = metalReduction.clamp(0.0, 0.85);
    return '${(reduction * 100).toStringAsFixed(1)}%';
  }

  bool _isPriceGood(double price) {
    return price < (GameConstants.MIN_METAL_PRICE + GameConstants.MAX_METAL_PRICE) / 2;
  }

  String _getPriceComment(double price) {
    if (price <= GameConstants.MIN_METAL_PRICE * 1.1) {
      return 'Prix excellent! C\'est le moment d\'acheter.';
    } else if (price < (GameConstants.MIN_METAL_PRICE + GameConstants.MAX_METAL_PRICE) / 2) {
      return 'Bon prix pour un achat.';
    } else if (price < GameConstants.MAX_METAL_PRICE * 0.9) {
      return 'Prix moyen, attendez peut-être une baisse.';
    } else {
      return 'Prix élevé, attendez une meilleure opportunité.';
    }
  }

  String _getTrendText() {
    if (_priceHistory.length < 2) {
      return 'Stable';
    }

    final latestPrice = _priceHistory.last;
    final previousPrice = _priceHistory[_priceHistory.length - 2];

    final percentChange = (latestPrice - previousPrice) / previousPrice * 100;

    if (percentChange.abs() < 0.5) {
      return 'Stable';
    } else if (percentChange > 0) {
      return 'En hausse';
    } else {
      return 'En baisse';
    }
  }

  Color _getStockColor(double stockLevel) {
    if (stockLevel < GameConstants.METAL_CRISIS_THRESHOLD_25) {
      return Colors.red;
    } else if (stockLevel < GameConstants.METAL_CRISIS_THRESHOLD_50) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }
}