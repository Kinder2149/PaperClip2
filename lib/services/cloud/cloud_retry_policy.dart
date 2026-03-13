import 'dart:math';
import 'package:paperclip2/utils/logger.dart';

/// Politique de retry avec backoff exponentiel pour les opérations cloud
class CloudRetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  
  const CloudRetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
  });
  
  /// Exécute une opération avec retry automatique
  Future<T> execute<T>({
    required Future<T> Function() operation,
    required String operationName,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;
    
    while (true) {
      attempt++;
      
      try {
        appLogger.debug(
          'Cloud operation attempt $attempt/$maxAttempts',
          code: 'cloud_retry',
          ctx: {'operation': operationName, 'attempt': attempt},
        );
        
        return await operation();
        
      } catch (e) {
        final isLastAttempt = attempt >= maxAttempts;
        final canRetry = shouldRetry?.call(e) ?? _defaultShouldRetry(e);
        
        if (isLastAttempt || !canRetry) {
          appLogger.error(
            'Cloud operation failed permanently',
            code: 'cloud_error',
            ctx: {
              'operation': operationName,
              'attempt': attempt,
              'error': e.toString(),
            },
          );
          rethrow;
        }
        
        appLogger.warn(
          'Cloud operation failed, retrying...',
          code: 'cloud_retry',
          ctx: {
            'operation': operationName,
            'attempt': attempt,
            'nextDelay': delay.inSeconds,
            'error': e.toString(),
          },
        );
        
        await Future.delayed(delay);
        
        // Backoff exponentiel avec jitter
        delay = Duration(
          milliseconds: min(
            (delay.inMilliseconds * backoffMultiplier).round() + 
              Random().nextInt(1000), // Jitter 0-1s
            maxDelay.inMilliseconds,
          ),
        );
      }
    }
  }
  
  /// Détermine si une erreur est retryable
  bool _defaultShouldRetry(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    // Retry sur erreurs réseau/temporaires
    if (errorStr.contains('network') ||
        errorStr.contains('timeout') ||
        errorStr.contains('connection') ||
        errorStr.contains('503') ||
        errorStr.contains('502') ||
        errorStr.contains('504')) {
      return true;
    }
    
    // Ne pas retry sur erreurs client (4xx sauf 429)
    if (errorStr.contains('401') ||
        errorStr.contains('403') ||
        errorStr.contains('404') ||
        errorStr.contains('400')) {
      return false;
    }
    
    // Retry sur rate limiting (429)
    if (errorStr.contains('429') || errorStr.contains('rate limit')) {
      return true;
    }
    
    // Par défaut, retry
    return true;
  }
}

/// Instance globale de la politique de retry
const cloudRetryPolicy = CloudRetryPolicy();
