import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' show min;
import '../models/game_state.dart';
import '../constants/game_config.dart'; // Importé depuis constants au lieu de models
import '../widgets/resources/resource_widgets.dart';
import '../widgets/cards/stats_panel.dart';
import '../widgets/indicators/stat_indicator.dart';
import '../widgets/dialogs/info_dialog.dart';
import '../widgets/cards/info_card.dart';
import '../managers/player_manager.dart';
import '../models/upgrade.dart' as upgrade_model;
import '../services/upgrades/upgrade_effects_calculator.dart';
import '../services/progression/progression_rules_service.dart';

class UpgradesScreen extends StatelessWidget {
  const UpgradesScreen({super.key});

  static bool _shouldShowUpgrades(VisibleUiElements visibleElements) {
    return visibleElements[UiElement.upgradesSection];
  }

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, bool>(
      selector: (context, gameState) =>
          _shouldShowUpgrades(gameState.getVisibleUiElements()),
      builder: (context, showUpgrades, child) {
        if (!showUpgrades) {
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

        return Consumer<GameState>(
          builder: (context, gameState, _) {
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
                        final entry =
                            gameState.player.upgrades.entries.elementAt(index);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildUpgradeCard(
                            context,
                            gameState,
                            entry.key,
                            entry.value as upgrade_model.Upgrade,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

    // Retourne une row avec les deux panneaux de statistiques côte à côte
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.precision_manufacturing, color: Colors.blue[800], size: 20),
                        const SizedBox(width: 8),
                        Text('Production',
                          style: TextStyle(fontSize: 16, color: Colors.blue[800], fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...productionStats,
                ],
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.storefront, color: Colors.teal[800], size: 20),
                        const SizedBox(width: 8),
                        Text('Marché', 
                          style: TextStyle(fontSize: 16, color: Colors.teal[800], fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...marketStats,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context, GameState gameState, String id, upgrade_model.Upgrade upgrade) {
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
      final requiredLevel = upgrade.requiredLevel ?? 1;
      upgradeDetails['Niveau requis'] = '$requiredLevel';
      
      // Si le niveau requis est atteint mais pas assez d'argent
      if (gameState.level.level >= requiredLevel) {
        upgradeDetails['Argent manquant'] = '${(upgrade.getCost() - gameState.player.money).toStringAsFixed(1)} €';
      }
    }

    // Déterminer la catégorie et les couleurs en fonction de l'ID
    String category;
    Color backgroundColor;
    Color iconColor;
    Color borderColor;
    Color titleColor;

    switch (id) {
      case 'efficiency':
      case 'speed':
      case 'bulk':
      case 'automation':
        category = 'Production';
        backgroundColor = Colors.blue.shade50;
        iconColor = Colors.blue.shade700;
        borderColor = Colors.blue.shade200;
        titleColor = Colors.blue.shade800;
        break;
      case 'quality':
        category = 'Marché';
        backgroundColor = Colors.teal.shade50;
        iconColor = Colors.teal.shade700;
        borderColor = Colors.teal.shade200;
        titleColor = Colors.teal.shade800;
        break;
      case 'storage':
        category = 'Stockage';
        backgroundColor = Colors.amber.shade50;
        iconColor = Colors.amber.shade700;
        borderColor = Colors.amber.shade200;
        titleColor = Colors.amber.shade800;
        break;
      default:
        category = 'Autre';
        backgroundColor = Colors.grey.shade50;
        iconColor = Colors.grey.shade700;
        borderColor = Colors.grey.shade200;
        titleColor = Colors.grey.shade800;
        break;
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

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        onTap: canBuy ? () => gameState.purchaseUpgrade(id) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(_getUpgradeIcon(id), color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          upgrade.name,
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            color: iconColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    isMaxed ? "MAX" : "${upgrade.getCost().toStringAsFixed(2)} €",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isMaxed ? Colors.green : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                upgrade.description,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              _buildUpgradeImpactPreview(id, upgrade, gameState),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: upgradeDetails.entries.map((entry) => 
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          '${entry.key}: ${entry.value}', 
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])
                        ),
                      )
                    ).toList(),
                  ),
                  ...actions,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeImpactPreview(String id, upgrade_model.Upgrade upgrade, GameState gameState) {
    // Initialiser un map pour stocker les impacts de l'amélioration selon le type
    Map<String, List<String>> impacts = {};

    // Vérifier si l'amélioration est déjà au niveau max
    if (upgrade.level >= upgrade.maxLevel) return const SizedBox.shrink();
    
    // Déterminer la catégorie et les couleurs en fonction de l'ID
    Color backgroundColor;
    Color borderColor;
    Color accentColor;

    switch (id) {
      case 'efficiency':
      case 'speed':
      case 'bulk':
      case 'automation':
        backgroundColor = Colors.blue.shade50;
        borderColor = Colors.blue.shade100;
        accentColor = Colors.blue.shade700;
        break;
      case 'quality':
        backgroundColor = Colors.teal.shade50;
        borderColor = Colors.teal.shade100;
        accentColor = Colors.teal.shade700;
        break;
      case 'storage':
        backgroundColor = Colors.amber.shade50;
        borderColor = Colors.amber.shade100;
        accentColor = Colors.amber.shade700;
        break;
      default:
        backgroundColor = Colors.grey.shade50;
        borderColor = Colors.grey.shade100;
        accentColor = Colors.grey.shade700;
        break;
    }

    // Déterminer les impacts spécifiques en fonction de l'ID de l'amélioration
    switch (id) {
      case 'speed':
        double currentSpeed = (upgrade.level * 0.20) * 100;
        double nextSpeed = ((upgrade.level + 1) * 0.20) * 100;
        impacts['Vitesse de production'] = [
          _formatImpact(currentSpeed),
          _formatImpact(nextSpeed)
        ];
        break;

      case 'bulk':
        double currentBulk = (upgrade.level * 0.35) * 100;
        double nextBulk = ((upgrade.level + 1) * 0.35) * 100;
        impacts['Production par lot'] = [
          _formatImpact(currentBulk),
          _formatImpact(nextBulk)
        ];
        break;

      case 'quality':
        double currentQuality = (upgrade.level * 0.10) * 100;
        double nextQuality = ((upgrade.level + 1) * 0.10) * 100;
        impacts['Augmentation qualité'] = [
          _formatImpact(currentQuality),
          _formatImpact(nextQuality)
        ];
        break;

      case 'efficiency':
        double currentReduction = UpgradeEffectsCalculator.efficiencyReduction(level: upgrade.level) * 100;
        double nextReduction = UpgradeEffectsCalculator.efficiencyReduction(level: upgrade.level + 1) * 100;
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
        double nextStorage = UpgradeEffectsCalculator.metalStorageCapacity(
          storageLevel: upgrade.level + 1,
        );
        impacts['Capacité de stockage'] = [
          '${currentStorage.toStringAsFixed(0)}',
          '${nextStorage.toStringAsFixed(0)}'
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
                  Icon(Icons.arrow_forward, size: 12, color: accentColor.withOpacity(0.5)),
                  Text(
                    value[1],
                    style: TextStyle(
                      fontSize: 11,
                      color: accentColor,
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
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impact de l\'amélioration',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: accentColor,
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
      case 'bulk':
        return Icons.inventory;
      case 'speed':
        return Icons.speed;
      case 'storage':
        return Icons.storage;
      case 'quality':
        return Icons.star;
      case 'automation':
        return Icons.precision_manufacturing;
      default:
        return Icons.upgrade;
    }
  }
}
