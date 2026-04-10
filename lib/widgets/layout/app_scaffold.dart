import 'package:flutter/material.dart';
import 'package:paperclip2/widgets/appbar/game_appbar.dart';
import 'package:paperclip2/widgets/appbar/settings_bottom_sheet.dart';
import 'package:paperclip2/utils/responsive_utils.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final List<Widget>? appBarActions;
  final Color? appBarBackgroundColor;
  final bool centerTitle;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final int appBarSelectedIndex;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBarActions,
    this.appBarBackgroundColor,
    this.centerTitle = true,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.appBarSelectedIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    // RESPONSIVE-APPBAR: toolbarHeight dynamique selon breakpoint
    // Mobile: 100px (2 lignes) | Tablette/Desktop: 56px (1 ligne Material standard)
    final toolbarHeight = const ResponsiveValue<double>(
      mobile: 100.0,
      tablet: 56.0,
      desktop: 56.0,
    ).getValue(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(toolbarHeight),
        child: GameAppBar(
          selectedIndex: appBarSelectedIndex,
          additionalActions: appBarActions,
          backgroundColor: appBarBackgroundColor,
          centerTitle: centerTitle,
          onSettingsPressed: () => showSettingsBottomSheet(context),
        ),
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
