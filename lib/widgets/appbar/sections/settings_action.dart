// lib/widgets/appbar/sections/settings_action.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:games_services/games_services.dart';
import 'package:paperclip2/services/google/google_bootstrap.dart';
import 'package:paperclip2/services/google/identity/google_identity_service.dart';
import 'package:paperclip2/services/google/identity/identity_status.dart';

class SettingsAction extends StatelessWidget {
  final VoidCallback? onPressed;
  
  const SettingsAction({
    Key? key, 
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.settings,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.white,
      ),
      onPressed: onPressed,
      tooltip: 'Paramètres',
    );
  }
}
