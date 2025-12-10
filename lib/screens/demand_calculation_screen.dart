import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../managers/market_manager.dart';
import '../widgets/charts/chart_widgets.dart';

class DemandCalculationScreen extends StatelessWidget {
  const DemandCalculationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    double currentDemand = gameState.marketManager.calculateDemand(
      gameState.player.sellPrice,
      gameState.player.getMarketingLevel(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calcul de la Demande'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // En-tête avec la demande actuelle
            Card(
              color: Colors.blue.shade50,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Demande Actuelle',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currentDemand.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    Text(
                      'unités par minute',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Facteurs influençant la demande
            _buildFactorCard(
              title: 'Prix de Vente',
              description: 'Des prix plus bas augmentent la demande, tandis que des prix plus élevés la réduisent.',
              currentValue: 'Prix actuel : ${gameState.player.sellPrice
                  .toStringAsFixed(2)} €',
              icon: Icons.price_change,
              color: Colors.green,
            ),
            _buildFactorCard(
              title: 'Niveau de Marketing',
              description: 'Un niveau de marketing plus élevé augmente la demande.',
              currentValue: 'Niveau ${gameState.player.getMarketingLevel()}',
              icon: Icons.campaign,
              color: Colors.orange,
            ),
            _buildFactorCard(
              title: 'Réputation',
              description: 'Une meilleure réputation augmente la demande.',
              currentValue: '${(gameState.marketManager.reputation * 100)
                  .toStringAsFixed(1)}%',
              icon: Icons.star,
              color: Colors.purple,
            ),

            const SizedBox(height: 24),
            // Section informative
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Facteurs de la Demande',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      'Prix de Vente',
                      'Des prix plus bas augmentent la demande, tandis que des prix plus élevés la réduisent.',
                    ),
                    _buildInfoItem(
                      'Niveau de Marketing',
                      'Un niveau de marketing plus élevé augmente la demande.',
                    ),
                    _buildInfoItem(
                      'Réputation',
                      'Une meilleure réputation augmente la demande, tandis qu\'une mauvaise réputation la diminue.',
                    ),
                    _buildInfoItem(
                      'Conditions du Marché',
                      'Les conditions du marché peuvent influencer positivement ou négativement la demande.',
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

  Widget _buildFactorCard({
    required String title,
    required String description,
    required String currentValue,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentValue,
                    style: TextStyle(
                      fontSize: 16,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_right, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$title : ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}