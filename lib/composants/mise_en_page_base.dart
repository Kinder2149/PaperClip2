import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titre),
        backgroundColor: Theme.of(context).primaryColor,
        actions: actions,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: corps,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getIndexFromRoute(ModalRoute.of(context)?.settings.name ?? ''),
        onTap: (index) => _navigateToPage(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Production',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Marché',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upgrade),
            label: 'Améliorations',
          ),
          BottomNavigationBarItem(
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
} 