import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/firebase_auth_service.dart';
import '../notification_manager.dart';

/// Client HTTP minimal qui ajoute automatiquement l'ID Token Firebase
/// et gère les cas 401/403 et utilisateur non authentifié.
class ProtectedHttpClient {
  ProtectedHttpClient({http.Client? inner}) : _inner = inner ?? http.Client();

  final http.Client _inner;

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    return _send('GET', uri, headers: headers);
  }

  Future<http.Response> post(Uri uri, {Map<String, String>? headers, Object? body}) async {
    return _send('POST', uri, headers: headers, body: body);
  }

  Future<http.Response> put(Uri uri, {Map<String, String>? headers, Object? body}) async {
    return _send('PUT', uri, headers: headers, body: body);
  }

  Future<http.Response> _send(String method, Uri uri, {Map<String, String>? headers, Object? body}) async {
    final token = await FirebaseAuthService.instance.getIdToken();
    if (token == null || token.isEmpty) {
      NotificationManager.instance.showNotification(
        message: 'Vous devez être connecté (Firebase) pour effectuer cette action.',
        level: NotificationLevel.WARNING,
      );
      throw StateError('Unauthenticated');
    }
    final all = {
      'Authorization': 'Bearer $token',
      if (headers != null) ...headers,
    };
    if (body is Map || body is List) {
      all.putIfAbsent('Content-Type', () => 'application/json');
    }
    http.Response resp;
    try {
      switch (method) {
        case 'GET':
          resp = await _inner.get(uri, headers: all);
          break;
        case 'POST':
          resp = await _inner.post(uri, headers: all, body: _encodeIfNeeded(body));
          break;
        case 'PUT':
          resp = await _inner.put(uri, headers: all, body: _encodeIfNeeded(body));
          break;
        default:
          throw UnsupportedError('Method $method not supported');
      }
    } catch (_) {
      NotificationManager.instance.showNotification(
        message: 'Erreur réseau. Veuillez réessayer.',
        level: NotificationLevel.ERROR,
      );
      rethrow;
    }
    if (resp.statusCode == 401) {
      NotificationManager.instance.showNotification(
        message: 'Session invalide ou expirée. Veuillez vous reconnecter.',
        level: NotificationLevel.WARNING,
      );
      throw StateError('Unauthorized');
    }
    if (resp.statusCode == 403) {
      NotificationManager.instance.showNotification(
        message: 'Accès refusé.',
        level: NotificationLevel.ERROR,
      );
      throw StateError('Forbidden');
    }
    return resp;
  }

  Object? _encodeIfNeeded(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    return jsonEncode(body);
  }
}
