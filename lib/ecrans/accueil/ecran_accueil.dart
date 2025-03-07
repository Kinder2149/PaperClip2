import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../composants/mise_en_page/mise_en_page_base.dart';
import '../../composants/communs/cartes/carte_information.dart';
import '../../composants/communs/boutons/bouton_principal.dart';
import '../../composants/communs/indicateurs/indicateur_chargement.dart';

import '../../models/game_state.dart';
import '../../services/save_manager.dart';

class EcranAccueil extends StatefulWidget {
  const EcranAccueil({Key? key}) : super(key: key);

  @override
  State<EcranAccueil> createState() => _EcranAccueilState();
}

class _EcranAccueilState extends State<EcranAccueil> {
  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    
    return MiseEnPageBase(
      titre: 'Paperclip 2',
      indexNavigationSelectionne: 0,
      onNavigationIndexChange: (index) {
        // Gérer la navigation ici
      },
      corps: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CarteInformation(
                titre: 'Ressources',
                contenu: Column(
                  children: [
                    // Ajouter les widgets de ressources ici
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CarteInformation(
                titre: 'Production',
                contenu: Column(
                  children: [
                    // Ajouter les widgets de production ici
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CarteInformation(
                titre: 'Statistiques',
                contenu: Column(
                  children: [
                    // Ajouter les widgets de statistiques ici
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      boutonFlottant: BoutonPrincipal(
        texte: 'Sauvegarder',
        icone: Icons.save,
        onPressed: () async {
          // Logique de sauvegarde
          await SaveManager.saveGame(gameState);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Partie sauvegardée')),
            );
          }
        },
      ),
    );
  }
} 