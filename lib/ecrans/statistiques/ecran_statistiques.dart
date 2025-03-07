import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/jeu_provider.dart';
import '../../components/mise_en_page_base.dart';
import '../../components/carte_information.dart';

class EcranStatistiques extends StatelessWidget {
  const EcranStatistiques({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<JeuProvider>(
      builder: (context, jeu, child) {
        return MiseEnPageBase(
          titre: 'Statistiques',
          corps: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Production',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  children: [
                    CarteInformation(
                      titre: 'Production Totale',
                      valeur: '${jeu.statistiques.productionTotale}',
                      icone: Icons.build,
                    ),
                    CarteInformation(
                      titre: 'Production Actuelle',
                      valeur: '${jeu.statistiques.productionCourante}/s',
                      icone: Icons.speed,
                    ),
                    CarteInformation(
                      titre: 'Record Production',
                      valeur: '${jeu.statistiques.productionMaximale}/s',
                      icone: Icons.emoji_events,
                    ),
                  ],
                ),
                const SizedBox(height: 32.0),
                const Text(
                  'Marché',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  children: [
                    CarteInformation(
                      titre: 'Prix Moyen',
                      valeur: '${jeu.statistiques.prixMoyen.toStringAsFixed(2)} €',
                      icone: Icons.euro,
                    ),
                    CarteInformation(
                      titre: 'Prix Actuel',
                      valeur: '${jeu.statistiques.prixCourant.toStringAsFixed(2)} €',
                      icone: Icons.price_change,
                    ),
                    CarteInformation(
                      titre: 'Record Prix',
                      valeur: '${jeu.statistiques.prixMaximal.toStringAsFixed(2)} €',
                      icone: Icons.emoji_events,
                    ),
                  ],
                ),
                const SizedBox(height: 32.0),
                const Text(
                  'Améliorations',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: jeu.ameliorations.ameliorations.values.map((amelioration) {
                        return ListTile(
                          title: Text(amelioration.nom),
                          trailing: Text('Niveau ${amelioration.niveau}'),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 