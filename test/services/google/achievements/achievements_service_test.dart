import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/services/google/achievements/achievements_service.dart';
import 'package:paperclip2/services/google/achievements/achievements_adapter.dart';
import 'package:paperclip2/services/google/achievements/achievements_mapper.dart';
import 'package:paperclip2/services/google/achievements/achievements_keys.dart';

class _ReadyAdapter implements AchievementsAdapter {
  final List<String> unlocked = [];
  bool ready = true;
  @override
  Future<bool> isReady() async => ready;
  @override
  Future<void> unlock(String achievementKey) async {
    unlocked.add(achievementKey);
  }
}

void main() {
  group('AchievementsService', () {
    test('maps and unlocks when adapter ready', () async {
      final adapter = _ReadyAdapter();
      final svc = AchievementsService(adapter: adapter, mapper: AchievementsMapper());

      await svc.handleEvent('production.total_clips', {'total': 12000});
      expect(adapter.unlocked.contains(AchievementKeys.totalClips10k), isTrue);
    });

    test('queues when not ready then flushes later', () async {
      final adapter = _ReadyAdapter()..ready = false;
      final svc = AchievementsService(adapter: adapter, mapper: AchievementsMapper());

      await svc.handleEvent('level.reached', {'level': 5});
      expect(adapter.unlocked, isEmpty);

      adapter.ready = true;
      await svc.tryFlush();
      expect(adapter.unlocked.contains(AchievementKeys.level5), isTrue);
    });

    test('deduplicates within session', () async {
      final adapter = _ReadyAdapter();
      final svc = AchievementsService(adapter: adapter, mapper: AchievementsMapper());

      await svc.handleEvent('production.total_clips', {'total': 100000});
      await svc.handleEvent('production.total_clips', {'total': 100000});
      await svc.tryFlush();

      // Clé 100k doit apparaître au plus une fois
      expect(adapter.unlocked.where((k) => k == AchievementKeys.totalClips100k).length, 1);
    });
  });
}
