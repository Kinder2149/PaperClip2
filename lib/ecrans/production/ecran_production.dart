import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/jeu_provider.dart';
import '../../composants/mise_en_page_base.dart';
import '../../composants/carte_information.dart';

class EcranProduction extends StatelessWidget {
  const EcranProduction({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<JeuProvider>(
      builder: (context, jeuProvider, child) {
        final production = jeuProvider.production;
        final stats = jeuProvider.statistiques;

        return MiseEnPageBase(
          titre: 'Production',
          corps: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Carte de production manuelle
              CarteInformation(
                titre: 'Production Manuelle',
                contenu: Column(
                  children: [
                    Text(
                      'Combo: ${production.comboActuel}x',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => jeuProvider.produireManuel(),
                      child: const Text('Produire'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Carte de production automatique
              if (jeuProvider.productionAutomatiqueDebloquee)
                CarteInformation(
                  titre: 'Production Automatique',
                  contenu: Column(
                    children: [
                      Text(
                        'Production/s: ${production.productionAutomatique.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => jeuProvider.demarrerProductionAutomatique(),
                            child: const Text('Démarrer'),
                          ),
                          ElevatedButton(
                            onPressed: () => jeuProvider.arreterProductionAutomatique(),
                            child: const Text('Arrêter'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Carte des bonus
              CarteInformation(
                titre: 'Bonus de Production',
                contenu: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vitesse: +${(production.bonusVitesse * 100).toStringAsFixed(0)}%'),
                    Text('Efficacité: +${(production.bonusEfficacite * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              ),

              // Carte des statistiques
              CarteInformation(
                titre: 'Statistiques',
                contenu: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trombones: ${production.trombonesProduits}'),
                    Text('Production actuelle: ${stats.productionCourante.toStringAsFixed(1)}/s'),
                    Text('Record de production: ${stats.productionMaximale.toStringAsFixed(1)}/s'),
                    Text('Production totale: ${stats.productionTotale}'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 