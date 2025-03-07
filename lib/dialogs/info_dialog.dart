import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../models/progression_system.dart';

class InfoDialog {
  static void showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(message),
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

  static void showAutoclipperInfoDialog(
    BuildContext context,
    GameState gameState,
    double bulkBonus,
    double speedBonus,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails des Autoclippers'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Production de base: ${gameState.player.autoclippers} trombone/s'),
              Text('Bonus de production: +${bulkBonus.toStringAsFixed(0)}%'),
              Text('Bonus de vitesse: +${speedBonus.toStringAsFixed(0)}%'),
              const Divider(),
              Text(
                'Production totale: ${gameState.player.autoclippers} trombones/s\n'
                'Consommation métal: ${(GameConstants.METAL_PER_PAPERCLIP * gameState.player.autoclippers).toStringAsFixed(2)}/s'
              ),
              const Divider(),
              Text('Coûts de maintenance: ${gameState.maintenanceCosts.toStringAsFixed(1)} € par min'),
            ],
          ),
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

  static void showMarketInfoDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations du Marché'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Réputation: ${gameState.market.reputation.toStringAsFixed(2)}'),
              const Text(
                'Influence les ventes et les prix maximum.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Divider(),
              Text('Demande actuelle: ${(gameState.market.calculateDemand(
                gameState.player.sellPrice,
                gameState.player.getMarketingLevel()) * 100).toStringAsFixed(0)}%'),
              const Text(
                'Basée sur le prix et le niveau marketing.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Divider(),
              Text('Stock mondial de métal: ${gameState.resources.marketMetalStock.toStringAsFixed(0)}'),
              const Text(
                'Influence les prix et la disponibilité.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
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

  static void showLevelInfoDialog(BuildContext context, LevelSystem levelSystem) {
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

  static void showAboutInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 8),
            const Text('À propos'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version ${GameConstants.VERSION}'),
            const SizedBox(height: 8),
            const Text('Un jeu incrémental de production de trombones.'),
            const SizedBox(height: 16),
            const Text('Fonctionnalités:'),
            const Text('• Production de trombones'),
            const Text('• Gestion du marché'),
            const Text('• Système d\'améliorations'),
            const Text('• Événements dynamiques'),
            const SizedBox(height: 16),
            const Text('Développé avec ❤️ par Kinder2149'),
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
} 