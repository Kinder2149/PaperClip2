// lib/widgets/appbar/sections/theme_mode_action.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/theme_service.dart';

class ThemeModeAction extends StatelessWidget {
  const ThemeModeAction({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        final isDarkMode = themeService.themeMode == ThemeMode.dark;
        
        return IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return RotationTransition(
                turns: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              key: ValueKey<bool>(isDarkMode),
              color: Colors.white,
            ),
          ),
          onPressed: () => themeService.toggleTheme(),
          tooltip: isDarkMode ? 'Mode Clair' : 'Mode Sombre',
        );
      },
    );
  }
}
