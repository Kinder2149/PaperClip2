import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/gameplay/game_engine.dart';

class OfflineProgressResult {
  final DateTime lastActiveAt;
  final DateTime lastOfflineAppliedAt;
  final String offlineSpecVersion;
  final bool didSimulate;

  const OfflineProgressResult({
    required this.lastActiveAt,
    required this.lastOfflineAppliedAt,
    required this.offlineSpecVersion,
    required this.didSimulate,
  });
}

class OfflineProgressService {
  static OfflineProgressResult apply({
    required GameEngine engine,
    required bool autoSellEnabled,
    required DateTime? lastActiveAt,
    required DateTime? lastOfflineAppliedAt,
    DateTime? nowOverride,
  }) {
    final now = nowOverride ?? DateTime.now();

    final candidates = <DateTime?>[lastActiveAt, lastOfflineAppliedAt];
    DateTime? base;
    for (final v in candidates) {
      if (v == null) continue;
      if (base == null || v.isAfter(base)) base = v;
    }

    if (base == null) {
      return OfflineProgressResult(
        lastActiveAt: now,
        lastOfflineAppliedAt: now,
        offlineSpecVersion: 'v2',
        didSimulate: false,
      );
    }

    var delta = now.difference(base);
    if (delta.isNegative || delta.inSeconds <= 0) {
      return OfflineProgressResult(
        lastActiveAt: now,
        lastOfflineAppliedAt: lastOfflineAppliedAt ?? base,
        offlineSpecVersion: 'v2',
        didSimulate: false,
      );
    }

    if (delta > GameConstants.OFFLINE_MAX_DURATION) {
      delta = GameConstants.OFFLINE_MAX_DURATION;
    }

    // Simulation par pas (<= 10s)
    double remainingSeconds = delta.inMilliseconds / 1000.0;
    const double maxStepSeconds = 10.0;
    while (remainingSeconds > 0) {
      final step = remainingSeconds > maxStepSeconds ? maxStepSeconds : remainingSeconds;
      engine.tick(
        elapsedSeconds: step,
        autoSellEnabled: autoSellEnabled,
      );
      remainingSeconds -= step;
    }

    return OfflineProgressResult(
      lastActiveAt: now,
      lastOfflineAppliedAt: now,
      offlineSpecVersion: 'v2',
      didSimulate: true,
    );
  }
}
