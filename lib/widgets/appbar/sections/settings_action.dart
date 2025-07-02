// lib/widgets/appbar/sections/settings_action.dart
import 'package:flutter/material.dart';

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
      onPressed: onPressed ?? () {
        // Fallback si onPressed n'est pas fourni
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres non configurés'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      tooltip: 'Paramètres',
    );
  }
}
