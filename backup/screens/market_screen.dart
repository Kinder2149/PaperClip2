import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/market.dart';
import '../models/game_config.dart';
import '../widgets/chart_widgets.dart';
import '../widgets/resource_widgets.dart';
import 'demand_calculation_screen.dart';
import '../services/save_manager.dart';
import '../screens/sales_history_screen.dart';
import 'dart:math' show min;

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  Widget _buildMarketCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onInfoPressed,
    Widget? trailing,
  }) {
    return Card(
      elevation: 2,
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (tooltip.isNotEmpty)
                    Text(
                      tooltip,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              onPressed: onInfoPressed,
              tooltip: tooltip,
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // Dans lib/screens/market_screen.dart

  Future<void> _saveGame(BuildContext context, GameState gameState) async {
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

      await gameState.saveGame(gameState.gameName!);

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
  }

  Widget _buildPriceControls(GameState gameState) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Min: ${GameConstants.MIN_PRICE.toStringAsFixed(2)} €',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              'Max: ${GameConstants.MAX_PRICE.toStringAsFixed(2)} €',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                double newValue = gameState.player.sellPrice - 0.01;
                if (newValue >= GameConstants.MIN_PRICE) {
                  gameState.player.updateSellPrice(newValue);
                }
              },
            ),
            Expanded(
              child: Slider(
                value: gameState.player.sellPrice,
                min: GameConstants.MIN_PRICE,
                max: GameConstants.MAX_PRICE,
                divisions: 200,
                label: '${gameState.player.sellPrice.toStringAsFixed(2)} €',
                onChanged: (value) => gameState.player.updateSellPrice(value),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                double newValue = gameState.player.sellPrice + 0.01;
                if (newValue <= GameConstants.MAX_PRICE) {
                  gameState.player.updateSellPrice(newValue);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  String _formatBonusText(String name, double bonus) {
    return '${name}: ${((bonus - 1.0) * 100).toStringAsFixed(1)}%';
  }

  Widget _buildProductionCard(BuildContext context, GameState gameState, double autoclipperProduction) {
    List<String> bonuses = [];

    double speedBonus = 1.0 + ((gameState.player.upgrades['speed']?.level ?? 0) * 0.20);
    double bulkBonus = 1.0 + ((gameState.player.upgrades['bulk']?.level ?? 0) * 0.35);
    double efficiencyBonus = 1.0 - ((gameState.player.upgrades['efficiency']?.level ?? 0) * 0.15);

    int speedLevel = gameState.player.upgrades['speed']?.level ?? 0;
    int bulkLevel = gameState.player.upgrades['bulk']?.level ?? 0;
    int efficiencyLevel = gameState.player.upgrades['efficiency']?.level ?? 0;

    if (speedLevel > 0) {
      bonuses.add(_formatBonusText('Vitesse', speedBonus));
    }
    if (bulkLevel > 0) {
      bonuses.add(_formatBonusText('Production en masse', bulkBonus));
    }
    if (efficiencyLevel > 0) {
      bonuses.add('Efficacité: -${((1.0 - efficiencyBonus) * 100).toStringAsFixed(1)}%');
    }

    double baseProduction = gameState.player.autoclippers * 60;

    return _buildMarketCard(
      title: 'Production des Autoclippers',
      value: '${autoclipperProduction.toStringAsFixed(1)}/min',
      icon: Icons.precision_manufacturing,
      color: Colors.orange.shade100,
      tooltip: 'Production avec bonus appliqués',
      onInfoPressed: () => _showInfoDialog(
        context,
        'Production Détaillée',
        'Détails de la production :\n'
            '- Base (${gameState.player.autoclippers} autoclippers): ${baseProduction.toStringAsFixed(1)}/min\n'
            '${bonuses.isNotEmpty ? '\nBonus actifs:\n${bonuses.join("\n")}\n' : ''}'
            '\nMétal utilisé par trombone: ${(GameConstants.METAL_PER_PAPERCLIP * efficiencyBonus).toStringAsFixed(2)} unités'
            '\n(Efficacité: -${((1.0 - efficiencyBonus) * 100).toStringAsFixed(1)}%)',
      ),
    );
  }

  Widget _buildMetalStatus(BuildContext context, GameState gameState) {
    double metalPerClip = GameConstants.METAL_PER_PAPERCLIP *
        (1.0 - ((gameState.player.upgrades['efficiency']?.level ?? 0) * 0.15));

    double currentMetalForClips = gameState.player.metal / metalPerClip;

    return _buildMarketCard(
      title: 'Stock de Métal',
      value: '${gameState.player.metal.toStringAsFixed(1)} / ${gameState.player.maxMetalStorage}',
      icon: Icons.inventory_2,
      color: Colors.grey.shade200,
      tooltip: 'Production possible: ${currentMetalForClips.toStringAsFixed(0)} trombones',
      onInfoPressed: () => _showInfoDialog(
        context,
        'Stock de Métal',
        'Métal disponible pour la production:\n'
            '- Stock actuel: ${gameState.player.metal.toStringAsFixed(1)} unités\n'
            '- Capacité maximale: ${gameState.player.maxMetalStorage} unités\n'
            '- Prix actuel: ${gameState.market.currentMetalPrice.toStringAsFixed(2)} €\n\n'
            'Production possible:\n'
            '- Métal par trombone: ${metalPerClip.toStringAsFixed(2)} unités\n'
            '- Trombones possibles: ${currentMetalForClips.toStringAsFixed(0)} unités',
      ),
    );
  }
  Widget _buildMarketSummaryCard(GameState gameState, double demand, double autoclipperProduction) {
    double effectiveProduction = min(demand, autoclipperProduction);
    double profitability = effectiveProduction * gameState.player.sellPrice;
    double qualityBonus = 1.0 + ((gameState.player.upgrades['quality']?.level ?? 0) * 0.10);

    return Card(
      elevation: 2,
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé du Marché',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                _buildMarketStat(
                  'Production',
                  '${autoclipperProduction.toStringAsFixed(1)}/min',
                  Icons.precision_manufacturing,
                ),
                _buildMarketStat(
                  'Demande',
                  '${demand.toStringAsFixed(1)}/min',
                  Icons.trending_up,
                ),
                _buildMarketStat(
                  'Ventes',
                  '${effectiveProduction.toStringAsFixed(1)}/min',
                  Icons.shopping_cart,
                ),
                _buildMarketStat(
                  'Revenus',
                  '${profitability.toStringAsFixed(1)} €/min',
                  Icons.attach_money,
                ),
              ],
            ),
            if (qualityBonus > 1.0) ...[
              const Divider(),
              Text(
                'Bonus qualité: +${((qualityBonus - 1.0) * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.teal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarketStat(String label, String value, IconData icon) {
    return SizedBox(
      width: 140,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPriceControlCard(GameState gameState) {
    double qualityBonus = 1.0 + ((gameState.player.upgrades['quality']?.level ?? 0) * 0.10);
    double effectivePrice = gameState.player.sellPrice * qualityBonus;

    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prix de Vente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${gameState.player.sellPrice.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (qualityBonus > 1.0)
                      Text(
                        'Prix effectif: ${effectivePrice.toStringAsFixed(2)} €',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Min: ${GameConstants.MIN_PRICE.toStringAsFixed(2)} €',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Max: ${GameConstants.MAX_PRICE.toStringAsFixed(2)} €',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    double newValue = gameState.player.sellPrice - 0.01;
                    if (newValue >= GameConstants.MIN_PRICE) {
                      gameState.player.updateSellPrice(newValue);
                    }
                  },
                ),
                Expanded(
                  child: Slider(
                    value: gameState.player.sellPrice,
                    min: GameConstants.MIN_PRICE,
                    max: GameConstants.MAX_PRICE,
                    divisions: 200,
                    label: '${gameState.player.sellPrice.toStringAsFixed(2)} €',
                    onChanged: (value) => gameState.player.updateSellPrice(value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    double newValue = gameState.player.sellPrice + 0.01;
                    if (newValue <= GameConstants.MAX_PRICE) {
                      gameState.player.updateSellPrice(newValue);
                    }
                  },
                ),
              ],
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
        final visibleElements = gameState.getVisibleScreenElements();
        double demand = gameState.market.calculateDemand(
          gameState.player.sellPrice,
          gameState.player.getMarketingLevel(),
        );

        double autoclipperProduction = 0;
        if (gameState.player.autoclippers > 0) {
          autoclipperProduction = gameState.player.autoclippers * 60;
          double speedBonus = 1.0 + ((gameState.player.upgrades['speed']?.level ?? 0) * 0.20);
          double bulkBonus = 1.0 + ((gameState.player.upgrades['bulk']?.level ?? 0) * 0.35);
          autoclipperProduction *= speedBonus * bulkBonus;
        }

        double effectiveProduction = min(demand, autoclipperProduction);
        double profitability = effectiveProduction * gameState.player.sellPrice;

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              const MoneyDisplay(),
              const SizedBox(height: 12),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Production et Stocks
                      _buildMetalStatus(context, gameState),
                      const SizedBox(height: 8),
                      if (gameState.player.autoclippers > 0)
                        _buildProductionCard(context, gameState, autoclipperProduction),
                      const SizedBox(height: 12),

                      if (visibleElements['marketPrice'] == true) ...[
                        _buildMarketCard(
                          title: 'Demande du Marché',
                          value: '${demand.toStringAsFixed(1)}/min',
                          icon: Icons.trending_up,
                          color: Colors.amber.shade100,
                          tooltip: 'Demande actuelle',
                          onInfoPressed: () => _showInfoDialog(
                            context,
                            'Demande du Marché',
                            'Demande actuelle: ${demand.toStringAsFixed(1)} unités/min\n'
                                'Production effective: ${effectiveProduction.toStringAsFixed(1)} unités/min',
                          ),
                        ),
                        const SizedBox(height: 8),

                        _buildMarketCard(
                          title: 'Réputation',
                          value: '${(gameState.marketManager.reputation * 100).toStringAsFixed(1)}%',
                          icon: Icons.star,
                          color: Colors.blue.shade100,
                          tooltip: 'Influence la demande globale',
                          onInfoPressed: () => _showInfoDialog(
                            context,
                            'Réputation',
                            'La réputation influence directement la demande du marché.\n'
                                'Une meilleure réputation augmente les ventes potentielles.',
                          ),
                        ),
                        const SizedBox(height: 8),

                        _buildMarketCard(
                          title: 'Marketing',
                          value: 'Niveau ${gameState.player.getMarketingLevel()}',
                          icon: Icons.campaign,
                          color: Colors.cyan.shade100,
                          tooltip: 'Augmente la visibilité',
                          onInfoPressed: () => _showInfoDialog(
                            context,
                            'Marketing',
                            'Le niveau de marketing augmente la demande de base.\n'
                                'Chaque niveau ajoute +30% à la demande.',
                          ),
                        ),
                        const SizedBox(height: 8),

                        _buildMarketCard(
                          title: 'Rentabilité Estimée',
                          value: '${profitability.toStringAsFixed(1)} €/min',
                          icon: Icons.assessment,
                          color: Colors.indigo.shade100,
                          tooltip: 'Basé sur la production et la demande',
                          onInfoPressed: () => _showInfoDialog(
                            context,
                            'Rentabilité',
                            'Estimation des revenus par minute basée sur:\n'
                                '- Prix de vente: ${gameState.player.sellPrice.toStringAsFixed(2)} €\n'
                                '- Production: ${autoclipperProduction.toStringAsFixed(1)} unités/min\n'
                                '- Demande: ${demand.toStringAsFixed(1)} unités/min\n'
                                '- Production effective: ${effectiveProduction.toStringAsFixed(1)} unités/min\n'
                                '- Revenus potentiels: ${profitability.toStringAsFixed(1)} €/min',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (visibleElements['sellButton'] == true) ...[
                        Card(
                          elevation: 2,
                          color: Colors.green.shade100,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Prix de Vente',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${gameState.player.sellPrice.toStringAsFixed(2)} €',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildPriceControls(gameState),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DemandCalculationScreen()),
                      ),
                      icon: const Icon(Icons.calculate),
                      label: const Text('Calculateur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (visibleElements['marketPrice'] == true)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SalesHistoryScreen()),
                        ),
                        icon: const Icon(Icons.history),
                        label: const Text('Historique'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _saveGame(context, gameState),
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
      },
    );
  }
// Helper pour les boutons d'action
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}