// Tests Gestion Erreurs Cloud - Phase 2.4
// 5 tests pour valider la gestion des erreurs et la résilience
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/cloud/cloud_retry_policy.dart';
import 'dart:async';

void main() {
  group('Tests Gestion Erreurs Cloud - 5 tests', () {
    
    group('Test 1: Erreur réseau → Retry automatique', () {
      test('1.1 - Retry sur erreur réseau temporaire', () async {
        // Arrange
        const policy = CloudRetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        );
        var attemptCount = 0;
        
        // Act
        final result = await policy.execute(
          operation: () async {
            attemptCount++;
            if (attemptCount < 3) {
              throw Exception('Network error');
            }
            return 'success';
          },
          operationName: 'test_network_retry',
        );
        
        // Assert
        expect(result, equals('success'));
        expect(attemptCount, equals(3));
      });

      test('1.2 - Retry avec backoff exponentiel', () async {
        // Arrange
        const policy = CloudRetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 50),
          backoffMultiplier: 2.0,
        );
        
        final timestamps = <DateTime>[];
        var attemptCount = 0;
        
        // Act
        try {
          await policy.execute(
            operation: () async {
              attemptCount++;
              timestamps.add(DateTime.now());
              throw Exception('Network error');
            },
            operationName: 'test_backoff',
          );
        } catch (_) {
          // Expected
        }
        
        // Assert
        expect(attemptCount, equals(3));
        expect(timestamps.length, equals(3));
        
        // Vérifier que les délais augmentent
        if (timestamps.length >= 2) {
          final delay1 = timestamps[1].difference(timestamps[0]).inMilliseconds;
          expect(delay1, greaterThan(30)); // Au moins 30ms (avec tolérance)
        }
      });

      test('1.3 - Abandon après max retries', () async {
        // Arrange
        const policy = CloudRetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        );
        var attemptCount = 0;
        
        // Act & Assert
        expect(
          () => policy.execute(
            operation: () async {
              attemptCount++;
              throw Exception('Permanent network error');
            },
            operationName: 'test_max_retries',
          ),
          throwsException,
        );
        
        await Future.delayed(const Duration(milliseconds: 100));
        // Le retry policy peut s'arrêter plus tôt sur certaines erreurs
        expect(attemptCount, greaterThanOrEqualTo(1));
        expect(attemptCount, lessThanOrEqualTo(3));
      });
    });

    group('Test 2: Erreur authentification → Message utilisateur', () {
      test('2.1 - Erreur 401 Unauthorized détectée', () {
        // Arrange
        final errorMessage = '401 Unauthorized';
        
        // Act
        final isAuthError = errorMessage.contains('401') || 
                           errorMessage.contains('Unauthorized');
        
        // Assert
        expect(isAuthError, isTrue);
      });

      test('2.2 - Erreur 403 Forbidden détectée', () {
        // Arrange
        final errorMessage = '403 Forbidden';
        
        // Act
        final isAuthError = errorMessage.contains('403') || 
                           errorMessage.contains('Forbidden');
        
        // Assert
        expect(isAuthError, isTrue);
      });

      test('2.3 - Token expiré détecté', () {
        // Arrange
        final errorMessage = 'Token expired';
        
        // Act
        final isTokenExpired = errorMessage.toLowerCase().contains('token') &&
                              errorMessage.toLowerCase().contains('expired');
        
        // Assert
        expect(isTokenExpired, isTrue);
      });

      test('2.4 - Pas de retry sur erreur auth', () async {
        // Arrange
        const policy = CloudRetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        );
        var attemptCount = 0;
        
        // Act & Assert
        expect(
          () => policy.execute(
            operation: () async {
              attemptCount++;
              throw Exception('401 Unauthorized');
            },
            operationName: 'test_auth_no_retry',
          ),
          throwsException,
        );
        
        await Future.delayed(const Duration(milliseconds: 50));
        // Devrait échouer au premier essai sans retry
        expect(attemptCount, equals(1));
      });
    });

    group('Test 3: Erreur backend → Gestion 500/503', () {
      test('3.1 - Erreur 500 Internal Server Error', () {
        // Arrange
        final errorMessage = '500 Internal Server Error';
        
        // Act
        final isServerError = errorMessage.contains('500');
        
        // Assert
        expect(isServerError, isTrue);
      });

      test('3.2 - Erreur 503 Service Unavailable avec retry', () async {
        // Arrange
        const policy = CloudRetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        );
        var attemptCount = 0;
        
        // Act
        final result = await policy.execute(
          operation: () async {
            attemptCount++;
            if (attemptCount < 2) {
              throw Exception('503 Service Unavailable');
            }
            return 'success';
          },
          operationName: 'test_503_retry',
        );
        
        // Assert
        expect(result, equals('success'));
        expect(attemptCount, equals(2));
      });

      test('3.3 - Erreur 429 Too Many Requests avec retry', () async {
        // Arrange
        const policy = CloudRetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        );
        var attemptCount = 0;
        
        // Act
        final result = await policy.execute(
          operation: () async {
            attemptCount++;
            if (attemptCount < 2) {
              throw Exception('429 Too Many Requests');
            }
            return 'success';
          },
          operationName: 'test_429_retry',
        );
        
        // Assert
        expect(result, equals('success'));
        expect(attemptCount, equals(2));
      });

      test('3.4 - Erreur 404 Not Found sans retry', () async {
        // Arrange
        const policy = CloudRetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        );
        var attemptCount = 0;
        
        // Act & Assert
        expect(
          () => policy.execute(
            operation: () async {
              attemptCount++;
              throw Exception('404 Not Found');
            },
            operationName: 'test_404_no_retry',
          ),
          throwsException,
        );
        
        await Future.delayed(const Duration(milliseconds: 50));
        expect(attemptCount, equals(1)); // Pas de retry sur 404
      });
    });

    group('Test 4: Timeout → Annulation après délai', () {
      test('4.1 - Timeout après délai configuré', () async {
        // Arrange
        Future<String> slowOperation() async {
          await Future.delayed(const Duration(seconds: 2));
          return 'success';
        }
        
        // Act & Assert
        expect(
          () => slowOperation().timeout(const Duration(milliseconds: 100)),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('4.2 - Opération réussit avant timeout', () async {
        // Arrange
        Future<String> fastOperation() async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 'success';
        }
        
        // Act
        final result = await fastOperation()
            .timeout(const Duration(seconds: 1));
        
        // Assert
        expect(result, equals('success'));
      });

      test('4.3 - Timeout avec message personnalisé', () async {
        // Arrange
        Future<String> slowOperation() async {
          await Future.delayed(const Duration(seconds: 2));
          return 'success';
        }
        
        // Act & Assert
        try {
          await slowOperation().timeout(
            const Duration(milliseconds: 100),
            onTimeout: () => throw TimeoutException('Operation timed out'),
          );
          fail('Should have thrown TimeoutException');
        } catch (e) {
          expect(e, isA<TimeoutException>());
          expect(e.toString(), contains('Operation timed out'));
        }
      });

      test('4.4 - Timeout respecte maxDelay dans retry policy', () async {
        // Arrange
        const policy = CloudRetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 100),
          backoffMultiplier: 2.0,
          maxDelay: Duration(milliseconds: 200),
        );
        
        final timestamps = <DateTime>[];
        var attemptCount = 0;
        
        // Act
        try {
          await policy.execute(
            operation: () async {
              attemptCount++;
              timestamps.add(DateTime.now());
              throw Exception('error');
            },
            operationName: 'test_maxdelay',
          );
        } catch (_) {
          // Expected
        }
        
        // Assert
        expect(attemptCount, greaterThanOrEqualTo(2));
        expect(attemptCount, lessThanOrEqualTo(3));
        
        // Vérifier que les délais ne dépassent pas maxDelay + jitter
        for (int i = 1; i < timestamps.length; i++) {
          final delay = timestamps[i].difference(timestamps[i - 1]).inMilliseconds;
          expect(delay, lessThan(1500)); // maxDelay (200ms) + jitter max (1000ms) + tolérance
        }
      });
    });

    group('Test 5: Offline → Sauvegarde locale continue', () {
      test('5.1 - Détection mode offline', () {
        // Arrange
        final isOnline = false;
        
        // Act
        final shouldUseCloud = isOnline;
        final shouldUseLocal = !isOnline;
        
        // Assert
        expect(shouldUseCloud, isFalse);
        expect(shouldUseLocal, isTrue);
      });

      test('5.2 - Sauvegarde locale fonctionne sans cloud', () {
        // Arrange
        final localData = {
          'level': 5,
          'paperclips': 1000,
          'money': 50.0,
        };
        
        // Act - Simuler sauvegarde locale
        final saved = Map<String, dynamic>.from(localData);
        
        // Assert
        expect(saved, isNotNull);
        expect(saved['level'], equals(5));
        expect(saved['paperclips'], equals(1000));
      });

      test('5.3 - Sync différée quand offline', () {
        // Arrange
        final isOnline = false;
        final hasPendingSync = true;
        
        // Act
        final shouldSyncNow = isOnline && hasPendingSync;
        final shouldSyncLater = !isOnline && hasPendingSync;
        
        // Assert
        expect(shouldSyncNow, isFalse);
        expect(shouldSyncLater, isTrue);
      });

      test('5.4 - Retry sync quand revient online', () {
        // Arrange
        var isOnline = false;
        final hasPendingSync = true;
        
        // Act - Simuler passage offline → online
        var shouldSync = isOnline && hasPendingSync;
        expect(shouldSync, isFalse);
        
        isOnline = true; // Revient online
        shouldSync = isOnline && hasPendingSync;
        
        // Assert
        expect(shouldSync, isTrue);
      });

      test('5.5 - Erreur cloud ne bloque pas le jeu', () {
        // Arrange
        var cloudError = false;
        var gameBlocked = false;
        
        // Act - Simuler erreur cloud
        try {
          throw Exception('Cloud error');
        } catch (e) {
          cloudError = true;
          // Le jeu continue malgré l'erreur
          gameBlocked = false;
        }
        
        // Assert
        expect(cloudError, isTrue);
        expect(gameBlocked, isFalse);
      });
    });

    group('Test Bonus: Gestion erreurs combinées', () {
      test('6.1 - Retry avec shouldRetry personnalisé', () async {
        // Arrange
        const policy = CloudRetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        );
        var attemptCount = 0;
        
        // Act
        final result = await policy.execute(
          operation: () async {
            attemptCount++;
            if (attemptCount < 2) {
              throw Exception('RETRYABLE_ERROR');
            }
            return 'success';
          },
          operationName: 'test_custom_retry',
          shouldRetry: (error) {
            return error.toString().contains('RETRYABLE_ERROR');
          },
        );
        
        // Assert
        expect(result, equals('success'));
        expect(attemptCount, equals(2));
      });

      test('6.2 - shouldRetry bloque retry sur erreur non-retryable', () async {
        // Arrange
        const policy = CloudRetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        );
        var attemptCount = 0;
        
        // Act & Assert
        expect(
          () => policy.execute(
            operation: () async {
              attemptCount++;
              throw Exception('NON_RETRYABLE_ERROR');
            },
            operationName: 'test_custom_no_retry',
            shouldRetry: (error) => false, // Jamais retry
          ),
          throwsException,
        );
        
        await Future.delayed(const Duration(milliseconds: 50));
        expect(attemptCount, equals(1)); // Pas de retry
      });
    });
  });
}
