import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Widget bouton d'action avec emoji
/// 
/// Bouton stylisé avec emoji et texte, utilisé pour les actions principales dans les panels.
/// 
/// Exemple :
/// ```dart
/// ActionButton(
///   emoji: '📎',
///   label: 'Créer un trombone',
///   onPressed: () => print('Action!'),
///   color: Colors.blue,
/// )
/// 
/// // Bouton désactivé
/// ActionButton(
///   emoji: '🤖',
///   label: 'Acheter Autoclipper',
///   onPressed: null,
///   color: Colors.purple,
/// )
/// ```
class ActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool isCompact;

  const ActionButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.onPressed,
    required this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(
          isCompact
              ? DesignTokens.kButtonPaddingCompact
              : DesignTokens.kButtonPaddingStandard,
        ),
        backgroundColor: isEnabled ? color : null,
        foregroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: DesignTokens.kEmojiSizeMedium),
          ),
          SizedBox(width: DesignTokens.kSpacingMedium),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: DesignTokens.kTextSizeButton,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
