import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/money_display.dart';
import '../models/upgrade.dart';

class UpgradesScreen extends StatelessWidget {
  const UpgradesScreen({super.key});

  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours}h ${minutes}m ${remainingSeconds}s';
  }

  void _showInfoDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Statistiques Générales'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total des trombones produits: ${gameState.totalPaperclipsProduced}'),
                Text('Temps total joué: ${_formatDuration(gameState.totalTimePlayed)}'),
                Text('Prix actuel de vente: ${gameState.sellPrice.toStringAsFixed(2)} €'),
                Text('Prix actuel du métal: ${gameState.currentMetalPrice.toStringAsFixed(2)} €'),
                Text('Niveau actuel: ${gameState.levelSystem.level}'),
                LinearProgressIndicator(
                  value: gameState.levelSystem.experienceProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text('Nombre d\'autoclippeuses: ${gameState.autoclippers}'),
                Text('Stock actuel de métal: ${gameState.metal.toStringAsFixed(1)}'),
                Text('Coût actuel de production: ${gameState.productionCost.toStringAsFixed(2)} €'),
                Text('Niveau de marketing: ${gameState.marketingLevel}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MoneyDisplay(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _showInfoDialog(context, gameState),
                child: const Text('Afficher les Statistiques Générales'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: gameState.upgrades.entries.map((entry) {
                    String id = entry.key;
                    Upgrade upgrade = entry.value;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(upgrade.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(upgrade.description),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: upgrade.level / upgrade.maxLevel,
                              minHeight: 8,
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Niveau ${upgrade.level}/${upgrade.maxLevel}'),
                            Text('${upgrade.currentCost.toStringAsFixed(1)} €'),
                          ],
                        ),
                        enabled: gameState.money >= upgrade.currentCost && upgrade.level < upgrade.maxLevel,
                        onTap: () async {
                          await gameState.purchaseUpgrade(id);
                          // Mettre à jour les informations sur les autres pages après l'achat
                          Provider.of<GameState>(context, listen: false).notifyListeners();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}