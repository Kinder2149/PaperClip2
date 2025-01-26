// lib/widgets/notification_widgets.dart
import 'package:flutter/material.dart';
import '../models/event_system.dart';
import '../main.dart' show navigatorKey;
import 'dart:async';
import '../models/game_config.dart';

class GlobalNotificationOverlay extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const GlobalNotificationOverlay({
    Key? key,
    required this.child,
    required this.navigatorKey,
  }) : super(key: key);

  @override
  _GlobalNotificationOverlayState createState() => _GlobalNotificationOverlayState();
}

class _GlobalNotificationOverlayState extends State<GlobalNotificationOverlay> {
  OverlayEntry? _overlayEntry;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    EventManager.instance.notificationStream.addListener(_handleNotification);
  }

  void _handleNotification() {
    final notification = EventManager.instance.notificationStream.value;
    if (notification != null) {
      _showNotificationOverlay(notification);
    } else {
      _hideNotificationOverlay();
    }
  }

  void _showNotificationOverlay(NotificationEvent event) {
    _overlayEntry?.remove();
    _autoHideTimer?.cancel();

    _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: GestureDetector(
                onTap: _hideNotificationOverlay,
                child: Container(
                  width: 300,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: _getPriorityColor(event.priority).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: const Offset(0, 4)
                        )
                      ]
                  ),
                  child: Row(
                    children: [
                      Icon(event.icon, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                event.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                )
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event.description,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
    );

    if (mounted && context.mounted) {
      Overlay.of(context).insert(_overlayEntry!);
      // Utilisez une durée plus longue pour les notifications de niveau
      final duration = event.type == EventType.LEVEL_UP ?
      const Duration(seconds: 5) :
      const Duration(seconds: 3);
      _autoHideTimer = Timer(duration, _hideNotificationOverlay);
    }
  }

  void _hideNotificationOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
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




  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: widget.navigatorKey,
      home: widget.child,
      debugShowCheckedModeBanner: false,
    );
  }

  @override
  void dispose() {
    EventManager.instance.notificationStream.removeListener(_handleNotification);
    _overlayEntry?.remove();
    super.dispose();
  }
}

// Dans lib/widgets/notification_widgets.dart
class EventNotificationOverlay extends StatelessWidget {
  const EventNotificationOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NotificationEvent?>(
      valueListenable: EventManager.instance.notificationStream,
      builder: (context, notification, child) {
        if (notification == null) return const SizedBox.shrink();

        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 10,
          child: GestureDetector(
            onTap: () {
              // Faire disparaître la notification
              EventManager.instance.notificationStream.value = null;
            },
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(notification.icon),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(notification.title),
                        Text(
                          notification.description,
                          style: TextStyle(fontSize: 12),
                        ),
                        if (notification.occurrences > 1)
                          Text(
                            '${notification.occurrences} occurrences',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}