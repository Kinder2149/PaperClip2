import 'package:flutter/material.dart';
import '../progress/progress.dart';

class LevelIndicator extends StatelessWidget {
  final int level;
  final double experienceProgress;
  final double productionMultiplier;
  final Color? color;

  const LevelIndicator({
    super.key,
    required this.level,
    required this.experienceProgress,
    required this.productionMultiplier,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Colors.blue;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: themeColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 24, color: themeColor),
              const SizedBox(width: 8),
              Text(
                'Niveau $level',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'x${productionMultiplier.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(
            value: experienceProgress,
            maxValue: 1.0,
            color: themeColor,
            showPercentage: true,
            height: 8,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
} 