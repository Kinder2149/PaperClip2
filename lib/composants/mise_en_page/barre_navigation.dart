import 'package:flutter/material.dart';

class ElementNavigation {
  final String label;
  final IconData icone;
  final String route;

  const ElementNavigation({
    required this.label,
    required this.icone,
    required this.route,
  });

  static const List<ElementNavigation> elementsParDefaut = [
    ElementNavigation(
      label: 'Production',
      icone: Icons.build,
      route: '/production',
    ),
    ElementNavigation(
      label: 'Marché',
      icone: Icons.shopping_cart,
      route: '/marche',
    ),
    ElementNavigation(
      label: 'Améliorations',
      icone: Icons.trending_up,
      route: '/ameliorations',
    ),
    ElementNavigation(
      label: 'Statistiques',
      icone: Icons.bar_chart,
      route: '/statistiques',
    ),
  ];
}

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
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: elements.asMap().entries.map((entry) {
              final index = entry.key;
              final element = entry.value;
              final isSelected = index == indexSelectionne;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onIndexChange(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryColor.withOpacity(0.1)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              element.icone,
                              color: isSelected
                                  ? theme.primaryColor
                                  : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            element.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? theme.primaryColor
                                  : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
} 