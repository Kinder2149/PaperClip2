// lib/presentation/widgets/notification_widgets.dart (continuation)
import 'package:flutter/material.dart';
import '../../domain/services/event_manager_service.dart';
import '../../core/constants/enums.dart';
import 'dart:async';

class NotificationBadge extends StatelessWidget {
  final int count;
  final Color color;
  final VoidCallback? onTap;

  const NotificationBadge({
    Key? key,
    required this.count,
    this.color = Colors.red,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(
          minWidth: 20,
          minHeight: 20,
        ),
        child: Center(
          child: Text(
            count > 99 ? '99+' : count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedNotificationOverlay extends StatefulWidget {
  final NotificationEvent event;
  final VoidCallback onDismiss;
  final Duration duration;

  const AnimatedNotificationOverlay({
    Key? key,
    required this.event,
    required this.onDismiss,
    this.duration = const Duration(seconds: 5),
  }) : super(key: key);

  @override
  State<AnimatedNotificationOverlay> createState() => _AnimatedNotificationOverlayState();
}

class _AnimatedNotificationOverlayState extends State<AnimatedNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();

    // Auto-dismiss after duration
    _timer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(_animation),
        child: FadeTransition(
          opacity: _animation,
          child: NotificationCard(
            event: widget.event,
            onDismiss: _dismiss,
          ),
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationEvent event;
  final VoidCallback? onDismiss;

  const NotificationCard({
    Key? key,
    required this.event,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final priorityData = _getPriorityData(event.type);

    return Card(
      elevation: priorityData.importance >= 2 ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: priorityData.color.withOpacity(0.5),
          width: 1,
        ),
      ),
      color: priorityData.color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              priorityData.icon,
              color: priorityData.color,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: priorityData.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onDismiss,
              color: Colors.grey[700],
            ),
          ],
        ),
      ),
    );
  }

  _NotificationPriorityData _getPriorityData(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.LOW:
        return _NotificationPriorityData(
          color: Colors.blue,
          icon: Icons.info_outline,
          importance: 0,
        );
      case NotificationPriority.MEDIUM:
        return _NotificationPriorityData(
          color: Colors.amber,
          icon: Icons.warning_amber_outlined,
          importance: 1,
        );
      case NotificationPriority.HIGH:
        return _NotificationPriorityData(
          color: Colors.orange,
          icon: Icons.priority_high,
          importance: 2,
        );
      case NotificationPriority.CRITICAL:
        return _NotificationPriorityData(
          color: Colors.red,
          icon: Icons.error_outline,
          importance: 3,
        );
    }
  }
}

class _NotificationPriorityData {
  final Color color;
  final IconData icon;
  final int importance;

  _NotificationPriorityData({
    required this.color,
    required this.icon,
    required this.importance,
  });
}

class EventLogItem extends StatelessWidget {
  final GameEvent event;
  final bool isNewEvent;

  const EventLogItem({
    Key? key,
    required this.event,
    this.isNewEvent = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventData = _getEventTypeData();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isNewEvent
            ? eventData.color.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNewEvent
              ? eventData.color.withOpacity(0.5)
              : Colors.grey.withOpacity(0.3),
          width: isNewEvent ? 1.5 : 1,
        ),
        boxShadow: isNewEvent
            ? [
          BoxShadow(
            color: eventData.color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: eventData.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                eventData.icon,
                color: eventData.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        eventData.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: eventData.color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(event.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getEventDescription(),
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  if (event.data.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: event.data.entries
                          .map((entry) => _buildDataTag(entry.key, entry.value))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTag(String key, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$key: $value',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute}';
    }
  }

  String _getEventDescription() {
    switch (event.type) {
      case EventType.LEVEL_UP:
        return 'Vous avez atteint le niveau ${event.data['level']}';
      case EventType.MARKET_CHANGE:
        return 'Changement important sur le marché';
      case EventType.RESOURCE_DEPLETION:
        return 'Une ressource est en voie d\'épuisement';
      case EventType.UPGRADE_AVAILABLE:
        return 'Nouvelle amélioration disponible';
      case EventType.SPECIAL_ACHIEVEMENT:
        return 'Vous avez débloqué un nouvel accomplissement';
      case EventType.XP_BOOST:
        return 'Bonus d\'expérience activé';
      case EventType.INFO:
        return event.data['message'] ?? 'Information';
      case EventType.CRISIS_MODE:
        return 'Mode crise activé';
      case EventType.UI_CHANGE:
        return 'Interface mise à jour';
      default:
        return 'Événement du jeu';
    }
  }

  _EventTypeData _getEventTypeData() {
    switch (event.type) {
      case EventType.LEVEL_UP:
        return _EventTypeData(
          title: 'Niveau supérieur',
          color: Colors.green,
          icon: Icons.arrow_upward,
        );
      case EventType.MARKET_CHANGE:
        return _EventTypeData(
          title: 'Marché',
          color: Colors.blue,
          icon: Icons.show_chart,
        );
      case EventType.RESOURCE_DEPLETION:
        return _EventTypeData(
          title: 'Ressources',
          color: Colors.orange,
          icon: Icons.warning_amber,
        );
      case EventType.UPGRADE_AVAILABLE:
        return _EventTypeData(
          title: 'Amélioration',
          color: Colors.purple,
          icon: Icons.upgrade,
        );
      case EventType.SPECIAL_ACHIEVEMENT:
        return _EventTypeData(
          title: 'Accomplissement',
          color: Colors.amber,
          icon: Icons.emoji_events,
        );
      case EventType.XP_BOOST:
        return _EventTypeData(
          title: 'Bonus XP',
          color: Colors.teal,
          icon: Icons.speed,
        );
      case EventType.INFO:
        return _EventTypeData(
          title: 'Information',
          color: Colors.blue,
          icon: Icons.info,
        );
      case EventType.CRISIS_MODE:
        return _EventTypeData(
          title: 'Mode Crise',
          color: Colors.red,
          icon: Icons.crisis_alert,
        );
      case EventType.UI_CHANGE:
        return _EventTypeData(
          title: 'Interface',
          color: Colors.indigo,
          icon: Icons.dashboard,
        );
    }
  }
}

class _EventTypeData {
  final String title;
  final Color color;
  final IconData icon;

  _EventTypeData({
    required this.title,
    required this.color,
    required this.icon,
  });
}