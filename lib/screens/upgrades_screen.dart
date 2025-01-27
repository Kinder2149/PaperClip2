import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/player_manager.dart';
import '../widgets/resource_widgets.dart';

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
        double currentEff = -(upgrade.level * 15.0);
        double nextEff = -((upgrade.level + 1) * 15.0);
        // Utilisez la constante de votre classe ou du fichier de configuration
        double metalPerClip = 1.5; // Remplacez par votre valeur de base
        double currentMetal = metalPerClip * (1 + currentEff/100);
        double nextMetal = metalPerClip * (1 + nextEff/100);
        impacts['Consommation de métal'] = [
          '${_formatImpact(currentMetal, isPercentage: false)} /clip',
          '${_formatImpact(nextMetal, isPercentage: false)} /clip'
        ];
        break;

      case 'storage':
      // Convertir en double si maxMetalStorage est un double
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Niveau de Production',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Niveau ${gameState.level.level}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: gameState.level.experienceProgress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  Icons.precision_manufacturing,
                  'Production',
                  '${gameState.totalPaperclipsProduced}',
                ),
                _buildStatItem(
                  Icons.trending_up,
                  'Multiplicateur',
                  'x${gameState.level.productionMultiplier.toStringAsFixed(1)}',
                ),
                _buildStatItem(
                  Icons.timer,
                  'Temps de jeu',
                  _formatDuration(gameState.totalTimePlayed),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
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
                child: ListView(
                  children: gameState.player.upgrades.entries
                      .map((entry) => _buildUpgradeCard(
                    context,
                    gameState,
                    entry.key,
                    entry.value,
                  ))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpgradeCard(
      BuildContext context,
      GameState gameState,
      String id,
      Upgrade upgrade,
      ) {
    bool canBuy = gameState.player.money >= upgrade.getCost() && upgrade.level < upgrade.maxLevel;
    bool isMaxed = upgrade.level >= upgrade.maxLevel;

    Map<String, bool> requirements = {
      'Niveau requis: ${upgrade.requiredLevel}':
      gameState.level.level >= upgrade.requiredLevel!,
      'Argent requis: ${upgrade.getCost().toStringAsFixed(1)} €':
      gameState.player.money >= upgrade.getCost(),
    };

    if (id == 'automation') {
      requirements['Autoclippers requis: 5'] = gameState.player.autoclippers >= 5;
    }
    if (id == 'marketing') {
      requirements['Production totale: 1000'] = gameState.totalPaperclipsProduced >= 1000;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: canBuy ? () => gameState.purchaseUpgrade(id) : null,
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
                    color: canBuy ? Colors.blue : Colors.grey,
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
                            color: canBuy ? Colors.black87 : Colors.grey,
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
                    Text(
                      '${upgrade.getCost().toStringAsFixed(1)} €',
                      style: TextStyle(
                        fontSize: 14,
                        color: canBuy ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Affichage de l'aperçu de l'impact
              if (!isMaxed) _buildUpgradeImpactPreview(id, upgrade, gameState),

              // Affichage des conditions requises
              if (!canBuy && !isMaxed) ...[
                const Divider(),
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
                const SizedBox(height: 8),
              ],

              // Barre de progression
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
                  const SizedBox(width: 8),
                  Text(
                    'Niveau ${upgrade.level}/${upgrade.maxLevel}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
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