// lib/screens/conflict_resolution_screen.dart
import 'package:flutter/material.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';
import 'package:intl/intl.dart';

enum ConflictChoice {
  keepLocal,
  keepCloud,
  cancel,
}

class ConflictResolutionData {
  final GameSnapshot localSnapshot;
  final GameSnapshot cloudSnapshot;
  final String enterpriseId;

  const ConflictResolutionData({
    required this.localSnapshot,
    required this.cloudSnapshot,
    required this.enterpriseId,
  });
}

/// Écran de résolution de conflits entre sauvegarde locale et cloud
/// 
/// Affiche les statistiques des deux versions et permet à l'utilisateur
/// de choisir quelle version conserver. La version non choisie sera supprimée.
class ConflictResolutionScreen extends StatelessWidget {
  final ConflictResolutionData data;

  const ConflictResolutionScreen({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Empêcher le retour arrière sans choix
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Conflit de Sauvegarde'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Message d'avertissement
                Card(
                  color: Colors.orange.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 48,
                          color: Colors.orange.shade900,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Conflit Détecté',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Deux versions différentes de votre entreprise ont été trouvées.\n'
                          'Veuillez choisir quelle version conserver.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '⚠️ La version non choisie sera définitivement supprimée',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Comparaison des deux versions
                Expanded(
                  child: Row(
                    children: [
                      // Version Locale
                      Expanded(
                        child: _buildVersionCard(
                          context,
                          title: '📱 Version Locale',
                          snapshot: data.localSnapshot,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Version Cloud
                      Expanded(
                        child: _buildVersionCard(
                          context,
                          title: '☁️ Version Cloud',
                          snapshot: data.cloudSnapshot,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Boutons de choix
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(ConflictChoice.keepLocal);
                        },
                        icon: const Icon(Icons.phone_android),
                        label: const Text('Garder Local'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(ConflictChoice.keepCloud);
                        },
                        icon: const Icon(Icons.cloud),
                        label: const Text('Garder Cloud'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionCard(
    BuildContext context, {
    required String title,
    required GameSnapshot snapshot,
    required MaterialColor color,
  }) {
    final metadata = snapshot.metadata;
    final core = snapshot.core;

    // Extraire les statistiques
    final enterpriseName = metadata['enterpriseName'] as String? ?? 'Inconnu';
    final lastModified = metadata['lastModified'] as String?;
    final gameVersion = metadata['gameVersion'] as String? ?? '?';
    
    // Extraire les données du PlayerManager
    final playerData = core['playerManager'] as Map<String, dynamic>?;
    final paperclips = playerData?['paperclips'] as num? ?? 0;
    final money = playerData?['money'] as num? ?? 0;
    
    // Extraire le niveau
    final levelData = core['levelSystem'] as Map<String, dynamic>?;
    final level = levelData?['level'] as int? ?? 0;
    final xp = levelData?['experience'] as num? ?? 0;
    
    // Extraire les statistiques
    final statsData = core['statistics'] as Map<String, dynamic>?;
    final totalTimeSec = statsData?['totalGameTimeSec'] as int? ?? 0;
    final totalTimeHours = (totalTimeSec / 3600).toStringAsFixed(1);

    // Formater la date
    String formattedDate = 'Date inconnue';
    if (lastModified != null) {
      try {
        final date = DateTime.parse(lastModified);
        formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
      } catch (_) {}
    }

    return Card(
      elevation: 4,
      color: color.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.shade900,
                  ),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Nom entreprise
            _buildStatRow(
              context,
              icon: Icons.business,
              label: 'Entreprise',
              value: enterpriseName,
            ),
            const SizedBox(height: 12),

            // Niveau
            _buildStatRow(
              context,
              icon: Icons.star,
              label: 'Niveau',
              value: '$level (${xp.toStringAsFixed(0)} XP)',
            ),
            const SizedBox(height: 12),

            // Paperclips
            _buildStatRow(
              context,
              icon: Icons.attach_file,
              label: 'Trombones',
              value: paperclips.toStringAsFixed(0),
            ),
            const SizedBox(height: 12),

            // Money
            _buildStatRow(
              context,
              icon: Icons.attach_money,
              label: 'Argent',
              value: '\$${money.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),

            // Temps de jeu
            _buildStatRow(
              context,
              icon: Icons.access_time,
              label: 'Temps de jeu',
              value: '${totalTimeHours}h',
            ),
            const SizedBox(height: 12),

            // Date de sauvegarde
            _buildStatRow(
              context,
              icon: Icons.calendar_today,
              label: 'Dernière sauvegarde',
              value: formattedDate,
            ),
            const SizedBox(height: 12),

            // Version du jeu
            _buildStatRow(
              context,
              icon: Icons.info_outline,
              label: 'Version',
              value: gameVersion,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
