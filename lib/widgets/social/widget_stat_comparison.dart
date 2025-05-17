// lib/widgets/social/widget_stat_comparison.dart
import 'package:flutter/material.dart';

class WidgetStatComparison extends StatelessWidget {
  final String title;
  final dynamic myValue;
  final dynamic friendValue;
  final dynamic difference;
  final IconData icon;
  final bool useCompactMode;
  final bool higherIsBetter;
  final String Function(dynamic)? valueFormatter;

  const WidgetStatComparison({
    Key? key,
    required this.title,
    required this.myValue,
    required this.friendValue,
    required this.difference,
    required this.icon,
    this.useCompactMode = true,
    this.higherIsBetter = true,
    this.valueFormatter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final diffValue = difference;
    final bool isPositive = diffValue > 0;
    final bool isBetter = higherIsBetter ? isPositive : !isPositive;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: useCompactMode
            ? _buildCompactVersion(context, isBetter, diffValue)
            : _buildDetailedVersion(context, isBetter, diffValue),
      ),
    );
  }

  Widget _buildCompactVersion(BuildContext context, bool isBetter, dynamic diffValue) {
    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildValueColumn('Vous', myValue),
        const SizedBox(width: 12),
        _buildValueColumn('Ami', friendValue),
        const SizedBox(width: 12),
        _buildDifferenceChip(diffValue, isBetter),
      ],
    );
  }

  Widget _buildDetailedVersion(BuildContext context, bool isBetter, dynamic diffValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            _buildDifferenceChip(diffValue, isBetter),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDetailedValueColumn('Vous', myValue, Colors.blue.shade100),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailedValueColumn('Ami', friendValue, Colors.orange.shade100),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValueColumn(String label, dynamic value) {
    final displayValue = valueFormatter != null
        ? valueFormatter!(value)
        : value.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          displayValue,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedValueColumn(String label, dynamic value, Color color) {
    final displayValue = valueFormatter != null
        ? valueFormatter!(value)
        : value.toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifferenceChip(dynamic diffValue, bool isBetter) {
    final displayDiff = valueFormatter != null
        ? valueFormatter!(diffValue)
        : diffValue.toString();

    final prefix = diffValue > 0 ? '+' : '';
    final text = '$prefix$displayDiff';

    return Chip(
      label: Text(text),
      backgroundColor: isBetter
          ? Colors.green.shade100
          : Colors.red.shade100,
      labelStyle: TextStyle(
        color: isBetter ? Colors.green.shade800 : Colors.red.shade800,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}