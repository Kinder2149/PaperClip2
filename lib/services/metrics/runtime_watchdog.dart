import 'package:flutter/foundation.dart';

class RuntimeWatchdogConfig {
  final int tickDriftWarnMs;
  final int tickDriftConsecutiveThreshold;
  final int autosaveSlowWarnMs;
  final int autosaveErrorConsecutiveThreshold;

  const RuntimeWatchdogConfig({
    this.tickDriftWarnMs = 150, // ~1.5x si tick = 100ms
    this.tickDriftConsecutiveThreshold = 5,
    this.autosaveSlowWarnMs = 800,
    this.autosaveErrorConsecutiveThreshold = 3,
  });
}

class RuntimeWatchdogState {
  int consecutiveHighDrift = 0;
  int consecutiveAutosaveErrors = 0;
}

class RuntimeWatchdog {
  static RuntimeWatchdogConfig config = const RuntimeWatchdogConfig();
  static final RuntimeWatchdogState _state = RuntimeWatchdogState();

  static void evaluateTick({required int driftMs}) {
    if (driftMs >= config.tickDriftWarnMs) {
      _state.consecutiveHighDrift++;
      if (_state.consecutiveHighDrift >= config.tickDriftConsecutiveThreshold) {
        _alert('tick_drift_high', {
          'driftMs': driftMs,
          'consecutive': _state.consecutiveHighDrift,
        });
      }
    } else {
      // reset si retour à la normale
      if (_state.consecutiveHighDrift > 0 && kDebugMode) {
        _log('tick_drift_recovered', {'previousConsecutive': _state.consecutiveHighDrift});
      }
      _state.consecutiveHighDrift = 0;
    }
  }

  static void evaluateAutosave({required int durationMs, required bool success}) {
    if (!success) {
      _state.consecutiveAutosaveErrors++;
      if (_state.consecutiveAutosaveErrors >= config.autosaveErrorConsecutiveThreshold) {
        _alert('autosave_errors_consecutive', {
          'consecutive': _state.consecutiveAutosaveErrors,
        });
      }
      return;
    }

    // success
    _state.consecutiveAutosaveErrors = 0;
    if (durationMs >= config.autosaveSlowWarnMs) {
      _alert('autosave_slow', {'durationMs': durationMs});
    }
  }

  static void _alert(String code, Map<String, Object?> data) {
    // Pour l’instant, alerte = log structuré (pas d’UI)
    if (kDebugMode) {
      print('[watchdog][ALERT] $code $data');
    }
  }

  static void _log(String code, Map<String, Object?> data) {
    if (kDebugMode) {
      print('[watchdog] $code $data');
    }
  }
}
