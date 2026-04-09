import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../dialogs/reset_progression_dialog.dart';
import '../dialogs/reset_success_dialog.dart';
import '../managers/reset_manager.dart';

/// Écran Progression affichant les stats lifetime et le système de reset
class ProgressionScreen extends StatelessWidget {
  const ProgressionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        final rareResources = gameState.rareResources;
        final resetManager = gameState.resetManager;
        final stats = gameState.statistics;
        final level = gameState.levelSystem.currentLevel;
        
        final canReset = resetManager.canReset();
        final rewards = resetManager.calculatePotentialRewards();

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.trending_up, size: 48, color: Colors.blue),
                      SizedBox(height: 8),
                      Text(
                        'Progression',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Stats lifetime et reset progression',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Ressources rares
              Card(
                color: Colors.purple.withOpacity(0.1),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ressources Rares',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildResourceRow(
                        icon: Icons.blur_on,
                        label: 'Quantum',
                        value: '${rareResources.quantum}',
                        color: Colors.purple,
                      ),
                      SizedBox(height: 8),
                      _buildResourceRow(
                        icon: Icons.lightbulb_outline,
                        label: 'Points Innovation',
                        value: '${rareResources.pointsInnovation}',
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Stats lifetime
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistiques Lifetime',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildStatRow('Total Resets', '${rareResources.totalResets}'),
                      _buildStatRow('Quantum Total Gagné', '${rareResources.quantumLifetime}'),
                      _buildStatRow('PI Total Gagnés', '${rareResources.innovationPointsLifetime}'),
                      Divider(),
                      _buildStatRow('Trombones Produits', '${stats.totalPaperclipsProduced}'),
                      _buildStatRow('Argent Gagné', '\$${stats.totalMoneyEarned.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Historique des resets
              if (rareResources.resetHistory.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Historique des Resets',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        ...rareResources.resetHistory.reversed.take(5).map((record) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(Icons.history, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Reset #${record.resetNumber} - Niveau ${record.levelReached}',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  '+${record.quantumGained} Q',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
              
              // Section Reset Progression
              Card(
                color: Colors.orange.withOpacity(0.1),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.restart_alt, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Reset Progression',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Recommencez votre partie en conservant vos ressources rares et recherches META.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 16),
                      
                      // Preview des gains
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Gains potentiels',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Icon(Icons.blur_on, color: Colors.purple),
                                    SizedBox(height: 4),
                                    Text(
                                      '+${rewards.quantum}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text('Quantum', style: TextStyle(fontSize: 11)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Icon(Icons.lightbulb_outline, color: Colors.amber),
                                    SizedBox(height: 4),
                                    Text(
                                      '+${rewards.innovationPoints}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text('Points Innovation', style: TextStyle(fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Bouton Reset
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: canReset
                              ? () => _handleResetProgression(context, gameState)
                              : null,
                          icon: Icon(Icons.restart_alt),
                          label: Text(
                            canReset
                                ? 'Reset Progression'
                                : 'Niveau ${ResetManager.MIN_LEVEL_FOR_RESET} requis',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      
                      if (!canReset) ...[
                        SizedBox(height: 8),
                        Text(
                          'Atteignez le niveau ${ResetManager.MIN_LEVEL_FOR_RESET} pour débloquer le reset progression.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResourceRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 15),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _handleResetProgression(BuildContext context, GameState gameState) async {
    // Afficher dialog de confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ResetProgressionDialog(),
    );

    if (confirmed != true) return;

    // Effectuer le reset
    final result = await gameState.performProgressionReset();

    if (!context.mounted) return;

    if (result.success) {
      // Afficher dialog de succès
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ResetSuccessDialog(
          rewards: result.rewards!,
          totalResets: gameState.rareResources.totalResets,
        ),
      );
    } else {
      // Afficher erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du reset: ${result.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
