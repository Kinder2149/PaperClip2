import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/game_viewmodel.dart';
import '../../../domain/services/event_service.dart';

class EventsList extends StatelessWidget {
  const EventsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameViewModel>(
      builder: (context, gameViewModel, child) {
        final events = gameViewModel.activeEvents;

        if (events.isEmpty) {
          return const Center(
            child: Text('Aucun événement en cours'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventCard(context, event, gameViewModel);
          },
        );
      },
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    GameEvent event,
    GameViewModel gameViewModel,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: _buildEventIcon(event.type),
            title: Text(event.title),
            subtitle: Text(event.description),
            trailing: _buildEventStatus(event),
          ),
          if (event.rewards.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Récompenses:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...event.rewards.entries.map((reward) => _buildRewardItem(reward)),
                ],
              ),
            ),
          ],
          if (event.endDate != null) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fin: ${_formatDate(event.endDate!)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (!event.isCompleted)
                    ElevatedButton(
                      onPressed: () => _completeEvent(context, event.id, gameViewModel),
                      child: const Text('Terminer'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventIcon(EventType type) {
    IconData icon;
    Color color;

    switch (type) {
      case EventType.SPECIAL_OFFER:
        icon = Icons.local_offer;
        color = Colors.orange;
        break;
      case EventType.ACHIEVEMENT:
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case EventType.MILESTONE:
        icon = Icons.flag;
        color = Colors.green;
        break;
      case EventType.DAILY_REWARD:
        icon = Icons.calendar_today;
        color = Colors.blue;
        break;
      case EventType.WEEKLY_CHALLENGE:
        icon = Icons.weekend;
        color = Colors.purple;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildEventStatus(GameEvent event) {
    if (event.isCompleted) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    if (event.endDate != null && event.endDate!.isBefore(DateTime.now())) {
      return const Icon(Icons.timer_off, color: Colors.red);
    }

    return const Icon(Icons.timer, color: Colors.blue);
  }

  Widget _buildRewardItem(MapEntry<String, dynamic> reward) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _getRewardIcon(reward.key),
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            '${reward.value} ${reward.key}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(String type) {
    switch (type.toLowerCase()) {
      case 'money':
        return Icons.attach_money;
      case 'paperclips':
        return Icons.attachment;
      case 'metal':
        return Icons.metal;
      case 'multiplier':
        return Icons.trending_up;
      default:
        return Icons.card_giftcard;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _completeEvent(
    BuildContext context,
    String eventId,
    GameViewModel gameViewModel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer l\'événement'),
        content: const Text('Êtes-vous sûr de vouloir terminer cet événement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await gameViewModel.completeEvent(eventId);
    }
  }
} 