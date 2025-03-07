import 'package:flutter/material.dart';
import 'card_styles.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final Widget content;
  final Color color;
  final VoidCallback? onInfoPressed;
  final Widget? trailing;

  const InfoCard({
    super.key,
    required this.title,
    required this.content,
    required this.color,
    this.onInfoPressed,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CardStyles.infoCard(color: color),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onInfoPressed != null) ...[
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: onInfoPressed,
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
            const Divider(),
            content,
          ],
        ),
      ),
    );
  }
} 