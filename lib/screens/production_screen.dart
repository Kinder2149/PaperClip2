import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../widgets/resource_widgets.dart';
import '../widgets/level_widgets.dart';
import '../services/save_manager.dart';

class ProductionScreen extends StatelessWidget {
  const ProductionScreen({super.key});

  String formatNumber(double number, bool isMetal) {
    if (isMetal) {
      return number.toStringAsFixed(2);
    } else {
      return number.floor().toString();
    }
  }

  // Toutes les méthodes précédentes restent identiques
  Widget _buildResourceCard(String title, String value, Color color,
      {VoidCallback? onTap}) {
    return Expanded(
      child: Card(
        elevation: 2,
        color: color,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    // Méthode inchangée
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          AlertDialog(
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

      await gameState.saveGame(
          gameState.gameName!); // Utiliser la méthode de GameState

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

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final comboMultiplier = gameState.level.currentComboMultiplier;

        return Stack(
          children: [
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(
                label,
                style: TextStyle(fontSize: 14, color: textColor),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor ?? Colors.grey.shade50,
                foregroundColor: textColor ?? Colors.black87,
                padding: const EdgeInsets.all(16),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            if (comboMultiplier > 1.0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'x${comboMultiplier.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAutoclippersSection(BuildContext context, GameState gameState) {
    double bulkBonus = (gameState.player.upgrades['bulk']?.level ?? 0) * 20;
    double speedBonus = (gameState.player.upgrades['speed']?.level ?? 0) * 15;

    return Card(
      elevation: 2,
      color: Colors.orange.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.precision_manufacturing),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Autoclippers: ${gameState.player.autoclippers}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () =>
                      _showAutoclipperInfoDialog(
                          context,
                          gameState,
                          bulkBonus,
                          speedBonus
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
                  '${bulkBonus.toStringAsFixed(0)}%',
                  Icons.trending_up,
                ),
                _buildBonusIndicator(
                  'Vitesse',
                  '${speedBonus.toStringAsFixed(0)}%',
                  Icons.speed,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              onPressed: gameState.player.money >= gameState.player.calculateAutoclipperCost()
                  ? () => gameState.player.purchaseAutoclipper()
                  : null,
              label: 'Acheter Autoclipper (${gameState.player.calculateAutoclipperCost().toStringAsFixed(1)} €)',
              icon: Icons.add_circle_outline,
            ),
          ],
        ),
      ),
    );
  }

  void _showAutoclipperInfoDialog(BuildContext context,
      GameState gameState,
      double bulkBonus,
      double speedBonus) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Détails des Autoclippers'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Production de base: ${gameState.player
                      .autoclippers} par cycle'),
                  Text(
                      'Bonus de production: +${bulkBonus.toStringAsFixed(0)}%'),
                  Text('Bonus de vitesse: +${speedBonus.toStringAsFixed(0)}%'),
                  const Divider(),
                  Text('Production effective: ${(gameState.player.autoclippers *
                      (1 + bulkBonus / 100) * (1 + speedBonus / 100))
                      .toStringAsFixed(1)} par cycle'),
                  const Divider(),
                  Text('Coûts de maintenance: ${gameState.maintenanceCosts
                      .toStringAsFixed(1)} € par min'),
                  const SizedBox(height: 8),
                  const Text(
                    'Note: La maintenance est automatiquement déduite de vos revenus.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
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

  Widget _buildMarketInfoCard(BuildContext context, GameState gameState) {
    return Card(
      elevation: 2,
      color: Colors.teal.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up),
                const SizedBox(width: 8),
                const Text('État du Marché',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showMarketInfoDialog(context, gameState),
                ),
              ],
            ),
            const Divider(),
            _buildMarketIndicator(
              'Réputation',
              gameState.market.reputation.toStringAsFixed(2),
              Icons.star,
            ),
            _buildMarketIndicator(
              'Demande',
              '${(gameState.market.calculateDemand(gameState.player.sellPrice, gameState.player.getMarketingLevel()) * 100).toStringAsFixed(0)}%',
              Icons.people,
            ),
            _buildMarketIndicator(
              'Stock Métal Mondial',
              gameState.resources.marketMetalStock.toStringAsFixed(0),
              Icons.inventory_2,
            ),
          ],
        ),
      ),
    );
  }

  void _showMarketInfoDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Informations du Marché'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Réputation: ${gameState.market.reputation
                      .toStringAsFixed(2)}'),
                  const Text(
                    'Influence les ventes et les prix maximum.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(),
                  Text('Demande actuelle: ${(gameState.market.calculateDemand(
                      gameState.player.sellPrice,
                      gameState.player.getMarketingLevel()) * 100)
                      .toStringAsFixed(0)}%'),
                  const Text(
                    'Basée sur le prix et le niveau marketing.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(),
                  Text('Stock mondial de métal: ${gameState.resources
                      .marketMetalStock.toStringAsFixed(0)}'),
                  const Text(
                    'Influence les prix et la disponibilité.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
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
  Widget _buildBonusIndicator(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(value),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
  Widget _buildMarketIndicator(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
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
  Widget _buildMetalPurchaseButton(GameState gameState) {
    return Visibility(
      visible: gameState.getVisibleScreenElements()['metalPurchaseButton'] == true,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.shopping_cart),
        label: Text('Acheter du métal (${gameState.market.currentMetalPrice.toStringAsFixed(2)} €)'),
        onPressed: () => gameState.buyMetal(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final visibleElements = gameState.getVisibleScreenElements();

        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const XPStatusDisplay(),
                      const MoneyDisplay(),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          _buildResourceCard(
                            'Total Trombones',
                            gameState.totalPaperclipsProduced.toString(),
                            Colors.purple.shade100,
                            onTap: () =>
                                _showInfoDialog(
                                  context,
                                  'Statistiques de Production',
                                  'Total produit: ${gameState
                                      .totalPaperclipsProduced}\n'
                                      'Niveau: ${gameState.level.level}\n'
                                      'Multiplicateur: x${gameState.level
                                      .productionMultiplier.toStringAsFixed(
                                      2)}',
                                ),
                          ),
                          const SizedBox(width: 16),
                          _buildResourceCard(
                            'Stock Trombones',
                            formatNumber(gameState.player.paperclips, false),
                            Colors.blue.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (visibleElements['marketInfo'] == true)
                        _buildMarketInfoCard(context, gameState),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          _buildResourceCard(
                            'Métal',
                            '${formatNumber(
                                gameState.player.metal, true)} / ${gameState
                                .player.maxMetalStorage}',
                            Colors.grey.shade200,
                            onTap: () =>
                                _showInfoDialog(
                                  context,
                                  'Stock de Métal',
                                  'Stock: ${formatNumber(
                                      gameState.player.metal, true)}\n'
                                      'Capacité: ${gameState.player
                                      .maxMetalStorage}\n'
                                      'Prix: ${gameState.market
                                      .currentMetalPrice.toStringAsFixed(
                                      2)} €\n'
                                      'Efficacité: ${((1 -
                                      ((gameState.player.upgrades["efficiency"]
                                          ?.level ?? 0) * 0.15)) * 100)
                                      .toStringAsFixed(0)}%',
                                ),
                          ),
                          const SizedBox(width: 16),
                          _buildResourceCard(
                            'Prix Vente',
                            '${gameState.player.sellPrice.toStringAsFixed(
                                2)} €',
                            Colors.green.shade100,
                            onTap: () =>
                                _showInfoDialog(
                                  context,
                                  'Prix de Vente',
                                  'Prix actuel: ${gameState.player.sellPrice
                                      .toStringAsFixed(2)} €\n'
                                      'Bonus qualité: +${((gameState.player
                                      .upgrades["quality"]?.level ?? 0) *
                                      10)}%\n'
                                      'Impact réputation: x${gameState.market
                                      .reputation.toStringAsFixed(2)}',
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (visibleElements['metalPurchaseButton'] == true) ...[
                        _buildActionButton(
                          onPressed: gameState.player.money >=
                              gameState.market.currentMetalPrice
                              ? () => gameState.buyMetal()
                              : null,
                          label: 'Acheter Métal (${gameState.market
                              .currentMetalPrice.toStringAsFixed(1)} €)',
                          icon: Icons.shopping_cart,
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (visibleElements['autoclippersSection'] == true) ...[
                        _buildAutoclippersSection(context, gameState),
                        const SizedBox(height: 16),
                      ],


                      _buildActionButton(
                        onPressed: () => _saveGame(context, gameState),
                        label: 'Sauvegarder la Partie',
                        icon: Icons.save,
                        backgroundColor: Colors.purple.shade200,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              child: _buildActionButton(
                onPressed: gameState.player.metal >=
                    GameConstants.METAL_PER_PAPERCLIP
                    ? () => gameState.producePaperclip()
                    : null,
                label: 'Produire un trombone (${GameConstants
                    .METAL_PER_PAPERCLIP} métal)',
                icon: Icons.add,
                backgroundColor: Colors.blue.shade500,
                textColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}