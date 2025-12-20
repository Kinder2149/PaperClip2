import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/controllers/game_session_controller.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/auto_save_service.dart';
import 'package:paperclip2/services/game_runtime_coordinator.dart';
import 'package:paperclip2/services/lifecycle/app_lifecycle_handler.dart';
import 'package:paperclip2/services/metrics/runtime_metrics.dart';
import 'package:paperclip2/services/runtime/clock.dart';
import 'package:paperclip2/services/runtime/runtime_meta.dart';
import 'package:paperclip2/services/offline_progress_service.dart';
import '../util/fake_clock.dart';

class _FakeGameState extends GameState {
  int offlineCalls = 0;
  _FakeGameState({Clock? clock}) : super(clock: clock);

  @override
  OfflineProgressResult applyOfflineWithService({
    required DateTime now,
    DateTime? lastActiveAt,
    DateTime? lastOfflineAppliedAt,
  }) {
    offlineCalls++;
    return OfflineProgressResult(
      lastActiveAt: now,
      lastOfflineAppliedAt: now,
      offlineSpecVersion: 'v2',
      didSimulate: true,
    );
  }
}

class _FakeAutoSaveService extends AutoSaveService {
  _FakeAutoSaveService(GameState gs) : super(gs);
  @override
  Future<void> start() async {}
  @override
  void stop() {}
}

void main() {
  test('GameRuntimeCoordinator: recoverOffline is guarded against re-entrance', () async {
    final clock = FakeClock(DateTime.utc(2025, 1, 1, 12, 0, 0));
    final gs = _FakeGameState(clock: clock);
    final lifecycle = AppLifecycleHandler();
    final autoSave = _FakeAutoSaveService(gs);
    final controller = GameSessionController(gs, clock: clock);
    final coordinator = GameRuntimeCoordinator(
      gameState: gs,
      lifecycleHandler: lifecycle,
      autoSaveService: autoSave,
      gameSessionController: controller,
      clock: clock,
    );

    RuntimeMetrics.reset();
    RuntimeMetaRegistry.instance.reset();

    // Start two concurrent recoverOffline calls
    final f1 = coordinator.recoverOffline();
    final f2 = coordinator.recoverOffline();
    await Future.wait([f1, f2]);

    expect(gs.offlineCalls, 1);
    // Metrics should have at least one recoverOffline.count increment
    expect((RuntimeMetrics.counters['recoverOffline.count'] ?? 0) >= 1, isTrue);
  });
}
