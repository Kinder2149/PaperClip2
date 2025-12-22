import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/services/google/achievements/achievements_service.dart';
import 'package:paperclip2/services/google/achievements/achievements_adapter.dart';
import 'package:paperclip2/services/google/achievements/achievements_mapper.dart';
import 'package:paperclip2/services/google/leaderboards/leaderboards_service.dart';
import 'package:paperclip2/services/google/leaderboards/leaderboards_adapter.dart';
import 'package:paperclip2/services/google/leaderboards/leaderboards_mapper.dart';
import 'package:paperclip2/services/google/cloudsave/cloud_save_service.dart';
import 'package:paperclip2/services/google/cloudsave/cloud_save_adapter.dart';
import 'package:paperclip2/services/google/cloudsave/cloud_save_models.dart';
import 'package:paperclip2/services/google/sync/sync_orchestrator.dart';
import 'package:paperclip2/services/google/sync/sync_readiness_port.dart';

class _AchievementsMemAdapter implements AchievementsAdapter {
  bool ready = true;
  final List<String> unlocked = [];
  @override
  Future<bool> isReady() async => ready;
  @override
  Future<void> unlock(String achievementKey) async {
    unlocked.add(achievementKey);
  }
}

class _LeaderboardsMemAdapter implements LeaderboardsAdapter {
  bool ready = true;
  final Map<String, int> submitted = {};
  @override
  Future<bool> isReady() async => ready;
  @override
  Future<void> submitScore(String leaderboardKey, int score) async {
    submitted[leaderboardKey] = score;
  }
}

class _CloudMemAdapter implements CloudSaveAdapter {
  bool ready = true;
  final List<CloudSaveRecord> uploaded = [];
  @override
  Future<bool> isReady() async => ready;
  @override
  Future<CloudSaveRecord?> getById(String id) async => null;
  @override
  Future<List<CloudSaveRecord>> listByOwner(String playerId) async => const [];
  @override
  Future<void> label(String id, {required String label}) async {}
  @override
  Future<CloudSaveRecord> upload(CloudSaveRecord record) async {
    uploaded.add(record);
    return record;
  }
}

class _Readiness implements SyncReadinessPort {
  bool allow = true;
  @override
  Future<bool> hasNetwork() async => allow;
  @override
  Future<bool> isSyncAllowed() async => allow;
}

void main() {
  group('GoogleSyncOrchestrator', () {
    test('processQueues routes to services when readiness ok', () async {
      final achAdapter = _AchievementsMemAdapter();
      final lbAdapter = _LeaderboardsMemAdapter();
      final cloudAdapter = _CloudMemAdapter();

      final achievements = AchievementsService(adapter: achAdapter, mapper: AchievementsMapper());
      final leaderboards = LeaderboardsService(adapter: lbAdapter, mapper: LeaderboardsMapper(), minSubmitInterval: Duration.zero);
      final cloud = CloudSaveService(adapter: cloudAdapter);
      final ready = _Readiness()..allow = true;

      final orch = GoogleSyncOrchestrator(
        achievements: achievements,
        leaderboards: leaderboards,
        cloud: cloud,
        readiness: ready,
      );

      orch.enqueueAchievementEvent(eventId: 'production.total_clips', payload: {'total': 15000});
      orch.enqueueLeaderboardEvent(eventId: 'economy.net_profit', payload: {'value': 42});
      orch.enqueueCloudPush(
        record: cloud.buildRecord(
          playerId: 'P',
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
        ),
      );

      await orch.processQueues();

      expect(achAdapter.unlocked, isNotEmpty);
      expect(lbAdapter.submitted.containsKey('lb_net_profit'), isTrue);
      expect(cloudAdapter.uploaded.length, 1);
    });

    test('readiness blocks processing', () async {
      final achAdapter = _AchievementsMemAdapter();
      final lbAdapter = _LeaderboardsMemAdapter();
      final cloudAdapter = _CloudMemAdapter();

      final achievements = AchievementsService(adapter: achAdapter, mapper: AchievementsMapper());
      final leaderboards = LeaderboardsService(adapter: lbAdapter, mapper: LeaderboardsMapper());
      final cloud = CloudSaveService(adapter: cloudAdapter);
      final ready = _Readiness()..allow = false;

      final orch = GoogleSyncOrchestrator(
        achievements: achievements,
        leaderboards: leaderboards,
        cloud: cloud,
        readiness: ready,
      );

      orch.enqueueAchievementEvent(eventId: 'level.reached', payload: {'level': 5});
      await orch.processQueues();
      expect(achAdapter.unlocked, isEmpty);
    });
  });
}
