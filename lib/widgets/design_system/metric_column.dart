import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Classe de données pour une métrique
class MetricData {
  final String label;
  final String value;
  final Color color;

  const MetricData({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Widget affichant une métrique en colonne (label au-dessus, valeur en dessous)
/// 
/// Utilisé dans les headers de panels pour afficher des statistiques clés.
/// 
/// Exemple :
/// ```dart
/// MetricColumn(
///   label: 'En stock',
///   value: '1,234',
///   color: Colors.blue,
/// )
/// ```
class MetricColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const MetricColumn({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: DesignTokens.kSpacingSmall),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
