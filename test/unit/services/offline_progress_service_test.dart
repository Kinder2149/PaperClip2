import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/offline_progress_service.dart';
import 'package:paperclip2/gameplay/game_engine.dart';
import 'package:paperclip2/managers/player_manager.dart';
import 'package:paperclip2/managers/market_manager.dart';
import 'package:paperclip2/managers/production_manager.dart';
import 'package:paperclip2/models/level_system.dart';
import 'package:paperclip2/models/statistics_manager.dart';
import 'package:paperclip2/services/progression/progression_rules_service.dart';
import 'package:paperclip2/gameplay/events/bus/game_event_bus.dart';

class _FakeEngine extends GameEngine {
  _FakeEngine()
      : super(
          player: PlayerManager(),
          market: MarketManager(),
          production: ProductionManager(
            playerManager: PlayerManager(),
            statistics: StatisticsManager(),
            levelSystem: LevelSystem(),
          ),
          level: LevelSystem(),
          statistics: StatisticsManager(),
          progressionRules: ProgressionRulesService(
            levelSystem: LevelSystem(),
            playerManager: PlayerManager(),
          ),
          eventBus: GameEventBus(),
        );

  int tickCalls = 0;
  double seconds = 0;

  @override
  void tick({required double elapsedSeconds, required bool autoSellEnabled}) {
    tickCalls++;
    seconds += elapsedSeconds;
  }
}

void main() {
  group('OfflineProgressService.apply', () {
    test('returns didSimulate=false when base is null', () {
      final engine = _FakeEngine();
      final now = DateTime(2025, 1, 1, 12);
      final result = OfflineProgressService.apply(
        engine: engine,
        autoSellEnabled: false,
        lastActiveAt: null,
        lastOfflineAppliedAt: null,
        nowOverride: now,
      );
      expect(result.didSimulate, isFalse);
      expect(result.lastActiveAt, now);
      expect(result.lastOfflineAppliedAt, now);
      expect(result.offlineSpecVersion, 'v2');
      expect(engine.tickCalls, 0);
    });

    test('returns didSimulate=false when delta <= 0', () {
      final engine = _FakeEngine();
      final now = DateTime(2025, 1, 1, 12);
      final result = OfflineProgressService.apply(
        engine: engine,
        autoSellEnabled: false,
        lastActiveAt: now,
        lastOfflineAppliedAt: null,
        nowOverride: now,
      );
      expect(result.didSimulate, isFalse);
      expect(engine.tickCalls, 0);
    });

    test('simulates when positive delta and aggregates seconds', () {
      final engine = _FakeEngine();
      final last = DateTime(2025, 1, 1, 12, 0, 0);
      final now = DateTime(2025, 1, 1, 12, 0, 7);
      final result = OfflineProgressService.apply(
        engine: engine,
        autoSellEnabled: true,
        lastActiveAt: last,
        lastOfflineAppliedAt: null,
        nowOverride: now,
      );
      expect(result.didSimulate, isTrue);
      expect(engine.seconds, closeTo(7.0, 0.0001));
      expect(engine.tickCalls, greaterThanOrEqualTo(1));
      expect(result.offlineSpecVersion, 'v2');
    });
  });
}
