import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/game_viewmodel.dart';
import '../../../domain/services/reward_service.dart';

class RewardsList extends StatelessWidget {
  const RewardsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameViewModel>(
      builder: (context, gameViewModel, child) {
        final rewards = gameViewModel.availableRewards;

        if (rewards.isEmpty) {
          return const Center(
            child: Text('Aucune récompense disponible'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            final reward = rewards[index];
            return _buildRewardCard(context, reward, gameViewModel);
          },
        );
      },
    );
  }

  Widget _buildRewardCard(
    BuildContext context,
    Reward reward,
    GameViewModel gameViewModel,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: _buildRewardIcon(reward.type),
            title: Text(reward.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.description),
                if (reward.expiryDate != null)
                  Text(
                    'Expire le: ${_formatDate(reward.expiryDate!)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: _buildRewardStatus(reward),
          ),
          if (!reward.isClaimed && !reward.isExpired) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _claimReward(context, reward.id, gameViewModel),
                    icon: const Icon(Icons.card_giftcard),
                    label: const Text('Réclamer'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardIcon(RewardType type) {
    IconData icon;
    Color color;

    switch (type) {
      case RewardType.MONEY:
        icon = Icons.attach_money;
        color = Colors.green;
        break;
      case RewardType.PAPERCLIPS:
        icon = Icons.attachment;
        color = Colors.blue;
        break;
      case RewardType.METAL:
        icon = Icons.metal;
        color = Colors.grey;
        break;
      case RewardType.MULTIPLIER:
        icon = Icons.trending_up;
        color = Colors.orange;
        break;
      case RewardType.SPECIAL_ITEM:
        icon = Icons.star;
        color = Colors.amber;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildRewardStatus(Reward reward) {
    if (reward.isClaimed) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    if (reward.isExpired) {
      return const Icon(Icons.timer_off, color: Colors.red);
    }

    if (reward.expiryDate != null && reward.expiryDate!.isBefore(DateTime.now())) {
      return const Icon(Icons.warning, color: Colors.orange);
    }

    return const Icon(Icons.card_giftcard, color: Colors.blue);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _claimReward(
    BuildContext context,
    String rewardId,
    GameViewModel gameViewModel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réclamer la récompense'),
        content: const Text('Voulez-vous réclamer cette récompense ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Réclamer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await gameViewModel.claimReward(rewardId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Récompense réclamée avec succès !')),
        );
      }
    }
  }
} 