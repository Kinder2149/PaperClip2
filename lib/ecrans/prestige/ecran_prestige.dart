import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/jeu_provider.dart';
import '../../composants/mise_en_page_base.dart';
import '../../composants/carte_information.dart';

class EcranPrestige extends StatelessWidget {
  const EcranPrestige({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<JeuProvider>(
      builder: (context, jeuProvider, child) {
        final prestige = jeuProvider.prestige;
        final pointsDisponibles = prestige.calculerPointsPrestige(
          jeuProvider.production.trombonesProduits,
          jeuProvider.marche.argentDisponible,
        );

        return MiseEnPageBase(
          titre: 'Prestige',
          corps: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Points de Prestige
              CarteInformation(
                titre: 'Points de Prestige',
                contenu: Column(
                  children: [
                    Text(
                      'Niveau de Prestige: ${prestige.niveau}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Points disponibles: $pointsDisponibles',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: pointsDisponibles > 0
                          ? () => _confirmerPrestige(context, jeuProvider, pointsDisponibles)
                          : null,
                      child: const Text('Effectuer un Prestige'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Multiplicateurs Actifs
              CarteInformation(
                titre: 'Multiplicateurs Actifs',
                contenu: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _construireLigneMultiplicateur(
                      'Production',
                      prestige.multiplicateurProduction,
                    ),
                    _construireLigneMultiplicateur(
                      'Expérience',
                      prestige.multiplicateurExperience,
                    ),
                    _construireLigneMultiplicateur(
                      'Vente',
                      prestige.multiplicateurVente,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Avantages Débloqués
              CarteInformation(
                titre: 'Avantages Débloqués',
                contenu: Column(
                  children: [
                    _construireAvantage(
                      'Auto-Vente',
                      'Vente automatique des trombones',
                      prestige.avantagesDebloques.contains('auto_vente'),
                      1,
                    ),
                    _construireAvantage(
                      'Auto-Amélioration',
                      'Achat automatique des améliorations',
                      prestige.avantagesDebloques.contains('auto_amelioration'),
                      2,
                    ),
                    _construireAvantage(
                      'Bonus Permanents',
                      'Les bonus restent actifs après prestige',
                      prestige.avantagesDebloques.contains('bonus_permanents'),
                      3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Prochain Palier
              CarteInformation(
                titre: 'Prochain Palier',
                contenu: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Production nécessaire: ${_formaterNombre(1000000)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      'Argent nécessaire: ${_formaterNombre(100000)}€',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: pointsDisponibles / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construireLigneMultiplicateur(String titre, double valeur) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titre),
          Text('x${valeur.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _construireAvantage(
    String titre,
    String description,
    bool debloque,
    int niveauRequis,
  ) {
    return ListTile(
      leading: Icon(
        debloque ? Icons.check_circle : Icons.lock,
        color: debloque ? Colors.green : Colors.grey,
      ),
      title: Text(titre),
      subtitle: Text(description),
      trailing: Text('Niveau $niveauRequis'),
    );
  }

  String _formaterNombre(int nombre) {
    if (nombre >= 1000000) {
      return '${(nombre / 1000000).toStringAsFixed(1)}M';
    } else if (nombre >= 1000) {
      return '${(nombre / 1000).toStringAsFixed(1)}K';
    }
    return nombre.toString();
  }

  Future<void> _confirmerPrestige(
    BuildContext context,
    JeuProvider jeu,
    int points,
  ) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le Prestige'),
        content: Text(
          'Voulez-vous effectuer un prestige et obtenir $points points ?\n\n'
          'Cela réinitialisera votre progression mais vous donnera des bonus permanents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      jeu.prestige.effectuerPrestige(points);
      jeu.reinitialiserJeu(conserverPrestige: true);
    }
  }
} 