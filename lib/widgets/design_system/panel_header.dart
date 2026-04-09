import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'metric_column.dart';
import 'metric_row.dart';

/// Widget header générique pour les panels de l'application
/// 
/// Affiche un emoji, un titre et optionnellement des métriques.
/// 
/// Exemples :
/// ```dart
/// // Header simple
/// PanelHeader(
///   emoji: '📎',
///   title: 'Production de Trombones',
/// )
/// 
/// // Header avec métrique unique
/// PanelHeader(
///   emoji: '🤖',
///   title: 'Agents IA',
///   singleMetric: MetricData(
///     label: 'Quantum',
///     value: '100',
///     color: Colors.cyan,
///   ),
/// )
/// 
/// // Header avec plusieurs métriques
/// PanelHeader(
///   emoji: '📎',
///   title: 'Production',
///   metrics: [
///     MetricData(label: 'En stock', value: '1,234', color: Colors.blue),
///     MetricData(label: 'Total produit', value: '5,678', color: Colors.green),
///   ],
/// )
/// ```
class PanelHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final List<MetricData>? metrics;
  final MetricData? singleMetric;

  const PanelHeader({
    super.key,
    required this.emoji,
    required this.title,
    this.metrics,
    this.singleMetric,
  }) : assert(
          metrics == null || singleMetric == null,
          'Cannot provide both metrics and singleMetric',
        );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: TextStyle(fontSize: DesignTokens.kEmojiSizeLarge),
                ),
                SizedBox(width: DesignTokens.kSpacingMedium),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            if (singleMetric != null || metrics != null) ...[
              SizedBox(height: DesignTokens.kSpacingSectionGap),
              if (singleMetric != null)
                MetricColumn(
                  label: singleMetric!.label,
                  value: singleMetric!.value,
                  color: singleMetric!.color,
                ),
              if (metrics != null) MetricRow(metrics: metrics!),
            ],
          ],
        ),
      ),
    );
  }
}
