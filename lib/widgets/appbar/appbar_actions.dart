// lib/widgets/appbar/appbar_actions.dart
import 'package:flutter/material.dart';
import '../../constants/game_config.dart'; // Importé depuis constants au lieu de models
import 'sections/settings_action.dart';
// Les autres actions (notif/musique/thème/google) sont déplacées dans le menu Paramètres.

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
    // Bouton Paramètres unique (le menu contiendra la connexion et autres)
    actions.add(SettingsAction(onPressed: onSettingsPressed));
    if (additionalActions != null && additionalActions!.isNotEmpty) {
      actions.addAll(additionalActions!);
    }
    return actions;
  }
}
