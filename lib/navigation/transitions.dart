import 'package:flutter/material.dart';

class TransitionPage extends Page {
  final Widget child;
  final String name;

  const TransitionPage({
    required this.child,
    required this.name,
  }) : super(key: ValueKey(name));

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}

class TransitionRouteBuilder {
  static PageRouteBuilder construire({
    required Widget page,
    TransitionType type = TransitionType.glissement,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (type) {
          case TransitionType.glissement:
            return _construireTransitionGlissement(animation, child);
          case TransitionType.fondu:
            return _construireTransitionFondu(animation, child);
          case TransitionType.echelle:
            return _construireTransitionEchelle(animation, child);
          case TransitionType.rotation:
            return _construireTransitionRotation(animation, child);
        }
      },
    );
  }

  static Widget _construireTransitionGlissement(Animation<double> animation, Widget child) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeInOut;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  static Widget _construireTransitionFondu(Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  static Widget _construireTransitionEchelle(Animation<double> animation, Widget child) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.fastOutSlowIn,
      )),
      child: child,
    );
  }

  static Widget _construireTransitionRotation(Animation<double> animation, Widget child) {
    return RotationTransition(
      turns: Tween<double>(
        begin: 0.5,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.fastOutSlowIn,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

enum TransitionType {
  glissement,
  fondu,
  echelle,
  rotation,
} 