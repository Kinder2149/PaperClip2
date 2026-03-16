import 'package:flutter/material.dart';
import 'package:paperclip2/services/offline_progress_service.dart';
import 'package:paperclip2/services/format/game_format.dart';

class OfflineProgressDialog extends StatelessWidget {
  final Duration absenceDuration;
  final double paperclipsProduced;
  final double moneyEarned;
  final bool wasCapped;

  const OfflineProgressDialog({
    Key? key,
    required this.absenceDuration,
    required this.paperclipsProduced,
    required this.moneyEarned,
    required this.wasCapped,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context,
    OfflineProgressResult result,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OfflineProgressDialog(
        absenceDuration: result.absenceDuration,
        paperclipsProduced: result.paperclipsProduced,
        moneyEarned: result.moneyEarned,
        wasCapped: result.wasCapped,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (totalMinutes == 0) {
      return '$seconds seconde${seconds > 1 ? 's' : ''}';
    } else {
      return '$totalMinutes minute${totalMinutes > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time,
              size: 48,
              color: wasCapped ? Colors.orange : theme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Bon retour !',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous étiez absent pendant',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDuration(absenceDuration),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            if (wasCapped) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Production limitée à 120 minutes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    context,
                    icon: Icons.attach_file,
                    label: 'Trombones produits',
                    value: GameFormat.quantityCompact(paperclipsProduced, decimals: 0),
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    context,
                    icon: Icons.euro,
                    label: 'Argent gagné',
                    value: GameFormat.money(moneyEarned, decimals: 2),
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
