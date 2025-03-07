import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jeu_provider.dart';

class MiseEnPageBase extends StatelessWidget {
  final String titre;
  final Widget corps;
  final List<Widget>? actions;

  const MiseEnPageBase({
    Key? key,
    required this.titre,
    required this.corps,
    this.actions,
  }) : super(key: key);

  void _afficherInfoNiveau(BuildContext context, JeuProvider jeu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Niveau ${jeu.niveau}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('XP: ${jeu.experience.toStringAsFixed(1)}/${jeu.experiencePourProchainNiveau.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: jeu.progressionNiveau,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 10,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jeu = Provider.of<JeuProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(titre),
        actions: actions,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barre de niveau
          InkWell(
            onTap: () => _afficherInfoNiveau(context, jeu),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              color: Colors.blue.shade700,
              child: Column(
                children: [
                  Text(
                    'Niveau ${jeu.niveau}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: jeu.progressionNiveau,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Barre d'informations
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  'Trombones',
                  jeu.production.trombonesProduits.toString(),
                  Icons.inventory_2,
                ),
                _buildInfoItem(
                  'Argent',
                  '${jeu.marche.argentDisponible.toStringAsFixed(2)} €',
                  Icons.euro,
                ),
                _buildInfoItem(
                  'Production/s',
                  jeu.production.productionAutomatique.toString(),
                  Icons.speed,
                ),
              ],
            ),
          ),
          // Corps principal
          Expanded(
            child: corps,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getIndexFromRoute(ModalRoute.of(context)?.settings.name ?? ''),
        onDestinationSelected: (index) => _navigateToPage(context, index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.build),
            label: 'Production',
          ),
          NavigationDestination(
            icon: Icon(jeu.marcheDebloque ? Icons.shopping_cart : Icons.lock),
            label: jeu.marcheDebloque ? 'Marché' : 'Niveau 3',
          ),
          NavigationDestination(
            icon: Icon(jeu.ameliorationsDebloquees ? Icons.upgrade : Icons.lock),
            label: jeu.ameliorationsDebloquees ? 'Améliorations' : 'Niveau 4',
          ),
          const NavigationDestination(
            icon: Icon(Icons.analytics),
            label: 'Statistiques',
          ),
        ],
      ),
    );
  }

  int _getIndexFromRoute(String route) {
    switch (route) {
      case '/production':
        return 0;
      case '/marche':
        return 1;
      case '/ameliorations':
        return 2;
      case '/statistiques':
        return 3;
      default:
        return 0;
    }
  }

  void _navigateToPage(BuildContext context, int index) {
    String route;
    switch (index) {
      case 0:
        route = '/production';
        break;
      case 1:
        route = '/marche';
        break;
      case 2:
        route = '/ameliorations';
        break;
      case 3:
        route = '/statistiques';
        break;
      default:
        route = '/production';
    }
    Navigator.pushReplacementNamed(context, route);
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 