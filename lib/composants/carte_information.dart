import 'package:flutter/material.dart';

class CarteInformation extends StatelessWidget {
  final String titre;
  final Widget contenu;
  final Color? couleurFond;
  final Color? couleurBordure;
  final EdgeInsets? padding;

  const CarteInformation({
    Key? key,
    required this.titre,
    required this.contenu,
    this.couleurFond,
    this.couleurBordure,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: couleurFond ?? Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: couleurBordure ?? Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titre,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            contenu,
          ],
        ),
      ),
    );
  }
} 