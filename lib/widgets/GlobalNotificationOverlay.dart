import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/level_system.dart';

class GlobalNotificationOverlay extends StatefulWidget {
  final Widget child;

  const GlobalNotificationOverlay({Key? key, required this.child}) : super(key: key);

  @override
  _GlobalNotificationOverlayState createState() => _GlobalNotificationOverlayState();
}

class _GlobalNotificationOverlayState extends State<GlobalNotificationOverlay> {
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();

    EventManager.notificationStream.addListener(_handleNotification);
  }

  void _handleNotification() {
    final notification = EventManager.notificationStream.value;
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

    Overlay.of(context).insert(_overlayEntry!);

    // Fermer automatiquement après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    EventManager.notificationStream.removeListener(_handleNotification);
    _overlayEntry?.remove();
    super.dispose();
  }
}