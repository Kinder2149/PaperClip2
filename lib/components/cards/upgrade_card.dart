import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import '../../models/upgrade.dart';
import 'card_styles.dart';

class UpgradeCard extends StatelessWidget {
  final String id;
  final Upgrade upgrade;
  final IconData icon;
  final Widget? impactPreview;
  final Widget? requirements;
  final VoidCallback? onTap;

  const UpgradeCard({
    super.key,
    required this.id,
    required this.upgrade,
    required this.icon,
    this.impactPreview,
    this.requirements,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final canBuy = gameState.player.money >= upgrade.getCost() && upgrade.level < upgrade.maxLevel;
        final isMaxed = upgrade.level >= upgrade.maxLevel;

        return InkWell(
          onTap: canBuy ? onTap : null,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: CardStyles.upgradeCard(
              color: Colors.white,
              isMaxed: isMaxed,
              canBuy: canBuy,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
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

                  if (!isMaxed && impactPreview != null) impactPreview!,

                  if (!canBuy && !isMaxed && requirements != null) ...[
                    const Divider(height: 24),
                    requirements!,
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
        );
      },
    );
  }
} 