// lib/widgets/appbar/sections/notification_action.dart
import 'package:flutter/material.dart';
import '../../../models/event_system.dart';
import '../../indicators/notification_widgets.dart';
import '../../../screens/event_log_screen.dart';

class NotificationAction extends StatelessWidget {
  const NotificationAction({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: EventManager.instance.unreadCount,
      builder: (context, unreadCount, child) {
        return Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EventLogScreen()),
                );
              },
              tooltip: 'Notifications',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
