import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:paperclip2/services/auth/jwt_auth_service.dart';

class _MemoryStorage implements SecureStorageAdapter {
  final Map<String, String> _m = {};
  @override
  Future<void> delete({required String key}) async {
    _m.remove(key);
  }

  @override
  Future<String?> read({required String key}) async => _m[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _m[key] = value;
  }
}

void main() {
  group('JwtAuthService', () {
    test('buildAuthHeaders returns null when token missing or expired (10s margin)', () async {
      final svc = JwtAuthService.instance;
      final mem = _MemoryStorage();
      svc.setStorageAdapterForTesting(mem);

      // No token stored
      expect(await svc.buildAuthHeaders(), isNull);

      // Token present but exp in <10s => invalid
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      await mem.write(key: 'jwt_token', value: 'tkn');
      await mem.write(key: 'jwt_expires_at', value: (nowMs + 5000).toString());
      expect(await svc.buildAuthHeaders(), isNull);
    });

    test('buildAuthHeaders returns Authorization when token valid', () async {
      final svc = JwtAuthService.instance;
      final mem = _MemoryStorage();
      svc.setStorageAdapterForTesting(mem);

      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      await mem.write(key: 'jwt_token', value: 'abc');
      await mem.write(key: 'jwt_expires_at', value: (nowMs + 60000).toString());
      final headers = await svc.buildAuthHeaders();
      expect(headers, isNotNull);
      expect(headers!['Authorization'], 'Bearer abc');
    });

    test('loginWithPlayerId success stores token and exp', () async {
      // Provide API_BASE_URL using dotenv test loader
      await dotenv.dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost');

      final svc = JwtAuthService.instance;
      final mem = _MemoryStorage();
      svc.setStorageAdapterForTesting(mem);

      final mock = MockClient((request) async {
        expect(request.url.toString(), 'http://localhost/auth/login');
        return http.Response(
          '{"access_token":"xyz","expires_at":"2030-01-01T00:00:00Z"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      svc.setHttpClientForTesting(mock);

      final ok = await svc.loginWithPlayerId('player-1');
      expect(ok, isTrue);
      expect(await mem.read(key: 'jwt_token'), 'xyz');
      final exp = await mem.read(key: 'jwt_expires_at');
      expect(exp, isNotNull);
      // Should be parseable as int milliseconds
      expect(int.tryParse(exp!), isNotNull);
    });

    test('loginWithPlayerId handles network error and non-2xx', () async {
      await dotenv.dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost');

      final svc = JwtAuthService.instance;
      final mem = _MemoryStorage();
      svc.setStorageAdapterForTesting(mem);

      // Non-2xx
      svc.setHttpClientForTesting(MockClient((request) async => http.Response('err', 500)));
      final ok1 = await svc.loginWithPlayerId('p');
      expect(ok1, isFalse);

      // Exception
      svc.setHttpClientForTesting(MockClient((request) async => throw Exception('boom')));
      final ok2 = await svc.loginWithPlayerId('p');
      expect(ok2, isFalse);
    });
  });
}
