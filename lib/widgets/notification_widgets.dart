// lib/widgets/notification_widgets.dart
import 'package:flutter/material.dart';
import '../models/event_system.dart';
import '../main.dart' show navigatorKey;
import 'dart:async';
import '../models/game_config.dart';
import '../services/notification_storage_service.dart'; // Nouveau import

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
    EventManager.instance.notificationStream.addListener(_handleNotification);
    // Charger les notifications importantes au démarrage
    _loadSavedNotifications();
  }

  // Nouvelle méthode pour charger les notifications sauvegardées
  Future<void> _loadSavedNotifications() async {
    final savedNotifications = await NotificationStorageService.getImportantNotifications();
    for (var notification in savedNotifications) {
      EventManager.instance.addNotification(notification);
    }
  }

  void _handleNotification() {
    final notification = EventManager.instance.notificationStream.value;
    if (notification != null && mounted) {
      _showNotificationOverlay(notification);
    }
  }

  void _showNotificationOverlay(NotificationEvent event) {
    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => AnimatedNotificationOverlay(
        event: event,
        onDismiss: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
          EventManager.instance.notificationStream.value = null;
        },
      ),
    );

    if (mounted && context.mounted) {
      Overlay.of(context).insert(_overlayEntry!);
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
class AnimatedNotificationOverlay extends StatefulWidget {
  final NotificationEvent event;
  final VoidCallback onDismiss;

  const AnimatedNotificationOverlay({
    Key? key,
    required this.event,
    required this.onDismiss,
  }) : super(key: key);

  @override
  _AnimatedNotificationOverlayState createState() => _AnimatedNotificationOverlayState();
}

class _AnimatedNotificationOverlayState extends State<AnimatedNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupAutoHide();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  void _setupAutoHide() {
    _autoHideTimer = Timer(
      Duration(seconds: widget.event.type == EventType.LEVEL_UP ? 5 : 3),
      _hideNotification,
    );
  }

  void _hideNotification() {
    _autoHideTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10 + _slideAnimation.value,
          right: 10,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: _hideNotification,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(widget.event.priority).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.event.icon ?? Icons.notifications,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.event.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.event.description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.event.occurrences > 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${widget.event.occurrences} occurrences',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.LOW:
        return Colors.grey[700]!;
      case NotificationPriority.MEDIUM:
        return Colors.blue[600]!;
      case NotificationPriority.HIGH:
        return Colors.orange[800]!;
      case NotificationPriority.CRITICAL:
        return Colors.red[700]!;
    }
  }
}