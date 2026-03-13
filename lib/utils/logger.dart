import 'dart:async';
import 'package:flutter/foundation.dart';

enum LogLevel { trace, debug, info, warn, error }

class LoggerConfig {
  final LogLevel minLevel;
  final bool wrapLongLines;

  const LoggerConfig({
    this.minLevel = LogLevel.info,
    this.wrapLongLines = true,
  });

  LoggerConfig copyWith({LogLevel? minLevel, bool? wrapLongLines}) => LoggerConfig(
        minLevel: minLevel ?? this.minLevel,
        wrapLongLines: wrapLongLines ?? this.wrapLongLines,
      );
}

class Logger {
  static LoggerConfig _config = LoggerConfig(
    minLevel: kReleaseMode ? LogLevel.info : LogLevel.info, // INFO par défaut même en debug
    wrapLongLines: true,
  );

  // Mission-focused logging: when enabled, only allow logs whose code is in
  // the allowlist (or messages starting with an emoji marker) to be printed.
  // ACTIVÉ PAR DÉFAUT en debug pour réduire le bruit
  static bool _missionMode = kDebugMode;
  static Set<String> _missionCodes = <String>{
    // World lifecycle
    'world_create_before',
    'world_create_after',
    'world_switch_before',
    'world_switch_after',
    // Save pipeline
    'save_queue_enqueue',
    'save_pump_start',
    'world_save_done',
    // Cloud sync
    'cloud_sync_decision',
    'cloud_sync_action',
    'cloud_start',
    'cloud_success',
    'cloud_backoff',
    // HTTP
    'http_put_world',
    'http_put_world_resp',
    // Snapshots around creation/save
    'worlds_snapshot_before',
    'worlds_snapshot_after_first_save',
    // Bootstrap & Auth (DIAGNOSTIC SYNC CLOUD)
    'bootstrap_listener_install',
    'bootstrap_initial_user_detected',
    'bootstrap_no_initial_user',
    'bootstrap_listener_installed',
    'bootstrap_listener_error',
    'auth_state_changed',
    'auth_new_user',
    'auth_user_disconnected',
    'auth_sync_skip',
    'sync_start',
    'sync_cloud_pref',
    'sync_auto_enable',
    'sync_cloudport_start',
    'sync_cloudport_result',
    'sync_cloudport_retry',
    'sync_cloudport_failed',
    'sync_cloudport_retry_success',
    'sync_orchestrator_start',
    'sync_orchestrator_result',
    'sync_failed',
    'sync_success',
    'sync_error',
    'init_playerid_provider_call',
    'init_playerid_not_ready',
    'init_playerid_null',
    'init_playerid_success',
    'auth_user_ready',
    'auth_silent_attempt',
    'auth_user_ready_silent',
    'auth_user_not_ready',
  };

  static void enableMissionMode([bool enabled = true]) {
    _missionMode = enabled;
  }

  static void setMissionCodes(Set<String> codes) {
    _missionCodes = codes;
  }

  static void configure(LoggerConfig config) {
    _config = config;
  }

  static Logger forComponent(String component) => Logger._(component);

  final String _component;
  final Map<String, DateTime> _throttle = {};

  Logger._(this._component);

  void trace(String message, {String? code, Map<String, Object?> ctx = const {}}) =>
      _log(LogLevel.trace, message, code: code, ctx: ctx);
  void debug(String message, {String? code, Map<String, Object?> ctx = const {}}) =>
      _log(LogLevel.debug, message, code: code, ctx: ctx);
  void info(String message, {String? code, Map<String, Object?> ctx = const {}}) =>
      _log(LogLevel.info, message, code: code, ctx: ctx);
  void warn(String message, {String? code, Map<String, Object?> ctx = const {}}) =>
      _log(LogLevel.warn, message, code: code, ctx: ctx);
  void error(String message, {String? code, Map<String, Object?> ctx = const {}}) =>
      _log(LogLevel.error, message, code: code, ctx: ctx);

  // Backward-compat helpers (old API names)
  void warning(String message, {String? code, Map<String, Object?> ctx = const {}}) =>
      warn(message, code: code, ctx: ctx);
  void severe(String message, {String? code, Map<String, Object?> ctx = const {}}) =>
      error(message, code: code, ctx: ctx);
  void fine(String message, {String? code, Map<String, Object?> ctx = const {}}) =>
      debug(message, code: code, ctx: ctx);

  // Log with probabilistic sampling
  void sampled(LogLevel level, String message,
      {double rate = 0.1, String? code, Map<String, Object?> ctx = const {}}) {
    if (rate <= 0) return;
    if (rate >= 1) {
      _log(level, message, code: code, ctx: ctx);
      return;
    }
    final now = DateTime.now().microsecondsSinceEpoch;
    final hash = now ^ _component.hashCode ^ message.hashCode;
    final bucket = (hash & 0x7fffffff) / 0x7fffffff;
    if (bucket < rate) {
      _log(level, message, code: code, ctx: ctx);
    }
  }

  // Log at most once per window for a given code
  void throttle(LogLevel level, String code, Duration window, String message,
      {Map<String, Object?> ctx = const {}}) {
    final last = _throttle[code];
    final now = DateTime.now();
    if (last != null && now.difference(last) < window) return;
    _throttle[code] = now;
    _log(level, message, code: code, ctx: ctx);
  }

  void _log(LogLevel level, String message, {String? code, Map<String, Object?> ctx = const {}}) {
    if (level.index < _config.minLevel.index) return;

    // Mission-mode filtering (debug-time helper to reduce log noise)
    if (_missionMode) {
      final hasEmojiPrefix = message.startsWith('🆕') || message.startsWith('🔀') ||
          message.startsWith('🧳') || message.startsWith('▶️') ||
          message.startsWith('💾') || message.startsWith('☁️') ||
          message.startsWith('🌐') || message.startsWith('📃');
      final codeAllowed = code != null && _missionCodes.contains(code);
      if (!(codeAllowed || hasEmojiPrefix)) {
        return;
      }
    }

    final ts = DateTime.now().toIso8601String();
    final lvl = level.name.toUpperCase();
    final codeStr = code == null ? '' : '[$code] ';
    final ctxStr = ctx.isEmpty ? '' : ' | ' + _formatCtx(ctx);
    final line = '[$ts][$lvl][${_component}] ${codeStr}${message}${ctxStr}';

    if (kDebugMode) {
      if (_config.wrapLongLines) {
        debugPrint(line);
      } else {
        // ignore: avoid_print
        print(line);
      }
    } else {
      // In release, keep only info/warn/error already filtered by minLevel.
      // ignore: avoid_print
      print(line);
    }
  }

  String _formatCtx(Map<String, Object?> ctx) {
    final parts = <String>[];
    ctx.forEach((k, v) {
      if (v is String && v.length > 200) {
        parts.add('$k=${v.substring(0, 200)}…');
      } else {
        parts.add('$k=$v');
      }
    });
    return parts.join(' ');
  }
}

// Global helpers
final Logger appLogger = Logger.forComponent('app');

Future<T> runWithGlobalErrorLogging<T>(Future<T> Function() body) {
  final completer = Completer<T>();
  runZonedGuarded(
    () async {
      try {
        final result = await body();
        if (!completer.isCompleted) completer.complete(result);
      } catch (e, st) {
        if (!completer.isCompleted) completer.completeError(e, st);
      }
    },
    (error, stack) {
      appLogger.error('Uncaught zone error: $error', code: 'uncaught', ctx: {
        'stack': kReleaseMode ? '<hidden>' : stack.toString(),
      });
      if (!completer.isCompleted) completer.completeError(error, stack);
    },
  );
  return completer.future;
}
