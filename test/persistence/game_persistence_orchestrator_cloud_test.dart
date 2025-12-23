import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/cloud/cloud_persistence_port.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';

class _FakePort implements CloudPersistencePort {
  CloudStatus status;
  Map<String, Map<String, dynamic>?> pulls = {};
  List<Map<String, dynamic>> pushes = [];

  _FakePort({required this.status});

  @override
  Future<CloudStatus> statusById({required String partieId}) async {
    return status;
  }

  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async {
    return pulls[partieId];
  }

  @override
  Future<void> pushById({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    pushes.add({
      'partieId': partieId,
      'snapshot': snapshot,
      'metadata': metadata,
    });
  }
}

void main() {
  group('GamePersistenceOrchestrator cloud port interactions', () {
    setUp(() {
      GamePersistenceOrchestrator.instance.resetForTesting();
    });

    test('cloudStatusById throws when no port configured', () async {
      expect(
        () => GamePersistenceOrchestrator.instance.cloudStatusById(partieId: 'p1'),
        throwsA(isA<StateError>()),
      );
    });

    test('pullCloudById throws when no port configured', () async {
      expect(
        () => GamePersistenceOrchestrator.instance.pullCloudById(partieId: 'p1'),
        throwsA(isA<StateError>()),
      );
    });

    test('cloudStatusById returns value from configured port', () async {
      final port = _FakePort(
        status: const CloudStatus(partieId: 'p1', syncState: 'in_sync', remoteVersion: 3),
      );
      GamePersistenceOrchestrator.instance.setCloudPort(port);
      final s = await GamePersistenceOrchestrator.instance.cloudStatusById(partieId: 'p1');
      expect(s.partieId, 'p1');
      expect(s.syncState, 'in_sync');
      expect(s.remoteVersion, 3);
    });

    test('pullCloudById returns payload from configured port', () async {
      final fake = _FakePort(
        status: const CloudStatus(partieId: 'p1', syncState: 'ahead_remote', remoteVersion: 4),
      );
      fake.pulls['p1'] = {
        'snapshot': {
          'metadata': {'partieId': 'p1'},
          'core': {'money': 42},
        }
      };
      GamePersistenceOrchestrator.instance.setCloudPort(fake);
      final obj = await GamePersistenceOrchestrator.instance.pullCloudById(partieId: 'p1');
      expect(obj, isNotNull);
      expect(obj!['snapshot'], isA<Map<String, dynamic>>());
      final snap = obj['snapshot'] as Map<String, dynamic>;
      expect(snap['core'], containsPair('money', 42));
    });
  });
}
