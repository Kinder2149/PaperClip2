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
      child: Text(
        isInCrisisMode ? 'Nouveau Mode de Production' : _getTitleForIndex(selectedIndex),
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white 
            : Colors.white,
          fontWeight: FontWeight.bold,
        ),
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
