import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/gameplay/game_engine.dart';
import 'package:paperclip2/managers/research_manager.dart';

class OfflineProgressResult {
  final DateTime lastActiveAt;
  final DateTime lastOfflineAppliedAt;
  final String offlineSpecVersion;
  final bool didSimulate;
  final Duration absenceDuration;
  final double paperclipsProduced;
  final double moneyEarned;
  final bool wasCapped;

  const OfflineProgressResult({
    required this.lastActiveAt,
    required this.lastOfflineAppliedAt,
    required this.offlineSpecVersion,
    required this.didSimulate,
    required this.absenceDuration,
    required this.paperclipsProduced,
    required this.moneyEarned,
    required this.wasCapped,
  });
}

class OfflineProgressService {
  static OfflineProgressResult apply({
    required GameEngine engine,
    required bool autoSellEnabled,
    required DateTime? lastActiveAt,
    required DateTime? lastOfflineAppliedAt,
    DateTime? nowOverride,
    ResearchManager? researchManager,
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
        absenceDuration: Duration.zero,
        paperclipsProduced: 0.0,
        moneyEarned: 0.0,
        wasCapped: false,
      );
    }

    var delta = now.difference(base);
    if (delta.isNegative || delta.inSeconds <= 0) {
      return OfflineProgressResult(
        lastActiveAt: now,
        lastOfflineAppliedAt: lastOfflineAppliedAt ?? base,
        offlineSpecVersion: 'v2',
        didSimulate: false,
        absenceDuration: Duration.zero,
        paperclipsProduced: 0.0,
        moneyEarned: 0.0,
        wasCapped: false,
      );
    }

    final actualDelta = delta;
    final wasCapped = delta > GameConstants.OFFLINE_MAX_DURATION;
    if (wasCapped) {
      delta = GameConstants.OFFLINE_MAX_DURATION;
    }

    final initialPaperclips = engine.player.paperclips;
    final initialMoney = engine.player.money;

    // Simulation par pas (<= 10s)
    // CHANTIER-03 : Appliquer bonus recherche offlineProduction (META6)
    final offlineBonus = researchManager?.getResearchBonus('offlineProduction') ?? 0.0;
    
    double remainingSeconds = delta.inMilliseconds / 1000.0;
    const double maxStepSeconds = 10.0;
    while (remainingSeconds > 0) {
      final step = remainingSeconds > maxStepSeconds ? maxStepSeconds : remainingSeconds;
      final adjustedStep = step * (1.0 + offlineBonus);
      engine.tick(
        elapsedSeconds: adjustedStep,
        autoSellEnabled: autoSellEnabled,
      );
      remainingSeconds -= step;
    }

    final paperclipsProduced = engine.player.paperclips - initialPaperclips;
    final moneyEarned = engine.player.money - initialMoney;

    return OfflineProgressResult(
      lastActiveAt: now,
      lastOfflineAppliedAt: now,
      offlineSpecVersion: 'v2',
      didSimulate: true,
      absenceDuration: actualDelta,
      paperclipsProduced: paperclipsProduced,
      moneyEarned: moneyEarned,
      wasCapped: wasCapped,
    );
  }
}
