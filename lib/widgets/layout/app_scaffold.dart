import 'package:flutter/material.dart';
import 'package:paperclip2/widgets/appbar/game_appbar.dart';
import 'package:paperclip2/widgets/appbar/settings_bottom_sheet.dart';

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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
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
