// lib/widgets/appbar/game_appbar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import '../../services/background_music.dart';
import '../../constants/game_config.dart'; // Importé depuis constants au lieu de models
import 'appbar_title.dart';
import 'appbar_level_indicator.dart';
import 'appbar_actions.dart';

class _GameAppBarView {
  final bool isInCrisisMode;
  final dynamic levelSystem;
  final dynamic gameMode;

  const _GameAppBarView({
    required this.isInCrisisMode,
    required this.levelSystem,
    required this.gameMode,
  });

  @override
  bool operator ==(Object other) {
    return other is _GameAppBarView &&
        other.isInCrisisMode == isInCrisisMode &&
        other.levelSystem == levelSystem &&
        other.gameMode == gameMode;
  }

  @override
  int get hashCode => Object.hash(isInCrisisMode, levelSystem, gameMode);
}

class GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final List<Widget>? additionalActions;
  final Color? backgroundColor;
  final bool centerTitle;
  final VoidCallback? onSettingsPressed;
  
  const GameAppBar({
    Key? key,
    required this.selectedIndex,
    this.additionalActions,
    this.backgroundColor,
    this.centerTitle = true,
    this.onSettingsPressed,
  }) : super(key: key);
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, _GameAppBarView>(
      selector: (context, gameState) => _GameAppBarView(
        isInCrisisMode: gameState.isInCrisisMode,
        levelSystem: gameState.level,
        gameMode: gameState.gameMode,
      ),
      builder: (context, view, _) {
        final theme = Theme.of(context);
        final Color appBarColor = backgroundColor ??
            (theme.brightness == Brightness.dark
                ? theme.colorScheme.surface
                : const Color(0xFF673AB7)); // Colors.deepPurple[700]

        return AppBar(
          title: AppBarTitle(
            isInCrisisMode: view.isInCrisisMode,
            selectedIndex: selectedIndex,
          ),
          centerTitle: centerTitle,
          backgroundColor: appBarColor,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AppBarLevelIndicator(levelSystem: view.levelSystem),
          ),
          leadingWidth: 60,
          actions: AppBarActions(
            gameMode: view.gameMode,
            additionalActions: additionalActions,
            onSettingsPressed: onSettingsPressed,
          ).buildActions(context),
        );
      },
    );
  }
}
