// lib/widgets/notification_widgets.dart
import 'package:flutter/material.dart';
import '../models/event_system.dart';
import '../main.dart' show navigatorKey;

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

  @override
  void initState() {
    super.initState();
    // Utiliser l'instance au lieu de l'accès statique
    EventManager.instance.notificationStream.addListener(_handleNotification);
  }

  void _handleNotification() {
    // Utiliser l'instance
    final notification = EventManager.instance.notificationStream.value;
    if (notification != null) {
      _showNotificationOverlay(notification);
    }
  }

  void _showNotificationOverlay(NotificationEvent event) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.deepPurple,
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
                    Icon(event.icon, color: Colors.white, size: 30),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              event.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16
                              )
                          ),
                          Text(
                              event.description,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14
                              )
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        )
    );

    if (widget.navigatorKey.currentContext != null) {
      Overlay.of(widget.navigatorKey.currentContext!).insert(_overlayEntry!);

      Future.delayed(const Duration(seconds: 3), () {
        _overlayEntry?.remove();
        _overlayEntry = null;
      });
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
                  Icon(notification.icon, color: Colors.blue),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        notification.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}