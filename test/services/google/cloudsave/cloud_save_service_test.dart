import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/services/google/cloudsave/cloud_save_service.dart';
import 'package:paperclip2/services/google/cloudsave/cloud_save_adapter.dart';
import 'package:paperclip2/services/google/cloudsave/cloud_save_models.dart';

class _NoopAdapter implements CloudSaveAdapter {
  bool ready = true;
  final List<CloudSaveRecord> uploaded = [];
  final Map<String, CloudSaveRecord> byId = {};

  @override
  Future<bool> isReady() async => ready;

  @override
  Future<List<CloudSaveRecord>> listByOwner(String playerId) async =>
      uploaded.where((r) => r.owner.playerId == playerId).toList(growable: false);

  @override
  Future<CloudSaveRecord?> getById(String id) async => byId[id];

  @override
  Future<CloudSaveRecord> upload(CloudSaveRecord record) async {
    final rec = CloudSaveRecord(
      id: record.id ?? 'srv-${uploaded.length + 1}',
      owner: record.owner,
      payload: record.payload,
      meta: record.meta,
    );
    uploaded.add(rec);
    byId[rec.id!] = rec;
    return rec;
  }

  @override
  Future<void> label(String id, {required String label}) async {}
}

void main() {
  group('CloudSaveService', () {
    test('buildRecord matches model and uploads when ready', () async {
      final adapter = _NoopAdapter();
      final svc = CloudSaveService(adapter: adapter);

      final record = svc.buildRecord(
        playerId: 'P1',
        appVersion: '1.0.0',
        gameSnapshot: {
          'meta': {
            'timestamps': {'lastSavedAt': DateTime.now().toIso8601String()}
          }
        },
        displayData: CloudSaveDisplayData(
          money: 100,
          paperclips: 1000,
          autoClipperCount: 2,
          netProfit: 80,
        ),
        device: CloudSaveDeviceInfo(model: 'X', platform: 'android', locale: 'fr-FR'),
      );

      final uploaded = await svc.upload(record);
      expect(uploaded.id, isNotNull);
      expect(uploaded.owner.playerId, 'P1');
      expect(uploaded.payload.version, 'SAVE_SCHEMA_V1');
    });

    test('buildRecord throws when lastSavedAt is missing', () async {
      final adapter = _NoopAdapter();
      final svc = CloudSaveService(adapter: adapter);

      expect(
        () => svc.buildRecord(
          playerId: 'P1',
          appVersion: '1.0.0',
          gameSnapshot: {
            'meta': {
              'timestamps': {
                // missing lastSavedAt
              }
            }
          },
          displayData: CloudSaveDisplayData(
            money: 0,
            paperclips: 0,
            autoClipperCount: 0,
            netProfit: 0,
          ),
          device: CloudSaveDeviceInfo(model: 'X', platform: 'android', locale: 'fr-FR'),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('list and get by id', () async {
      final adapter = _NoopAdapter();
      final svc = CloudSaveService(adapter: adapter);

      final r1 = await svc.upload(svc.buildRecord(
        playerId: 'P2',
        appVersion: '1.0.0',
        gameSnapshot: {
          'meta': {
            'timestamps': {'lastSavedAt': DateTime.now().toIso8601String()}
          }
        },
        displayData: CloudSaveDisplayData(
          money: 1,
          paperclips: 2,
          autoClipperCount: 0,
          netProfit: 1,
        ),
        device: CloudSaveDeviceInfo(model: 'X', platform: 'android', locale: 'fr-FR'),
      ));
      final list = await svc.listByOwner('P2');
      expect(list.map((e) => e.id), contains(r1.id));

      final fetched = await svc.getById(r1.id!);
      expect(fetched?.id, r1.id);
    });

    test('recommendResolution prefers newer snapshot', () async {
      final adapter = _NoopAdapter();
      final svc = CloudSaveService(adapter: adapter);
      final now = DateTime.now();

      final local = {
        'meta': {
          'timestamps': {
            'lastSavedAt': now.add(const Duration(minutes: 1)).toIso8601String()
          }
        }
      };
      final cloud = CloudSaveRecord(
        id: 'id1',
        owner: CloudSaveOwner(provider: 'google', playerId: 'PX'),
        payload: CloudSavePayload(
          version: 'SAVE_SCHEMA_V1',
          snapshot: {
            'meta': {
              'timestamps': {'lastSavedAt': now.toIso8601String()}
            }
          },
          displayData: CloudSaveDisplayData(money: 0, paperclips: 0, autoClipperCount: 0, netProfit: 0),
        ),
        meta: CloudSaveMeta(
          appVersion: '1.0.0',
          createdAt: now,
          uploadedAt: now,
          device: CloudSaveDeviceInfo(model: 'X', platform: 'android', locale: 'fr-FR'),
        ),
      );

      final res = svc.recommendResolution(localSnapshot: local, cloud: cloud);
      expect(res, CloudConflictResolution.keepLocalCreateNewRevision);
    });

    test('recommendResolution prefers cloud when cloud newer', () async {
      final adapter = _NoopAdapter();
      final svc = CloudSaveService(adapter: adapter);
      final now = DateTime.now();

      final local = {
        'meta': {
          'timestamps': {
            'lastSavedAt': now.toIso8601String()
          }
        }
      };
      final cloud = CloudSaveRecord(
        id: 'id2',
        owner: CloudSaveOwner(provider: 'google', playerId: 'PX'),
        payload: CloudSavePayload(
          version: 'SAVE_SCHEMA_V1',
          snapshot: {
            'meta': {
              'timestamps': {'lastSavedAt': now.add(const Duration(minutes: 1)).toIso8601String()}
            }
          },
          displayData: CloudSaveDisplayData(money: 0, paperclips: 0, autoClipperCount: 0, netProfit: 0),
        ),
        meta: CloudSaveMeta(
          appVersion: '1.0.0',
          createdAt: now,
          uploadedAt: now,
          device: CloudSaveDeviceInfo(model: 'X', platform: 'android', locale: 'fr-FR'),
        ),
      );

      final res = svc.recommendResolution(localSnapshot: local, cloud: cloud);
      expect(res, CloudConflictResolution.importCloudReplaceLocal);
    });

    test('recommendResolution undecided when timestamps equal or missing', () async {
      final adapter = _NoopAdapter();
      final svc = CloudSaveService(adapter: adapter);
      final now = DateTime.now();

      // Equal timestamps
      final localEq = {
        'meta': {
          'timestamps': {
            'lastSavedAt': now.toIso8601String()
          }
        }
      };
      final cloudEq = CloudSaveRecord(
        id: 'id3',
        owner: CloudSaveOwner(provider: 'google', playerId: 'PX'),
        payload: CloudSavePayload(
          version: 'SAVE_SCHEMA_V1',
          snapshot: {
            'meta': {
              'timestamps': {'lastSavedAt': now.toIso8601String()}
            }
          },
          displayData: CloudSaveDisplayData(money: 0, paperclips: 0, autoClipperCount: 0, netProfit: 0),
        ),
        meta: CloudSaveMeta(
          appVersion: '1.0.0',
          createdAt: now,
          uploadedAt: now,
          device: CloudSaveDeviceInfo(model: 'X', platform: 'android', locale: 'fr-FR'),
        ),
      );
      expect(
        svc.recommendResolution(localSnapshot: localEq, cloud: cloudEq),
        CloudConflictResolution.undecided,
      );

      // Missing timestamps in local
      final localMissing = {
        'meta': {
          'timestamps': {
            // missing
          }
        }
      };
      expect(
        svc.recommendResolution(localSnapshot: localMissing, cloud: cloudEq),
        CloudConflictResolution.undecided,
      );
    });
  });
}
