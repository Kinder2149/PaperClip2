import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'production_screen.dart';
import 'market_screen.dart';
import 'upgrades_screen.dart';
import 'event_log_screen.dart';
import '../widgets/event_notification_overlay.dart';
import '../models/notification_manager.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Scaffold(
          body: Stack(
            children: [
              DefaultTabController(
                length: 4,
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text('PaperClip Game'),
                    bottom: const TabBar(
                      tabs: [
                        Tab(icon: Icon(Icons.precision_manufacturing), text: 'Production'),
                        Tab(icon: Icon(Icons.storefront), text: 'Marché'),
                        Tab(icon: Icon(Icons.upgrade), text: 'Améliorations'),
                        Tab(icon: Icon(Icons.event_note), text: 'Événements'),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          NotificationManager.showGameNotification(
                            context,
                            title: 'À propos',
                            message: 'Version 1.0.0\nDéveloppé avec ❤️',
                            icon: Icons.info,
                          );
                        },
                      ),
                    ],
                  ),
                  body: TabBarView(
                    children: [
                      const ProductionScreen(),
                      const MarketScreen(),
                      const UpgradesScreen(),
                      const EventLogScreen(),
                    ],
                  ),
                ),
              ),
              const EventNotificationOverlay(),
            ],
          ),
        );
      },
    );
  }
}