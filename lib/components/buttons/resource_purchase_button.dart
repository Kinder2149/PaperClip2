import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import 'action_button.dart';

class ResourcePurchaseButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final double cost;
  final Color? backgroundColor;
  final Color? textColor;

  const ResourcePurchaseButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.cost,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final canAfford = gameState.player.money >= cost;

        return ActionButton(
          onPressed: canAfford ? onPressed : null,
          label: '$label (${cost.toStringAsFixed(1)} €)',
          icon: icon,
          backgroundColor: backgroundColor ?? Colors.grey.shade50,
          textColor: textColor ?? Colors.black87,
          trailing: canAfford
              ? null
              : Icon(
                  Icons.lock,
                  size: 16,
                  color: Colors.grey[400],
                ),
        );
      },
    );
  }
} 