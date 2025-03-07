import 'package:flutter/foundation.dart';

abstract class ServiceBase {
  @protected
  void logInfo(String message) {
    if (kDebugMode) {
      print('INFO: $message');
    }
  }

  @protected
  void logError(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('ERROR: $message');
      if (error != null) {
        print('Error details: $error');
      }
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }

  @protected
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delayBetweenRetries = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        attempts++;
        if (attempts >= maxRetries) {
          logError(
            'Operation failed after $attempts attempts',
            e,
            stackTrace,
          );
          rethrow;
        }
        logError(
          'Operation failed (attempt $attempts/$maxRetries), retrying...',
          e,
        );
        await Future.delayed(delayBetweenRetries);
      }
    }
    throw Exception('Should not reach here');
  }
} 