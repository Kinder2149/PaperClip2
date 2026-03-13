import 'package:flutter/material.dart';

/// Un panneau réutilisable pour afficher des statistiques et indicateurs groupés
/// 
/// Ce widget encapsule plusieurs indicateurs dans une carte avec un titre optionnel
/// et divers styles de mise en page.
class StatsPanel extends StatelessWidget {
  /// Titre du panneau de statistiques
  final String? title;
  
  /// Icône optionnelle pour le titre
  final IconData? titleIcon;
  
  /// Liste des widgets enfants à afficher dans le panneau
  final List<Widget> children;
  
  /// Couleur de fond du panneau
  final Color backgroundColor;
  
  /// Widget d'action optionnel (affiché à côté du titre)
  final Widget? action;
  
  /// Padding interne du panneau
  final EdgeInsets padding;
  
  /// Espacement entre les éléments du panneau
  final double spacing;
  
  /// Style du texte du titre
  final TextStyle? titleStyle;
  
  /// Direction de la disposition (vertical ou horizontal)
  final Axis direction;
  
  /// Callback quand on tap sur le panneau
  final VoidCallback? onTap;

  const StatsPanel({
    Key? key,
    this.title,
    this.titleIcon,
    required this.children,
    required this.backgroundColor,
    this.action,
    this.padding = const EdgeInsets.all(12),
    this.spacing = 8.0,
    this.titleStyle,
    this.direction = Axis.vertical,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultTitleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

    return Card(
      elevation: 2,
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Row(
                  children: [
                    if (titleIcon != null) ...[
                      Icon(titleIcon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      title!,
                      style: titleStyle ?? defaultTitleStyle,
                    ),
                    const Spacer(),
                    if (action != null) action!,
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // Contenu principal - soit vertical, soit horizontal
              if (direction == Axis.vertical)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _addSpacingBetweenItems(children, spacing),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ajoute un espacement entre les widgets enfants
  List<Widget> _addSpacingBetweenItems(List<Widget> items, double spacing) {
    if (items.isEmpty) return [];
    if (items.length == 1) return items;

    final result = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(SizedBox(height: spacing));
      }
    }
    return result;
  }
}
