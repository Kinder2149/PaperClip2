import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import 'action_button.dart';

class UpgradeButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final double cost;
  final int level;
  final int maxLevel;
  final Color? backgroundColor;
  final Color? textColor;

  const UpgradeButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.cost,
    required this.level,
    required this.maxLevel,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final canAfford = gameState.player.money >= cost;
        final isMaxed = level >= maxLevel;

        return ActionButton(
          onPressed: canAfford && !isMaxed ? onPressed : null,
          label: '$label (${cost.toStringAsFixed(1)} €)',
          icon: icon,
          backgroundColor: backgroundColor ?? Colors.grey.shade50,
          textColor: textColor ?? Colors.black87,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMaxed && !canAfford)
                Icon(
                  Icons.lock,
                  size: 16,
                  color: Colors.grey[400],
                ),
              if (isMaxed)
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green,
                ),
              const SizedBox(width: 4),
              Text(
                'Niveau $level/$maxLevel',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 