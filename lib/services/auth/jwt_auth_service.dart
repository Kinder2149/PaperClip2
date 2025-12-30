// lib/services/auth/jwt_auth_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Minimal storage adapter to decouple from FlutterSecureStorage in tests.
abstract class SecureStorageAdapter {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class DefaultSecureStorageAdapter implements SecureStorageAdapter {
  const DefaultSecureStorageAdapter(this._inner);
  final FlutterSecureStorage _inner;

  @override
  Future<void> delete({required String key}) => _inner.delete(key: key);

  @override
  Future<String?> read({required String key}) => _inner.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _inner.write(key: key, value: value);
}

class JwtAuthService {
  static final JwtAuthService instance = JwtAuthService._();
  JwtAuthService._()
      : _client = http.Client(),
        _storage = const DefaultSecureStorageAdapter(FlutterSecureStorage());

  static const _kJwtKey = 'jwt_token';
  static const _kJwtExp = 'jwt_expires_at'; // millisSinceEpoch (UTC)

  // Injectable dependencies for testability
  http.Client _client;
  SecureStorageAdapter _storage;

  /// Testing hooks: inject a custom HTTP client
  @visibleForTesting
  void setHttpClientForTesting(http.Client client) {
    _client = client;
  }

  /// Testing hooks: inject a custom storage adapter
  @visibleForTesting
  void setStorageAdapterForTesting(SecureStorageAdapter adapter) {
    _storage = adapter;
  }

  Future<bool> _isJwtValid() async {
    try {
      final expStr = await _storage.read(key: _kJwtExp);
      if (expStr == null) return false;
      final expMs = int.tryParse(expStr);
      if (expMs == null) return false;
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      // Marge de 10s pour éviter bord de fenêtre
      return nowMs + 10000 < expMs;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, String>?> buildAuthHeaders() async {
    final haveValid = await _isJwtValid();
    if (!haveValid) return null;
    final token = await _storage.read(key: _kJwtKey);
    if (token == null || token.isEmpty) return null;
    return {
      'Authorization': 'Bearer ' + token,
    };
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _kJwtKey);
      await _storage.delete(key: _kJwtExp);
    } catch (_) {}
  }

  Future<bool> loginWithPlayerId(String playerId) async {
    // Normaliser la base et éviter le double /api
    var base = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (base.isEmpty) {
      // fallback sur CLOUD_BACKEND_BASE_URL si API_BASE_URL non fourni
      base = (dotenv.env['CLOUD_BACKEND_BASE_URL'] ?? '').trim();
    }
    if (base.isEmpty) {
      if (kDebugMode) {
        print('[JwtAuthService] API_BASE_URL et CLOUD_BACKEND_BASE_URL vides, impossible de se connecter');
      }
      return false;
    }
    // retirer un trailing slash et un suffixe /api pour éviter /api/api/
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    if (base.toLowerCase().endsWith('/api')) {
      base = base.substring(0, base.length - 4);
    }
    final uri = Uri.parse(base).replace(path: '/api/auth/login');
    try {
      final resp = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            // Option A: le backend requiert désormais provider + provider_user_id.
            // On interprète ici le playerId fourni comme l'identifiant côté provider
            // et on envoie un provider par défaut 'google'.
            body: jsonEncode({'provider': 'google', 'provider_user_id': playerId}),
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        if (kDebugMode) {
          print('[JwtAuthService] login failed: ${resp.statusCode} ${resp.body}');
        }
        return false;
      }
      final body = jsonDecode(resp.body);
      final token = (body['access_token'] ?? '').toString();
      final expiresAtStr = body['expires_at']?.toString();
      if (token.isEmpty || expiresAtStr == null) return false;
      final exp = DateTime.tryParse(expiresAtStr)?.toUtc();
      if (exp == null) return false;
      await _storage.write(key: _kJwtKey, value: token);
      await _storage.write(key: _kJwtExp, value: exp.millisecondsSinceEpoch.toString());
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[JwtAuthService] login exception: $e');
      }
      return false;
    }
  }
}
