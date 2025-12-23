import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:paperclip2/services/game_runtime_coordinator.dart';
import 'package:paperclip2/services/lifecycle/app_lifecycle_handler.dart';
import 'package:paperclip2/services/auto_save_service.dart';
import 'package:paperclip2/controllers/game_session_controller.dart';
import 'package:paperclip2/services/runtime/clock.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';

class _FakeClock implements Clock {
  DateTime _now;
  _FakeClock(this._now);
  @override
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

class _PortAheadRemoteSpy implements CloudPersistencePort {
  int statusCalls = 0;
  int pullCalls = 0;
  final Map<String, Map<String, dynamic>> snapsById;
  _PortAheadRemoteSpy(this.snapsById);

  @override
  Future<CloudStatus> statusById({required String partieId}) async {
    statusCalls++;
    return CloudStatus(partieId: partieId, syncState: 'ahead_remote', remoteVersion: 2);
    }

  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async {
    pullCalls++;
    final snap = snapsById[partieId];
    if (snap == null) return null;
    return {'snapshot': snap};
  }

  @override
  Future<void> pushById({required String partieId, required Map<String, dynamic> snapshot, required Map<String, dynamic> metadata}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resume triggers cloud pull when ahead_remote', () async {
    await dotenv.load(fileName: '.env', mergeWith: {'FEATURE_CLOUD_PER_PARTIE': 'true'});

    final clock = _FakeClock(DateTime.utc(2025, 1, 1, 12, 0, 0));
    final gs = GameState(clock: clock);
    gs.setPartieId('pid-resume-1');
    // Assure que AppLifecycleHandler ne court-circuite pas (gameName non null)
    gs.applyLoadedGameDataWithoutSnapshot('ResumePartie', <String, dynamic>{});

    final lifecycle = AppLifecycleHandler();
    final autoSave = AutoSaveService(gs);
    final session = GameSessionController(gs, clock: clock);

    final coord = GameRuntimeCoordinator(
      gameState: gs,
      lifecycleHandler: lifecycle,
      autoSaveService: autoSave,
      gameSessionController: session,
      clock: clock,
    );

    final port = _PortAheadRemoteSpy({
      'pid-resume-1': {
        'metadata': {'partieId': 'pid-resume-1'},
        'core': {'money': 77.0},
        'stats': {'paperclips': 10},
      }
    });
    GamePersistenceOrchestrator.instance.setCloudPort(port);

    await coord.register();

    lifecycle.didChangeAppLifecycleState(AppLifecycleState.resumed);

    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(port.statusCalls, greaterThanOrEqualTo(1));
    expect(port.pullCalls, greaterThanOrEqualTo(1));
  });
}
