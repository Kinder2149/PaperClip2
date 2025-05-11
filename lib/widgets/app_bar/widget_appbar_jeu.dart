// lib/widgets/app_bar/widget_appbar_jeu.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game_config.dart';
import '../../models/event_system.dart';
import '../../models/game_state.dart';
import '../../models/progression_system.dart';
import '../../screens/event_log_screen.dart';
import '../../services/background_music.dart';
import '../competitive_mode_indicator.dart';
import '../../screens/settings_screen.dart';

/// Widget d'AppBar personnalisé pour le jeu ClipFactory Empire.
///
/// Ce widget fournit une AppBar cohérente et configurable pour tous les
/// écrans du jeu, avec différentes options selon le contexte.
class WidgetAppBarJeu extends StatelessWidget implements PreferredSizeWidget {
  /// Titre affiché dans l'AppBar
  final String? title;

  /// Titre dynamique basé sur une fonction (prioritaire sur title si fourni)
  final String Function(BuildContext)? titleBuilder;

  /// Afficher l'indicateur de niveau (leading)
  final bool showLevelIndicator;

  /// Afficher le bouton de notifications
  final bool showNotifications;

  /// Afficher le bouton de musique
  final bool showMusicToggle;

  /// Afficher le bouton de paramètres
  final bool showSettings;

  /// Actions supplémentaires à afficher à droite
  final List<Widget>? additionalActions;

  /// Fonction appelée quand le bouton de paramètres est pressé
  final VoidCallback? onSettingsPressed;

  /// Couleur de fond de l'AppBar
  final Color? backgroundColor;

  /// Hauteur de l'élévation de l'AppBar
  final double elevation;

  /// Widget personnalisé à afficher à la place du leading par défaut
  final Widget? leadingWidget;

  const WidgetAppBarJeu({
    Key? key,
    this.title,
    this.titleBuilder,
    this.showLevelIndicator = true,
    this.showNotifications = true,
    this.showMusicToggle = true,
    this.showSettings = true,
    this.additionalActions,
    this.onSettingsPressed,
    this.backgroundColor,
    this.elevation = 4.0,
    this.leadingWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtenir l'état du jeu via Provider
    final gameState = Provider.of<GameState>(context, listen: false);
    final backgroundMusicService = Provider.of<BackgroundMusicService>(context);

    // Vérifier si le système de niveau est disponible
    // (important pour les écrans qui n'ont pas accès à GameState)
    final bool hasLevelSystem = Provider.of<GameState?>(context, listen: false) != null;
    final levelSystem = hasLevelSystem ? gameState.levelSystem : null;

    return AppBar(
      title: titleBuilder != null
          ? Text(
        titleBuilder!(context),
        style: const TextStyle(color: Colors.white),
      )
          : Text(
        title ?? 'ClipFactory Empire',
        style: const TextStyle(color: Colors.white),
      ),
      centerTitle: true,
      backgroundColor: backgroundColor ?? Colors.deepPurple[700],
      elevation: elevation,
      // Indicateur de niveau ou leading personnalisé
      leading: leadingWidget ?? (showLevelIndicator && hasLevelSystem && levelSystem != null
          ? Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildLevelIndicator(context, levelSystem),
      )
          : null),
      actions: _buildActions(context, gameState, backgroundMusicService),
    );
  }

  /// Construit l'indicateur de niveau
  Widget _buildLevelIndicator(BuildContext context, LevelSystem levelSystem) {
    return GestureDetector(
      onTap: () => _showLevelInfoDialog(context, levelSystem),
      child: Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: levelSystem.experienceProgress,
                backgroundColor: Colors.grey[700],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                strokeWidth: 3,
              ),
            ),
            Text(
              '${levelSystem.level}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit le bouton de notifications avec compteur
  Widget _buildNotificationButton(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: EventManager.instance.unreadCount,
      builder: (context, unreadCount, child) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventLogScreen()),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Construit la liste des actions de l'AppBar
  List<Widget> _buildActions(
      BuildContext context,
      GameState? gameState,
      BackgroundMusicService backgroundMusicService
      ) {
    final List<Widget> actions = [];

    // Indicateur de mode compétitif (si GameState est disponible)
    if (gameState != null && gameState.gameMode == GameMode.COMPETITIVE) {
      actions.add(
        const Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: CompetitiveModeIndicator(),
        ),
      );
    }

    // Bouton de notifications
    if (showNotifications) {
      actions.add(_buildNotificationButton(context));
    }

    // Bouton de musique
    if (showMusicToggle) {
      actions.add(
        IconButton(
          icon: Icon(
            backgroundMusicService.isPlaying ? Icons.volume_up : Icons.volume_off,
            color: Colors.white,
          ),
          onPressed: () => _toggleMusic(backgroundMusicService),
          tooltip: 'Activer/Désactiver la musique',
        ),
      );
    }

    // Actions additionnelles
    if (additionalActions != null) {
      actions.addAll(additionalActions!);
    }

    // Bouton de paramètres
    if (showSettings) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: onSettingsPressed ?? () => _showDefaultSettingsMenu(context),
          tooltip: 'Paramètres',
        ),
      );
    }

    return actions;
  }

  /// Affiche la boîte de dialogue d'information de niveau
  void _showLevelInfoDialog(BuildContext context, LevelSystem levelSystem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Niveau ${levelSystem.level}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('XP: ${levelSystem.experience}/${levelSystem.experienceForNextLevel}'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: levelSystem.experienceProgress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 16),
            Text('Multiplicateur: x${levelSystem.productionMultiplier.toStringAsFixed(1)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Bascule la lecture/pause de la musique
  void _toggleMusic(BackgroundMusicService musicService) async {
    if (musicService.isPlaying) {
      await musicService.pause();
    } else {
      await musicService.play();
    }
  }

  /// Affiche un menu de paramètres par défaut simplifié
  void _showDefaultSettingsMenu(BuildContext context) {
    // Remplacer l'affichage du dialog par une navigation vers SettingsScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}