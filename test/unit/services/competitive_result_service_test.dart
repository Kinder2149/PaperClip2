import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/competitive/competitive_result_service.dart';

void main() {
  group('CompetitiveResultService.compute', () {
    test('computes score with efficiency and returns rounded score', () {
      final data = CompetitiveResultService.compute(
        paperclips: 100,
        money: 50.0,
        level: 2,
        playTime: const Duration(seconds: 100),
      );
      // efficiency = 100/100 = 1.0; score = 100 + 50 + 2*100 + 1.0*50 = 300
      expect(data.score, 300);
      expect(data.paperclips, 100);
      expect(data.money, 50.0);
      expect(data.level, 2);
      expect(data.playTime, const Duration(seconds: 100));
      expect(data.efficiency, closeTo(1.0, 1e-9));
    });

    test('handles zero seconds playtime by avoiding division by zero', () {
      final data = CompetitiveResultService.compute(
        paperclips: 10,
        money: 0.0,
        level: 0,
        playTime: Duration.zero,
      );
      // efficiency fallback = paperclips.toDouble() = 10
      // score = 10 + 0 + 0 + 10*50 = 510
      expect(data.score, 510);
      expect(data.efficiency, closeTo(10.0, 1e-9));
    });
  });
}
