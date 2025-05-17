// lib/widgets/app_bar/widget_appbar_jeu.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/background_music.dart';

class WidgetAppBarJeu extends StatelessWidget implements PreferredSizeWidget {
  final Widget Function(BuildContext) titleBuilder;
  final VoidCallback onSettingsPressed;
  final List<Widget>? actions;
  final double elevation;
  final bool showLevelIndicator;
  final bool showNotifications;
  final bool showSettings;
  final Color? backgroundColor;
  final Widget? leading;
  final List<Widget>? additionalActions;

  const WidgetAppBarJeu({
    Key? key,
    required this.titleBuilder,
    required this.onSettingsPressed,
    this.actions,
    this.elevation = 4.0,
    this.showLevelIndicator = true,
    this.showNotifications = true,
    this.showSettings = true,
    this.backgroundColor,
    this.leading,
    this.additionalActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backgroundMusicService = Provider.of<BackgroundMusicService>(context, listen: false);
    final finalBackgroundColor = backgroundColor ?? Colors.deepPurple;

    return AppBar(
      backgroundColor: finalBackgroundColor,
      title: titleBuilder(context),
      elevation: elevation,
      leading: leading,
      actions: [
        // Ajouter les actions personnalisées si fournies
        if (additionalActions != null) ...additionalActions!,

        // Actions standard
        if (actions != null) ...actions!,

        // Bouton de musique
        IconButton(
          icon: Icon(
            backgroundMusicService.isPlaying ? Icons.volume_up : Icons.volume_off,
            color: Colors.white,
          ),
          onPressed: () async {
            if (backgroundMusicService.isPlaying) {
              await backgroundMusicService.pause();
            } else {
              await backgroundMusicService.play();
            }
          },
          tooltip: 'Musique',
        ),

        // Bouton des paramètres
        if (showSettings)
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: onSettingsPressed,
            tooltip: 'Paramètres',
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}