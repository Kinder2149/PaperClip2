import 'package:flutter/material.dart';

/// Widget de carte d'information réutilisable pour afficher des données avec un design cohérent
/// 
/// Utilisé pour présenter des statistiques, des ressources, et d'autres informations
/// dans un format visuel attractif et cohérent dans l'application.
class InfoCard extends StatelessWidget {
  /// Titre de la carte
  final String title;
  
  /// Valeur principale à afficher
  final String value;
  
  /// Couleur de fond de la carte
  final Color backgroundColor;
  
  /// Icône optionnelle à afficher
  final IconData? icon;
  
  /// Couleur de l'icône (par défaut: Colors.black87)
  final Color iconColor;
  
  /// Texte explicatif optionnel
  final String? tooltip;
  
  /// Fonction appelée lors du tap sur la carte
  final VoidCallback? onTap;
  
  /// Widget additionnel optionnel (affiché à droite)
  final Widget? trailing;
  
  /// Alignement horizontal du contenu (par défaut: centre)
  final CrossAxisAlignment crossAxisAlignment;

  /// Taille du titre (par défaut: 14)
  final double titleFontSize;
  
  /// Taille de la valeur (par défaut: 16)
  final double valueFontSize;
  
  /// Détermine si la carte prend tout l'espace disponible
  final bool expanded;

  const InfoCard({
    Key? key,
    required this.title,
    required this.value,
    required this.backgroundColor,
    this.icon,
    this.iconColor = Colors.black87,
    this.tooltip,
    this.onTap,
    this.trailing,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.titleFontSize = 14,
    this.valueFontSize = 16,
    this.expanded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Card(
      elevation: 2,
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 24, color: iconColor),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: crossAxisAlignment,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: crossAxisAlignment == CrossAxisAlignment.center 
                        ? TextAlign.center 
                        : TextAlign.start,
                    ),
                    if (tooltip != null && tooltip!.isNotEmpty) ...[
                      Text(
                        tooltip!,
                        style: TextStyle(
                          fontSize: titleFontSize - 2,
                          color: Colors.black54,
                        ),
                        textAlign: crossAxisAlignment == CrossAxisAlignment.center 
                          ? TextAlign.center 
                          : TextAlign.start,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: valueFontSize,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: crossAxisAlignment == CrossAxisAlignment.center 
                        ? TextAlign.center 
                        : TextAlign.start,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );

    // Si expanded est vrai, on emballe la carte dans un Expanded
    if (expanded) {
      return Expanded(child: cardContent);
    } else {
      return cardContent;
    }
  }
}
