import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import 'dart:math';

class ResourceIndicator extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final double value;
  final bool isInteger;
  final bool showExactCount;
  final String? suffix;
  final double? maxValue;
  final bool showProgress;

  const ResourceIndicator({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.isInteger = false,
    this.showExactCount = false,
    this.suffix,
    this.maxValue,
    this.showProgress = false,
  });

  static String formatNumber(double number, {bool isInteger = false, bool showExactCount = false, String? suffix}) {
    // Si showExactCount est true, on affiche le nombre exact sans formatage
    if (showExactCount) {
      if (isInteger) {
        return '${number.toStringAsFixed(0)}${suffix ?? ''}';
      }
      return '${number.toString()}${suffix ?? ''}';
    }

    // Liste des suffixes pour les grands nombres
    const suffixes = ['', 'K', 'M', 'B', 'T', 'Qa', 'Qi', 'Sx', 'Sp', 'Oc', 'No', 'Dc'];

    // Fonction helper pour formater avec séparateur de milliers
    String formatWithThousandSeparator(double n) {
      String str = n.toString();
      int dotIndex = str.indexOf('.');
      if (dotIndex == -1) dotIndex = str.length;

      String result = '';
      for (int i = 0; i < str.length; i++) {
        if (i < dotIndex && i > 0 && (dotIndex - i) % 3 == 0) {
          result += '.';
        }
        result += str[i];
      }
      return result;
    }

    if (number < 1000) {
      // Nombres inférieurs à 1000
      return isInteger
          ? '${number.toStringAsFixed(0)}${suffix ?? ''}'
          : '${formatWithThousandSeparator(double.parse(number.toStringAsFixed(2)))}${suffix ?? ''}';
    }

    // Pour les grands nombres
    int index = (log(number) / log(1000)).floor();
    index = min(index, suffixes.length - 1);
    double simplified = number / pow(1000, index);

    // Formatage avec plus de précision
    String formatted;
    if (simplified >= 100) {
      formatted = simplified.toStringAsFixed(3);
      if (formatted.contains('.')) {
        formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
      }
    } else if (simplified >= 10) {
      formatted = simplified.toStringAsFixed(3);
      if (formatted.contains('.')) {
        formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
      }
    } else {
      formatted = simplified.toStringAsFixed(3);
      if (formatted.contains('.')) {
        formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
      }
    }

    return '$formatted${suffixes[index]}${suffix ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                formatNumber(value, isInteger: isInteger, showExactCount: showExactCount, suffix: suffix),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
          if (showProgress && maxValue != null) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: value / maxValue!,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ],
      ),
    );
  }
} 