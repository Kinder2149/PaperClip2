import 'package:flutter/material.dart';
import 'card_styles.dart';

class MarketCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onInfoPressed;
  final Widget? trailing;
  final Widget? subtitle;

  const MarketCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onInfoPressed,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CardStyles.marketCard(color: color),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    subtitle!,
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              onPressed: onInfoPressed,
              tooltip: tooltip,
            ),
          ],
        ),
      ),
    );
  }
} 