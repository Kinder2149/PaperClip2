// lib/widgets/appbar/resource_chip.dart

import 'package:flutter/material.dart';

/// Widget réutilisable pour afficher une ressource avec emoji et valeur
class ResourceChip extends StatelessWidget {
  final String emoji;
  final double value;
  final Color color;
  final bool formatLarge;

  const ResourceChip({
    Key? key,
    required this.emoji,
    required this.value,
    required this.color,
    this.formatLarge = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            formatLarge ? _formatNumber(value) : value.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Formate les grands nombres en K (milliers) ou M (millions)
  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }
}
