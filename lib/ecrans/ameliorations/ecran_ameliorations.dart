import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/jeu_provider.dart';
import '../../composants/mise_en_page_base.dart';
import '../../composants/carte_information.dart';
import '../../composants/bouton_amelioration.dart';

class EcranAmeliorations extends StatelessWidget {
  const EcranAmeliorations({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<JeuProvider>(
      builder: (context, jeuProvider, child) {
        final production = jeuProvider.production;
        final marche = jeuProvider.marche;
        final ameliorations = jeuProvider.ameliorations;

        return MiseEnPageBase(
          titre: 'Améliorations',
          corps: ListView(
            children: [
              CarteInformation(
                titre: 'Ressources Disponibles',
                contenu: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Argent: ${marche.argentDisponible.toStringAsFixed(2)}€',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Production Automatique: ${production.productionAutomatique.toStringAsFixed(1)}/s',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              BoutonAmelioration(
                titre: 'Production Automatique',
                description: 'Augmente la production automatique de trombones',
                niveau: ameliorations.niveauProductionAuto,
                cout: ameliorations.coutProductionAuto,
                argentDisponible: marche.argentDisponible,
                estDisponible: true,
                onPressed: () => jeuProvider.acheterAmelioration('prod_auto'),
              ),
              
              const SizedBox(height: 8),
              
              BoutonAmelioration(
                titre: 'Vitesse de Production',
                description: 'Augmente la vitesse de production de tous les trombones',
                niveau: ameliorations.niveauVitesse,
                cout: ameliorations.coutVitesse,
                argentDisponible: marche.argentDisponible,
                estDisponible: true,
                onPressed: () => jeuProvider.acheterAmelioration('vitesse'),
              ),
              
              const SizedBox(height: 8),
              
              BoutonAmelioration(
                titre: 'Efficacité de Production',
                description: 'Réduit les coûts de production',
                niveau: ameliorations.niveauEfficacite,
                cout: ameliorations.coutEfficacite,
                argentDisponible: marche.argentDisponible,
                estDisponible: true,
                onPressed: () => jeuProvider.acheterAmelioration('efficacite'),
              ),
              
              const SizedBox(height: 16),
              
              CarteInformation(
                titre: 'Prochaines Améliorations',
                contenu: Text(
                  'Débloquez plus d\'améliorations en progressant dans le jeu !',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 