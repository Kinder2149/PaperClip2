// lib/widgets/appbar/level_badge.dart

import 'package:flutter/material.dart';
import '../../models/progression_system.dart';
import '../../utils/responsive_utils.dart';

/// Badge moderne pour afficher le niveau avec gradient doré
class LevelBadge extends StatelessWidget {
  final LevelSystem levelSystem;

  const LevelBadge({
    Key? key,
    required this.levelSystem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // RESPONSIVE-APPBAR: Paddings et tailles adaptés selon breakpoint
    final horizontalPadding = const ResponsiveValue<double>(
      mobile: 8.0,
      tablet: 10.0,
      desktop: 10.0,
    ).getValue(context);

    final verticalPadding = const ResponsiveValue<double>(
      mobile: 4.0,
      tablet: 6.0,
      desktop: 6.0,
    ).getValue(context);

    final iconSize = const ResponsiveValue<double>(
      mobile: 14.0,
      tablet: 16.0,
      desktop: 16.0,
    ).getValue(context);

    final fontSize = const ResponsiveValue<double>(
      mobile: 12.0,
      tablet: 14.0,
      desktop: 14.0,
    ).getValue(context);

    final spacing = const ResponsiveValue<double>(
      mobile: 4.0,
      tablet: 6.0,
      desktop: 6.0,
    ).getValue(context);

    return GestureDetector(
      onTap: () => _showLevelInfoDialog(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade400,
              Colors.orange.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: iconSize,
              color: Colors.white,
            ),
            SizedBox(width: spacing),
            Text(
              'Niv. ${levelSystem.level}',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLevelInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Niveau'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Niveau actuel: ${levelSystem.level}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Expérience: ${levelSystem.experience.toStringAsFixed(0)} / ${levelSystem.experienceForNextLevel.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: levelSystem.experienceProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade600),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Débloquez de nouvelles fonctionnalités en augmentant votre niveau!',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
