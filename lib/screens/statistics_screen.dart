import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'package:paperclip2/models/game_state_interfaces.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final stats = gameState.statistics.getAllStats();

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  color: Colors.deepPurple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatRow(
                          'Total Produit',
                          stats['production']?['Total produit'] ?? 0,
                        ),
                        _buildStatRow(
                          'Argent Total',
                          stats['economie']?['Argent gagné'] ?? 0,
                        ),
                        _buildStatRow(
                          'Niveau',
                          stats['progression']?['Niveau actuel'] ?? 0,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatSection('Production', stats['production']!),
                const SizedBox(height: 16),
                _buildStatSection('Économie', stats['economie']!),
                const SizedBox(height: 16),
                _buildStatSection('Progression', stats['progression']!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatSection(String title, Map<String, dynamic> stats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getSectionIcon(title),
                  size: 24,
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...stats.entries.map((entry) => _buildStatRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title.toLowerCase()) {
      case 'production':
        return Icons.precision_manufacturing;
      case 'économie':
        return Icons.attach_money;
      case 'progression':
        return Icons.trending_up;
      default:
        return Icons.analytics;
    }
  }

  String _getDisplayValue(dynamic value) {
    if (value == null) return '0';
    return value.toString();
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getDisplayValue(value),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}