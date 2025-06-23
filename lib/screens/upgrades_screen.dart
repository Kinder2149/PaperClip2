import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/player_manager.dart';
import '../widgets/resources/resource_widgets.dart';
import 'dart:math' show min;
import 'package:paperclip2/models/game_config.dart';

class UpgradesScreen extends StatelessWidget {
  const UpgradesScreen({super.key});

  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours}h ${minutes}m ${remainingSeconds}s';
  }

  String _formatImpact(double value, {bool isPercentage = true}) {
    if (isPercentage) {
      return value >= 0 ? '+${value.toStringAsFixed(1)}%' : '${value.toStringAsFixed(1)}%';
    }
    return value.toStringAsFixed(1);
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

    // Le reste du widget reste inchangé
    if (impacts.isEmpty) return const SizedBox.shrink();

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
          ...impacts.entries.map((impact) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  impact.key,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                Row(
                  children: [
                    Text(
                      impact.value[0],
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    const Icon(Icons.arrow_forward, size: 12, color: Colors.black54),
                    Text(
                      impact.value[1],
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
          )).toList(),
        ],
      ),
    );
  }



  Widget _buildStatisticsCard(GameState gameState) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Section niveau et progression (gauche)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mise à jour de l'affichage du niveau
                  Container(
                    constraints: const BoxConstraints(minHeight: 32), // Hauteur minimale fixe
                    child: Row(
                      children: [
                        Icon(Icons.bar_chart, size: 24, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Flexible( // Ajout de Flexible pour gérer le débordement
                          child: Text(
                            'Niveau ${gameState.level.level}',
                            style: TextStyle(
                              fontSize: 20, // Taille réduite
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                            overflow: TextOverflow.ellipsis, // Gestion du débordement
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8), // Espacement réduit
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: gameState.level.experienceProgress,
                      minHeight: 10, // Hauteur légèrement réduite
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Section statistiques (droite)
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    Icons.precision_manufacturing,
                    'Production',
                    '${gameState.totalPaperclipsProduced}',
                  ),
                  _buildStatItem(
                    Icons.trending_up,
                    'Multi.',
                    'x${gameState.level.productionMultiplier.toStringAsFixed(1)}',
                  ),
                  _buildStatItem(
                    Icons.timer,
                    'Temps',
                    _formatDuration(gameState.totalTimePlayed),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[700]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final visibleElements = gameState.getVisibleScreenElements();

        if (visibleElements['upgradesSection'] != true) {
          // Garder votre écran de verrouillage tel quel
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
              // Garde la même carte de statistiques mais avec une meilleure organisation
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
      },
    );
  }
  Widget _buildRequirements(GameState gameState, Upgrade upgrade) {
    Map<String, bool> requirements = {
      'Niveau requis: ${upgrade.requiredLevel}':
      gameState.level.level >= upgrade.requiredLevel!,
      'Argent requis: ${upgrade.getCost().toStringAsFixed(1)} €':
      gameState.player.money >= upgrade.getCost(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Conditions requises :',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        ...requirements.entries.map((requirement) => Row(
          children: [
            Icon(
              requirement.value ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: requirement.value ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              requirement.key,
              style: TextStyle(
                fontSize: 12,
                color: requirement.value ? Colors.green : Colors.red,
              ),
            ),
          ],
        )).toList(),
      ],
    );
  }
  Widget _buildUpgradeCard(BuildContext context, GameState gameState, String id, Upgrade upgrade) {
    bool canBuy = gameState.player.money >= upgrade.getCost() && upgrade.level < upgrade.maxLevel;
    bool isMaxed = upgrade.level >= upgrade.maxLevel;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: canBuy ? 3 : 1,
      child: InkWell(
        onTap: canBuy ? () => gameState.purchaseUpgrade(id) : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: canBuy
                ? Border.all(color: Colors.blue.shade200)
                : isMaxed
                ? Border.all(color: Colors.green.shade200)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getUpgradeIcon(id),
                      size: 24,
                      color: isMaxed ? Colors.green : (canBuy ? Colors.blue : Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            upgrade.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isMaxed ? Colors.green : (canBuy ? Colors.black87 : Colors.grey),
                            ),
                          ),
                          Text(
                            upgrade.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isMaxed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: canBuy ? Colors.green.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${upgrade.getCost().toStringAsFixed(1)} €',
                          style: TextStyle(
                            fontSize: 14,
                            color: canBuy ? Colors.green[700] : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (!isMaxed) _buildUpgradeImpactPreview(id, upgrade, gameState),

                if (!canBuy && !isMaxed) ...[
                  const Divider(height: 24),
                  _buildRequirements(gameState, upgrade),
                ],

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: upgrade.level / upgrade.maxLevel,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isMaxed ? Colors.green : Colors.blue,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Niveau ${upgrade.level}/${upgrade.maxLevel}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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