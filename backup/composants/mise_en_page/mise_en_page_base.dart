import 'package:flutter/material.dart';
import 'barre_navigation.dart';

class MiseEnPageBase extends StatelessWidget {
  final Widget corps;
  final String? titre;
  final List<Widget>? actions;
  final Widget? boutonFlottant;
  final bool afficherBarreNavigation;
  final int? indexNavigationSelectionne;
  final Function(int)? onNavigationIndexChange;
  final List<ElementNavigation>? elementsNavigation;

  const MiseEnPageBase({
    Key? key,
    required this.corps,
    this.titre,
    this.actions,
    this.boutonFlottant,
    this.afficherBarreNavigation = true,
    this.indexNavigationSelectionne,
    this.onNavigationIndexChange,
    this.elementsNavigation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: titre != null
          ? AppBar(
              title: Text(titre!),
              actions: actions,
            )
          : null,
      body: SafeArea(
        child: corps,
      ),
      floatingActionButton: boutonFlottant,
      bottomNavigationBar: afficherBarreNavigation &&
              indexNavigationSelectionne != null &&
              onNavigationIndexChange != null
          ? BarreNavigation(
              indexSelectionne: indexNavigationSelectionne!,
              onIndexChange: onNavigationIndexChange!,
              elements: elementsNavigation ?? ElementNavigation.elementsParDefaut,
            )
          : null,
    );
  }
} 