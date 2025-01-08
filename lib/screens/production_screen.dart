import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/constants.dart';
import '../widgets/money_display.dart';
import '../utils/update_manager.dart';
import 'dart:io';
import '../models/constants.dart';

class ProductionScreen extends StatelessWidget {
  const ProductionScreen({super.key});

  String formatNumber(double number, bool isMetal) {
    if (isMetal) {
      return number.toStringAsFixed(2);
    } else {
      return number.floor().toString();
    }
  }

  String _formatTimePlayed(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours}h ${minutes}m ${remainingSeconds}s';
  }

  Widget _buildResourceCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSaveDialog(BuildContext context, GameState gameState) async {
    final TextEditingController nameController = TextEditingController(
        text: 'save_${DateTime.now().toString().split('.')[0].replaceAll(RegExp(r'[^0-9]'), '')}'
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sauvegarder la partie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la sauvegarde',
                hintText: 'Entrez un nom pour votre sauvegarde',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Dossier de sauvegarde :\n${gameState.customSaveDirectory ?? "Dossier par défaut"}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => gameState.selectSaveDirectory(),
              icon: const Icon(Icons.folder),
              label: const Text('Changer le dossier'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await gameState.exportSave(nameController.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sauvegarde créée avec succès')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la sauvegarde'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showChangelogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Version ${UpdateManager.CURRENT_VERSION}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Derniers changements :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(UpdateManager.getChangelogForVersion(UpdateManager.CURRENT_VERSION)),
              const Divider(),
              const Text(
                'Historique complet :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(UpdateManager.getFullChangelog()),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const MoneyDisplay(),
              const SizedBox(height: 16),

              // Stats de production
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Trombones Créés',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gameState.totalPaperclipsProduced.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Cartes de ressources
              _buildResourceCard(
                'Trombones en stock',
                formatNumber(gameState.paperclips, false),
                Icons.attach_file,
                Colors.blue.shade100,
              ),
              const SizedBox(height: 12),
              _buildResourceCard(
                'Métal',
                formatNumber(gameState.metal, true),
                Icons.inventory_2,
                Colors.grey.shade200,
              ),
              const SizedBox(height: 12),
              _buildResourceCard(
                'Autoclippers',
                gameState.autoclippers.toString(),
                Icons.precision_manufacturing,
                Colors.orange.shade100,
              ),
              const SizedBox(height: 20),

              // Boutons de production et d'achat
              ElevatedButton.icon(
                onPressed: gameState.money >= gameState.autocliperCost
                    ? gameState.buyAutoclipper
                    : null,
                icon: const Icon(Icons.shopping_cart),
                label: Text(
                  'Acheter Autoclipper (${gameState.autocliperCost.toStringAsFixed(1)} €)',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 16),

              // Bouton de sauvegarde
              ElevatedButton.icon(
                onPressed: () {
                  Provider.of<GameState>(context, listen: false).saveGame();
                },
                icon: const Icon(Icons.save),
                label: const Text('Sauvegarder la Partie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Conserve la couleur du design actuel
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),

              // Bouton de production de trombone
              ElevatedButton.icon(
                onPressed: gameState.metal >= GameConstants.METAL_PER_PAPERCLIP
                    ? gameState.producePaperclip
                    : null,
                icon: const Icon(Icons.add),
                label: Text(
                  'Produire un trombone (${GameConstants.METAL_PER_PAPERCLIP} métal)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}