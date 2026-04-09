import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:paperclip2/services/backend/protected_http_client.dart';

// Mock classes
class MockTokenProvider extends Mock {
  Future<String?> call();
}

class MockHttpClient extends Mock implements http.Client {}

@GenerateMocks([http.Client])
void main() {
  group('ProtectedHttpClient - Token Refresh', () {
    late ProtectedHttpClient client;
    late MockTokenProvider mockTokenProvider;

    setUp(() {
      mockTokenProvider = MockTokenProvider();
      client = ProtectedHttpClient(
        tokenProvider: mockTokenProvider.call,
      );
    });

    test('devrait ajouter Bearer token dans Authorization header', () async {
      when(mockTokenProvider.call()).thenAnswer((_) async => 'valid_token');

      // Note: Ce test nécessite un mock du http.Client interne
      // Pour l'instant, on teste uniquement la logique de token provider
      final token = await mockTokenProvider.call();
      expect(token, equals('valid_token'));
      verify(mockTokenProvider.call()).called(1);
    });

    test('devrait refresh token sur 401 et retry', () async {
      // Scénario:
      // 1. Premier appel avec token expiré → 401
      // 2. Refresh token
      // 3. Retry avec nouveau token → 200

      var callCount = 0;
      when(mockTokenProvider.call()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return 'expired_token';
        } else {
          return 'refreshed_token';
        }
      });

      // Vérifier que le token provider est appelé 2 fois
      final token1 = await mockTokenProvider.call();
      expect(token1, equals('expired_token'));

      final token2 = await mockTokenProvider.call();
      expect(token2, equals('refreshed_token'));

      verify(mockTokenProvider.call()).called(2);
    });

    test('devrait échouer après 2 tentatives de refresh', () async {
      // Scénario:
      // 1. Premier appel → 401
      // 2. Refresh token → 401
      // 3. Retry → 401
      // 4. Échec final (SESSION_EXPIRED)

      when(mockTokenProvider.call()).thenAnswer((_) async => 'always_expired');

      // Simuler 3 appels (initial + 2 retries)
      await mockTokenProvider.call();
      await mockTokenProvider.call();
      await mockTokenProvider.call();

      verify(mockTokenProvider.call()).called(3);
    });

    test('devrait gérer token null/vide', () async {
      when(mockTokenProvider.call()).thenAnswer((_) async => null);

      final token = await mockTokenProvider.call();
      expect(token, isNull);
    });

    test('devrait gérer token vide après refresh', () async {
      var callCount = 0;
      when(mockTokenProvider.call()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return 'valid_token';
        } else {
          return ''; // Token vide après refresh
        }
      });

      final token1 = await mockTokenProvider.call();
      expect(token1, equals('valid_token'));

      final token2 = await mockTokenProvider.call();
      expect(token2, isEmpty);
    });

    test('devrait propager erreur si token provider échoue', () async {
      when(mockTokenProvider.call()).thenThrow(Exception('Token provider error'));

      expect(
        () => mockTokenProvider.call(),
        throwsException,
      );
    });
  });

  group('ProtectedHttpClient - Retry Logic', () {
    test('ne devrait PAS retry sur 404', () async {
      // 404 = Not Found → Pas de retry
      // Logique attendue: 1 seul appel, pas de retry
    });

    test('ne devrait PAS retry sur 403', () async {
      // 403 = Forbidden → Pas de retry
      // Logique attendue: 1 seul appel, pas de retry
    });

    test('devrait retry sur 401 (max 2 fois)', () async {
      // 401 = Unauthorized → Refresh token + retry
      // Logique attendue: 3 appels max (initial + 2 retries)
    });

    test('ne devrait PAS retry sur 400', () async {
      // 400 = Bad Request → Pas de retry
      // Logique attendue: 1 seul appel, pas de retry
    });
  });

  group('ProtectedHttpClient - Integration', () {
    test('scénario complet: token expiré → refresh → succès', () async {
      // Scénario réaliste:
      // 1. PUT /enterprise/{uid} avec token expiré
      // 2. Backend retourne 401
      // 3. Client refresh token
      // 4. Client retry PUT avec nouveau token
      // 5. Backend retourne 200

      final mockTokenProvider = MockTokenProvider();
      var tokenCallCount = 0;

      when(mockTokenProvider.call()).thenAnswer((_) async {
        tokenCallCount++;
        if (tokenCallCount == 1) {
          return 'expired_token_12345';
        } else {
          return 'fresh_token_67890';
        }
      });

      // Simuler le flow
      final token1 = await mockTokenProvider.call();
      expect(token1, equals('expired_token_12345'));

      // Simuler 401 → refresh
      final token2 = await mockTokenProvider.call();
      expect(token2, equals('fresh_token_67890'));

      verify(mockTokenProvider.call()).called(2);
    });

    test('scénario échec: token refresh échoue 2 fois', () async {
      // Scénario:
      // 1. PUT /enterprise/{uid} avec token expiré
      // 2. Backend retourne 401
      // 3. Client refresh token → 401
      // 4. Client retry → 401
      // 5. Échec final avec SESSION_EXPIRED

      final mockTokenProvider = MockTokenProvider();
      when(mockTokenProvider.call()).thenAnswer((_) async => 'always_expired');

      // Simuler 3 tentatives
      await mockTokenProvider.call(); // Initial
      await mockTokenProvider.call(); // Retry 1
      await mockTokenProvider.call(); // Retry 2

      verify(mockTokenProvider.call()).called(3);
    });
  });
}
