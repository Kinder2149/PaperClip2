// lib/services/auth/jwt_auth_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class JwtAuthService {
  static final JwtAuthService instance = JwtAuthService._();
  JwtAuthService._();

  static const _kJwtKey = 'jwt_token';
  static const _kJwtExp = 'jwt_expires_at'; // millisSinceEpoch (UTC)

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
    final base = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (base.isEmpty) {
      if (kDebugMode) {
        print('[JwtAuthService] API_BASE_URL vide, impossible de se connecter');
      }
      return false;
    }
    final uri = Uri.parse(base + '/auth/login');
    try {
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'playerId': playerId}),
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
