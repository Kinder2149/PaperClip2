import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import '../util/fake_clock.dart';

class _PerPartiePort implements CloudPersistencePort {
  final Map<String, CloudStatus> _statusById = {};
  final Map<String, Map<String, dynamic>> _snapshotById = {};
  final Map<String, int> pushCountById = {};

  void setStatus(String id, CloudStatus status) => _statusById[id] = status;
  void setSnapshot(String id, Map<String, dynamic> snapshot) => _snapshotById[id] = snapshot;

  @override
  Future<CloudStatus> statusById({required String partieId}) async => _statusById[partieId] ?? CloudStatus(partieId: partieId, syncState: 'unknown');

  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async {
    final snap = _snapshotById[partieId];
    if (snap == null) return null;
    return {'snapshot': snap};
  }

  @override
  Future<void> pushById({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    pushCountById.update(partieId, (v) => v + 1, ifAbsent: () => 1);
  }
}

void main() {
  group('Multi-parties isolation (per-partie cloud)', () {
    setUp(() {
      GamePersistenceOrchestrator.instance.resetForTesting();
    });

    test('status & pull are isolated per partieId', () async {
      final port = _PerPartiePort();
      port.setStatus('A', const CloudStatus(partieId: 'A', syncState: 'ahead_remote', remoteVersion: 2));
      port.setStatus('B', const CloudStatus(partieId: 'B', syncState: 'in_sync', remoteVersion: 1));
      port.setSnapshot('A', {
        'metadata': {'partieId': 'A'},
        'core': {'money': 100},
      });
      GamePersistenceOrchestrator.instance.setCloudPort(port);

      final sA = await GamePersistenceOrchestrator.instance.cloudStatusById(partieId: 'A');
      final sB = await GamePersistenceOrchestrator.instance.cloudStatusById(partieId: 'B');
      expect(sA.syncState, 'ahead_remote');
      expect(sB.syncState, 'in_sync');

      final pA = await GamePersistenceOrchestrator.instance.pullCloudById(partieId: 'A');
      final pB = await GamePersistenceOrchestrator.instance.pullCloudById(partieId: 'B');
      expect(pA, isNotNull);
      expect(pB, isNull);
    });

    test('autosave pushes only for the targeted partieId', () async {
      final clock = FakeClock(DateTime.utc(2025, 1, 1, 10));
      final gsA = GameState(clock: clock)..setPartieId('A');
      final gsB = GameState(clock: clock)..setPartieId('B');
      final port = _PerPartiePort();
      GamePersistenceOrchestrator.instance.setCloudPort(port);

      // Autosave A uniquement
      await GamePersistenceOrchestrator.instance.requestAutoSave(gsA, reason: 'multi');
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(port.pushCountById['A'] ?? 0, greaterThanOrEqualTo(1));
      expect(port.pushCountById['B'] ?? 0, 0);

      // Autosave B ensuite
      await GamePersistenceOrchestrator.instance.requestAutoSave(gsB, reason: 'multi');
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(port.pushCountById['B'] ?? 0, greaterThanOrEqualTo(1));
    });
  });
}
