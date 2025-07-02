// lib/widgets/appbar/appbar_actions.dart
import 'package:flutter/material.dart';
import '../../models/game_config.dart';
import '../indicators/competitive_mode_indicator.dart';
import 'sections/notification_action.dart';
import 'sections/music_control_action.dart';
import 'sections/theme_mode_action.dart';
import 'sections/settings_action.dart';

class AppBarActions {
  final GameMode gameMode;
  final List<Widget>? additionalActions;
  final VoidCallback? onSettingsPressed;
  
  const AppBarActions({
    required this.gameMode,
    this.additionalActions,
    this.onSettingsPressed,
  });
  
  List<Widget> buildActions(BuildContext context) {
    final List<Widget> actions = [];
    
    // Ajouter l'indicateur de mode compétitif si nécessaire
    if (gameMode == GameMode.COMPETITIVE) {
      actions.add(
        const Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: CompetitiveModeIndicator(),
        ),
      );
    }
    
    // Ajouter le bouton de notification
    actions.add(const NotificationAction());
    
    // Ajouter le contrôle de musique
    actions.add(const MusicControlAction());

    // Ajouter le bouton de basculement de thème
    actions.add(const ThemeModeAction());
    
    // Ajouter le bouton de paramètres
    actions.add(SettingsAction(
      onPressed: onSettingsPressed,
    ));
    
    // Ajouter des actions supplémentaires si fournies
    if (additionalActions != null && additionalActions!.isNotEmpty) {
      actions.addAll(additionalActions!);
    }
    
    return actions;
  }
}
