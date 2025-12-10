// lib/widgets/resources/resource_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import 'dart:math';
import '../../constants/game_config.dart'; // Importé depuis constants au lieu de models

class MoneyDisplay extends StatelessWidget {
  const MoneyDisplay({super.key});

  static String formatNumber(dynamic number, {bool isInteger = false, bool showExactCount = false}) {
    // Convertir en double si c'est un int
    double value = number is int ? number.toDouble() : number;
    // Si showExactCount est true, on affiche le nombre exact sans formatage
    if (showExactCount) {
      if (isInteger) {
        return value.toStringAsFixed(0);
      }
      return value.toString();
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

    if (value < 1000) {
      // Nombres inférieurs à 1000
      return isInteger
          ? '${value.toStringAsFixed(0)} €'
          : '${formatWithThousandSeparator(double.parse(value.toStringAsFixed(2)))} €';
    }

    // Pour les grands nombres
    int index = (log(value) / log(1000)).floor();
    index = min(index, suffixes.length - 1);
    double simplified = value / pow(1000, index);

    // Formatage avec plus de précision
    String formatted;
    if (simplified >= 100) {
      // Pour les nombres ≥ 100, on montre 3 chiffres significatifs
      formatted = simplified.toStringAsFixed(3);
      // Enlever les zéros inutiles après la virgule
      if (formatted.contains('.')) {
        formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
      }
    } else if (simplified >= 10) {
      // Pour les nombres entre 10 et 100, on montre jusqu'à 4 chiffres significatifs
      formatted = simplified.toStringAsFixed(3);
      if (formatted.contains('.')) {
        formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
      }
    } else {
      // Pour les nombres < 10, on montre jusqu'à 4 chiffres significatifs
      formatted = simplified.toStringAsFixed(3);
      if (formatted.contains('.')) {
        formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
      }
    }

    return '$formatted${suffixes[index]} €';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.euro, size: 20),
              const SizedBox(width: 8),
              Text(
                formatNumber(gameState.player.money),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ResourceStatusWidget extends StatelessWidget {
  const ResourceStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final metalStock = gameState.resources.marketMetalStock;  // Utilisation du getter
        final warningLevel = metalStock <= GameConstants.WARNING_THRESHOLD;  // Utilisation de GameConstants
        final criticalLevel = metalStock <= GameConstants.CRITICAL_THRESHOLD;  // Utilisation de GameConstants

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  'Stock de métal mondial',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: criticalLevel
                        ? Colors.red
                        : warningLevel
                        ? Colors.orange
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: metalStock / GameConstants.INITIAL_MARKET_METAL,  // Utilisation de GameConstants
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    criticalLevel
                        ? Colors.red
                        : warningLevel
                        ? Colors.orange
                        : Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${metalStock.toStringAsFixed(1)} unités',
                  style: TextStyle(
                    fontSize: 12,
                    color: criticalLevel
                        ? Colors.red
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ResourceOverview extends StatelessWidget {
  const ResourceOverview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ressources',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ResourceItem(
                      icon: Icons.euro,
                      label: 'Argent',
                      value: gameState.player.money.toStringAsFixed(2),  // Utilisation du getter
                      color: Colors.green,
                    ),
                    _ResourceItem(
                      icon: Icons.link,
                      label: 'Trombones',
                      value: gameState.player.paperclips.toStringAsFixed(0),  // Utilisation du getter
                      color: Colors.blue,
                    ),
                    _ResourceItem(
                      icon: Icons.straighten,
                      label: 'Métal',
                      value: '${gameState.player.metal.toStringAsFixed(1)}/${gameState.player.maxMetalStorage}',  // Utilisation du getter
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResourceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResourceItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}