// lib/presentation/widgets/competitive_mode_indicator.dart
import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';

class CompetitiveModeIndicator extends StatelessWidget {
  const CompetitiveModeIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.shade700,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events,
            size: 14,
            color: Colors.amber.shade700,
          ),
          const SizedBox(width: 4),
          const Text(
            'Compétitif',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}