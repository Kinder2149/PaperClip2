import 'package:flutter/material.dart';

enum TypeBouton {
  primaire,
  secondaire,
  outline,
  danger
}

class BoutonPrincipal extends StatelessWidget {
  final String texte;
  final VoidCallback? onPressed;
  final TypeBouton type;
  final bool enChargement;
  final IconData? icone;
  final double? largeur;
  final double? hauteur;

  const BoutonPrincipal({
    Key? key,
    required this.texte,
    this.onPressed,
    this.type = TypeBouton.primaire,
    this.enChargement = false,
    this.icone,
    this.largeur,
    this.hauteur,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Configuration des couleurs selon le type
    Color? backgroundColor;
    Color? foregroundColor;
    switch (type) {
      case TypeBouton.primaire:
        backgroundColor = theme.primaryColor;
        foregroundColor = Colors.white;
        break;
      case TypeBouton.secondaire:
        backgroundColor = theme.colorScheme.secondary;
        foregroundColor = Colors.white;
        break;
      case TypeBouton.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = theme.primaryColor;
        break;
      case TypeBouton.danger:
        backgroundColor = theme.colorScheme.error;
        foregroundColor = Colors.white;
        break;
    }

    return SizedBox(
      width: largeur,
      height: hauteur,
      child: ElevatedButton(
        onPressed: enChargement ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: type == TypeBouton.outline
              ? BorderSide(color: theme.primaryColor)
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: enChargement
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icone != null) ...[
                    Icon(icone),
                    const SizedBox(width: 8),
                  ],
                  Text(texte),
                ],
              ),
      ),
    );
  }
} 