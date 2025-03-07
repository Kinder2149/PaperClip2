import 'package:flutter/material.dart';
import 'progress_styles.dart';

class ProgressBar extends StatelessWidget {
  final double value;
  final double maxValue;
  final Color color;
  final String? label;
  final String? valueLabel;
  final bool showPercentage;
  final double height;
  final double borderRadius;

  const ProgressBar({
    super.key,
    required this.value,
    required this.maxValue,
    required this.color,
    this.label,
    this.valueLabel,
    this.showPercentage = true,
    this.height = 8,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: ProgressStyles.labelStyle,
              ),
              if (valueLabel != null)
                Text(
                  valueLabel!,
                  style: ProgressStyles.valueStyle,
                ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            children: [
              Container(
                height: height,
                decoration: ProgressStyles.progressBarDecoration(
                  color: color,
                  borderRadius: borderRadius,
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: height,
                  decoration: ProgressStyles.progressBarFillDecoration(
                    color: color,
                    borderRadius: borderRadius,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showPercentage) ...[
          const SizedBox(height: 4),
          Text(
            '${(percentage * 100).toStringAsFixed(1)}%',
            style: ProgressStyles.percentageStyle,
          ),
        ],
      ],
    );
  }
} 