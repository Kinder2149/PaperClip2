import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../widgets/resource_widgets.dart';
import '../widgets/level_widgets.dart';

import 'package:paperclip2/widgets/resource_widgets.dart'; // Ajustez le chemin selon votre structure

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}
class _ProductionScreenState extends State<ProductionScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Rafraîchir l'interface toutes les 100ms
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String formatNumber(double number, bool isMetal) {
    if (isMetal) {
      return number.toStringAsFixed(2);
    } else {
      return number.floor().toString();
    }
  }

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

  void _showInfoDialog(BuildContext context, String title, String message) {
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

  Widget _buildAutoclippersSection(BuildContext context, GameState gameState) {
    double bulkBonus = (gameState.player.upgrades['bulk']?.level ?? 0) * 20;
    double speedBonus = (gameState.player.upgrades['speed']?.level ?? 0) * 15;
    double efficiencyBonus = 1.0 -
        ((gameState.player.upgrades['efficiency']?.level ?? 0) * 0.15);
    double roi = gameState.productionManager.calculateAutoclipperROI(gameState.player.sellPrice);

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Autoclippers: ${gameState.productionManager.autoclippers}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Rentabilité: ${(gameState.player
                            .calculateAutoclipperCost() /
                            (GameConstants.BASE_AUTOCLIPPER_PRODUCTION *
                                gameState.player.sellPrice)).toStringAsFixed(
                            1)}s',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () =>
                      _showAutoclipperInfoDialog(
                        context,
                        gameState,
                        bulkBonus,
                        speedBonus,
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
                _buildBonusIndicator(
                  'Efficacité',
                  '${(efficiencyBonus * 100).toStringAsFixed(0)}%',
                  Icons.eco,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              onPressed: gameState.player.money >=
                  gameState.productionManager.calculateAutoclipperCost()
                  ? () => gameState.buyAutoclipper()
                  : null,
              label: 'Acheter Autoclipper (${gameState.player
                  .calculateAutoclipperCost().toStringAsFixed(1)} €)',
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
                      .autoclippers} trombone/s'),
                  Text(
                      'Bonus de production: +${bulkBonus.toStringAsFixed(0)}%'),
                  Text('Bonus de vitesse: +${speedBonus.toStringAsFixed(0)}%'),
                  const Divider(),
                  Text(
                      'Production totale: ${gameState.player
                          .autoclippers} trombones/s\n'
                          'Consommation métal: ${(GameConstants
                          .METAL_PER_PAPERCLIP * gameState.productionManager.autoclippers)
                          .toStringAsFixed(2)}/s'
                  ),
                  const Divider(),
                  Text('Coûts de maintenance: ${gameState.maintenanceCosts
                      .toStringAsFixed(1)} € par min'),
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
                  Text('Stock mondial de métal: ${gameState.metalManager.marketMetalStock.toStringAsFixed(0)}'),
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
                const Text(
                  'État du Marché',
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
              '${(gameState.market.calculateDemand(
                  gameState.player.sellPrice,
                  gameState.player.getMarketingLevel()) * 100).toStringAsFixed(
                  0)}%',
              Icons.people,
            ),
            _buildMarketIndicator(
              'Stock Métal Mondial',
              gameState.metalManager.marketMetalStock.toStringAsFixed(0),
              Icons.inventory_2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductionStatsCard(GameState gameState) {
    double efficiencyBonus = 1.0 -
        ((gameState.player.upgrades['efficiency']?.level ?? 0) * 0.15);
    double baseProduction = gameState.productionManager.autoclippers * 60;
    double actualProduction = baseProduction * efficiencyBonus;

    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques de Production',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            // Utilisation de Wrap au lieu de Row pour éviter l'overflow
            Wrap(
              spacing: 20, // Espace horizontal entre les éléments
              runSpacing: 10, // Espace vertical entre les lignes
              children: [
                // Première colonne
                SizedBox(
                  width: 160, // Largeur fixe pour la première colonne
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Production/min:',
                        style: TextStyle(fontSize: 13),
                      ),
                      Text(
                        baseProduction.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Deuxième colonne
                SizedBox(
                  width: 160, // Largeur fixe pour la deuxième colonne
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Production effective:',
                        style: TextStyle(fontSize: 13),
                      ),
                      Text(
                        actualProduction.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Troisième colonne
                SizedBox(
                  width: 160, // Largeur fixe pour la troisième colonne
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rendement:',
                        style: TextStyle(fontSize: 13),
                      ),
                      Text(
                        '${(efficiencyBonus * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Quatrième colonne
                SizedBox(
                  width: 160, // Largeur fixe pour la quatrième colonne
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Métal utilisé/min:',
                        style: TextStyle(fontSize: 13),
                      ),
                      Text(
                        (actualProduction * GameConstants.METAL_PER_PAPERCLIP)
                            .toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Information sur les coûts de maintenance
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Coût maintenance: ${gameState.maintenanceCosts.toStringAsFixed(
                    2)} €/min',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
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

                      // Ressources existantes
                      Row(
                        children: [
                          _buildResourceCard(
                            'Total Trombones',
                            MoneyDisplay.formatNumber(
                                gameState.productionManager.totalPaperclipsProduced.toDouble(),
                                isInteger: true).replaceAll(' €', ''),
                            Colors.purple.shade100,
                            onTap: () =>
                                _showInfoDialog(
                                  context,
                                  'Statistiques de Production',
                                  'Total produit: ${MoneyDisplay.formatNumber(
                                      gameState.productionManager.totalPaperclipsProduced
                                          .toDouble(), isInteger: true)
                                      .replaceAll(' €', '')}\n'
                                      'Niveau: ${gameState.level.level}\n'
                                      'Multiplicateur: x${gameState.level
                                      .productionMultiplier.toStringAsFixed(
                                      2)}',
                                ),
                          ),
                          const SizedBox(width: 16),
                          _buildResourceCard(
                            'Stock Trombones',
                            MoneyDisplay.formatNumber(
                                gameState.productionManager.paperclips, isInteger: true)
                                .replaceAll(' €', ''),
                            Colors.blue.shade100,
                            onTap: () =>
                                _showInfoDialog(
                                  context,
                                  'Stock de Trombones',
                                  'Total en stock: ${MoneyDisplay.formatNumber(
                                      gameState.productionManager.paperclips,
                                      isInteger: true).replaceAll(' €', '')}\n'
                                      'Production totale: ${MoneyDisplay
                                      .formatNumber(
                                      gameState.productionManager.totalPaperclipsProduced
                                          .toDouble(), isInteger: true)
                                      .replaceAll(' €', '')}',
                                ),
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
                            '${formatNumber(gameState.metalManager.metal, true)} / ${gameState.metalManager.maxMetalStorage}',
                            Colors.grey.shade200,
                            onTap: () => _showInfoDialog(
                              context,
                              'Stock de Métal',
                              'Stock: ${formatNumber(gameState.metalManager.metal, true)}\n'
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

                      if (visibleElements['marketInfo'] == true)
                        _buildMarketInfoCard(context, gameState),
                      if (visibleElements['marketInfo'] == true)
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
                        backgroundColor: Colors.deepPurple,
                        textColor: Colors.white,
                      ),

                      // Statistiques de production déplacées à la fin
                      if (gameState.productionManager.autoclippers > 0) ...[
                        const SizedBox(height: 16),
                        _buildProductionStatsCard(gameState),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}