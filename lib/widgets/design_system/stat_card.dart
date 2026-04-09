import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Widget carte de statistique colorée avec emoji
/// 
/// Affiche une statistique avec un emoji, un label et une valeur dans un container coloré.
/// 
/// Exemple :
/// ```dart
/// StatCard(
///   emoji: '🤖',
///   label: 'Autoclippers',
///   value: '5',
///   color: Colors.purple,
/// )
/// ```
class StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const StatCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.kSpacingMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: DesignTokens.kColorOpacityLight),
        borderRadius: DesignTokens.standardBorderRadius,
        border: Border.all(
          color: color.withValues(alpha: DesignTokens.kColorOpacityMedium),
          width: DesignTokens.kBorderWidthStandard,
        ),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: DesignTokens.kEmojiSizeMedium),
          ),
          SizedBox(width: DesignTokens.kSpacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: DesignTokens.kTextSizeLabel,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: DesignTokens.kSpacingSmall / 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: DesignTokens.kTextSizeValue,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
