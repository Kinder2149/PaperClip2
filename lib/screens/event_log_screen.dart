import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/event_system.dart';

class EventLogScreen extends StatefulWidget {
  const EventLogScreen({Key? key}) : super(key: key);

  @override
  EventLogScreenState createState() => EventLogScreenState();
}

class EventLogScreenState extends State<EventLogScreen> {
  List<NotificationEvent> notifications = [];
  late final EventManager eventManager;

  @override
  void initState() {
    super.initState();
    eventManager = EventManager.instance;
    eventManager.notificationStream.addListener(_handleNewNotification);
  }

  void _handleNewNotification() {
    setState(() {});
  }

  void loadNotifications() {
    setState(() {
      // Charger les événements existants si nécessaire
      notifications = List.from(notifications);
    });
  }

  void _clearNotifications() {
    setState(() {
      notifications.clear();
      eventManager.clearEvents();
    });
  }

  @override
  void dispose() {
    eventManager.notificationStream.removeListener(_handleNewNotification);
    super.dispose();
  }

  void _showDetailedNotification(BuildContext context, NotificationEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(event.icon),
            const SizedBox(width: 8),
            Expanded(child: Text(event.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (event.detailedDescription != null)
                Text(event.detailedDescription!),
              if (event.additionalData != null && event.additionalData!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                ...event.additionalData!.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(e.value.toString()),
                    ],
                  ),
                )),
              ],
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
    final notifications = eventManager.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal des Événements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              eventManager.clearEvents();
              setState(() {});
            },
            tooltip: 'Effacer toutes les notifications',
          )
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Aucune notification pour le moment',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            )
          ],
        ),
      )
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }
  Widget _buildNotificationCard(NotificationEvent notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(
          notification.icon,
          color: _getPriorityColor(notification.priority),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.priority == NotificationPriority.CRITICAL
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.description),
            Text(
              _formatEventTime(notification.timestamp),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        onTap: () => _showDetailedNotification(context, notification),
      ),
    );
  }


  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.LOW:
        return Colors.grey;
      case NotificationPriority.MEDIUM:
        return Colors.blue;
      case NotificationPriority.HIGH:
        return Colors.orange;
      case NotificationPriority.CRITICAL:
        return Colors.red;
    }
  }


  String _formatEventTime(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}