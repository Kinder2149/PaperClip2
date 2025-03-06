import 'package:flutter/material.dart';
import '../../../domain/services/daily_reward_service.dart';

class DailyRewardCard extends StatelessWidget {
  final DailyRewardService _dailyRewardService = DailyRewardService();

  DailyRewardCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Récompense Quotidienne',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStreakBadge(),
              ],
            ),
            const SizedBox(height: 16),
            _buildRewardInfo(),
            const SizedBox(height: 16),
            _buildClaimButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '${_dailyRewardService.currentStreak} jours',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardInfo() {
    final isAvailable = _dailyRewardService.isDailyRewardAvailable;
    final nextRewardTime = _dailyRewardService.nextRewardTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAvailable
              ? 'Votre récompense est disponible !'
              : 'Prochaine récompense dans $nextRewardTime',
          style: TextStyle(
            fontSize: 16,
            color: isAvailable ? Colors.green : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Montant de base: 100\$',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          'Multiplicateur de streak: +${(_dailyRewardService.currentStreak * 10)}%',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildClaimButton(BuildContext context) {
    final isAvailable = _dailyRewardService.isDailyRewardAvailable;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isAvailable
            ? () async {
                await _dailyRewardService.claimDailyReward();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Récompense quotidienne réclamée avec succès !'),
                    ),
                  );
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: isAvailable ? Colors.green : Colors.grey,
        ),
        child: Text(
          isAvailable ? 'Réclamer la Récompense' : 'Récompense Non Disponible',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
} 