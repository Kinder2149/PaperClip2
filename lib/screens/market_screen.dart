import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/constants.dart';
import '../models/market/market_manager.dart';
import '../widgets/money_display.dart';
import '../services/save_manager.dart';
import 'demand_calculation_screen.dart';
import 'sales_history_screen.dart';

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
                      style: TextStyle(
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
          duration: Duration(seconds: 4),
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
              'Min: ${MarketManager.MIN_PRICE.toStringAsFixed(2)} €',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              'Max: ${MarketManager.MAX_PRICE.toStringAsFixed(2)} €',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                double newValue = gameState.sellPrice - 0.01;
                if (newValue >= MarketManager.MIN_PRICE) {
                  gameState.sellPrice = newValue;
                }
              },
            ),
            Expanded(
              child: Slider(
                value: gameState.sellPrice,
                min: MarketManager.MIN_PRICE,
                max: MarketManager.MAX_PRICE,
                divisions: 200,
                label: '${gameState.sellPrice.toStringAsFixed(2)} €',
                onChanged: (value) => gameState.sellPrice = value,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                double newValue = gameState.sellPrice + 0.01;
                if (newValue <= MarketManager.MAX_PRICE) {
                  gameState.sellPrice = newValue;
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        double demand = gameState.marketManager.calculateDemand(
            gameState.sellPrice,
            gameState.getMarketingLevel()
        );
        double profitability = demand * gameState.sellPrice;
        double marketCondition = gameState.marketManager.dynamics.getMarketConditionMultiplier();
        String marketStatus = marketCondition > 1.1 ? '📈 En hausse' :
        marketCondition < 0.9 ? '📉 En baisse' : '➡️ Stable';

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
                      _buildMarketCard(
                        title: 'Stock de Métal',
                        value: '${gameState.metal.toStringAsFixed(1)}',
                        icon: Icons.inventory_2,
                        color: Colors.grey.shade200,
                        tooltip: 'Métal disponible pour la production',
                        onInfoPressed: () => _showInfoDialog(
                          context,
                          'Stock de Métal',
                          'Quantité de métal disponible pour la production.\n'
                              'Capacité maximale: ${gameState.maxMetalStorage}\n'
                              'Prix actuel: ${gameState.currentMetalPrice.toStringAsFixed(2)} €',
                        ),
                        trailing: Text(
                          '/ ${gameState.maxMetalStorage}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildMarketCard(
                        title: 'Réputation du Marché',
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
                        value: 'Niveau ${gameState.getMarketingLevel()}',
                        icon: Icons.campaign,
                        color: Colors.orange.shade100,
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
                        title: 'Conditions du Marché',
                        value: marketStatus,
                        icon: Icons.trending_up,
                        color: Colors.purple.shade100,
                        tooltip: 'Multiplicateur: x${marketCondition.toStringAsFixed(2)}',
                        onInfoPressed: () => _showInfoDialog(
                          context,
                          'Conditions du Marché',
                          'Les conditions actuelles influencent la demande.\n'
                              'Multiplicateur actuel: x${marketCondition.toStringAsFixed(2)}\n'
                              'Status: $marketStatus',
                        ),
                      ),
                      const SizedBox(height: 12),

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
                                    '${gameState.sellPrice.toStringAsFixed(2)} €',
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
                      const SizedBox(height: 12),

                      _buildMarketCard(
                        title: 'Rentabilité Estimée',
                        value: '${profitability.toStringAsFixed(1)} €/min',
                        icon: Icons.assessment,
                        color: Colors.amber.shade100,
                        tooltip: 'Basé sur la demande actuelle',
                        onInfoPressed: () => _showInfoDialog(
                          context,
                          'Rentabilité',
                          'Estimation des revenus par minute basée sur:\n'
                              '- Prix de vente: ${gameState.sellPrice.toStringAsFixed(2)} €\n'
                              '- Demande estimée: ${demand.toStringAsFixed(1)} unités/min\n'
                              '- Revenus potentiels: ${profitability.toStringAsFixed(1)} €/min',
                        ),
                      ),
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
                    backgroundColor: Colors.green,
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
}