import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/player_state.dart';
import '../viewmodels/upgrades_viewmodel.dart';

class UpgradeList extends StatelessWidget {
  const UpgradeList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UpgradesViewModel>(
      builder: (context, upgradesViewModel, child) {
        final selectedCategory = upgradesViewModel.selectedCategory;
        if (selectedCategory == null) {
          return const Center(
            child: Text('Sélectionnez une catégorie pour voir les améliorations'),
          );
        }

        final upgrades = upgradesViewModel.getUpgradesForCategory(selectedCategory.id);
        if (upgrades.isEmpty) {
          return const Center(
            child: Text('Aucune amélioration disponible dans cette catégorie'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: upgrades.length,
          itemBuilder: (context, index) {
            final upgrade = upgrades[index];
            return _buildUpgradeCard(context, upgrade);
          },
        );
      },
    );
  }

  Widget _buildUpgradeCard(BuildContext context, Upgrade upgrade) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(upgrade.icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        upgrade.name,
                        style: Theme.of(context).textTheme.subtitle1?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        upgrade.description,
                        style: Theme.of(context).textTheme.bodyText2?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                _buildUpgradeButton(context, upgrade),
              ],
            ),
            if (upgrade.currentLevel > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: upgrade.progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Niveau ${upgrade.currentLevel}',
                style: Theme.of(context).textTheme.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeButton(BuildContext context, Upgrade upgrade) {
    final canAfford = upgrade.canAfford;
    final isMaxed = upgrade.isMaxed;

    return ElevatedButton(
      onPressed: canAfford && !isMaxed
          ? () => upgrade.onPurchase()
          : null,
      style: ElevatedButton.styleFrom(
        primary: isMaxed ? Colors.green : Theme.of(context).primaryColor,
        onPrimary: Colors.white,
      ),
      child: Text(
        isMaxed ? 'MAX' : '${upgrade.cost}€',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
} 