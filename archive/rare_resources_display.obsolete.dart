// lib/widgets/appbar/rare_resources_display.dart

import 'package:flutter/material.dart';

/// Widget compact pour afficher les ressources rares dans l'AppBar
class RareResourcesDisplay extends StatelessWidget {
  final int quantum;
  final int innovationPoints;

  const RareResourcesDisplay({
    Key? key,
    required this.quantum,
    required this.innovationPoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildResourceChip(
          icon: Icons.flash_on,
          value: quantum,
          color: Colors.cyan,
        ),
        const SizedBox(width: 8),
        _buildResourceChip(
          icon: Icons.lightbulb,
          value: innovationPoints,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildResourceChip({
    required IconData icon,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
