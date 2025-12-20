import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/metrics/runtime_metrics.dart';

void main() {
  setUp(() {
    RuntimeMetrics.reset();
  });

  test('RuntimeMetrics pause/resume counters increment', () {
    RuntimeMetrics.recordPause();
    RuntimeMetrics.recordResume();

    expect(RuntimeMetrics.counters['runtime.pause.count'], 1);
    expect(RuntimeMetrics.counters['runtime.resume.count'], 1);
  });

  test('RuntimeMetrics recoverOffline records gauges and counters', () {
    RuntimeMetrics.recordRecoverOffline(durationMs: 123, didSimulate: true);

    expect(RuntimeMetrics.counters['recoverOffline.count'], 1);
    expect(RuntimeMetrics.counters['recoverOffline.simulated'], 1);
    expect(RuntimeMetrics.gauges['recoverOffline.last.durationMs'], 123);
    expect(RuntimeMetrics.gauges['recoverOffline.last.didSimulate'], 1);
  });
}
