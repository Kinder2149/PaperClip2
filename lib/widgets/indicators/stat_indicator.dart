import 'package:flutter/material.dart';

/// Widget affichant un indicateur de statistique avec label, valeur et icône
/// 
/// Utilisé pour afficher des statistiques du jeu comme la réputation, la demande, etc.
/// de manière consistante à travers l'application
class StatIndicator extends StatelessWidget {
  /// Le libellé de la statistique
  final String label;
  
  /// La valeur de la statistique (sous forme de texte)
  final String value;
  
  /// L'icône représentant la statistique
  final IconData icon;
  
  /// Taille de l'icône (défaut: 16)
  final double iconSize;
  
  /// Couleur de l'icône (défaut: null, utilise la couleur du thème)
  final Color? iconColor;
  
  /// Style du texte pour le label
  final TextStyle? labelStyle;
  
  /// Style du texte pour la valeur
  final TextStyle? valueStyle;
  
  /// Espace entre l'icône et le texte (défaut: 8)
  final double spaceBetween;
  
  /// Type d'affichage (horizontal ou vertical)
  final StatIndicatorLayout layout;

  /// Callback lorsqu'on tap sur l'indicateur
  final VoidCallback? onTap;

  const StatIndicator({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconSize = 16,
    this.iconColor,
    this.labelStyle,
    this.valueStyle,
    this.spaceBetween = 8,
    this.layout = StatIndicatorLayout.horizontal,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultLabelStyle = TextStyle(
      fontSize: 14,
      color: Colors.grey[800],
    );

    final defaultValueStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );

    Widget content;
    
    if (layout == StatIndicatorLayout.horizontal) {
      // Disposition horizontale (label | valeur)
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: iconSize, color: iconColor),
            SizedBox(width: spaceBetween),
            Text(label, style: labelStyle ?? defaultLabelStyle),
            const Spacer(),
            Text(value, style: valueStyle ?? defaultValueStyle),
          ],
        ),
      );
    } else {
      // Disposition verticale (valeur au-dessus du label)
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: iconColor),
              SizedBox(width: spaceBetween / 2),
              Text(value, style: valueStyle ?? defaultValueStyle),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: labelStyle ?? defaultLabelStyle.copyWith(fontSize: 12)),
        ],
      );
    }

    // Si un onTap est fourni, on entoure le contenu d'un InkWell
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: content,
      );
    }

    return content;
  }
}

/// Types de disposition pour StatIndicator
enum StatIndicatorLayout {
  /// Affichage horizontal avec label à gauche et valeur à droite
  horizontal,
  
  /// Affichage vertical avec valeur au-dessus du label
  vertical,
}
