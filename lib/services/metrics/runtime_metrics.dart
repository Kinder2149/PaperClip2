import 'package:flutter/foundation.dart';

class RuntimeMetrics {
  static final Map<String, num> _counters = <String, num>{};
  static final Map<String, num> _gauges = <String, num>{};

  static void _inc(String key, [num by = 1]) {
    _counters.update(key, (v) => v + by, ifAbsent: () => by);
  }

  static void _setGauge(String key, num value) {
    _gauges[key] = value;
  }

  // Ticks
  static void recordTick({required int driftMs, required int durationMs}) {
    _inc('tick.count');
    _setGauge('tick.last.driftMs', driftMs);
    _setGauge('tick.last.durationMs', durationMs);
    if (kDebugMode) {
      // Lightweight structured log
      print('[metrics] tick driftMs=$driftMs durationMs=$durationMs');
    }
  }

  // Offline progress
  static void recordOfflineApplied({required int totalSeconds, required int steps}) {
    _inc('offline.apply.count');
    _setGauge('offline.last.totalSeconds', totalSeconds);
    _setGauge('offline.last.steps', steps);
    if (kDebugMode) {
      print('[metrics] offline applied totalSeconds=$totalSeconds steps=$steps');
    }
  }

  // Runtime lifecycle
  static void recordPause() {
    _inc('runtime.pause.count');
    if (kDebugMode) {
      print('[metrics] runtime pause');
    }
  }

  static void recordResume() {
    _inc('runtime.resume.count');
    if (kDebugMode) {
      print('[metrics] runtime resume');
    }
  }

  static void recordRecoverOffline({required int durationMs, required bool didSimulate}) {
    _inc('recoverOffline.count');
    if (didSimulate) _inc('recoverOffline.simulated');
    _setGauge('recoverOffline.last.durationMs', durationMs);
    _setGauge('recoverOffline.last.didSimulate', didSimulate ? 1 : 0);
    if (kDebugMode) {
      print('[metrics] recoverOffline durationMs=$durationMs didSimulate=$didSimulate');
    }
  }

  // Autosave
  static void recordAutosaveTriggered() {
    _inc('autosave.triggered');
    if (kDebugMode) {
      print('[metrics] autosave triggered');
    }
  }

  static void recordAutosaveCompleted({required int durationMs, required bool success}) {
    _inc('autosave.completed');
    if (!success) _inc('autosave.errors');
    _setGauge('autosave.last.durationMs', durationMs);
    _setGauge('autosave.last.success', success ? 1 : 0);
    if (kDebugMode) {
      print('[metrics] autosave completed durationMs=$durationMs success=$success');
    }
  }

  // Exposition minimaliste (lecture seule)
  static Map<String, num> get counters => Map<String, num>.unmodifiable(_counters);
  static Map<String, num> get gauges => Map<String, num>.unmodifiable(_gauges);

  // Test support only
  static void reset() {
    _counters.clear();
    _gauges.clear();
  }
}
