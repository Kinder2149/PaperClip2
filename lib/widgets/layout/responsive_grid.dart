// lib/widgets/layout/responsive_grid.dart
import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';

/// Grille responsive qui adapte le nombre de colonnes selon la taille d'écran
/// 
/// Mobile : 1-2 colonnes
/// Tablet : 2-3 colonnes
/// Desktop : 3-4 colonnes
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  
  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.mainAxisSpacing = 12.0,
    this.crossAxisSpacing = 12.0,
    this.childAspectRatio = 1.0,
    this.padding,
  }) : super(key: key);
  
  int _getCrossAxisCount(BuildContext context) {
    if (Breakpoints.isDesktop(context)) {
      return desktopColumns ?? 3;
    }
    
    if (Breakpoints.isTablet(context)) {
      return tabletColumns ?? 2;
    }
    
    return mobileColumns ?? 1;
  }
  
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: _getCrossAxisCount(context),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
      padding: padding,
      children: children,
    );
  }
}

/// Grille responsive avec builder
class ResponsiveGridBuilder extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  
  const ResponsiveGridBuilder({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.mainAxisSpacing = 12.0,
    this.crossAxisSpacing = 12.0,
    this.childAspectRatio = 1.0,
    this.padding,
  }) : super(key: key);
  
  int _getCrossAxisCount(BuildContext context) {
    if (Breakpoints.isDesktop(context)) {
      return desktopColumns ?? 3;
    }
    
    if (Breakpoints.isTablet(context)) {
      return tabletColumns ?? 2;
    }
    
    return mobileColumns ?? 1;
  }
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Row responsive qui wrap sur mobile
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool forceWrap;
  
  const ResponsiveRow({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 8.0,
    this.forceWrap = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final shouldWrap = forceWrap || Breakpoints.isMobile(context);
    
    if (shouldWrap) {
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        alignment: _getWrapAlignment(mainAxisAlignment),
        crossAxisAlignment: _getWrapCrossAlignment(crossAxisAlignment),
        children: children,
      );
    }
    
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: _addSpacing(children, spacing),
    );
  }
  
  List<Widget> _addSpacing(List<Widget> children, double spacing) {
    if (children.isEmpty) return children;
    
    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(SizedBox(width: spacing));
      }
    }
    return result;
  }
  
  WrapAlignment _getWrapAlignment(MainAxisAlignment alignment) {
    switch (alignment) {
      case MainAxisAlignment.start:
        return WrapAlignment.start;
      case MainAxisAlignment.end:
        return WrapAlignment.end;
      case MainAxisAlignment.center:
        return WrapAlignment.center;
      case MainAxisAlignment.spaceBetween:
        return WrapAlignment.spaceBetween;
      case MainAxisAlignment.spaceAround:
        return WrapAlignment.spaceAround;
      case MainAxisAlignment.spaceEvenly:
        return WrapAlignment.spaceEvenly;
    }
  }
  
  WrapCrossAlignment _getWrapCrossAlignment(CrossAxisAlignment alignment) {
    switch (alignment) {
      case CrossAxisAlignment.start:
        return WrapCrossAlignment.start;
      case CrossAxisAlignment.end:
        return WrapCrossAlignment.end;
      case CrossAxisAlignment.center:
        return WrapCrossAlignment.center;
      default:
        return WrapCrossAlignment.start;
    }
  }
}

/// Card responsive avec padding adaptatif
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;
  
  const ResponsiveCard({
    Key? key,
    required this.child,
    this.padding,
    this.color,
    this.elevation,
    this.shape,
  }) : super(key: key);
  
  EdgeInsetsGeometry _getPadding(BuildContext context) {
    if (padding != null) return padding!;
    
    if (Breakpoints.isDesktop(context)) {
      return const EdgeInsets.all(20.0);
    }
    
    if (Breakpoints.isTablet(context)) {
      return const EdgeInsets.all(16.0);
    }
    
    return const EdgeInsets.all(12.0);
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: elevation,
      shape: shape,
      child: Padding(
        padding: _getPadding(context),
        child: child,
      ),
    );
  }
}
