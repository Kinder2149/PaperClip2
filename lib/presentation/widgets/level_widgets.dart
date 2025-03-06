// lib/presentation/widgets/level_widgets.dart
import 'package:flutter/material.dart';
import '../../domain/entities/level_system_entity.dart';
import '../../core/constants/enums.dart';

class LevelIndicator extends StatelessWidget {
  final int level;
  final double progress;
  final bool isCompact;

  const LevelIndicator({
    Key? key,
    required this.level,
    required this.progress,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isCompact ? _buildCompactIndicator() : _buildFullIndicator(context);
  }

  Widget _buildCompactIndicator() {
    return Container(
      width: 50,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade800,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[700],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              strokeWidth: 3,
            ),
          ),
          Text(
            '$level',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.deepPurple.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple.shade600,
                ),
                child: Center(
                  child: Text(
                    '$level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Niveau $level',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.deepPurple.shade500,
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Progression: ${(progress * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class PathProgressCard extends StatelessWidget {
  final ProgressionPath path;
  final double progress;
  final bool isSelected;

  const PathProgressCard({
    Key? key,
    required this.path,
    required this.progress,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pathData = _getPathData();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? pathData.color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? pathData.color
              : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: pathData.color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  pathData.icon,
                  color: pathData.color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  pathData.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? pathData.color
                        : Colors.black87,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: pathData.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Actif',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: pathData.color,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              pathData.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(pathData.color),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Maîtrise: ${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _PathData _getPathData() {
    switch (path) {
      case ProgressionPath.PRODUCTION:
        return _PathData(
          name: 'Production',
          description: 'Optimisez vos chaînes de production pour fabriquer plus de trombones.',
          icon: Icons.precision_manufacturing,
          color: Colors.blue,
        );
      case ProgressionPath.MARKETING:
        return _PathData(
          name: 'Marketing',
          description: 'Augmentez la demande pour vos trombones et vendez-les à meilleur prix.',
          icon: Icons.campaign,
          color: Colors.purple,
        );
      case ProgressionPath.EFFICIENCY:
        return _PathData(
          name: 'Efficacité',
          description: 'Réduisez la consommation de ressources et optimisez vos processus.',
          icon: Icons.eco,
          color: Colors.green,
        );
      case ProgressionPath.INNOVATION:
        return _PathData(
          name: 'Innovation',
          description: 'Développez de nouvelles technologies et débloquez des fonctionnalités avancées.',
          icon: Icons.lightbulb,
          color: Colors.amber,
        );
    }
  }
}

class _PathData {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  _PathData({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class ExperienceBar extends StatelessWidget {
  final double experience;
  final double experienceForNextLevel;
  final int level;
  final bool showLevel;

  const ExperienceBar({
    Key? key,
    required this.experience,
    required this.experienceForNextLevel,
    required this.level,
    this.showLevel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = experience / experienceForNextLevel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (showLevel)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple,
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${experience.toInt()} / ${experienceForNextLevel.toInt()} XP',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}