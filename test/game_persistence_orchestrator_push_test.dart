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

  test('pushCloudById is marked pending when playerId is absent; succeeds when later available', () async {
    // Préparer un GameState minimal avec partieId et snapshot
    final state = GameState();
    state.initializeNewGame('Test Partie');
    // Forcer un partieId connu et un snapshot valide
    final pid = state.partieId!;
    // Injecter un snapshot en sauvegardant d'abord localement
    await const LocalGamePersistenceService().saveSnapshot(_makeSnapshot(), slotId: pid);

    // Injecter un faux port cloud
    final fakePort = _FakeCloudPort();
    GamePersistenceOrchestrator.instance.setCloudPort(fakePort);

    // Simuler absence de playerId -> pending
    GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async => null);

    // Déclencher un enregistrement standard (non backup) qui entraînera une tentative de push
    await GamePersistenceOrchestrator.instance.requestManualSave(state, reason: 'test');

    // Laisser la pompe asynchrone se dérouler
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final prefs = await SharedPreferences.getInstance();
    final pendingKey = 'pending_cloud_push_' + pid;
    expect(prefs.getBool(pendingKey), isTrue);
    expect(fakePort.pushCount, 0); // aucun push sans playerId

    // Maintenant simuler l'arrivée d'un playerId valide et relancer une sauvegarde
    GamePersistenceOrchestrator.instance.setPlayerIdProvider(() async => 'player-abc');
    await GamePersistenceOrchestrator.instance.requestManualSave(state, reason: 'retry');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Un push doit avoir eu lieu
    expect(fakePort.pushCount, greaterThan(0));
    // Et le pending doit être nettoyé
    expect(prefs.getBool(pendingKey), isNull);
  });
}
