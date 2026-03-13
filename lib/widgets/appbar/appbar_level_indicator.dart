// lib/widgets/appbar/appbar_level_indicator.dart
import 'package:flutter/material.dart';
import '../../models/progression_system.dart';

class AppBarLevelIndicator extends StatelessWidget {
  final LevelSystem levelSystem;
  
  const AppBarLevelIndicator({
    Key? key,
    required this.levelSystem,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLevelInfoDialog(context, levelSystem),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.deepPurple.shade900 
            : Colors.deepPurple.shade800,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: levelSystem.experienceProgress,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).brightness == Brightness.dark
                    ? Colors.greenAccent
                    : Colors.green,
                ),
                strokeWidth: 3,
              ),
            ),
            Text(
              '${levelSystem.level}',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showLevelInfoDialog(BuildContext context, LevelSystem levelSystem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star),
            SizedBox(width: 8),
            Text('Niveau'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Niveau actuel: ${levelSystem.level}'),
            const SizedBox(height: 8),
            Text('Expérience: ${levelSystem.experience.toStringAsFixed(0)} / ${levelSystem.experienceForNextLevel.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: levelSystem.experienceProgress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 16),
            const Text(
              'Débloquez de nouvelles fonctionnalités en augmentant votre niveau!',
              style: TextStyle(fontStyle: FontStyle.italic),
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
