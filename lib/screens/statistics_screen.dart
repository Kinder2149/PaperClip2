import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'package:paperclip2/models/game_state_interfaces.dart';
import '../models/statistics_manager.dart';
import '../widgets/cards/stats_panel.dart';
import '../widgets/indicators/stat_indicator.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, StatisticsManager>(
      selector: (context, gameState) => gameState.statistics,
      builder: (context, statistics, _) {
        return AnimatedBuilder(
          animation: statistics,
          builder: (context, child) {
            final stats = statistics.getAllStats();

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
                            StatIndicator(
                              label: 'Total Produit',
                              value: _getDisplayValue(stats['production']?['Total produit'] ?? 0),
                              icon: Icons.add_chart,
                              layout: StatIndicatorLayout.vertical,
                              labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14.0),
                              valueStyle: const TextStyle(color: Colors.deepPurple, fontSize: 16.0, fontWeight: FontWeight.bold),
                            ),
                            StatIndicator(
                              label: 'Argent Total',
                              value: _getDisplayValue(stats['economy']?['Argent gagné'] ?? 0),
                              icon: Icons.attach_money,
                              layout: StatIndicatorLayout.vertical,
                              labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14.0),
                              valueStyle: const TextStyle(color: Colors.deepPurple, fontSize: 16.0, fontWeight: FontWeight.bold),
                            ),
                            StatIndicator(
                              label: 'Niveau',
                              value: _getDisplayValue(stats['progression']?['Niveau actuel'] ?? 0),
                              icon: Icons.trending_up,
                              layout: StatIndicatorLayout.vertical,
                              labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14.0),
                              valueStyle: const TextStyle(color: Colors.deepPurple, fontSize: 16.0, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStatSection('Production', stats['production']!),
                    const SizedBox(height: 16),
                    _buildStatSection('Économie', stats['economy']!),
                    const SizedBox(height: 16),
                    _buildStatSection('Progression', stats['progression']!),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatSection(String title, Map<String, dynamic> stats) {
    List<Widget> statItems = stats.entries.map((entry) => 
      StatIndicator(
        label: entry.key,
        value: _getDisplayValue(entry.value),
        icon: _getStatIconByKeyword(entry.key), // Icône spécifique selon le type de stat
        layout: StatIndicatorLayout.horizontal,
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14.0),
        valueStyle: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
      )
    ).toList().cast<Widget>();
    
    return StatsPanel(
      title: title,
      titleIcon: _getSectionIcon(title),
      titleStyle: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(16),
      children: statItems,
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
  
  /// Sélectionne une icône appropriée selon le mot-clé dans le label de la statistique
  IconData _getStatIconByKeyword(String label) {
    final String lowerLabel = label.toLowerCase();
    
    // Production
    if (lowerLabel.contains('produit') || lowerLabel.contains('production')) {
      return Icons.precision_manufacturing;
    }
    // Argent et économie
    else if (lowerLabel.contains('argent') || lowerLabel.contains('euro') || 
             lowerLabel.contains('coût') || lowerLabel.contains('prix') ||
             lowerLabel.contains('vendu')) {
      return Icons.euro;
    }
    // Temps
    else if (lowerLabel.contains('temps') || lowerLabel.contains('durée') ||
             lowerLabel.contains('minute') || lowerLabel.contains('seconde')) {
      return Icons.timer;
    }
    // Niveau et progression
    else if (lowerLabel.contains('niveau') || lowerLabel.contains('progression') ||
             lowerLabel.contains('xp') || lowerLabel.contains('expérience')) {
      return Icons.trending_up;
    }
    // Qualité
    else if (lowerLabel.contains('qualité')) {
      return Icons.star;
    }
    // Efficacité
    else if (lowerLabel.contains('efficacité') || lowerLabel.contains('rendement')) {
      return Icons.eco;
    }
    // Marketing et ventes
    else if (lowerLabel.contains('marketing') || lowerLabel.contains('vente') ||
             lowerLabel.contains('demande') || lowerLabel.contains('client')) {
      return Icons.storefront;
    }
    // Par défaut
    return Icons.analytics;
  }
}