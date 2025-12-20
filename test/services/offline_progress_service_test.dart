import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/game_state.dart';
import '../util/fake_clock.dart';

void main() {
  test('OfflineProgressService: delta > OFFLINE_MAX_DURATION is handled and simulated once', () {
    final start = DateTime.utc(2025, 1, 1, 12, 0, 0);
    final clock = FakeClock(start);
    final gs = GameState(clock: clock);

    // lastActive très ancien
    final veryOld = start.subtract(GameConstants.OFFLINE_MAX_DURATION * 10);

    // Appel
    final result = gs.applyOfflineWithService(
      now: clock.now(),
      lastActiveAt: veryOld,
      lastOfflineAppliedAt: null,
    );

    expect(result.didSimulate, isTrue);
    expect(result.lastActiveAt, clock.now());
    expect(result.lastOfflineAppliedAt, clock.now());
  });

  test('OfflineProgressService: delta <= 0 does not simulate', () {
    final start = DateTime.utc(2025, 1, 1, 12, 0, 0);
    final clock = FakeClock(start);
    final gs = GameState(clock: clock);

    final result = gs.applyOfflineWithService(
      now: clock.now(),
      lastActiveAt: clock.now(),
      lastOfflineAppliedAt: clock.now(),
    );

    expect(result.didSimulate, isFalse);
    expect(result.lastActiveAt, clock.now());
    // lastOfflineAppliedAt should remain the same (not "now") in the zero-delta branch
    expect(result.lastOfflineAppliedAt.isAtSameMomentAs(clock.now()), isTrue);
  });
}
