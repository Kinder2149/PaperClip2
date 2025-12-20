import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/controllers/game_session_controller.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/metrics/runtime_metrics.dart';
import '../util/fake_clock.dart';

void main() {
  test('GameSessionController: tick increments metrics when running, stops when paused, resumes after resume', () {
    final clock = FakeClock(DateTime.utc(2025, 1, 1, 12, 0, 0));
    final gameState = GameState(clock: clock);
    final controller = GameSessionController(gameState, clock: clock);

    // 1) Tick when running
    RuntimeMetrics.reset();
    controller.runProductionTickForTest();
    expect(RuntimeMetrics.counters['tick.count'], 1);

    // 2) Pause prevents tick
    controller.pauseSession();
    RuntimeMetrics.reset();
    controller.runProductionTickForTest();
    expect(RuntimeMetrics.counters['tick.count'] ?? 0, 0);

    // 3) Resume enables tick again
    controller.resumeSession();
    RuntimeMetrics.reset();
    // Advance clock to simulate interval
    clock.advance(const Duration(milliseconds: 1000));
    controller.runProductionTickForTest();
    expect(RuntimeMetrics.counters['tick.count'], 1);
  });
}
