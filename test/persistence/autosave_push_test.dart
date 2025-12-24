import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import '../util/fake_clock.dart';

class _SpyPort implements CloudPersistencePort {
  int pushCount = 0;
  @override
  Future<void> pushById({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    pushCount++;
  }

  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async => null;

  @override
  Future<CloudStatus> statusById({required String partieId}) async => CloudStatus(partieId: partieId, syncState: 'in_sync');

  @override
  Future<List<CloudIndexEntry>> listParties() async => <CloudIndexEntry>[];

  @override
  Future<void> deleteById({required String partieId}) async {}
}

void main() {
  group('Autosave triggers cloud push', () {
    setUp(() {
      GamePersistenceOrchestrator.instance.resetForTesting();
      // Fournir un playerId pour activer le push auto
      GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async => 'player-test');
    });

    test('requestAutoSave → push once for non-backup save', () async {
      final clock = FakeClock(DateTime.utc(2025, 1, 1, 12));
      final gs = GameState(clock: clock);
      gs.setPartieId('pid-auto-1');
      final port = _SpyPort();
      GamePersistenceOrchestrator.instance.setCloudPort(port);

      await GamePersistenceOrchestrator.instance.requestAutoSave(gs, reason: 'test');
      // Laisser la pompe terminer
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(port.pushCount, greaterThanOrEqualTo(1));
    });
  });
}
