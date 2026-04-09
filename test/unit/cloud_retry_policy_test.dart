import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/cloud/cloud_retry_policy.dart';

void main() {
  group('CloudRetryPolicy', () {
    test('devrait réussir au premier essai', () async {
      const policy = CloudRetryPolicy(maxAttempts: 3);
      int attempts = 0;

      final result = await policy.execute(
        operation: () async {
          attempts++;
          return 'success';
        },
        operationName: 'test_operation',
      );

      expect(result, equals('success'));
      expect(attempts, equals(1));
    });

    test('devrait retry 3 fois sur timeout puis réussir', () async {
      const policy = CloudRetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      int attempts = 0;

      final result = await policy.execute(
        operation: () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('timeout');
          }
          return 'success';
        },
        operationName: 'test_timeout',
      );

      expect(result, equals('success'));
      expect(attempts, equals(3));
    });

    test('devrait échouer après 3 tentatives', () async {
      const policy = CloudRetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      int attempts = 0;

      expect(
        () => policy.execute(
          operation: () async {
            attempts++;
            throw Exception('network error');
          },
          operationName: 'test_fail',
        ),
        throwsException,
      );

      await Future.delayed(Duration(milliseconds: 100));
      expect(attempts, equals(3));
    });

    test('devrait retry sur erreur 503', () async {
      const policy = CloudRetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      int attempts = 0;

      final result = await policy.execute(
        operation: () async {
          attempts++;
          if (attempts < 2) {
            throw Exception('503 Service Unavailable');
          }
          return 'success';
        },
        operationName: 'test_503',
      );

      expect(result, equals('success'));
      expect(attempts, equals(2));
    });

    test('ne devrait PAS retry sur erreur 404', () async {
      const policy = CloudRetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      int attempts = 0;

      expect(
        () => policy.execute(
          operation: () async {
            attempts++;
            throw Exception('404 Not Found');
          },
          operationName: 'test_404',
        ),
        throwsException,
      );

      await Future.delayed(Duration(milliseconds: 50));
      expect(attempts, equals(1)); // Pas de retry
    });

    test('ne devrait PAS retry sur erreur 401', () async {
      const policy = CloudRetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      int attempts = 0;

      expect(
        () => policy.execute(
          operation: () async {
            attempts++;
            throw Exception('401 Unauthorized');
          },
          operationName: 'test_401',
        ),
        throwsException,
      );

      await Future.delayed(Duration(milliseconds: 50));
      expect(attempts, equals(1)); // Pas de retry
    });

    test('devrait retry sur rate limiting (429)', () async {
      const policy = CloudRetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      int attempts = 0;

      final result = await policy.execute(
        operation: () async {
          attempts++;
          if (attempts < 2) {
            throw Exception('429 Too Many Requests');
          }
          return 'success';
        },
        operationName: 'test_429',
      );

      expect(result, equals('success'));
      expect(attempts, equals(2));
    });

    test('devrait utiliser backoff exponentiel', () async {
      const policy = CloudRetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 100),
        backoffMultiplier: 2.0,
      );
      
      final timestamps = <DateTime>[];
      int attempts = 0;

      try {
        await policy.execute(
          operation: () async {
            attempts++;
            timestamps.add(DateTime.now());
            throw Exception('network error');
          },
          operationName: 'test_backoff',
        );
      } catch (_) {
        // Expected
      }

      expect(attempts, equals(3));
      expect(timestamps.length, equals(3));

      // Vérifier délais approximatifs (avec tolérance)
      final delay1 = timestamps[1].difference(timestamps[0]).inMilliseconds;
      final delay2 = timestamps[2].difference(timestamps[1]).inMilliseconds;

      // Delay 1 devrait être ~100ms + jitter (0-1000ms)
      expect(delay1, greaterThan(50));
      expect(delay1, lessThan(1500));

      // Delay 2 devrait être ~200ms + jitter (0-1000ms)
      expect(delay2, greaterThan(100));
      expect(delay2, lessThan(1500));
    });

    test('devrait respecter maxDelay', () async {
      const policy = CloudRetryPolicy(
        maxAttempts: 5,
        initialDelay: Duration(seconds: 10),
        backoffMultiplier: 2.0,
        maxDelay: Duration(milliseconds: 100),
      );

      final timestamps = <DateTime>[];
      int attempts = 0;

      try {
        await policy.execute(
          operation: () async {
            attempts++;
            timestamps.add(DateTime.now());
            throw Exception('network error');
          },
          operationName: 'test_maxdelay',
        );
      } catch (_) {
        // Expected
      }

      expect(attempts, equals(5));

      // Tous les délais doivent être < maxDelay + jitter
      for (int i = 1; i < timestamps.length; i++) {
        final delay = timestamps[i].difference(timestamps[i - 1]).inMilliseconds;
        expect(delay, lessThan(1500)); // maxDelay (100ms) + jitter max (1000ms)
      }
    });

    test('devrait utiliser shouldRetry custom', () async {
      const policy = CloudRetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      int attempts = 0;

      // Custom shouldRetry : retry uniquement sur "CUSTOM_ERROR"
      final result = await policy.execute(
        operation: () async {
          attempts++;
          if (attempts < 2) {
            throw Exception('CUSTOM_ERROR');
          }
          return 'success';
        },
        operationName: 'test_custom',
        shouldRetry: (error) {
          return error.toString().contains('CUSTOM_ERROR');
        },
      );

      expect(result, equals('success'));
      expect(attempts, equals(2));
    });

    test('shouldRetry custom devrait bloquer retry', () async {
      const policy = CloudRetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      int attempts = 0;

      expect(
        () => policy.execute(
          operation: () async {
            attempts++;
            throw Exception('CUSTOM_ERROR');
          },
          operationName: 'test_custom_block',
          shouldRetry: (error) => false, // Jamais retry
        ),
        throwsException,
      );

      await Future.delayed(Duration(milliseconds: 50));
      expect(attempts, equals(1)); // Pas de retry
    });
  });
}
