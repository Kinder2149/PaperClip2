// lib/widgets/resources/resource_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import '../../constants/game_config.dart'; // Importé depuis constants au lieu de models
import '../../services/format/game_format.dart';

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

    if (value < 1000) {
      return GameFormat.money(
        value,
        decimals: isInteger ? 0 : 2,
      );
    }

    return '${GameFormat.quantityCompact(value, decimals: 3)} €';
  }

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, double>(
      selector: (context, gameState) => gameState.player.money,
      builder: (context, money, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
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
                formatNumber(money),
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
  const ResourceStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, double>(
      selector: (context, gameState) => gameState.marketManager.marketMetalStock,
      builder: (context, metalStock, child) {
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
                  '${GameFormat.number(metalStock, decimals: 1)} unités',
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

class _ResourceOverviewView {
  final double money;
  final double paperclips;
  final double metal;
  final double maxMetalStorage;

  const _ResourceOverviewView({
    required this.money,
    required this.paperclips,
    required this.metal,
    required this.maxMetalStorage,
  });

  @override
  bool operator ==(Object other) {
    return other is _ResourceOverviewView &&
        other.money == money &&
        other.paperclips == paperclips &&
        other.metal == metal &&
        other.maxMetalStorage == maxMetalStorage;
  }

  @override
  int get hashCode => Object.hash(money, paperclips, metal, maxMetalStorage);
}

class ResourceOverview extends StatelessWidget {
  const ResourceOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, _ResourceOverviewView>(
      selector: (context, gameState) {
        final player = gameState.player;
        return _ResourceOverviewView(
          money: player.money,
          paperclips: player.paperclips,
          metal: player.metal,
          maxMetalStorage: player.maxMetalStorage,
        );
      },
      builder: (context, view, child) {
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
                      value: GameFormat.money(view.money, decimals: 2),
                      color: Colors.green,
                    ),
                    _ResourceItem(
                      icon: Icons.link,
                      label: 'Trombones',
                      value: GameFormat.intWithSeparators(view.paperclips.floor()),
                      color: Colors.blue,
                    ),
                    _ResourceItem(
                      icon: Icons.straighten,
                      label: 'Métal',
                      value: '${GameFormat.number(view.metal, decimals: 1)}/${GameFormat.number(view.maxMetalStorage, decimals: 0)}',
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