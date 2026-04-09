import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../services/reset/reset_rewards_calculator.dart';

/// Dialog de confirmation pour le reset progression
/// 
/// Affiche un aperçu des gains potentiels et demande confirmation
class ResetProgressionDialog extends StatelessWidget {
  const ResetProgressionDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context, listen: false);
    final resetManager = gameState.resetManager;
    
    // Calculer les récompenses potentielles
    final rewards = resetManager.calculatePotentialRewards();
    final canReset = resetManager.canReset();
    final recommendation = resetManager.getResetRecommendation(
      gameState.levelSystem.currentLevel,
      rewards,
    );

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.restart_alt, color: Colors.orange),
          SizedBox(width: 8),
          Text('Reset Progression'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recommandation
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canReset ? Colors.blue.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: canReset ? Colors.blue : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    canReset ? Icons.info_outline : Icons.warning_amber,
                    color: canReset ? Colors.blue : Colors.red,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: canReset ? Colors.blue : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Gains potentiels
            Text(
              'Gains potentiels',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildRewardRow(
              icon: Icons.blur_on,
              label: 'Quantum',
              value: '+${rewards.quantum}',
              color: Colors.purple,
            ),
            _buildRewardRow(
              icon: Icons.lightbulb_outline,
              label: 'Points Innovation',
              value: '+${rewards.innovationPoints}',
              color: Colors.amber,
            ),
            
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            
            // Ce qui sera conservé
            Text(
              '✓ Conservé',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 4),
            _buildConservedItem('Quantum et Points Innovation'),
            _buildConservedItem('Recherches META'),
            _buildConservedItem('Agents débloqués'),
            _buildConservedItem('Slots agents'),
            
            SizedBox(height: 12),
            
            // Ce qui sera réinitialisé
            Text(
              '✗ Réinitialisé',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 4),
            _buildResetItem('Niveau et XP'),
            _buildResetItem('Argent et trombones'),
            _buildResetItem('Autoclippers'),
            _buildResetItem('Recherches non-META'),
            _buildResetItem('Agents actifs'),
            _buildResetItem('Upgrades'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: canReset
              ? () => Navigator.of(context).pop(true)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: Text('Confirmer le reset'),
        ),
      ],
    );
  }

  Widget _buildRewardRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Text(label),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConservedItem(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 16, top: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.green[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildResetItem(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 16, top: 2),
      child: Row(
        children: [
          Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.red[700]),
          ),
        ],
      ),
    );
  }
}
