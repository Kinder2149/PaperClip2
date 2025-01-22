import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import 'package:paperclip2/models/level_system.dart';

class LevelDisplay extends StatelessWidget {
  const LevelDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Niveau ${gameState.levelSystem.level}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => showLevelInfo(context, gameState),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: gameState.levelSystem.experienceProgress,
                    minHeight: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'XP: ${gameState.levelSystem.experience.floor()} / ${gameState.levelSystem.experienceForNextLevel.floor()}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showLevelInfo(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations de niveau'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Niveau actuel: ${gameState.levelSystem.level}'),
            const SizedBox(height: 8),
            Text('Bonus de production: +${((gameState.levelSystem.productionMultiplier - 1) * 100).toStringAsFixed(1)}%'),
            Text('Bonus de vente: +${((gameState.levelSystem.salesMultiplier - 1) * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 16),
            const Text(
              'Gains d\'expérience :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Production manuelle : 0.1 XP'),
            const Text('• Production auto : 0.05 XP × quantité'),
            const Text('• Vente : 0.2 XP × quantité (plafonné à 5)'),
            const Text('• Achat autoclipper : 2 XP'),
            const Text('• Amélioration : 1 XP × niveau'),
            const SizedBox(height: 16),
            const Text(
              'Progression de niveau :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Courbe exponentielle : 50 * 2.5^niveau + (niveau² * 10)'),
          ],
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

}
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
                          offset: Offset(0, 4)
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