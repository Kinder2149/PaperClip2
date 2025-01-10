import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/constants.dart';
import '../widgets/money_display.dart';
import '../services/save_manager.dart';

class ProductionScreen extends StatelessWidget {
  const ProductionScreen({super.key});

  String formatNumber(double number, bool isMetal) {
    if (isMetal) {
      return number.toStringAsFixed(2);
    } else {
      return number.floor().toString();
    }
  }

  Widget _buildResourceCard(String title, String value, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: Card(
        elevation: 2,
        color: color,
        child: InkWell(
          onTap: onTap,
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
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
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

  Future<void> _saveGame(BuildContext context, GameState gameState) async {
    try {
      if (gameState.gameName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Aucun nom de partie défini'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await SaveManager.saveGame(gameState, gameState.gameName!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Partie sauvegardée avec succès'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: TextStyle(fontSize: 14, color: textColor),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.grey.shade50,
        foregroundColor: textColor ?? Colors.black87,
        padding: const EdgeInsets.all(16),
        minimumSize: const Size(double.infinity, 50),
        disabledBackgroundColor: (backgroundColor ?? Colors.grey.shade50).withOpacity(0.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

                        // Stats de production
                        Row(
                          children: [
                            _buildResourceCard(
                              'Total Trombones Créés',
                              gameState.totalPaperclipsProduced.toString(),
                              Colors.purple.shade100,
                              onTap: () => _showInfoDialog(
                                context,
                                'Statistiques de Production',
                                'Total de trombones produits depuis le début du jeu: ${gameState.totalPaperclipsProduced}\n'
                                    'Niveau de production: ${gameState.levelSystem.level}\n'
                                    'Multiplicateur de production: x${gameState.levelSystem.productionMultiplier.toStringAsFixed(2)}',
                              ),
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

                        // Ressources et métal
                        Row(
                          children: [
                            _buildResourceCard(
                              'Métal',
                              '${formatNumber(gameState.metal, true)} / ${gameState.maxMetalStorage}',
                              Colors.grey.shade200,
                              onTap: () => _showInfoDialog(
                                context,
                                'Stock de Métal',
                                'Stock actuel: ${formatNumber(gameState.metal, true)}\n'
                                    'Capacité maximale: ${gameState.maxMetalStorage}\n'
                                    'Prix actuel: ${gameState.currentMetalPrice.toStringAsFixed(2)} €',
                              ),
                            ),
                            const SizedBox(width: 16),
                            _buildResourceCard(
                              'Prix du Marché',
                              '${gameState.sellPrice.toStringAsFixed(2)} €',
                              Colors.green.shade100,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Actions de production
                        _buildActionButton(
                          onPressed: gameState.money >= gameState.currentMetalPrice ?
                          gameState.buyMetal : null,
                          label: 'Acheter Métal (${gameState.currentMetalPrice.toStringAsFixed(1)} €)',
                          icon: Icons.shopping_cart,
                        ),
                        const SizedBox(height: 12),

                        // Bloc Autoclippers amélioré
                        Card(
                          elevation: 2,
                          color: Colors.orange.shade100,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.precision_manufacturing),
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
                                    IconButton(
                                      icon: const Icon(Icons.info_outline),
                                      onPressed: () => _showInfoDialog(
                                        context,
                                        'Détails des Autoclippers',
                                        'Production de base: ${gameState.autoclippers} par cycle\n'
                                            'Bonus de production: +${bulkBonus.toStringAsFixed(0)}%\n'
                                            'Bonus de vitesse: +${speedBonus.toStringAsFixed(0)}%\n'
                                            'Production effective: ${(gameState.autoclippers * (1 + bulkBonus/100) * (1 + speedBonus/100)).toStringAsFixed(1)} par cycle',
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildBonusIndicator(
                                      'Production',
                                      '${bulkBonus.toStringAsFixed(0)}%',
                                      Icons.trending_up,
                                    ),
                                    _buildBonusIndicator(
                                      'Vitesse',
                                      '${speedBonus.toStringAsFixed(0)}%',
                                      Icons.speed,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildActionButton(
                          onPressed: gameState.money >= gameState.autocliperCost ?
                          gameState.buyAutoclipper : null,
                          label: 'Acheter Autoclipper (${gameState.autocliperCost.toStringAsFixed(1)} €)',
                          icon: Icons.add_circle_outline,
                        ),
                        const SizedBox(height: 16),

                        _buildActionButton(
                          onPressed: () => _saveGame(context, gameState),
                          label: 'Sauvegarder la Partie',
                          icon: Icons.save,
                          backgroundColor: Colors.purple.shade200,
                          textColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Bouton de production
          Container(
            padding: const EdgeInsets.all(16),
            child: Consumer<GameState>(
              builder: (context, gameState, child) {
                bool canProduce = gameState.metal >= GameConstants.METAL_PER_PAPERCLIP;
                return _buildActionButton(
                  onPressed: canProduce ? gameState.producePaperclip : null,
                  label: 'Produire un trombone (${GameConstants.METAL_PER_PAPERCLIP} métal)',
                  icon: Icons.add,
                  backgroundColor: Colors.blue.shade500,
                  textColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusIndicator(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(value),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}