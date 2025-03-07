import 'package:flutter/material.dart';

class BoutonAmelioration extends StatelessWidget {
  final String titre;
  final String description;
  final int niveau;
  final double cout;
  final double argentDisponible;
  final bool estDisponible;
  final VoidCallback onPressed;

  const BoutonAmelioration({
    Key? key,
    required this.titre,
    required this.description,
    required this.niveau,
    required this.cout,
    required this.argentDisponible,
    required this.estDisponible,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool peutAcheter = estDisponible && argentDisponible >= cout;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: peutAcheter ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      titre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: peutAcheter ? null : Colors.grey,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Niveau $niveau',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: peutAcheter ? null : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Coût: ${cout.toStringAsFixed(0)}€',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: peutAcheter ? Colors.green : Colors.red,
                    ),
                  ),
                  Icon(
                    peutAcheter ? Icons.check_circle : Icons.lock,
                    color: peutAcheter ? Colors.green : Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 