import 'package:flutter/material.dart';

class IndicateurChargement extends StatelessWidget {
  final String? message;
  final Color? couleur;
  final double taille;
  final double epaisseurTrait;
  final EdgeInsetsGeometry? padding;

  const IndicateurChargement({
    Key? key,
    this.message,
    this.couleur,
    this.taille = 40.0,
    this.epaisseurTrait = 4.0,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: taille,
              height: taille,
              child: CircularProgressIndicator(
                strokeWidth: epaisseurTrait,
                valueColor: couleur != null
                    ? AlwaysStoppedAnimation<Color>(couleur!)
                    : AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
} 