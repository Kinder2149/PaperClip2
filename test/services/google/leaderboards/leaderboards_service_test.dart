import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/services/google/leaderboards/leaderboards_service.dart';
import 'package:paperclip2/services/google/leaderboards/leaderboards_adapter.dart';
import 'package:paperclip2/services/google/leaderboards/leaderboards_mapper.dart';
import 'package:paperclip2/services/google/leaderboards/leaderboards_keys.dart';

class _MemAdapter implements LeaderboardsAdapter {
  bool ready = true;
  final Map<String, int> submitted = {};
  @override
  Future<bool> isReady() async => ready;
  @override
  Future<void> submitScore(String leaderboardKey, int score) async {
    submitted[leaderboardKey] = score;
  }
}

void main() {
  group('LeaderboardsService', () {
    test('best score only is enforced', () async {
      final adapter = _MemAdapter();
      final svc = LeaderboardsService(adapter: adapter, mapper: LeaderboardsMapper(), minSubmitInterval: Duration.zero);

      await svc.handleEvent('production.total_clips', {'total': 100});
      await svc.handleEvent('production.total_clips', {'total': 90});
      await svc.tryFlush();

      expect(adapter.submitted[LeaderboardsKeys.productionTotalClips], 100);
    });

    test('rate limit defers submissions', () async {
      final adapter = _MemAdapter();
      final svc = LeaderboardsService(adapter: adapter, mapper: LeaderboardsMapper(), minSubmitInterval: const Duration(hours: 1));

      await svc.handleEvent('economy.net_profit', {'value': 10});
      await svc.tryFlush();

      // première soumission OK
      expect(adapter.submitted[LeaderboardsKeys.netProfit], 10);

      await svc.handleEvent('economy.net_profit', {'value': 20});
      await svc.tryFlush();

      // rate-limit actif: soumission reportée (toujours 10)
      expect(adapter.submitted[LeaderboardsKeys.netProfit], 10);
    });

    test('queues when not ready then flushes later', () async {
      final adapter = _MemAdapter()..ready = false;
      final svc = LeaderboardsService(adapter: adapter, mapper: LeaderboardsMapper(), minSubmitInterval: Duration.zero);

      await svc.handleEvent('economy.net_profit', {'value': 50});
      await svc.tryFlush();
      expect(adapter.submitted.containsKey(LeaderboardsKeys.netProfit), isFalse);

      adapter.ready = true;
      await svc.tryFlush();
      expect(adapter.submitted[LeaderboardsKeys.netProfit], 50);
    });
  });
}
