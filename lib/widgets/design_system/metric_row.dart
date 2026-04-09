import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'metric_column.dart';

/// Widget affichant plusieurs métriques en ligne avec séparateurs verticaux
/// 
/// Utilisé dans les headers de panels pour afficher plusieurs statistiques côte à côte.
/// 
/// Exemple :
/// ```dart
/// MetricRow(
///   metrics: [
///     MetricData(label: 'En stock', value: '1,234', color: Colors.blue),
///     MetricData(label: 'Total produit', value: '5,678', color: Colors.green),
///   ],
/// )
/// ```
class MetricRow extends StatelessWidget {
  final List<MetricData> metrics;

  const MetricRow({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];

    for (int i = 0; i < metrics.length; i++) {
      children.add(
        Expanded(
          child: MetricColumn(
            label: metrics[i].label,
            value: metrics[i].value,
            color: metrics[i].color,
          ),
        ),
      );

      // Ajouter un séparateur sauf après le dernier élément
      if (i < metrics.length - 1) {
        children.add(
          Container(
            width: DesignTokens.kBorderWidthThin,
            height: DesignTokens.kSeparatorHeight,
            color: Colors.grey[300],
          ),
        );
      }
    }

    return Row(
      children: children,
    );
  }
}
