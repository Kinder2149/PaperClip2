import 'package:flutter/material.dart';

class BarreNavigation extends StatelessWidget {
  final int indexSelectionne;
  final Function(int) onIndexChange;
  final List<ElementNavigation> elements;

  const BarreNavigation({
    Key? key,
    required this.indexSelectionne,
    required this.onIndexChange,
    required this.elements,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: indexSelectionne,
      onTap: onIndexChange,
      type: BottomNavigationBarType.fixed,
      items: elements
          .map((element) => BottomNavigationBarItem(
                icon: Icon(element.icone),
                label: element.etiquette,
              ))
          .toList(),
    );
  }
}

class ElementNavigation {
  final String etiquette;
  final IconData icone;
  final String route;

  const ElementNavigation({
    required this.etiquette,
    required this.icone,
    required this.route,
  });

  static List<ElementNavigation> get elementsParDefaut => [
        ElementNavigation(
          etiquette: 'Accueil',
          icone: Icons.home,
          route: '/',
        ),
        ElementNavigation(
          etiquette: 'Production',
          icone: Icons.build,
          route: '/production',
        ),
        ElementNavigation(
          etiquette: 'Marché',
          icone: Icons.shopping_cart,
          route: '/marche',
        ),
        ElementNavigation(
          etiquette: 'Stats',
          icone: Icons.bar_chart,
          route: '/statistiques',
        ),
      ];
} 