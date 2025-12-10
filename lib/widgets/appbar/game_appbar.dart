// lib/widgets/appbar/game_appbar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import '../../services/background_music.dart';
import '../../constants/game_config.dart'; // Importé depuis constants au lieu de models
import 'appbar_title.dart';
import 'appbar_level_indicator.dart';
import 'appbar_actions.dart';

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
    return Consumer<GameState>(
      builder: (context, gameState, _) {
        final theme = Theme.of(context);
        final Color appBarColor = backgroundColor ?? 
          (theme.brightness == Brightness.dark 
            ? theme.colorScheme.surface 
            : const Color(0xFF673AB7));  // Colors.deepPurple[700]
        
        return AppBar(
          title: AppBarTitle(
            isInCrisisMode: gameState.isInCrisisMode,
            selectedIndex: selectedIndex,
          ),
          centerTitle: centerTitle,
          backgroundColor: appBarColor,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AppBarLevelIndicator(levelSystem: gameState.level),
          ),
          leadingWidth: 60,
          actions: AppBarActions(
            gameMode: gameState.gameMode,
            additionalActions: additionalActions,
            onSettingsPressed: onSettingsPressed,
          ).buildActions(context),
        );
      },
    );
  }
}
