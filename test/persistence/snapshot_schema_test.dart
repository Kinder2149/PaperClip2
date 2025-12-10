import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';

void main() {
  group('GameSnapshot JSON roundtrip', () {
    test('toJson / fromJson conserve la structure des sections', () {
      final snapshot = GameSnapshot(
        metadata: {
          'saveFormatVersion': '2.0',
          'savedAt': '2025-01-01T12:00:00.000Z',
          'gameVersion': '1.0.3',
          'gameId': 'test-game',
        },
        core: {
          'player': {
            'money': 123.45,
            'paperclips': 1000,
          },
          'level': {
            'level': 5,
            'xp': 200,
          },
        },
        market: {
          'currentPrice': 0.15,
          'reputation': 1.2,
        },
        production: {
          'totalProduced': 5000,
        },
        stats: {
          'playTimeSeconds': 3600,
        },
      );

      final json = snapshot.toJson();
      final rebuilt = GameSnapshot.fromJson(json);

      expect(rebuilt.metadata['saveFormatVersion'], '2.0');
      expect(rebuilt.metadata['gameId'], 'test-game');
      expect(rebuilt.core['player']['money'], 123.45);
      expect(rebuilt.market?['currentPrice'], 0.15);
      expect(rebuilt.production?['totalProduced'], 5000);
      expect(rebuilt.stats?['playTimeSeconds'], 3600);
    });
  });
}
