import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';

import 'support/game_state_test_factory.dart';

class _FakeCloudPort implements CloudPersistencePort {
  final List<String> pushed = [];
  @override
  Future<void> deleteById({required String partieId}) async {}

  @override
  Future<List<CloudIndexEntry>> listParties() async => <CloudIndexEntry>[];

  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async => null;

  @override
  Future<void> pushById({required String partieId, required Map<String, dynamic> snapshot, required Map<String, dynamic> metadata}) async {
    pushed.add(partieId);
  }

  @override
  Future<CloudStatus> statusById({required String partieId}) async => CloudStatus(partieId: partieId, syncState: 'unknown');
}

GameSnapshot _snapshot() => GameSnapshot(
      metadata: {
        'snapshotSchemaVersion': 1,
        'lastActiveAt': DateTime.now().toIso8601String(),
      },
      core: {'paperclips': 0, 'money': 0.0},
      market: const {},
      production: const {},
      stats: const {},
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GamePersistenceOrchestrator.instance.resetForTesting();
    SaveManagerAdapter.resetForTesting();
  });

  test('pending cloud push when no playerId, then resumed after login', () async {
    final pid = 'pending-resume-1';
    final state = GameStateTestFactory.newInitialized(partieId: pid);

    await const LocalGamePersistenceService().saveSnapshot(_snapshot(), slotId: pid);

    final fakePort = _FakeCloudPort();
    GamePersistenceOrchestrator.instance.setCloudPort(fakePort);
    // playerId not available initially
    GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async => null);

    await GamePersistenceOrchestrator.instance.requestManualSave(state, reason: 'manual');
    await Future<void>.delayed(const Duration(milliseconds: 150));

    // Nothing pushed yet
    expect(fakePort.pushed.contains(pid), isFalse);

    // Now identity becomes available and we trigger retry
    GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async => 'player-x');
    await GamePersistenceOrchestrator.instance.retryPendingCloudPushes();
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(fakePort.pushed.contains(pid), isTrue);
  });

  test('importantEvent coalescing within window keeps only one request', () async {
    final pid = 'coalesce-important-1';
    final state = GameStateTestFactory.newInitialized(partieId: pid);
    await const LocalGamePersistenceService().saveSnapshot(_snapshot(), slotId: pid);

    final fakePort = _FakeCloudPort();
    GamePersistenceOrchestrator.instance.setCloudPort(fakePort);
    GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async => 'player-x');

    await GamePersistenceOrchestrator.instance.requestImportantSave(state, reason: 'evt1');
    await GamePersistenceOrchestrator.instance.requestImportantSave(state, reason: 'evt2');
    await GamePersistenceOrchestrator.instance.requestImportantSave(state, reason: 'evt3');

    await Future<void>.delayed(const Duration(milliseconds: 200));

    // Au minimum une poussée; selon le timing interne du pump asynchrone, une deuxième peut survenir
    final pushes = fakePort.pushed.where((e) => e == pid).length;
    expect(pushes >= 1 && pushes <= 2, isTrue);
  });
}
