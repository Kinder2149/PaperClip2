import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/market.dart';
import '../widgets/chart_widgets.dart';

class DemandCalculationScreen extends StatelessWidget {
  const DemandCalculationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calcul de la Demande'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Calcul de la Demande',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFactorCard(
              title: 'Prix de Vente',
              description: 'Des prix plus bas augmentent la demande, tandis que des prix plus élevés la réduisent.',
              currentValue: 'Actuel : ${gameState.sellPrice.toStringAsFixed(2)} €',
            ),
            _buildFactorCard(
              title: 'Niveau de Marketing',
              description: 'Un niveau de marketing plus élevé augmente la demande.',
              currentValue: 'Niveau actuel : ${gameState.getMarketingLevel()}',
            ),
            _buildFactorCard(
              title: 'Réputation',
              description: 'Une meilleure réputation augmente la demande.',
              currentValue: 'Réputation : ${gameState.marketManager.reputation.toStringAsFixed(2)}',
            ),
            _buildFactorCard(
              title: 'Demande Actuelle',
              description: 'La demande totale calculée en fonction de tous les facteurs.',
              currentValue: 'Demande : ${gameState.marketManager.calculateDemand(gameState.sellPrice, gameState.getMarketingLevel()).toStringAsFixed(0)} unités/s',
            ),
            SizedBox(height: 16),
            Text(
              'La demande pour les trombones est influencée par plusieurs facteurs :',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '- Prix de Vente : Des prix plus bas augmentent la demande, tandis que des prix plus élevés la réduisent.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '- Niveau de Marketing : Un niveau de marketing plus élevé augmente la demande.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '- Réputation : Une meilleure réputation augmente la demande, tandis qu\'une mauvaise réputation la diminue.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '- Conditions du Marché : Les conditions du marché peuvent influencer positivement ou négativement la demande.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFactorCard({
    required String title,
    required String description,
    required String currentValue
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                )
            ),
            const SizedBox(height: 8),
            Text(
                description,
                style: const TextStyle(fontSize: 16)
            ),
            const SizedBox(height: 8),
            Text(
                currentValue,
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue
                )
            ),
          ],
        ),
      ),
    );
  }
}