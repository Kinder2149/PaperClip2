import 'package:flutter/material.dart';

enum PrioriteNotification {
  basse,
  moyenne,
  haute,
  critique
}

class NotificationToast extends StatelessWidget {
  final String message;
  final PrioriteNotification priorite;
  final IconData? icone;
  final VoidCallback? onTap;
  final Duration duree;

  const NotificationToast({
    Key? key,
    required this.message,
    this.priorite = PrioriteNotification.basse,
    this.icone,
    this.onTap,
    this.duree = const Duration(seconds: 4),
  }) : super(key: key);

  Color _getCouleurPriorite(BuildContext context) {
    final theme = Theme.of(context);
    switch (priorite) {
      case PrioriteNotification.basse:
        return Colors.blue;
      case PrioriteNotification.moyenne:
        return Colors.orange;
      case PrioriteNotification.haute:
        return Colors.deepOrange;
      case PrioriteNotification.critique:
        return theme.colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final couleur = _getCouleurPriorite(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: couleur.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (icone != null) ...[
                  Icon(
                    icone,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    // Fermer la notification
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void afficher(
    BuildContext context, {
    required String message,
    PrioriteNotification priorite = PrioriteNotification.basse,
    IconData? icone,
    VoidCallback? onTap,
    Duration? duree,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        child: NotificationToast(
          message: message,
          priorite: priorite,
          icone: icone,
          onTap: onTap,
          duree: duree ?? const Duration(seconds: 4),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duree ?? const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }
} 