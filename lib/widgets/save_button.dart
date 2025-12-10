// lib/widgets/save_button.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../services/notification_manager.dart';

/// Widget réutilisable pour un bouton de sauvegarde standard
/// 
/// Ce widget fournit un bouton standardisé pour sauvegarder la partie
/// avec une gestion des états, des animations et des notifications.
class SaveButton extends StatefulWidget {
  /// Style du bouton
  final ButtonStyle? buttonStyle;
  
  /// Icon à afficher (par défaut, une icône de sauvegarde)
  final IconData icon;
  
  /// Texte à afficher sur le bouton (facultatif)
  final String? label;
  
  /// Callback appelé après une sauvegarde réussie
  final Function? onSaveComplete;
  
  /// Indique si le bouton doit être affiché comme un FloatingActionButton
  final bool isFloatingActionButton;
  
  /// Indique si le bouton doit être affiché comme un IconButton simple
  final bool isIconOnly;
  
  /// Indique si le bouton doit afficher un label sous l'icône
  final bool showLabelBelow;

  /// Crée un nouveau bouton de sauvegarde
  const SaveButton({
    Key? key,
    this.buttonStyle,
    this.icon = Icons.save,
    this.label,
    this.onSaveComplete,
    this.isFloatingActionButton = false,
    this.isIconOnly = false,
    this.showLabelBelow = false,
  }) : super(key: key);

  /// Méthode utilitaire statique pour sauvegarder une partie depuis n'importe où
  /// sans avoir à instancier le widget
  static Future<void> saveGame(BuildContext context) async {
    final gameState = Provider.of<GameState>(context, listen: false);
    if (!gameState.isInitialized || gameState.gameName == null) {
      NotificationManager.instance.showNotification(
        message: 'Erreur: Jeu non initialisé ou sans nom',
        level: NotificationLevel.ERROR,
      );
      return;
    }

    try {
      await gameState.saveGame(gameState.gameName!);
      if (context.mounted) {
        NotificationManager.instance.showNotification(
          message: 'Partie sauvegardée avec succès!',
          level: NotificationLevel.SUCCESS,
        );
      }
    } catch (e) {
      if (context.mounted) {
        NotificationManager.instance.showNotification(
          message: 'Erreur lors de la sauvegarde: $e',
          level: NotificationLevel.ERROR,
          duration: const Duration(seconds: 5),
        );
      }
      if (kDebugMode) {
        print('Erreur de sauvegarde: $e');
      }
    }
  }

  /// Méthode utilitaire statique pour sauvegarder une partie avec un nom spécifique
  /// sans avoir à instancier le widget
  /// Retourne true en cas de succès, false en cas d'échec
  static Future<bool> saveGameWithName(BuildContext context, String saveName) async {
    if (saveName.isEmpty) {
      NotificationManager.instance.showNotification(
        message: 'Erreur: Nom de sauvegarde vide',
        level: NotificationLevel.ERROR,
      );
      return false;
    }

    final gameState = Provider.of<GameState>(context, listen: false);
    if (!gameState.isInitialized) {
      NotificationManager.instance.showNotification(
        message: 'Erreur: Jeu non initialisé',
        level: NotificationLevel.ERROR,
      );
      return false;
    }

    try {
      await gameState.saveGame(saveName);
      if (context.mounted) {
        NotificationManager.instance.showNotification(
          message: 'Partie sauvegardée avec succès!',
          level: NotificationLevel.SUCCESS,
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        NotificationManager.instance.showNotification(
          message: 'Erreur lors de la sauvegarde: $e',
          level: NotificationLevel.ERROR,
          duration: const Duration(seconds: 5),
        );
      }
      if (kDebugMode) {
        print('Erreur de sauvegarde: $e');
      }
      return false;
    }
  }

  @override
  State<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton> {
  bool _isSaving = false;

  /// Déclenche la sauvegarde du jeu
  Future<void> _saveGame(BuildContext context) async {
    if (_isSaving) return; // Éviter les sauvegardes multiples
    
    final gameState = context.read<GameState>();
    final String gameName = gameState.gameName ?? 'DefaultGame';
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      if (kDebugMode) {
        print('Sauvegarde en cours: $gameName');
      }
      
      await gameState.saveGame(gameName);
      
      if (context.mounted) {
        NotificationManager.instance.showNotification(
          message: 'Partie sauvegardée avec succès!',
          level: NotificationLevel.SUCCESS,
        );
      }
      
      if (widget.onSaveComplete != null) {
        widget.onSaveComplete!();
      }
    } catch (e) {
      if (context.mounted) {
        NotificationManager.instance.showNotification(
          message: 'Erreur lors de la sauvegarde: $e',
          level: NotificationLevel.ERROR,
          duration: const Duration(seconds: 5),
        );
      }
      if (kDebugMode) {
        print('Erreur de sauvegarde: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialiser le contexte pour NotificationManager si ce n'est pas déjà fait
    NotificationManager.instance.setContext(context);
    
    // Si le gameState n'est pas disponible ou initialisé, ne pas afficher le bouton
    final gameState = context.watch<GameState>();
    if (!gameState.isInitialized || gameState.gameName == null) {
      return const SizedBox.shrink();
    }

    // Choix du type de bouton selon les propriétés
    if (widget.isFloatingActionButton) {
      return FloatingActionButton(
        onPressed: _isSaving ? null : () => _saveGame(context),
        tooltip: 'Sauvegarder',
        backgroundColor: _isSaving ? Colors.grey : Theme.of(context).primaryColor,
        child: _isSaving 
          ? const CircularProgressIndicator(color: Colors.white)
          : Icon(widget.icon),
      );
    } else if (widget.isIconOnly) {
      return IconButton(
        onPressed: _isSaving ? null : () => _saveGame(context),
        icon: _isSaving 
          ? const SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(widget.icon),
        tooltip: 'Sauvegarder',
      );
    } else if (widget.showLabelBelow) {
      return InkWell(
        onTap: _isSaving ? null : () => _saveGame(context),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isSaving 
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(widget.icon),
              const SizedBox(height: 4),
              Text(widget.label ?? 'Sauvegarder'),
            ],
          ),
        ),
      );
    } else {
      // Bouton standard ElevatedButton
      return ElevatedButton.icon(
        onPressed: _isSaving ? null : () => _saveGame(context),
        style: widget.buttonStyle,
        icon: _isSaving 
          ? const SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(widget.icon),
        label: Text(widget.label ?? 'Sauvegarder'),
      );
    }
  }
}
