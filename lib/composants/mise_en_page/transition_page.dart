import 'package:flutter/material.dart';

enum TypeTransition {
  fade,
  slide,
  scale,
  rotation,
}

class TransitionPage extends PageRouteBuilder {
  final Widget page;
  final TypeTransition type;
  final Duration duree;
  final Curve courbe;

  TransitionPage({
    required this.page,
    this.type = TypeTransition.fade,
    this.duree = const Duration(milliseconds: 300),
    this.courbe = Curves.easeInOut,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duree,
          reverseTransitionDuration: duree,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = _getTween(type);
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: courbe,
            );

            switch (type) {
              case TypeTransition.fade:
                return FadeTransition(
                  opacity: curvedAnimation,
                  child: child,
                );
              case TypeTransition.slide:
                return SlideTransition(
                  position: tween.animate(curvedAnimation),
                  child: child,
                );
              case TypeTransition.scale:
                return ScaleTransition(
                  scale: curvedAnimation,
                  child: child,
                );
              case TypeTransition.rotation:
                return RotationTransition(
                  turns: curvedAnimation,
                  child: child,
                );
            }
          },
        );

  static Tween<Offset> _getTween(TypeTransition type) {
    switch (type) {
      case TypeTransition.slide:
        return Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        );
      default:
        return Tween<Offset>(
          begin: Offset.zero,
          end: Offset.zero,
        );
    }
  }
}

// Extension pour faciliter l'utilisation des transitions
extension NavigatorTransitionExtension on BuildContext {
  Future<T?> navigateWithTransition<T>({
    required Widget page,
    TypeTransition type = TypeTransition.fade,
    Duration duree = const Duration(milliseconds: 300),
    Curve courbe = Curves.easeInOut,
  }) {
    return Navigator.push<T>(
      this,
      TransitionPage(
        page: page,
        type: type,
        duree: duree,
        courbe: courbe,
      ),
    );
  }

  Future<T?> replaceWithTransition<T>({
    required Widget page,
    TypeTransition type = TypeTransition.fade,
    Duration duree = const Duration(milliseconds: 300),
    Curve courbe = Curves.easeInOut,
  }) {
    return Navigator.pushReplacement(
      this,
      TransitionPage(
        page: page,
        type: type,
        duree: duree,
        courbe: courbe,
      ),
    );
  }
} 