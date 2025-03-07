import 'package:flutter/material.dart';

class ConfirmationDialog {
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    Color? confirmColor,
    IconData? icon,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: confirmColor != null
                ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    ) ?? false;
  }

  static Future<bool> showDangerousAction({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    return await show(
      context: context,
      title: title,
      message: message,
      confirmText: 'Je comprends',
      confirmColor: Colors.red,
      icon: Icons.warning,
    );
  }

  static Future<bool> showResetConfirmation({
    required BuildContext context,
  }) async {
    return await showDangerousAction(
      context: context,
      title: 'Réinitialiser la partie ?',
      message: 'Cette action est irréversible. Tout votre progrès sera perdu.',
    );
  }

  static Future<bool> showDeleteSaveConfirmation({
    required BuildContext context,
    required String saveName,
  }) async {
    return await showDangerousAction(
      context: context,
      title: 'Supprimer la sauvegarde ?',
      message: 'Voulez-vous vraiment supprimer la sauvegarde "$saveName" ?\nCette action est irréversible.',
    );
  }

  static Future<bool> showExitConfirmation({
    required BuildContext context,
  }) async {
    return await show(
      context: context,
      title: 'Quitter le jeu ?',
      message: 'Votre progression sera automatiquement sauvegardée.',
      confirmText: 'Quitter',
      icon: Icons.exit_to_app,
    );
  }

  static Future<bool> showCompetitiveModeConfirmation({
    required BuildContext context,
  }) async {
    return await show(
      context: context,
      title: 'Mode Compétitif',
      message: 'Vous êtes sur le point de commencer une partie en mode compétitif.\n\n'
          'Dans ce mode :\n'
          '• Vous avez un temps limité\n'
          '• Les ressources sont limitées\n'
          '• Votre score sera enregistré\n'
          '• Pas de sauvegarde possible\n\n'
          'Êtes-vous prêt ?',
      confirmText: 'Commencer',
      icon: Icons.emoji_events,
    );
  }

  static Future<bool> showMaintenanceConfirmation({
    required BuildContext context,
    required double cost,
  }) async {
    return await show(
      context: context,
      title: 'Maintenance',
      message: 'Voulez-vous effectuer la maintenance ?\n'
          'Coût : ${cost.toStringAsFixed(2)} €\n\n'
          'La maintenance améliore l\'efficacité de votre production.',
      confirmText: 'Effectuer',
      icon: Icons.build,
    );
  }

  static Future<bool> showUpgradeConfirmation({
    required BuildContext context,
    required String upgradeName,
    required double cost,
    required String description,
  }) async {
    return await show(
      context: context,
      title: 'Acheter l\'amélioration',
      message: 'Voulez-vous acheter l\'amélioration "$upgradeName" ?\n'
          'Coût : ${cost.toStringAsFixed(2)} €\n\n'
          'Effet : $description',
      confirmText: 'Acheter',
      icon: Icons.upgrade,
    );
  }
} 