// Nouveau fichier à créer: lib/widgets/market_trends_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../managers/statistics_manager.dart';

class MarketTrendsWidget extends StatelessWidget {
  const MarketTrendsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final trendsData = gameState.statistics.analyzeSalesTrends();

        // Si pas assez de données pour analyser les tendances
        if (trendsData['trend'] == 'undefined') {
          return Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.trending_neutral,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Analyse du marché',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text(
                    'Pas assez de données pour analyser les tendances du marché.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Effectuez plus de ventes pour voir apparaître des analyses ici.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        // Déterminer les icônes et couleurs en fonction des tendances
        IconData trendIcon;
        Color trendColor;
        String trendMessage;

        switch (trendsData['trend']) {
          case 'up':
            trendIcon = Icons.trending_up;
            trendColor = Colors.green;
            trendMessage = 'Le marché est en hausse! C\'est le moment de vendre.';
            break;
          case 'down':
            trendIcon = Icons.trending_down;
            trendColor = Colors.red;
            trendMessage = 'Le marché est en baisse. Envisagez d\'ajuster vos prix.';
            break;
          default:
            trendIcon = Icons.trending_flat;
            trendColor = Colors.amber;
            trendMessage = 'Le marché est stable. Maintenez votre stratégie actuelle.';
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Colors.deepPurple,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Analyse du marché',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Icon(
                      trendIcon,
                      color: trendColor,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trendMessage,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: trendColor,
                            ),
                          ),
                          Text(
                            'Évolution du revenu: ${trendsData['revenueGrowth'].toStringAsFixed(1)}%',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricColumn(
                      'Prix moyen',
                      '${trendsData['averagePrice'].toStringAsFixed(2)} €',
                      Icons.euro,
                    ),
                    _buildMetricColumn(
                      'Quantité moyenne',
                      '${trendsData['averageQuantity']}',
                      Icons.shopping_cart,
                    ),
                    _buildMetricColumn(
                      'Prix recommandé',
                      _calculateRecommendedPrice(gameState, trendsData),
                      Icons.lightbulb_outline,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _calculateRecommendedPrice(GameState gameState, Map<String, dynamic> trendsData) {
    double averagePrice = trendsData['averagePrice'];
    String trend = trendsData['trend'];
    double revenueGrowth = trendsData['revenueGrowth'];

    // Prix de base actuel
    double currentPrice = gameState.player.sellPrice;

    // Calcul du prix recommandé en fonction des tendances
    double recommendedPrice = currentPrice;

    if (trend == 'up') {
      // Si le marché est en hausse, augmenter légèrement le prix
      recommendedPrice = currentPrice * (1 + min(0.05, revenueGrowth / 100));
    } else if (trend == 'down' && revenueGrowth < -10) {
      // Si le marché est en forte baisse, baisser le prix
      recommendedPrice = currentPrice * (1 - min(0.03, -revenueGrowth / 200));
    }

    // Limiter le prix recommandé
    recommendedPrice = recommendedPrice.clamp(
      gameState.market.currentPrice * 0.8,
      gameState.market.currentPrice * 1.2,
    );

    return '${recommendedPrice.toStringAsFixed(2)} €';
  }

  double min(double a, double b) => a < b ? a : b;
}