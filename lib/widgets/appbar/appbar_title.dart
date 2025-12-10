// lib/widgets/appbar/appbar_title.dart
import 'package:flutter/material.dart';

class AppBarTitle extends StatelessWidget {
  final bool isInCrisisMode;
  final int selectedIndex;
  
  const AppBarTitle({
    Key? key,
    required this.isInCrisisMode,
    required this.selectedIndex,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      // Aucun titre n'est affiché dans l'AppBar
      child: Container(
        key: ValueKey<String>(isInCrisisMode ? 'crisis' : selectedIndex.toString()),
      ),
    );
  }
  
  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Production';
      case 1:
        return 'Marché';
      case 2:
        return 'Améliorations';
      default:
        return 'PaperClip Game';
    }
  }
}
