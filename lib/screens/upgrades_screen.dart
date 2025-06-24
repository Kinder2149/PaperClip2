import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' show min;
import '../models/game_state.dart';
import '../models/player_manager.dart';
import '../models/game_config.dart';
import '../widgets/resources/resource_widgets.dart';
import '../widgets/cards/stats_panel.dart';
import '../widgets/indicators/stat_indicator.dart';
import '../widgets/dialogs/info_dialog.dart';
import '../widgets/cards/info_card.dart';

class UpgradesScreen extends StatelessWidget {
  const UpgradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final visibleElements = gameState.getVisibleScreenElements();

    if (visibleElements['upgradesSection'] != true) {
      // Écran de verrouillage
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Améliorations verrouillées',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Continuez à produire pour débloquer cette section.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MoneyDisplay(),
          const SizedBox(height: 16),
          _buildStatisticsCard(gameState),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: gameState.player.upgrades.length,
              itemBuilder: (context, index) {
                final entry = gameState.player.upgrades.entries.elementAt(index);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildUpgradeCard(
                    context,
                    gameState,
                    entry.key,
                    entry.value,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(GameState gameState) {
    // Création des statistiques de production
    List<StatIndicator> productionStats = [
      StatIndicator(
        label: 'Production manuelle',
        value: '${(1.0).toStringAsFixed(0)} clips', // Valeur fixe en attendant implementation
        icon: Icons.touch_app,
        layout: StatIndicatorLayout.horizontal,
        labelStyle: TextStyle(color: Colors.grey[700]),
      ),
      StatIndicator(
        label: 'Vitesse de production',
        value: '+${(0.0).toStringAsFixed(0)}%', // Valeur fixe en attendant implementation
        icon: Icons.speed,
        layout: StatIndicatorLayout.horizontal,
        valueStyle: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        labelStyle: TextStyle(color: Colors.grey[700]),
      ),
      StatIndicator(
        label: 'Efficacité',
        value: '-${(0.0).toStringAsFixed(0)}%', // Valeur fixe en attendant implementation
        icon: Icons.eco,
        layout: StatIndicatorLayout.horizontal,
        valueStyle: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        labelStyle: TextStyle(color: Colors.grey[700]),
      ),
    ];

    // Création des statistiques du marché
    List<StatIndicator> marketStats = [
      StatIndicator(
        label: 'Demande actuelle',
        value: '+${(0.0).toStringAsFixed(0)}%', // Valeur fixe en attendant implementation
        icon: Icons.trending_up,
        layout: StatIndicatorLayout.horizontal,
        valueStyle: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        labelStyle: TextStyle(color: Colors.grey[700]),
      ),
      StatIndicator(
        label: 'Prix unitaire',
        value: '${gameState.market.currentPrice.toStringAsFixed(2)} €',
        icon: Icons.euro,
        layout: StatIndicatorLayout.horizontal,
        labelStyle: TextStyle(color: Colors.grey[700]),
      ),
    ];

    // Retourne une colonne avec les deux panneaux de statistiques
    return Column(
      children: [
        StatsPanel(
          title: 'Production',
          titleIcon: Icons.precision_manufacturing,
          children: productionStats,
          backgroundColor: Colors.white,
          titleStyle: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StatsPanel(
          title: 'Marché',
          titleIcon: Icons.storefront,
          children: marketStats,
          backgroundColor: Colors.white,
          titleStyle: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildUpgradeCard(BuildContext context, GameState gameState, String id, Upgrade upgrade) {
    bool canBuy = gameState.player.money >= upgrade.getCost() && upgrade.level < upgrade.maxLevel;
    bool isMaxed = upgrade.level >= upgrade.maxLevel;

    // Préparer les informations à afficher
    final upgradeDetails = {
      'Niveau': '${upgrade.level}/${upgrade.maxLevel}',
    };
    
    // Ajouter le coût uniquement si l'amélioration n'est pas au niveau max
    if (!isMaxed) {
      upgradeDetails['Coût'] = '${upgrade.getCost().toStringAsFixed(1)} €';
    }

    // Construire les actions disponibles
    List<Widget> actions = [];
    if (canBuy) {
      actions.add(
        TextButton.icon(
          onPressed: () => gameState.purchaseUpgrade(id),
          icon: const Icon(Icons.shopping_cart, color: Colors.green),
          label: const Text('Acheter', style: TextStyle(color: Colors.green)),
        )
      );
    } else if (!isMaxed) {
      // Afficher les conditions requises si pas achetable et pas au niveau max
      upgradeDetails['Niveau requis'] = '${upgrade.requiredLevel}';
      
      // Si le niveau requis est atteint mais pas assez d'argent
      if (gameState.level.level >= upgrade.requiredLevel!) {
        upgradeDetails['Argent manquant'] = '${(upgrade.getCost() - gameState.player.money).toStringAsFixed(1)} €';
      }
    }

    // Ajouter un badge si l'amélioration est au niveau maximum ou achetable
    String? badge;
    Color? badgeColor;
    Color? badgeBackgroundColor;
    if (isMaxed) {
      badge = 'Maximum';
      badgeColor = Colors.green;
      badgeBackgroundColor = Colors.green[50];
    } else if (canBuy) {
      badge = 'Disponible';
      badgeColor = Colors.blue;
      badgeBackgroundColor = Colors.blue[50];
    }

    return InfoCard(
      title: upgrade.name,
      value: '${isMaxed ? "MAX" : "${upgrade.getCost().toStringAsFixed(2)} €"}',
      tooltip: upgrade.description,
      icon: _getUpgradeIcon(id),
      // Utiliser trailing pour afficher les détails et actions
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...upgradeDetails.entries.map((entry) => Text('${entry.key}: ${entry.value}', style: TextStyle(fontSize: 12))).toList(),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: actions,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      onTap: canBuy ? () => gameState.purchaseUpgrade(id) : null,
      // Une version future pourrait intégrer des indicateurs visuels comme des badges ou barres de progression
    );
  }

  Widget _buildUpgradeImpactPreview(String id, Upgrade upgrade, GameState gameState) {
    Map<String, List<String>> impacts = {};

    // Calculer l'impact actuel et futur
    switch (id) {
      case 'speed':
        double currentSpeed = upgrade.level * 20.0;
        double nextSpeed = (upgrade.level + 1) * 20.0;
        impacts['Vitesse de production'] = [
          _formatImpact(currentSpeed),
          _formatImpact(nextSpeed)
        ];
        break;

      case 'bulk':
        double currentBulk = upgrade.level * 35.0;
        double nextBulk = (upgrade.level + 1) * 35.0;
        impacts['Production par cycle'] = [
          _formatImpact(currentBulk),
          _formatImpact(nextBulk)
        ];
        break;

      case 'efficiency':
      // Nouveau calcul avec 11% par niveau et plafond 85%
        double currentReduction = min(
            (upgrade.level * GameConstants.EFFICIENCY_UPGRADE_MULTIPLIER * 100),
            GameConstants.EFFICIENCY_MAX_REDUCTION * 100
        );

        double nextReduction = min(
            ((upgrade.level + 1) * GameConstants.EFFICIENCY_UPGRADE_MULTIPLIER * 100),
            GameConstants.EFFICIENCY_MAX_REDUCTION * 100
        );

        // Calcul de la consommation de métal avec les réductions
        double baseMetalPerClip = GameConstants.METAL_PER_PAPERCLIP;
        double currentMetal = baseMetalPerClip * (1.0 - currentReduction/100);
        double nextMetal = baseMetalPerClip * (1.0 - nextReduction/100);

        impacts['Réduction de consommation'] = [
          _formatImpact(currentReduction),
          _formatImpact(nextReduction)
        ];

        impacts['Consommation de métal'] = [
          '${_formatImpact(currentMetal, isPercentage: false)} /clip',
          '${_formatImpact(nextMetal, isPercentage: false)} /clip'
        ];
        break;

      case 'storage':
        double currentStorage = gameState.player.maxMetalStorage.toDouble();
        double nextStorage = currentStorage + 100.0;
        impacts['Capacité de stockage'] = [
          '${currentStorage.toStringAsFixed(0)}',
          '${nextStorage.toStringAsFixed(0)}'
        ];
        break;

      case 'marketing':
        double currentMarketing = upgrade.level * 30.0;
        double nextMarketing = (upgrade.level + 1) * 30.0;
        impacts['Bonus de demande'] = [
          _formatImpact(currentMarketing),
          _formatImpact(nextMarketing)
        ];
        break;
    }

    if (impacts.isEmpty) return const SizedBox.shrink();

    // Utilisation de StatIndicator pour afficher les impacts
    List<Widget> impactWidgets = [];
    impacts.forEach((key, value) {
      impactWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                key,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
              Row(
                children: [
                  Text(
                    value[0],
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  const Icon(Icons.arrow_forward, size: 12, color: Colors.black54),
                  Text(
                    value[1],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Impact de l\'amélioration',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          ...impactWidgets,
        ],
      ),
    );
  }

  String _formatImpact(double value, {bool isPercentage = true}) {
    if (isPercentage) {
      return value >= 0 ? '+${value.toStringAsFixed(1)}%' : '${value.toStringAsFixed(1)}%';
    }
    return value.toStringAsFixed(1);
  }

  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours}h ${minutes}m ${remainingSeconds}s';
  }

  IconData _getUpgradeIcon(String upgradeId) {
    switch (upgradeId) {
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
}
