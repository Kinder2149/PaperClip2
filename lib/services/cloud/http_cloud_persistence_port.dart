// lib/services/cloud/http_cloud_persistence_port.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'cloud_persistence_port.dart';
import '../auth/jwt_auth_service.dart';

typedef AuthHeaderProvider = FutureOr<Map<String, String>?> Function();
typedef PlayerIdProvider = FutureOr<String?> Function();

class HttpCloudPersistencePort implements CloudPersistencePort {
  final String baseUrl;
  final AuthHeaderProvider? authHeaderProvider;
  final PlayerIdProvider? playerIdProvider;
  // Cache ETag par partieId pour la gestion de concurrence
  final Map<String, String> _etagCache = <String, String>{};

  HttpCloudPersistencePort({
    required this.baseUrl,
    this.authHeaderProvider,
    this.playerIdProvider,
  });

  Uri _uri(String path, {Map<String, String>? query}) {
    final base = Uri.parse(baseUrl);
    final merged = Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: base.path.endsWith('/') ? (base.path + path.replaceFirst('/', '')) : (base.path + path),
      queryParameters: query,
    );
    return merged;
  }


  @override
  Future<void> deleteById({required String partieId}) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = _uri('/api/cloud/parties/$partieId');
      Future<HttpClientResponse> _send() async {
        final req = await client.deleteUrl(uri);
        final headers = await _buildHeaders();
        headers.forEach(req.headers.set);
        return await req.close().timeout(const Duration(seconds: 30));
      }
      var resp = await _send();
      if (resp.statusCode == 401) {
        try {
          final pid = await playerIdProvider?.call();
          if (pid != null && pid.isNotEmpty) {
            final ok = await JwtAuthService.instance.loginWithPlayerId(pid);
            if (ok) {
              resp = await _send();
            }
          }
        } catch (_) {}
      }
      if (resp.statusCode == 404) return; // déjà supprimé
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final text = await resp.transform(utf8.decoder).join();
        throw HttpException('HTTP ${resp.statusCode}: $text', uri: uri);
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };
    final extra = await authHeaderProvider?.call();
    if (extra != null) {
      headers.addAll(extra);
      // Compat backend: si Authorization est fourni mais pas X-Authorization, duplique pour l'API key simple
      if (extra.containsKey('Authorization') && !extra.containsKey('X-Authorization')) {
        headers['X-Authorization'] = extra['Authorization']!;
      }
    }
    if (kDebugMode) {
      try {
        final hasAuth = headers.containsKey('Authorization');
        final hasXAuth = headers.containsKey('X-Authorization');
        print('[DEBUG_AUTH_HEADER] Authorization present=${hasAuth}, X-Authorization present=${hasXAuth}');
      } catch (_) {}
    }
    return headers;
  }

  @override
  Future<List<CloudIndexEntry>> listParties() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final pid = await playerIdProvider?.call();
      if (pid == null || pid.isEmpty) {
        // Sans playerId, l'endpoint contractuel ne peut pas répondre.
        return <CloudIndexEntry>[];
      }
      final uri = _uri('/api/cloud/parties', query: {'playerId': pid});
      Future<HttpClientResponse> _send() async {
        final req = await client.getUrl(uri);
        final headers = await _buildHeaders();
        headers.forEach(req.headers.set);
        return await req.close().timeout(const Duration(seconds: 30));
      }
      var resp = await _send();
      if (resp.statusCode == 401) {
        try {
          final ok = await JwtAuthService.instance.loginWithPlayerId(pid);
          if (ok) {
            resp = await _send();
          }
        } catch (_) {}
      }
      if (resp.statusCode == 404) return <CloudIndexEntry>[];
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final text = await resp.transform(utf8.decoder).join();
        throw HttpException('HTTP ${resp.statusCode}: $text', uri: uri);
      }
      final text = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(text);
      final List<CloudIndexEntry> list = [];
      if (json is List) {
        for (final item in json) {
          if (item is Map<String, dynamic>) {
            list.add(CloudIndexEntry(
              partieId: item['partieId']?.toString() ?? '',
              name: item['name']?.toString(),
              gameVersion: item['gameVersion']?.toString(),
              remoteVersion: item['remoteVersion'] is int
                  ? item['remoteVersion'] as int
                  : int.tryParse(item['remoteVersion']?.toString() ?? ''),
              lastPushAt: _parseDate(item['lastPushAt']),
              lastPullAt: _parseDate(item['lastPullAt']),
              playerId: item['playerId']?.toString(),
            ));
          }
        }
      }
      return list;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> pushById({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = _uri('/api/cloud/parties/$partieId');
      final metaToSend = Map<String, dynamic>.from(metadata);
      try {
        if (!metaToSend.containsKey('playerId')) {
          final pid = await playerIdProvider?.call();
          if (pid != null && pid.isNotEmpty) {
            metaToSend['playerId'] = pid;
          }
        }
      } catch (_) {}
      final body = jsonEncode({
        'snapshot': snapshot,
        'metadata': metaToSend,
      });
      Future<HttpClientResponse> _send() async {
        final req = await client.putUrl(uri);
        final headers = await _buildHeaders();
        headers.forEach(req.headers.set);
        // Concurrence: If-Match pour mise à jour, If-None-Match: * pour création
        final cached = _etagCache[partieId];
        if (cached != null && cached.isNotEmpty) {
          req.headers.set(HttpHeaders.ifMatchHeader, '"$cached"');
        } else {
          req.headers.set(HttpHeaders.ifNoneMatchHeader, '*');
        }
        req.add(utf8.encode(body));
        return await req.close().timeout(const Duration(seconds: 30));
      }
      var resp = await _send();
      if (resp.statusCode == 401) {
        try {
          final pid = await playerIdProvider?.call();
          if (pid != null && pid.isNotEmpty) {
            final ok = await JwtAuthService.instance.loginWithPlayerId(pid);
            if (ok) {
              resp = await _send();
            }
          }
        } catch (_) {}
      }
      if (resp.statusCode == 412 || resp.statusCode == 428) {
        final text = await resp.transform(utf8.decoder).join();
        throw ETagPreconditionException(resp.statusCode, text, currentEtag: _etagCache[partieId]);
      }
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final text = await resp.transform(utf8.decoder).join();
        throw HttpException('HTTP ${resp.statusCode}: $text', uri: uri);
      }
      // Mettre à jour l'ETag si retourné par le serveur
      final newEtag = resp.headers.value(HttpHeaders.etagHeader);
      if (newEtag != null && newEtag.isNotEmpty) {
        _etagCache[partieId] = newEtag.replaceAll('"', '');
      }
      if (kDebugMode) {
        print('[HttpCloudPersistencePort] pushById ok: $partieId');
      }
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<Map<String, dynamic>?> pullById({required String partieId}) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = _uri('/api/cloud/parties/$partieId');
      Future<HttpClientResponse> _send() async {
        final req = await client.getUrl(uri);
        final headers = await _buildHeaders();
        headers.forEach(req.headers.set);
        return await req.close().timeout(const Duration(seconds: 30));
      }
      var resp = await _send();
      if (resp.statusCode == 401) {
        try {
          final pid = await playerIdProvider?.call();
          if (pid != null && pid.isNotEmpty) {
            final ok = await JwtAuthService.instance.loginWithPlayerId(pid);
            if (ok) {
              resp = await _send();
            }
          }
        } catch (_) {}
      }
      if (resp.statusCode == 404) return null;
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final text = await resp.transform(utf8.decoder).join();
        throw HttpException('HTTP ${resp.statusCode}: $text', uri: uri);
      }
      // Capturer l'ETag courant
      final etag = resp.headers.value(HttpHeaders.etagHeader);
      if (etag != null && etag.isNotEmpty) {
        _etagCache[partieId] = etag.replaceAll('"', '');
      }
      final text = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(text);
      if (json is Map<String, dynamic>) return json;
      return null;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<CloudStatus> statusById({required String partieId}) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = _uri('/api/cloud/parties/$partieId/status');
      Future<HttpClientResponse> _send() async {
        final req = await client.getUrl(uri);
        final headers = await _buildHeaders();
        headers.forEach(req.headers.set);
        return await req.close().timeout(const Duration(seconds: 30));
      }
      var resp = await _send();
      if (resp.statusCode == 401) {
        try {
          final pid = await playerIdProvider?.call();
          if (pid != null && pid.isNotEmpty) {
            final ok = await JwtAuthService.instance.loginWithPlayerId(pid);
            if (ok) {
              resp = await _send();
            }
          }
        } catch (_) {}
      }
      if (resp.statusCode == 404) {
        return CloudStatus(partieId: partieId, syncState: 'unknown');
      }
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final text = await resp.transform(utf8.decoder).join();
        throw HttpException('HTTP ${resp.statusCode}: $text', uri: uri);
      }
      // Capturer l'ETag courant exposé par /status
      final etag = resp.headers.value(HttpHeaders.etagHeader);
      if (etag != null && etag.isNotEmpty) {
        _etagCache[partieId] = etag.replaceAll('"', '');
      }
      final text = await resp.transform(utf8.decoder).join();
      final obj = jsonDecode(text);
      if (obj is Map<String, dynamic>) {
        return CloudStatus(
          partieId: obj['partieId']?.toString() ?? partieId,
          syncState: obj['syncState']?.toString() ?? 'unknown',
          remoteVersion: obj['remoteVersion'] is int ? obj['remoteVersion'] as int : int.tryParse(obj['remoteVersion']?.toString() ?? ''),
          lastPushAt: _parseDate(obj['lastPushAt']),
          lastPullAt: _parseDate(obj['lastPullAt']),
          playerId: obj['playerId']?.toString(),
        );
      }
      return CloudStatus(partieId: partieId, syncState: 'unknown');
    } finally {
      client.close(force: true);
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}
