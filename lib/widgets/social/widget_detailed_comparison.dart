// lib/widgets/social/widget_detailed_comparison.dart

import 'package:flutter/material.dart';
import '../../models/social/user_stats_model.dart';
import 'dart:math' as math;

/// Widget de comparaison détaillée entre deux joueurs.
///
/// Fournit une visualisation des différences de performance
/// entre l'utilisateur et un ami.
class WidgetDetailedComparison extends StatelessWidget {
  /// Données de l'utilisateur actuel
  final UserStatsModel myStats;

  /// Données de l'ami pour la comparaison
  final UserStatsModel friendStats;

  /// Couleur thème pour l'utilisateur actuel
  final Color myColor;

  /// Couleur thème pour l'ami
  final Color friendColor;

  const WidgetDetailedComparison({
    Key? key,
    required this.myStats,
    required this.friendStats,
    this.myColor = Colors.blue,
    this.friendColor = Colors.orange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // En-tête avec avatars
        _buildHeaderWithAvatars(context),

        const SizedBox(height: 16),

        // Graphiques de comparaison simplifié
        _buildSimpleComparisonBars(context),

        const SizedBox(height: 24),

        // Statistiques détaillées en tableau
        _buildDetailedStatsTable(context),
      ],
    );
  }

  /// Crée l'en-tête avec les avatars et noms des joueurs
  Widget _buildHeaderWithAvatars(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPlayerCard(
          context,
          myStats.displayName,
          null, // Photo URL à implémenter
          'Vous',
          myColor.withOpacity(0.2),
        ),

        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.withOpacity(0.1),
          ),
          child: const Center(
            child: Text(
              'VS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),

        _buildPlayerCard(
          context,
          friendStats.displayName,
          null, // Photo URL à implémenter
          'Ami',
          friendColor.withOpacity(0.2),
        ),
      ],
    );
  }

  /// Crée une carte pour afficher les informations du joueur
  Widget _buildPlayerCard(
      BuildContext context,
      String name,
      String? photoUrl,
      String label,
      Color backgroundColor,
      ) {
    return Card(
      elevation: 2,
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            CircleAvatar(
              radius: 30,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 24),
              )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Crée des barres de comparaison simpliifiées
  Widget _buildSimpleComparisonBars(BuildContext context) {
    // Liste des statistiques à comparer
    final stats = [
      {'key': 'totalPaperclips', 'title': 'Trombones'},
      {'key': 'level', 'title': 'Niveau'},
      {'key': 'money', 'title': 'Argent'},
      {'key': 'efficiency', 'title': 'Efficacité'},
      {'key': 'bestScore', 'title': 'Score'},
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparaison visuelle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...stats.map((stat) => _buildComparisonBar(
              context,
              stat['title'] as String,
              stat['key'] as String,
            )).toList(),
          ],
        ),
      ),
    );
  }

  /// Construit une barre de comparaison pour une statistique donnée
  Widget _buildComparisonBar(BuildContext context, String title, String statKey) {
    // Récupérer les valeurs
    final dynamic myValue = _getStatValue(myStats, statKey);
    final dynamic friendValue = _getStatValue(friendStats, statKey);

    // Calculer les pourcentages
    final max = math.max(
        myValue is int ? myValue.toDouble() : myValue as double,
        friendValue is int ? friendValue.toDouble() : friendValue as double
    );

    double myPercentage = max > 0
        ? (myValue is int ? myValue.toDouble() : myValue as double) / max
        : 0;

    double friendPercentage = max > 0
        ? (friendValue is int ? friendValue.toDouble() : friendValue as double) / max
        : 0;

    // Formater pour l'affichage
    final myValueFormatted = _formatValue(title, myValue);
    final friendValueFormatted = _formatValue(title, friendValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: myColor,
                  ),
                  const SizedBox(width: 4),
                  Text('Vous: $myValueFormatted'),
                  const SizedBox(width: 12),
                  Container(
                    width: 12,
                    height: 12,
                    color: friendColor,
                  ),
                  const SizedBox(width: 4),
                  Text('Ami: $friendValueFormatted'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 24,
            child: Stack(
              children: [
                // Fond
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Barre de l'ami
                Row(
                  children: [
                    Expanded(
                      flex: (friendPercentage * 100).toInt(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: friendColor.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 100 - (friendPercentage * 100).toInt(),
                      child: Container(),
                    ),
                  ],
                ),
                // Barre de l'utilisateur (plus fine pour voir les deux)
                Row(
                  children: [
                    Expanded(
                      flex: (myPercentage * 100).toInt(),
                      child: Container(
                        height: 12,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: myColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 100 - (myPercentage * 100).toInt(),
                      child: Container(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Obtient la valeur d'une statistique à partir de la clé
  dynamic _getStatValue(UserStatsModel stats, String key) {
    switch (key) {
      case 'totalPaperclips': return stats.totalPaperclips;
      case 'level': return stats.level;
      case 'money': return stats.money;
      case 'efficiency': return stats.efficiency;
      case 'bestScore': return stats.bestScore;
      case 'upgradesBought': return stats.upgradesBought;
      default: return 0;
    }
  }

  /// Crée un tableau détaillé des statistiques
  Widget _buildDetailedStatsTable(BuildContext context) {
    // Obtenir la comparaison entre les deux joueurs
    final comparison = myStats.compareWith(friendStats);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques détaillées',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...comparison.entries.map((entry) {
              final statName = _formatStatName(entry.key);
              final myValue = entry.value['me'];
              final friendValue = entry.value['friend'];
              final diff = entry.value['diff'];

              return _buildDetailedStatRow(
                context,
                statName,
                myValue,
                friendValue,
                diff,
                _isHigherBetter(entry.key),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Crée une ligne du tableau de statistiques détaillées
  Widget _buildDetailedStatRow(
      BuildContext context,
      String statName,
      dynamic myValue,
      dynamic friendValue,
      dynamic difference,
      bool higherIsBetter,
      ) {
    final formattedMyValue = _formatValue(statName, myValue);
    final formattedFriendValue = _formatValue(statName, friendValue);
    final formattedDiff = _formatDifference(statName, difference);

    final bool isPositive = difference > 0;
    final bool isBetter = higherIsBetter ? isPositive : !isPositive;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              statName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formattedMyValue,
              style: TextStyle(
                color: myColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formattedFriendValue,
              style: TextStyle(
                color: friendColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isBetter ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                formattedDiff,
                style: TextStyle(
                  color: isBetter ? Colors.green.shade800 : Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Détermine si une valeur plus élevée est meilleure pour cette statistique
  bool _isHigherBetter(String statKey) {
    switch (statKey) {
      case 'efficiency': return true;
      default: return true; // Par défaut, plus est mieux
    }
  }

  /// Formate le nom de la statistique pour l'affichage
  String _formatStatName(String statKey) {
    switch (statKey) {
      case 'totalPaperclips': return 'Production';
      case 'money': return 'Argent';
      case 'level': return 'Niveau';
      case 'bestScore': return 'Score';
      case 'efficiency': return 'Efficacité';
      case 'upgradesBought': return 'Améliorations';
      default: return statKey;
    }
  }

  /// Formate la valeur selon le type de statistique
  String _formatValue(String statName, dynamic value) {
    if (statName == 'Argent') {
      return '$value \$';
    } else if (statName == 'Efficacité') {
      return '${(value * 100).toStringAsFixed(1)}%';
    }
    return value.toString();
  }

  /// Formate la différence avec un préfixe + ou -
  String _formatDifference(String statName, dynamic diff) {
    final prefix = diff > 0 ? '+' : '';
    if (statName == 'Argent') {
      return '$prefix$diff \$';
    } else if (statName == 'Efficacité') {
      return '$prefix${(diff * 100).toStringAsFixed(1)}%';
    }
    return '$prefix$diff';
  }
}