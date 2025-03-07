import 'package:flutter/material.dart';

class CarteInformation extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icone;
  final Color? couleurFond;
  final VoidCallback? onTap;

  const CarteInformation({
    Key? key,
    required this.titre,
    required this.valeur,
    required this.icone,
    this.couleurFond,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: couleurFond ?? Theme.of(context).cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icone,
                size: 32.0,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8.0),
              Text(
                titre,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4.0),
              Text(
                valeur,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Icon(
                    Icons.info_outline,
                    size: 16.0,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 