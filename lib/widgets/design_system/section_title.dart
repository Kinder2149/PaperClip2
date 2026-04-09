import 'package:flutter/material.dart';

/// Widget titre de section avec emoji
/// 
/// Affiche un titre de section avec un emoji et un style bold.
/// 
/// Exemple :
/// ```dart
/// SectionTitle(
///   emoji: '📊',
///   title: 'Statistiques',
/// )
/// ```
class SectionTitle extends StatelessWidget {
  final String emoji;
  final String title;

  const SectionTitle({
    super.key,
    required this.emoji,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$emoji $title',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
