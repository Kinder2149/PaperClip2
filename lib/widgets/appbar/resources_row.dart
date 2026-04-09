// lib/widgets/appbar/resources_row.dart

import 'package:flutter/material.dart';
import 'resource_chip.dart';

/// Widget qui affiche les 4 ressources principales en ligne
class ResourcesRow extends StatelessWidget {
  final double money;
  final double paperclips;
  final int quantum;
  final int innovationPoints;

  const ResourcesRow({
    Key? key,
    required this.money,
    required this.paperclips,
    required this.quantum,
    required this.innovationPoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ResourceChip(
          emoji: '💵',
          value: money,
          color: Colors.green.shade600,
          formatLarge: true,
        ),
        const SizedBox(width: 8),
        ResourceChip(
          emoji: '📎',
          value: paperclips,
          color: Colors.blue.shade500,
          formatLarge: true,
        ),
        const SizedBox(width: 8),
        ResourceChip(
          emoji: '⚡',
          value: quantum.toDouble(),
          color: Colors.cyan.shade400,
          formatLarge: false,
        ),
        const SizedBox(width: 8),
        ResourceChip(
          emoji: '💡',
          value: innovationPoints.toDouble(),
          color: Colors.purple.shade400,
          formatLarge: false,
        ),
      ],
    );
  }
}
