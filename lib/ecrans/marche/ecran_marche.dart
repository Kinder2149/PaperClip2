import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/jeu_provider.dart';
import '../../composants/mise_en_page_base.dart';
import '../../composants/carte_information.dart';

class EcranMarche extends StatelessWidget {
  const EcranMarche({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<JeuProvider>(
      builder: (context, jeuProvider, child) {
        final marche = jeuProvider.marche;
        final production = jeuProvider.production;
        final stats = jeuProvider.statistiques;

        return MiseEnPageBase(
          titre: 'Marché',
          corps: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Carte des prix
              CarteInformation(
                titre: 'Prix du Marché',
                contenu: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prix actuel: ${marche.prixCourant.toStringAsFixed(2)}€',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text('Prix moyen: ${stats.prixMoyen.toStringAsFixed(2)}€'),
                    Text('Prix record: ${stats.prixMaximal.toStringAsFixed(2)}€'),
                  ],
                ),
              ),

              // Carte de vente
              CarteInformation(
                titre: 'Vendre des Trombones',
                contenu: Column(
                  children: [
                    Text('Trombones disponibles: ${production.trombonesProduits}'),
                    Text('Argent disponible: ${marche.argentDisponible.toStringAsFixed(2)}€'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: production.trombonesProduits >= 1
                              ? () => jeuProvider.vendreTrambones(1)
                              : null,
                          child: const Text('Vendre 1'),
                        ),
                        ElevatedButton(
                          onPressed: production.trombonesProduits >= 10
                              ? () => jeuProvider.vendreTrambones(10)
                              : null,
                          child: const Text('Vendre 10'),
                        ),
                        ElevatedButton(
                          onPressed: production.trombonesProduits >= 100
                              ? () => jeuProvider.vendreTrambones(100)
                              : null,
                          child: const Text('Vendre 100'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Carte des statistiques
              CarteInformation(
                titre: 'Statistiques de Vente',
                contenu: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trombones vendus: ${stats.ventesTotales}'),
                    Text('Revenus totaux: ${stats.revenusTotal.toStringAsFixed(2)}€'),
                    Text('ROI moyen: ${marche.calculerROI(
                      marche.argentDisponible,
                      production.productionAutomatique,
                    ).toStringAsFixed(1)} secondes'),
                  ],
                ),
              ),

              // Historique des prix
              CarteInformation(
                titre: 'Historique des Prix',
                contenu: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: marche.historiquePrix.length,
                    itemBuilder: (context, index) {
                      final prix = marche.historiquePrix[index];
                      return ListTile(
                        dense: true,
                        title: Text('Prix: ${prix.toStringAsFixed(2)}€'),
                        trailing: Text('il y a ${index + 1} updates'),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 