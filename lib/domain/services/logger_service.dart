// lib/domain/services/logger_service.dart

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

enum LogLevel { debug, info, warning, error, critical }

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  void log(
      String message, {
        LogLevel level = LogLevel.info,
        dynamic error,
        StackTrace? stackTrace,
        String? tag,
      }) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final logPrefix = _getLogPrefix(level);

    // Console log
    if (kDebugMode) {
      switch (level) {
        case LogLevel.debug:
          developer.log(
            message,
            name: tag ?? 'PaperClip',
            level: 300,
            error: error,
            stackTrace: stackTrace,
          );
          break;
        case LogLevel.info:
          debugPrint('$timestamp $logPrefix $message');
          break;
        case LogLevel.warning:
          debugPrint('\x1B[33m$timestamp $logPrefix $message\x1B[0m');
          break;
        case LogLevel.error:
        case LogLevel.critical:
          debugPrint('\x1B[31m$timestamp $logPrefix $message\x1B[0m');
          break;
      }
    }

    // TODO: Implémenter la journalisation dans un fichier ou un service distant
    _persistLog(timestamp, logPrefix, message, level);
  }

  String _getLogPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '[DEBUG]';
      case LogLevel.info:
        return '[INFO] ';
      case LogLevel.warning:
        return '[WARN] ';
      case LogLevel.error:
        return '[ERROR]';
      case LogLevel.critical:
        return '[CRIT] ';
    }
  }

  void _persistLog(
      String timestamp,
      String prefix,
      String message,
      LogLevel level
      ) {
    // Implémentation future de la persistance des logs
    // Peut inclure l'écriture dans un fichier, envoi à un service distant, etc.
  }

  // Méthodes de log rapides
  void debug(String message, {String? tag}) =>
      log(message, level: LogLevel.debug, tag: tag);

  void info(String message, {String? tag}) =>
      log(message, level: LogLevel.info, tag: tag);

  void warning(String message, {dynamic error, StackTrace? stackTrace}) =>
      log(message, level: LogLevel.warning, error: error, stackTrace: stackTrace);

  void error(String message, {dynamic error, StackTrace? stackTrace}) =>
      log(message, level: LogLevel.error, error: error, stackTrace: stackTrace);

  void critical(String message, {dynamic error, StackTrace? stackTrace}) =>
      log(message, level: LogLevel.critical, error: error, stackTrace: stackTrace);
}