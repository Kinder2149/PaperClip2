import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/models/game_state.dart';

class _FakeCloudPort implements CloudPersistencePort {
  int pushCount = 0;
  Map<String, dynamic>? lastSnapshot;
  Map<String, dynamic>? lastMetadata;

  @override
  Future<void> deleteById({required String partieId}) async {}

  @override
  Future<List<CloudIndexEntry>> listParties() async => <CloudIndexEntry>[];

  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async => null;

  @override
  Future<void> pushById({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    pushCount++;
    lastSnapshot = snapshot;
    lastMetadata = metadata;
  }

  @override
  Future<CloudStatus> statusById({required String partieId}) async => CloudStatus(partieId: partieId, syncState: 'unknown');
}

GameSnapshot _makeSnapshot() => GameSnapshot(
      metadata: {
        'snapshotSchemaVersion': 1,
        'lastActiveAt': DateTime.now().toIso8601String(),
      },
      core: {
        'paperclips': 1,
        'money': 0.0,
      },
      market: const {},
      production: const {},
      stats: const {},
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    GamePersistenceOrchestrator.instance.resetForTesting();
  });

  test('pending push without playerId then retryPendingCloudPushes succeeds when playerId appears', () async {
    // Créer une sauvegarde locale snapshot-only sous un ID connu
    final pid = 'push-test-1';
    await const LocalGamePersistenceService().saveSnapshot(_makeSnapshot(), slotId: pid);

    // Port cloud factice
    final fakePort = _FakeCloudPort();
    GamePersistenceOrchestrator.instance.setCloudPort(fakePort);

    // Marquer pending manuellement (simulateur d'un push raté faute d'identité)
    final prefs = await SharedPreferences.getInstance();
    final pendingKey = 'pending_cloud_push_' + pid;
    await prefs.setBool(pendingKey, true);
    expect(fakePort.pushCount, 0);

    // Fournir un playerId désormais disponible et relancer la mécanique de retry
    GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async => 'player-abc');
    await GamePersistenceOrchestrator.instance.retryPendingCloudPushes();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Vérifier qu'un push a été effectué et que le flag est nettoyé
    expect(fakePort.pushCount, greaterThan(0));
    expect(prefs.getBool(pendingKey), isNull);
  });
}
