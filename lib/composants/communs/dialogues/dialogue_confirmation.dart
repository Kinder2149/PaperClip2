import 'package:flutter/material.dart';

class DialogueConfirmation extends StatelessWidget {
  final String titre;
  final String message;
  final String? texteBoutonConfirmer;
  final String? texteBoutonAnnuler;
  final VoidCallback? onConfirmer;
  final VoidCallback? onAnnuler;
  final IconData? icone;
  final Color? couleur;
  final bool dangereux;

  const DialogueConfirmation({
    Key? key,
    required this.titre,
    required this.message,
    this.texteBoutonConfirmer,
    this.texteBoutonAnnuler,
    this.onConfirmer,
    this.onAnnuler,
    this.icone,
    this.couleur,
    this.dangereux = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurFinale = couleur ?? (dangereux ? theme.colorScheme.error : theme.primaryColor);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: couleurFinale.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icone,
                  color: couleurFinale,
                  size: 32,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              titre,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    if (onAnnuler != null) {
                      onAnnuler!();
                    }
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    texteBoutonAnnuler ?? 'Annuler',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (onConfirmer != null) {
                      onConfirmer!();
                    }
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: couleurFinale,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(texteBoutonConfirmer ?? 'Confirmer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> afficher(
    BuildContext context, {
    required String titre,
    required String message,
    String? texteBoutonConfirmer,
    String? texteBoutonAnnuler,
    VoidCallback? onConfirmer,
    VoidCallback? onAnnuler,
    IconData? icone,
    Color? couleur,
    bool dangereux = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DialogueConfirmation(
        titre: titre,
        message: message,
        texteBoutonConfirmer: texteBoutonConfirmer,
        texteBoutonAnnuler: texteBoutonAnnuler,
        onConfirmer: onConfirmer,
        onAnnuler: onAnnuler,
        icone: icone,
        couleur: couleur,
        dangereux: dangereux,
      ),
    );
  }
} 