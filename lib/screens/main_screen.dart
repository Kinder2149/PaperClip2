import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'production_screen.dart';
import 'market_screen.dart';
import 'upgrades_screen.dart';
import 'event_log_screen.dart';
import '../widgets/event_notification_overlay.dart';
import '../models/notification_manager.dart';
import '../models/notification_event.dart';
import '../models/game_enums.dart';
import '../models/constants.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        // Mettre à jour le contexte du GameState
        gameState.setContext(context);

        // Obtenir les écrans visibles basés sur le niveau
        final visibleScreens = gameState.getVisibleScreenElements();

        // Filtrer les tabs visibles
        final tabs = _buildVisibleTabs(visibleScreens);
        final tabViews = _buildVisibleTabViews(visibleScreens);

        return Scaffold(
          body: Stack(
            children: [
              DefaultTabController(
                length: tabs.length,
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text('PaperClip Game'),
                    bottom: TabBar(tabs: tabs),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _showAboutInfo(context),
                      ),
                    ],
                  ),
                  body: TabBarView(
                    children: tabViews,
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

  List<Tab> _buildVisibleTabs(Map<String, bool> visibleScreens) {
    final List<Tab> tabs = [];

    // Production toujours visible
    tabs.add(const Tab(
        icon: Icon(Icons.precision_manufacturing),
        text: 'Production'
    ));

    if (visibleScreens['market'] == true) {
      tabs.add(const Tab(
          icon: Icon(Icons.storefront),
          text: 'Marché'
      ));
    }

    if (visibleScreens['upgrades'] == true) {
      tabs.add(const Tab(
          icon: Icon(Icons.upgrade),
          text: 'Améliorations'
      ));
    }

    // Journal d'événements toujours visible
    tabs.add(const Tab(
        icon: Icon(Icons.event_note),
        text: 'Événements'
    ));

    return tabs;
  }

  List<Widget> _buildVisibleTabViews(Map<String, bool> visibleScreens) {
    final List<Widget> views = [];

    // Production toujours visible
    views.add(const ProductionScreen());

    if (visibleScreens['market'] == true) {
      views.add(const MarketScreen());
    }

    if (visibleScreens['upgrades'] == true) {
      views.add(const UpgradesScreen());
    }

    // Journal d'événements toujours visible
    views.add(const EventLogScreen());

    return views;
  }

  void _showAboutInfo(BuildContext context) {
    final notification = NotificationEvent(
      title: 'À propos',
      description: 'Version ${GameConstants.VERSION}',
      detailedDescription: """
PaperClip Game
Version ${GameConstants.VERSION}

Développé avec ❤️ par ${GameConstants.DEVELOPER}

Fonctionnalités:
• Production de trombones
• Gestion du marché
• Système d'améliorations
• Événements dynamiques

Dernière mise à jour: ${GameConstants.LAST_UPDATE}
""",
      icon: Icons.info,
      priority: NotificationPriority.LOW,
      additionalData: {
        'Version': GameConstants.VERSION,
        'Développeur': GameConstants.DEVELOPER,
        'Date de mise à jour': GameConstants.LAST_UPDATE,
      },
      canBeSuppressed: false,
    );

    NotificationManager.showGameNotification(
      context,
      event: notification,
    );
  }
}