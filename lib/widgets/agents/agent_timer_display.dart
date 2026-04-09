// lib/widgets/agents/agent_timer_display.dart

import 'dart:async';
import 'package:flutter/material.dart';

/// Widget affichant un timer countdown pour un agent actif
class AgentTimerDisplay extends StatefulWidget {
  final DateTime expiresAt;
  final bool compact;

  const AgentTimerDisplay({
    Key? key,
    required this.expiresAt,
    this.compact = false,
  }) : super(key: key);

  @override
  State<AgentTimerDisplay> createState() => _AgentTimerDisplayState();
}

class _AgentTimerDisplayState extends State<AgentTimerDisplay> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateRemainingTime();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemainingTime() {
    setState(() {
      final now = DateTime.now();
      _remainingTime = widget.expiresAt.difference(now);
      if (_remainingTime.isNegative) {
        _remainingTime = Duration.zero;
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Color _getTimerColor() {
    final totalMinutes = _remainingTime.inMinutes;
    
    if (totalMinutes > 30) {
      return Colors.green;
    } else if (totalMinutes > 10) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  double _getProgress() {
    const totalDuration = Duration(hours: 1);
    final elapsed = totalDuration - _remainingTime;
    return elapsed.inSeconds / totalDuration.inSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTimerColor();
    final progress = _getProgress();

    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(_remainingTime),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  'restant',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ],
        ),
      );
    }

    // Mode non-compact (pour dialog ou détails)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timer, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              'Temps restant: ${_formatDuration(_remainingTime)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
