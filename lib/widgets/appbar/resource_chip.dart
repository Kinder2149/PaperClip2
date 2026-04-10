// lib/widgets/appbar/resource_chip.dart

import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';

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
    // RESPONSIVE-APPBAR: Paddings et tailles adaptés selon breakpoint
    final horizontalPadding = const ResponsiveValue<double>(
      mobile: 10.0,
      tablet: 12.0,
      desktop: 12.0,
    ).getValue(context);

    final verticalPadding = const ResponsiveValue<double>(
      mobile: 6.0,
      tablet: 8.0,
      desktop: 8.0,
    ).getValue(context);

    final emojiFontSize = const ResponsiveValue<double>(
      mobile: 16.0,
      tablet: 18.0,
      desktop: 18.0,
    ).getValue(context);

    final textFontSize = const ResponsiveValue<double>(
      mobile: 13.0,
      tablet: 14.0,
      desktop: 14.0,
    ).getValue(context);

    final spacing = const ResponsiveValue<double>(
      mobile: 6.0,
      tablet: 8.0,
      desktop: 8.0,
    ).getValue(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
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
            style: TextStyle(fontSize: emojiFontSize),
          ),
          SizedBox(width: spacing),
          Text(
            formatLarge ? _formatNumber(value) : value.toStringAsFixed(0),
            style: TextStyle(
              fontSize: textFontSize,
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
