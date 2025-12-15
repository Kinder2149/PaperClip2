import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';

/// Widget de bouton d'action réutilisable pour l'application PaperClip
///
/// Ce widget unifie les différents styles de boutons d'action utilisés dans l'application.
/// Il peut afficher un multiplicateur de combo s'il est activé et si la valeur est > 1.0
class ActionButton extends StatelessWidget {
  /// Fonction appelée quand le bouton est pressé
  final VoidCallback? onPressed;
  
  /// Texte affiché sur le bouton
  final String label;
  
  /// Icône affichée sur le bouton
  final IconData icon;
  
  /// Couleur de fond du bouton (facultatif)
  final Color? backgroundColor;
  
  /// Couleur du texte et de l'icône (facultatif)
  final Color? textColor;
  
  /// Si le bouton doit prendre toute la largeur disponible
  final bool fullWidth;
  
  /// Si le bouton doit afficher le multiplicateur de combo du joueur
  final bool showComboMultiplier;
  
  /// Padding interne du bouton
  final EdgeInsets? padding;

  /// Taille de l'icône
  final double iconSize;
  
  /// Taille du texte
  final double fontSize;
  
  /// Style du texte (facultatif)
  final TextStyle? labelStyle;

  const ActionButton({
    Key? key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.backgroundColor,
    this.textColor,
    this.fullWidth = true,
    this.showComboMultiplier = false,
    this.padding,
    this.iconSize = 20,
    this.fontSize = 14,
    this.labelStyle,
  }) : super(key: key);
  
  /// Constructeur pour un bouton d'action primaire (bleu)
  factory ActionButton.primary({
    required VoidCallback? onPressed,
    required String label,
    IconData icon = Icons.check_circle,
    bool fullWidth = true,
    bool showComboMultiplier = false,
    EdgeInsets? padding,
    double iconSize = 20,
    double fontSize = 14,
    TextStyle? labelStyle,
  }) {
    return ActionButton(
      onPressed: onPressed,
      label: label,
      icon: icon,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      fullWidth: fullWidth,
      showComboMultiplier: showComboMultiplier,
      padding: padding,
      iconSize: iconSize,
      fontSize: fontSize,
      labelStyle: labelStyle,
    );
  }
  
  /// Constructeur pour un bouton d'achat (vert)
  factory ActionButton.purchase({
    required VoidCallback? onPressed,
    required String label,
    IconData icon = Icons.shopping_cart,
    bool fullWidth = true,
    bool showComboMultiplier = false,
    EdgeInsets? padding,
    double iconSize = 20,
    double fontSize = 14,
    TextStyle? labelStyle,
  }) {
    return ActionButton(
      onPressed: onPressed,
      label: label,
      icon: icon,
      backgroundColor: Colors.green.shade600,
      textColor: Colors.white,
      fullWidth: fullWidth,
      showComboMultiplier: showComboMultiplier,
      padding: padding,
      iconSize: iconSize,
      fontSize: fontSize,
      labelStyle: labelStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize),
      label: Text(
        label,
        style: labelStyle ?? TextStyle(
          fontSize: fontSize,
          color: textColor,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.grey.shade50,
        foregroundColor: textColor ?? Colors.black87,
        padding: padding ?? const EdgeInsets.all(16),
        minimumSize: fullWidth ? const Size(double.infinity, 50) : null,
      ),
    );

    // Si on ne montre pas le multiplicateur, on retourne juste le bouton
    if (!showComboMultiplier) {
      return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
    }

    // Sinon on l'enveloppe dans un Selector ciblé sur le multiplicateur
    return Selector<GameState, double>(
      selector: (context, gameState) => gameState.level.currentComboMultiplier,
      builder: (context, comboMultiplier, _) {
        return Stack(
          children: [
            fullWidth ? SizedBox(width: double.infinity, child: button) : button,
            if (comboMultiplier > 1.0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'x${comboMultiplier.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Extension pour les boutons préstyled
extension ActionButtonExtensions on ActionButton {
  /// Crée un bouton d'action primaire (bleu)
  static ActionButton primary({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    bool fullWidth = true,
    bool showComboMultiplier = false,
    EdgeInsets? padding,
  }) {
    return ActionButton(
      onPressed: onPressed,
      label: label,
      icon: icon,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      fullWidth: fullWidth,
      showComboMultiplier: showComboMultiplier,
      padding: padding,
    );
  }

  /// Crée un bouton d'achat
  static ActionButton purchase({
    required VoidCallback? onPressed,
    required String label,
    IconData icon = Icons.shopping_cart,
    bool fullWidth = true,
    bool showComboMultiplier = true,
    EdgeInsets? padding,
  }) {
    return ActionButton(
      onPressed: onPressed,
      label: label,
      icon: icon,
      backgroundColor: Colors.green.shade600,
      textColor: Colors.white,
      fullWidth: fullWidth,
      showComboMultiplier: showComboMultiplier,
      padding: padding,
    );
  }
}
