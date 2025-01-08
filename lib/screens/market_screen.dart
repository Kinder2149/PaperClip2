import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/constants.dart';
import '../models/market/market_manager.dart';
import '../widgets/money_display.dart';
import 'demand_calculation_screen.dart';
import 'sales_history_screen.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  Widget _buildMarketCard(String title, String value, IconData icon, Color color, String tooltipMessage, VoidCallback onInfoPressed) {
    return Card(
      elevation: 2,
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: onInfoPressed,
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
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        // Calcul de la rentabilité actuelle
        double demand = gameState.marketManager.calculateDemand(gameState.sellPrice, gameState.marketingLevel);
        double profitability = demand * gameState.sellPrice - gameState.productionCost;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const MoneyDisplay(),
              const SizedBox(height: 8),

              // Cartes d'information du marché avec boutons d'information
              _buildMarketCard(
                'Métal disponible',
                gameState.metal.toStringAsFixed(3),
                Icons.inventory,
                Colors.grey.shade200,
                'Métal disponible pour produire des trombones.',
                    () => _showInfoDialog(context, 'Métal disponible', 'Le métal disponible est utilisé pour produire des trombones.'),
              ),
              const SizedBox(height: 8),
              _buildMarketCard(
                'Réputation',
                '${(gameState.marketManager.reputation * 100).toStringAsFixed(1)}%',
                Icons.star,
                Colors.blue.shade100,
                'La réputation affecte la demande du marché. Limites : 0% (min), 100% (max).',
                    () => _showInfoDialog(context, 'Réputation', 'La réputation influence la demande en augmentant ou diminuant le facteur de réputation. Une meilleure réputation augmente la demande, tandis qu\'une mauvaise réputation la diminue. Limites : 0% (min), 100% (max).'),
              ),
              const SizedBox(height: 8),
              _buildMarketCard(
                'Niveau de Marketing',
                gameState.marketingLevel.toString(),
                Icons.campaign,
                Colors.orange.shade100,
                'Le niveau de marketing affecte la demande.',
                    () => _showInfoDialog(context, 'Niveau de Marketing', 'Le niveau de marketing augmente la demande en améliorant la visibilité et l\'attractivité des trombones. Un niveau de marketing plus élevé se traduit par une demande plus élevée.'),
              ),
              const SizedBox(height: 8),
              _buildMarketCard(
                'Conditions du marché',
                gameState.marketManager.dynamics.getMarketConditionMultiplier().toStringAsFixed(2),
                Icons.trending_up,
                Colors.purple.shade100,
                'Les conditions actuelles du marché influencent la demande.',
                    () => _showInfoDialog(context, 'Conditions du marché', 'Les conditions du marché sont des facteurs externes qui influencent la demande via un multiplicateur. Les conditions favorables augmentent la demande, tandis qu\'une condition défavorable la réduisent.'),
              ),
              const SizedBox(height: 8),

              // Afficheur du prix de vente dans un bloc
              _buildMarketCard(
                'Prix de vente',
                '${gameState.sellPrice.toStringAsFixed(2)} €',
                Icons.attach_money,
                Colors.green.shade100,
                'Le prix de vente des trombones affecte la demande. Limites : ${MarketManager.MIN_PRICE} € (min), ${MarketManager.MAX_PRICE} € (max).',
                    () => _showInfoDialog(context, 'Prix de vente', 'Le prix de vente des trombones affecte la demande. Des prix plus bas augmentent la demande, tandis qu\'des prix plus élevés la réduisent. Limites : ${MarketManager.MIN_PRICE} € (min), ${MarketManager.MAX_PRICE} € (max).'),
              ),
              const SizedBox(height: 8),

              // Slider pour ajuster le prix de vente avec boutons + et -
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      double newValue = gameState.sellPrice - 0.01;
                      if (newValue >= MarketManager.MIN_PRICE) {
                        gameState.setSellPrice(newValue);
                      }
                    },
                  ),
                  Expanded(
                    child: Slider(
                      value: gameState.sellPrice,
                      min: MarketManager.MIN_PRICE,
                      max: MarketManager.MAX_PRICE,
                      divisions: 99,
                      onChanged: (value) => gameState.setSellPrice(value),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      double newValue = gameState.sellPrice + 0.01;
                      if (newValue <= MarketManager.MAX_PRICE) {
                        gameState.setSellPrice(newValue);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Afficheur de la rentabilité actuelle
              _buildMarketCard(
                'Rentabilité actuelle',
                profitability.toStringAsFixed(2),
                Icons.assessment,
                Colors.red.shade100,
                'La rentabilité actuelle est calculée en fonction de la demande, du prix de vente et des coûts de production.',
                    () => _showInfoDialog(context, 'Rentabilité actuelle', 'La rentabilité actuelle est calculée en fonction de la demande, du prix de vente et des coûts de production. Une rentabilité positive indique que vous générez des bénéfices.'),
              ),

              const Spacer(),

              // Boutons pour ouvrir les pages de calcul de la demande et de l'historique des ventes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DemandCalculationScreen()),
                        );
                      },
                      child: const Text('Calcul de la demande'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SalesHistoryScreen()),
                        );
                      },
                      child: const Text('Historique des ventes'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Bouton de sauvegarde
              ElevatedButton(
                onPressed: () {
                  Provider.of<GameState>(context, listen: false).saveGame();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Conserve la couleur du design actuel
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('Sauvegarder la Partie'),
              ),
            ],
          ),
        );
      },
    );
  }
}