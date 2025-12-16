import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/lifecycle/app_lifecycle_handler.dart';

class _FakeSavePort {
  int calls = 0;
  String? lastReason;

  Future<void> save({required String reason}) async {
    calls++;
    lastReason = reason;
  }
}

class _FakeGameState extends GameState {
  int offlineAppliedCalls = 0;

  @override
  void applyOfflineProgressV2({DateTime? nowOverride}) {
    offlineAppliedCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLifecycleHandler (P0)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('paused déclenche requestLifecycleSave avec reason', () async {
      final persistence = _FakeSavePort();
      final now = DateTime(2025, 1, 1, 12, 0, 0);

      final handler = AppLifecycleHandler(
        onLifecycleSave: persistence.save,
        now: () => now,
      );

      final state = GameState();
      state.initialize();
      await state.startNewGame('lifecycle-test');

      handler.register(state);

      handler.didChangeAppLifecycleState(AppLifecycleState.paused);

      expect(persistence.calls, 1);
      expect(persistence.lastReason, 'app_lifecycle_paused');

      handler.unregister();
      state.dispose();
    });

    test('inactive déclenche requestLifecycleSave avec reason', () async {
      final persistence = _FakeSavePort();

      final handler = AppLifecycleHandler(
        onLifecycleSave: persistence.save,
        now: () => DateTime(2025, 1, 1),
      );

      final state = GameState();
      state.initialize();
      await state.startNewGame('lifecycle-test');

      handler.register(state);

      handler.didChangeAppLifecycleState(AppLifecycleState.inactive);

      expect(persistence.calls, 1);
      expect(persistence.lastReason, 'app_lifecycle_inactive');

      handler.unregister();
      state.dispose();
    });

    test('resumed appelle applyOfflineProgressV2', () async {
      final persistence = _FakeSavePort();
      final handler = AppLifecycleHandler(
        onLifecycleSave: persistence.save,
        now: () => DateTime(2025, 1, 1),
      );

      final state = _FakeGameState();
      state.initialize();
      await state.startNewGame('lifecycle-test');

      handler.register(state);

      handler.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(state.offlineAppliedCalls, 1);
      expect(persistence.calls, 0);

      handler.unregister();
      state.dispose();
    });

    test('ignore si gameName null', () {
      final persistence = _FakeSavePort();
      final handler = AppLifecycleHandler(
        onLifecycleSave: persistence.save,
        now: () => DateTime(2025, 1, 1),
      );

      final state = GameState();
      state.initialize();
      // gameName null

      handler.register(state);

      handler.didChangeAppLifecycleState(AppLifecycleState.paused);
      handler.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(persistence.calls, 0);

      handler.unregister();
      state.dispose();
    });
  });
}
