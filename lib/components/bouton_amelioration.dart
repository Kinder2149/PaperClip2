import 'package:flutter/material.dart';
import '../services/ameliorations_service.dart';

class BoutonAmelioration extends StatelessWidget {
  final Amelioration amelioration;
  final bool peutAcheter;
  final VoidCallback onAcheter;

  const BoutonAmelioration({
    Key? key,
    required this.amelioration,
    required this.peutAcheter,
    required this.onAcheter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        amelioration.nom,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        amelioration.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColorLight,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'Niveau ${amelioration.niveau}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Coût: ${amelioration.coutActuel.toStringAsFixed(2)} €',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                ElevatedButton(
                  onPressed: peutAcheter ? onAcheter : null,
                  child: const Text('Améliorer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 