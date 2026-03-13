import 'package:flutter/material.dart';

/// Un dialogue d'information réutilisable qui affiche un titre et un message
/// 
/// Ce widget simplifie la création de dialogues d'information cohérents dans l'application.
class InfoDialog extends StatelessWidget {
  /// Titre du dialogue
  final String title;
  
  /// Message principal à afficher (texte)
  final String message;
  
  /// Widget de contenu personnalisé (prioritaire sur message si fourni)
  final Widget? content;
  
  /// Libellé du bouton de fermeture (défaut: 'Fermer')
  final String closeButtonLabel;
  
  /// Fonction appelée lorsque le bouton de fermeture est pressé
  final VoidCallback? onClose;
  
  /// Actions supplémentaires à afficher (boutons)
  final List<Widget>? additionalActions;
  
  /// Détermine si le dialogue peut être fermé en tapant à l'extérieur
  final bool barrierDismissible;

  const InfoDialog({
    Key? key,
    required this.title,
    required this.message,
    this.content,
    this.closeButtonLabel = 'Fermer',
    this.onClose,
    this.additionalActions,
    this.barrierDismissible = true,
  }) : super(key: key);

  /// Affiche le dialogue dans le contexte donné
  /// 
  /// Retourne un Future<bool> qui sera résolu à true si le bouton principal de confirmation est pressé
  /// ou false si le dialogue est fermé d'une autre manière (comme un bouton d'annulation ou clic extérieur)
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    Widget? content,
    String closeButtonLabel = 'Fermer',
    VoidCallback? onClose,
    List<Widget>? additionalActions,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => InfoDialog(
        title: title,
        message: message,
        content: content,
        closeButtonLabel: closeButtonLabel,
        onClose: onClose,
        additionalActions: additionalActions,
        barrierDismissible: barrierDismissible,
      ),
    ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content ?? SingleChildScrollView(
        child: Text(message),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, true); // Retourne true pour indiquer la confirmation
            if (onClose != null) {
              onClose!();
            }
          },
          child: Text(closeButtonLabel),
        ),
        if (additionalActions != null) ...additionalActions!,
      ],
    );
  }
}
