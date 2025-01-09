import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/constants.dart';
import '../widgets/money_display.dart';
import '../utils/update_manager.dart';

class ProductionScreen extends StatelessWidget {
  const ProductionScreen({super.key});

  String formatNumber(double number, bool isMetal) {
    if (isMetal) {
      return number.toStringAsFixed(2);
    } else {
      return number.floor().toString();
    }
  }

  Widget _buildResourceCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
  void _showEventHistoryDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<GameState>(
          builder: (context, gameState, child) {
            return AlertDialog(
              title: const Text('Historique des Événements'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (gameState.activeEvent != null)
                      Container(
                        color: Colors.blue.shade100,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            gameState.activeEvent!['title'] ?? 'Titre inconnu',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gameState.activeEvent!['description'] ?? 'Description inconnue',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                gameState.activeEvent!['time'] ?? 'Temps inconnu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ACTIF',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ...gameState.eventHistory.map((event) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          event['title'] ?? 'Titre inconnu',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event['description'] ?? 'Description inconnue'),
                            Text(
                              event['time'] ?? 'Temps inconnu',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
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
      },
    );
  }

  Future<void> _showSaveDialog(BuildContext context, GameState gameState) async {
    final TextEditingController nameController = TextEditingController(
        text: 'save_${DateTime.now().toString().split('.')[0].replaceAll(RegExp(r'[^0-9]'), '')}');

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
                await gameState.saveGame();
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
  @override
  Widget build(BuildContext context) {
    // Initialiser le contexte dans GameState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameState>(context, listen: false).setContext(context);
    });

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Consumer<GameState>(
              builder: (context, gameState, child) {
                double bulkBonus = (gameState.upgrades['bulk']?.level ?? 0) * 20;
                double speedBonus = (gameState.upgrades['speed']?.level ?? 0) * 15;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const MoneyDisplay(),
                        const SizedBox(height: 16),

                        // Stats de production et trombones en stock
                        Row(
                          children: [
                            _buildResourceCard(
                              'Total Trombones Créés',
                              gameState.totalPaperclipsProduced.toString(),
                              Colors.purple.shade100,
                            ),
                            const SizedBox(width: 16),
                            _buildResourceCard(
                              'Trombones en stock',
                              formatNumber(gameState.paperclips, false),
                              Colors.blue.shade100,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Métal et historique des événements
                        Row(
                          children: [
                            _buildResourceCard(
                              'Métal',
                              formatNumber(gameState.metal, true),
                              Colors.grey.shade200,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Stack(
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _showEventHistoryDialog(context, gameState),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      minimumSize: const Size(double.infinity, 72),
                                    ),
                                    child: const Text(
                                      'Historique des Événements',
                                      style: TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  if (gameState.activeEvent != null)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Bouton pour acheter du métal
                        ElevatedButton.icon(
                          onPressed: gameState.money >= gameState.currentMetalPrice
                              ? gameState.buyMetal
                              : null,
                          icon: const Icon(Icons.shopping_cart, size: 20),
                          label: Text(
                            'Acheter Métal (${gameState.currentMetalPrice.toStringAsFixed(1)} €)',
                            style: const TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade50,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.all(16),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Bloc Autoclippers
                        Card(
                          elevation: 2,
                          color: Colors.orange.shade100,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.precision_manufacturing, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Autoclippers: ${gameState.autoclippers}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.trending_up, size: 14),
                                        const SizedBox(width: 4),
                                        Text('${bulkBonus.toStringAsFixed(0)}%'),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.speed, size: 14),
                                        const SizedBox(width: 4),
                                        Text('${speedBonus.toStringAsFixed(0)}%'),
                                      ],
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.info_outline, size: 20),
                                  onPressed: () {
                                    _showInfoDialog(
                                      context,
                                      'Bonus des Autoclippers',
                                      'Bonus de Production: Augmente la quantité de production par unité de temps.\n\n'
                                      'Bonus de Vitesse: Augmente la vitesse de production des autoclippeuses.',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Bouton d'achat d'autoclipper
                        ElevatedButton.icon(
                          onPressed: gameState.money >= gameState.autocliperCost
                              ? gameState.buyAutoclipper
                              : null,
                          icon: const Icon(Icons.shopping_cart, size: 20),
                          label: Text(
                            'Acheter Autoclipper (${gameState.autocliperCost.toStringAsFixed(1)} €)',
                            style: const TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade50,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.all(16),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Bouton de sauvegarde
                        ElevatedButton(
                          onPressed: () => _showSaveDialog(context, gameState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade200,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            'Sauvegarder la Partie',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Bouton de production fixe en bas
          Container(
            padding: const EdgeInsets.all(16),
            child: Consumer<GameState>(
              builder: (context, gameState, child) {
                return ElevatedButton.icon(
                  onPressed: gameState.metal >= GameConstants.METAL_PER_PAPERCLIP
                      ? gameState.producePaperclip
                      : null,
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Produire un trombone (${gameState.productionCost.toStringAsFixed(2)} €)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}