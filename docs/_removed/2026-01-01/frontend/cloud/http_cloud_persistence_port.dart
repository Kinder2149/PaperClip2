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
    }
    if (kDebugMode) {
      try {
        final hasAuth = headers.containsKey('Authorization');
        print('[DEBUG_AUTH_HEADER] Authorization present=${hasAuth}, X-Authorization present=false');
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
      if (kDebugMode) {
        print('[HTTP] GET ' + uri.toString());
      }
      Future<HttpClientResponse> _send() async {
        final req = await client.getUrl(uri);
        final headers = await _buildHeaders();
        headers.forEach(req.headers.set);
        return await req.close().timeout(const Duration(seconds: 30));
      }
      var resp = await _send();
      if (kDebugMode) {
        print('[HTTP] GET ' + uri.toString() + ' -> ' + resp.statusCode.toString());
      }
      if (resp.statusCode == 401) {
        try {
          final ok = await JwtAuthService.instance.loginWithPlayerId(pid);
          if (ok) {
            resp = await _send();
            if (kDebugMode) {
              print('[HTTP][retry] GET ' + uri.toString() + ' -> ' + resp.statusCode.toString());
            }
          }
        } catch (_) {}
      }
      if (resp.statusCode == 404) return <CloudIndexEntry>[];
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final text = await resp.transform(utf8.decoder).join();
        if (kDebugMode) {
          final preview = text.length > 512 ? (text.substring(0, 512) + '...') : text;
          print('[HTTP][ERR] GET ' + uri.toString() + ' body: ' + preview);
        }
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
      // S'assurer que le snapshot contient la version de schéma requise par le backend
      final snapToSend = Map<String, dynamic>.from(snapshot);
      if (!snapToSend.containsKey('snapshotSchemaVersion')) {
        snapToSend['snapshotSchemaVersion'] = 1; // aligné sur SNAPSHOT_SCHEMA_VERSION serveur
      }
      final body = jsonEncode({
        'snapshot': snapToSend,
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
        if (kDebugMode) {
          final cm = _etagCache[partieId];
          print('[HTTP] PUT ' + uri.toString() + ' If-Match=' + (cm ?? '-') + ' If-None-Match=' + (cm == null ? '*' : '-'));
        }
        req.add(utf8.encode(body));
        return await req.close().timeout(const Duration(seconds: 30));
      }
      var resp = await _send();
      if (kDebugMode) {
        print('[HTTP] PUT ' + uri.toString() + ' -> ' + resp.statusCode.toString());
      }
      if (resp.statusCode == 401) {
        try {
          final pid = await playerIdProvider?.call();
          if (pid != null && pid.isNotEmpty) {
            final ok = await JwtAuthService.instance.loginWithPlayerId(pid);
            if (ok) {
              resp = await _send();
              if (kDebugMode) {
                print('[HTTP][retry] PUT ' + uri.toString() + ' -> ' + resp.statusCode.toString());
              }
            }
          }
        } catch (_) {}
      }
      if (resp.statusCode == 412 || resp.statusCode == 428) {
        final text = await resp.transform(utf8.decoder).join();
        if (kDebugMode) {
          final preview = text.length > 512 ? (text.substring(0, 512) + '...') : text;
          print('[HTTP][ERR] PUT ' + uri.toString() + ' -> ' + resp.statusCode.toString() + ' body: ' + preview);
          print('[HTTP][RECOVERY] attempting to fetch ETag then retry once');
        }
        try {
          await statusById(partieId: partieId);
          if ((_etagCache[partieId] ?? '').isEmpty) {
            await pullById(partieId: partieId);
          }
          // Retry once after fetching ETag
          resp = await _send();
          if (kDebugMode) {
            print('[HTTP][retry-after-etag] PUT ' + uri.toString() + ' -> ' + resp.statusCode.toString());
          }
        } catch (_) {}
      }
      if (resp.statusCode == 412 || resp.statusCode == 428) {
        final text2 = await resp.transform(utf8.decoder).join();
        throw ETagPreconditionException(resp.statusCode, text2, currentEtag: _etagCache[partieId]);
      }
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final text = await resp.transform(utf8.decoder).join();
        if (kDebugMode) {
          final preview = text.length > 512 ? (text.substring(0, 512) + '...') : text;
          print('[HTTP][ERR] PUT ' + uri.toString() + ' body: ' + preview);
        }
        throw HttpException('HTTP ${resp.statusCode}: $text', uri: uri);
      }
      // Mettre à jour l'ETag si retourné par le serveur
      String? newEtag = resp.headers.value(HttpHeaders.etagHeader);
      newEtag ??= resp.headers.value('X-Entity-Tag');
      if (newEtag != null && newEtag.isNotEmpty) {
        _etagCache[partieId] = newEtag.replaceAll('"', '');
        if (kDebugMode) {
          print('[HTTP] PUT ' + uri.toString() + ' ETag=' + _etagCache[partieId]!);
        }
      } else {
        // Fallback: certains environnements ne renvoient pas l'ETag sur PUT 200.
        // On interroge /status pour capturer l'ETag courant et préparer le prochain If-Match.
        try {
          if (kDebugMode) {
            print('[HTTP] PUT ' + uri.toString() + ' no ETag in response, fetching /status as fallback');
          }
          await statusById(partieId: partieId);
          var cached = _etagCache[partieId];
          if (cached == null || cached.isEmpty) {
            if (kDebugMode) {
              print('[HTTP] Fallback /status had no ETag, trying full GET resource for headers');
            }
            // Appeler le GET de la ressource pour capturer l'ETag via les headers
            await pullById(partieId: partieId);
            cached = _etagCache[partieId];
          }
          if (kDebugMode) {
            print('[HTTP] Fallback etag cached for ' + partieId + ': ' + (cached ?? '-'));
          }
        } catch (_) {}
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
      if (kDebugMode) {
        print('[HTTP] GET ' + uri.toString());
      }
      Future<HttpClientResponse> _send() async {
        final req = await client.getUrl(uri);
        final headers = await _buildHeaders();
        headers.forEach(req.headers.set);
        return await req.close().timeout(const Duration(seconds: 30));
      }
      var resp = await _send();
      if (kDebugMode) {
        print('[HTTP] GET ' + uri.toString() + ' -> ' + resp.statusCode.toString());
      }
      if (resp.statusCode == 401) {
        try {
          final pid = await playerIdProvider?.call();
          if (pid != null && pid.isNotEmpty) {
            final ok = await JwtAuthService.instance.loginWithPlayerId(pid);
            if (ok) {
              resp = await _send();
              if (kDebugMode) {
                print('[HTTP][retry] GET ' + uri.toString() + ' -> ' + resp.statusCode.toString());
              }
            }
          }
        } catch (_) {}
      }
      if (resp.statusCode == 404) {
        // La ressource n'existe pas (ou plus) côté serveur: purger l'ETag pour forcer une création (If-None-Match: *) au prochain push
        _etagCache.remove(partieId);
        return null;
      }
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final text = await resp.transform(utf8.decoder).join();
        if (kDebugMode) {
          final preview = text.length > 512 ? (text.substring(0, 512) + '...') : text;
          print('[HTTP][ERR] GET ' + uri.toString() + ' body: ' + preview);
        }
        throw HttpException('HTTP ${resp.statusCode}: $text', uri: uri);
      }
      // Capturer l'ETag courant
      String? etag = resp.headers.value(HttpHeaders.etagHeader);
      etag ??= resp.headers.value('X-Entity-Tag');
      if (etag != null && etag.isNotEmpty) {
        _etagCache[partieId] = etag.replaceAll('"', '');
        if (kDebugMode) {
          print('[HTTP] GET ' + uri.toString() + ' ETag=' + _etagCache[partieId]!);
        }
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
      if (kDebugMode) {
        print('[HTTP] GET ' + uri.toString());
      }
      Future<HttpClientResponse> _send() async {
        final req = await client.getUrl(uri);
        final headers = await _buildHeaders();
        headers.forEach(req.headers.set);
        return await req.close().timeout(const Duration(seconds: 30));
      }
      var resp = await _send();
      if (kDebugMode) {
        print('[HTTP] GET ' + uri.toString() + ' -> ' + resp.statusCode.toString());
      }
      if (resp.statusCode == 401) {
        try {
          final pid = await playerIdProvider?.call();
          if (pid != null && pid.isNotEmpty) {
            final ok = await JwtAuthService.instance.loginWithPlayerId(pid);
            if (ok) {
              resp = await _send();
              if (kDebugMode) {
                print('[HTTP][retry] GET ' + uri.toString() + ' -> ' + resp.statusCode.toString());
              }
            }
          }
        } catch (_) {}
      }
      if (resp.statusCode == 404) {
        // Invalider tout ETag connu afin que le prochain PUT parte en création
        _etagCache.remove(partieId);
        return CloudStatus(partieId: partieId, syncState: 'unknown');
      }
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final text = await resp.transform(utf8.decoder).join();
        if (kDebugMode) {
          final preview = text.length > 512 ? (text.substring(0, 512) + '...') : text;
          print('[HTTP][ERR] GET ' + uri.toString() + ' body: ' + preview);
        }
        throw HttpException('HTTP ${resp.statusCode}: $text', uri: uri);
      }
      // Capturer l'ETag courant exposé par /status (header, header alternatif, ou depuis le corps)
      String? etagHeader = resp.headers.value(HttpHeaders.etagHeader);
      etagHeader ??= resp.headers.value('X-Entity-Tag');
      bool etagCached = false;
      if (etagHeader != null && etagHeader.isNotEmpty) {
        _etagCache[partieId] = etagHeader.replaceAll('"', '');
        etagCached = true;
        if (kDebugMode) {
          print('[HTTP] GET ' + uri.toString() + ' ETag=' + _etagCache[partieId]!);
        }
      }
      final text = await resp.transform(utf8.decoder).join();
      final obj = jsonDecode(text);
      if (!etagCached && obj is Map<String, dynamic>) {
        final bodyEtag = obj['etag'];
        if (bodyEtag != null && bodyEtag.toString().isNotEmpty) {
          _etagCache[partieId] = bodyEtag.toString();
          etagCached = true;
          if (kDebugMode) {
            print('[HTTP] GET ' + uri.toString() + ' using body etag=' + _etagCache[partieId]!);
          }
        }
        final rv = obj['remoteVersion'];
        if (rv != null && rv.toString().isNotEmpty) {
          _etagCache[partieId] = rv.toString();
          if (kDebugMode) {
            print('[HTTP] GET ' + uri.toString() + ' no header ETag, using remoteVersion as ETag=' + _etagCache[partieId]!);
          }
        }
      }
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
