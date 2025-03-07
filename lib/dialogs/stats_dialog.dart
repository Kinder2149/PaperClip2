import 'package:flutter/material.dart';
import '../models/game_state_interfaces.dart';
import '../models/game_config.dart';

class StatsDialog extends StatelessWidget {
  final StatisticsManager statistics;

  const StatsDialog({
    Key? key,
    required this.statistics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = statistics.getAllStats();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: DefaultTabController(
          length: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Statistiques',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Onglets
              const TabBar(
                tabs: [
                  Tab(
                    icon: Icon(Icons.precision_manufacturing),
                    text: 'Production',
                  ),
                  Tab(
                    icon: Icon(Icons.attach_money),
                    text: 'Économie',
                  ),
                  Tab(
                    icon: Icon(Icons.trending_up),
                    text: 'Progression',
                  ),
                ],
              ),

              // Contenu des onglets
              Expanded(
                child: TabBarView(
                  children: [
                    _buildStatsList(stats['production']!),
                    _buildStatsList(stats['economie']!),
                    _buildStatsList(stats['progression']!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsList(Map<String, dynamic> stats) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final entry = stats.entries.elementAt(index);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              entry.key,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Text(
              entry.value.toString(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
              ),
            ),
          ),
        );
      },
    );
  }

  static void show(BuildContext context, StatisticsManager statistics) {
    showDialog(
      context: context,
      builder: (context) => StatsDialog(statistics: statistics),
    );
  }
}

class AchievementDialog extends StatelessWidget {
  final List<Achievement> achievements;
  final List<Achievement> unlockedAchievements;

  const AchievementDialog({
    Key? key,
    required this.achievements,
    required this.unlockedAchievements,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Réalisations',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Progression
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${unlockedAchievements.length}/${achievements.length} réalisations',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: achievements.isEmpty
                                ? 0
                                : unlockedAchievements.length / achievements.length,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Liste des réalisations
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  final isUnlocked = unlockedAchievements.contains(achievement);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                        color: isUnlocked ? Colors.amber : Colors.grey,
                        size: 32,
                      ),
                      title: Text(
                        achievement.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? null : Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        achievement.description,
                        style: TextStyle(
                          color: isUnlocked ? null : Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void show(
    BuildContext context,
    List<Achievement> achievements,
    List<Achievement> unlockedAchievements,
  ) {
    showDialog(
      context: context,
      builder: (context) => AchievementDialog(
        achievements: achievements,
        unlockedAchievements: unlockedAchievements,
      ),
    );
  }
} 