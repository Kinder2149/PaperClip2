import 'dart:convert';
import 'dart:io';
import '../../utils/logger.dart';
import '../auth/firebase_auth_service.dart';

class ProtectedHttpClient {
  final Logger _logger = Logger.forComponent('auth-http');
  final Future<String?> Function() _tokenProvider;
  final HttpClient _client;

  ProtectedHttpClient({required Future<String?> Function() tokenProvider, HttpClient? inner})
      : _tokenProvider = tokenProvider,
        _client = inner ?? HttpClient();

  /// P0-3: Méthode _send avec retry automatique sur 401
  /// 
  /// Paramètres:
  /// - [isRetry] empêche boucle infinie (legacy, conservé pour compatibilité)
  /// - [retryCount] compteur tentatives (0 = première tentative, max 2)
  Future<_HttpResult> _send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    bool isRetry = false,
    int retryCount = 0,
  }) async {
    var token = await _tokenProvider();
    
    // P0-3: Si token manquant, tenter refresh
    if (token == null || token.isEmpty) {
      _logger.warn('[HTTP] Token manquant, tentative refresh', code: 'http_no_token');
      try {
        token = await FirebaseAuthService.instance.getIdToken(forceRefresh: true);
      } catch (e) {
        _logger.error('[HTTP] Refresh token échoué', code: 'http_refresh_failed', ctx: {
          'error': e.toString(),
        });
        throw StateError('SESSION_EXPIRED: Impossible d\'obtenir un token Firebase valide');
      }
      
      if (token == null || token.isEmpty) {
        throw StateError('SESSION_EXPIRED: Token Firebase vide après refresh');
      }
    }

    final req = await _client.openUrl(method, uri);
    req.headers.set(HttpHeaders.authorizationHeader, 'Bearer '+token);
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    (headers ?? const <String, String>{}).forEach(req.headers.set);
    if (body != null) {
      final data = body is String ? body : jsonEncode(body);
      req.add(utf8.encode(data));
    }
    final res = await req.close();
    
    // P0-3: Gérer 401 avec retry LIMITÉ
    if (res.statusCode == 401) {
      // Vérifier limite retry (max 2 tentatives)
      if (retryCount >= 2) {
        _logger.error('[HTTP] 401 après 2 tentatives - abandon', code: 'http_401_max_retry', ctx: {
          'uri': uri.toString(),
          'method': method,
          'retryCount': retryCount,
        });
        
        await res.drain();
        throw StateError('SESSION_EXPIRED: Échec authentification après 2 tentatives - reconnexion requise');
      }
      
      _logger.warn('[HTTP] 401 Unauthorized, tentative refresh token (${retryCount + 1}/2)', code: 'http_401_retry', ctx: {
        'uri': uri.toString(),
        'method': method,
        'retryCount': retryCount,
      });
      
      // Consommer réponse pour libérer connexion
      await res.drain();
      
      try {
        token = await FirebaseAuthService.instance.getIdToken(forceRefresh: true);
      } catch (e) {
        _logger.error('[HTTP] Refresh token échoué après 401', code: 'http_401_refresh_failed', ctx: {
          'error': e.toString(),
          'uri': uri.toString(),
        });
        
        // P0-3: Lever exception spécifique pour UI
        throw StateError('SESSION_EXPIRED: Session expirée - reconnexion requise');
      }
      
      if (token == null || token.isEmpty) {
        _logger.error('[HTTP] Token vide après refresh 401', code: 'http_401_token_empty');
        throw StateError('SESSION_EXPIRED: Token vide après refresh');
      }
      
      _logger.info('[HTTP] Refresh token réussi, retry requête (${retryCount + 1}/2)', code: 'http_401_retry_ok');
      
      // Retry avec compteur incrémenté
      return await _send(
        method,
        uri,
        headers: headers,
        body: body,
        isRetry: true,
        retryCount: retryCount + 1,
      );
    }

    final text = await utf8.decodeStream(res);
    dynamic json;
    try { json = text.isNotEmpty ? jsonDecode(text) : null; } catch (_) { json = text; }
    return _HttpResult(statusCode: res.statusCode, body: json);
  }

  Future<_HttpResult> get(Uri uri, {Map<String, String>? headers}) => _send('GET', uri, headers: headers);
  Future<_HttpResult> post(Uri uri, {Map<String, String>? headers, Object? body}) => _send('POST', uri, headers: headers, body: body);
  Future<_HttpResult> put(Uri uri, {Map<String, String>? headers, Object? body}) => _send('PUT', uri, headers: headers, body: body);
  Future<_HttpResult> delete(Uri uri, {Map<String, String>? headers}) => _send('DELETE', uri, headers: headers);
}

class _HttpResult {
  final int statusCode;
  final dynamic body;
  _HttpResult({required this.statusCode, this.body});
}
