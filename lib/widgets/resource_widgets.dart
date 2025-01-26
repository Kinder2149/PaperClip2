// lib/widgets/resource_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'dart:math';
import '../models/game_config.dart';

class MoneyDisplay extends StatelessWidget {
  const MoneyDisplay({super.key});

  String formatNumber(double number, {bool isInteger = false}) {
    const suffixes = ['', 'K', 'M', 'B', 'T', 'Qa', 'Qi', 'Sx', 'Sp', 'Oc', 'No', 'Dc'];

    if (number >= 1e12) { // Pour les valeurs supérieures à 1 trillion
      int index = (log(number) / log(1000)).floor();
      index = min(index, suffixes.length - 1);

      double simplified = number / pow(1000, index);
      String formatted;

      // Pour les nombres entiers (trombones)
      if (isInteger) {
        formatted = simplified.toStringAsFixed(0);
      } else {
        // Pour les valeurs monétaires
        if (simplified >= 100) {
          formatted = simplified.toStringAsFixed(0);
        } else if (simplified >= 10) {
          formatted = simplified.toStringAsFixed(1);
        } else {
          formatted = simplified.toStringAsFixed(2);
        }

        if (formatted.contains('.')) {
          formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
        }
      }

      return '$formatted ${suffixes[index]}€';
    } else if (number >= 1e9) {
      return isInteger
          ? '${(number / 1e9).toStringAsFixed(0)}B €'
          : '${(number / 1e9).toStringAsFixed(2)}B €';
    } else if (number >= 1e6) {
      return isInteger
          ? '${(number / 1e6).toStringAsFixed(0)}M €'
          : '${(number / 1e6).toStringAsFixed(2)}M €';
    } else if (number >= 1e3) {
      return isInteger
          ? '${(number / 1e3).toStringAsFixed(0)}K €'
          : '${(number / 1e3).toStringAsFixed(2)}K €';
    }
    return isInteger
        ? '${number.toStringAsFixed(0)} €'
        : '${number.toStringAsFixed(2)} €';
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