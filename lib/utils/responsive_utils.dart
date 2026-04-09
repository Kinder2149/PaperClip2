// lib/utils/responsive_utils.dart
import 'package:flutter/material.dart';

/// Breakpoints pour le responsive design
/// 
/// - Mobile : < 600px (smartphones)
/// - Tablet : 600-1023px (tablettes)
/// - Desktop : >= 1024px (desktop, Chrome)
class Breakpoints {
  Breakpoints._();
  
  /// Breakpoint mobile/tablet
  static const double mobile = 600;
  
  /// Breakpoint tablet/desktop
  static const double tablet = 1024;
  
  /// Vérifie si l'écran est mobile (< 600px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }
  
  /// Vérifie si l'écran est tablette (600-1023px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }
  
  /// Vérifie si l'écran est desktop (>= 1024px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tablet;
  }
  
  /// Retourne le type d'écran actuel
  static ScreenType getScreenType(BuildContext context) {
    if (isDesktop(context)) return ScreenType.desktop;
    if (isTablet(context)) return ScreenType.tablet;
    return ScreenType.mobile;
  }
}

/// Type d'écran
enum ScreenType {
  mobile,
  tablet,
  desktop,
}

/// Widget responsive qui affiche différents layouts selon la taille d'écran
/// 
/// Exemple :
/// ```dart
/// ResponsiveLayout(
///   mobile: MobileLayout(),
///   tablet: TabletLayout(),
///   desktop: DesktopLayout(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (Breakpoints.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    
    if (Breakpoints.isTablet(context)) {
      return tablet ?? mobile;
    }
    
    return mobile;
  }
}

/// Builder responsive qui fournit le type d'écran
/// 
/// Exemple :
/// ```dart
/// ResponsiveBuilder(
///   builder: (context, screenType) {
///     if (screenType == ScreenType.desktop) {
///       return DesktopLayout();
///     }
///     return MobileLayout();
///   },
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType screenType) builder;
  
  const ResponsiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final screenType = Breakpoints.getScreenType(context);
    return builder(context, screenType);
  }
}

/// Valeur responsive qui s'adapte selon la taille d'écran
/// 
/// Exemple :
/// ```dart
/// ResponsiveValue<int>(
///   mobile: 1,
///   tablet: 2,
///   desktop: 3,
/// ).getValue(context)
/// ```
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;
  
  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  T getValue(BuildContext context) {
    if (Breakpoints.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    
    if (Breakpoints.isTablet(context)) {
      return tablet ?? mobile;
    }
    
    return mobile;
  }
}

/// Extensions pour faciliter l'utilisation du responsive
extension ResponsiveContext on BuildContext {
  /// Vérifie si l'écran est mobile
  bool get isMobile => Breakpoints.isMobile(this);
  
  /// Vérifie si l'écran est tablette
  bool get isTablet => Breakpoints.isTablet(this);
  
  /// Vérifie si l'écran est desktop
  bool get isDesktop => Breakpoints.isDesktop(this);
  
  /// Retourne le type d'écran
  ScreenType get screenType => Breakpoints.getScreenType(this);
  
  /// Retourne la largeur de l'écran
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Retourne la hauteur de l'écran
  double get screenHeight => MediaQuery.of(this).size.height;
}
