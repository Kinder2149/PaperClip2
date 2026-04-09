import 'package:flutter/material.dart';
import '../services/reset/reset_rewards_calculator.dart';

/// Dialog affichant les résultats d'un reset réussi
class ResetSuccessDialog extends StatelessWidget {
  final ResetRewards rewards;
  final int totalResets;

  const ResetSuccessDialog({
    Key? key,
    required this.rewards,
    required this.totalResets,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.celebration, color: Colors.amber, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reset réussi !'),
                Text(
                  'Reset #$totalResets',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.withOpacity(0.2), Colors.amber.withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Récompenses obtenues',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                _buildRewardCard(
                  icon: Icons.blur_on,
                  label: 'Quantum',
                  value: '+${rewards.quantum}',
                  color: Colors.purple,
                ),
                SizedBox(height: 8),
                _buildRewardCard(
                  icon: Icons.lightbulb_outline,
                  label: 'Points Innovation',
                  value: '+${rewards.innovationPoints}',
                  color: Colors.amber,
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Utilisez vos ressources rares pour débloquer des recherches META et des agents IA !',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text('Commencer une nouvelle partie !'),
        ),
      ],
    );
  }

  Widget _buildRewardCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
