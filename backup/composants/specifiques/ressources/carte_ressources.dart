import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_state.dart';
import '../../communs/cartes/carte_information.dart';

class CarteRessources extends StatelessWidget {
  const CarteRessources({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final theme = Theme.of(context);

    return CarteInformation(
      titre: 'Ressources',
      icone: const Icon(Icons.inventory_2),
      contenu: Column(
        children: [
          _LigneRessource(
            icone: Icons.attach_file,
            nom: 'Trombones',
            valeur: gameState.paperclips.toString(),
            couleur: theme.primaryColor,
          ),
          const SizedBox(height: 8),
          _LigneRessource(
            icone: Icons.money,
            nom: 'Argent',
            valeur: '\$${gameState.funds.toStringAsFixed(2)}',
            couleur: Colors.green,
          ),
          if (gameState.hasWire) ...[
            const SizedBox(height: 8),
            _LigneRessource(
              icone: Icons.cable,
              nom: 'Fil',
              valeur: gameState.wire.toString(),
              couleur: Colors.orange,
            ),
          ],
          // Ajouter d'autres ressources selon le besoin
        ],
      ),
    );
  }
}

class _LigneRessource extends StatelessWidget {
  final IconData icone;
  final String nom;
  final String valeur;
  final Color couleur;

  const _LigneRessource({
    Key? key,
    required this.icone,
    required this.nom,
    required this.valeur,
    required this.couleur,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icone,
          color: couleur,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          nom,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          valeur,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: couleur,
              ),
        ),
      ],
    );
  }
} 