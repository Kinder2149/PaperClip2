// lib/services/cloud/http_cloud_persistence_port.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'cloud_persistence_port.dart';

typedef AuthHeaderProvider = FutureOr<Map<String, String>?> Function();

class HttpCloudPersistencePort implements CloudPersistencePort {
  final String baseUrl;
  final AuthHeaderProvider? authHeaderProvider;

  HttpCloudPersistencePort({required this.baseUrl, this.authHeaderProvider});

  Uri _uri(String path) => Uri.parse(baseUrl + path);

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };
    final extra = await authHeaderProvider?.call();
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  @override
  Future<void> pushById({
    required String partieId,
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> metadata,
  }) async {
    final client = HttpClient();
    try {
      final uri = _uri('/api/cloud/parties/$partieId');
      final req = await client.putUrl(uri);
      final headers = await _buildHeaders();
      headers.forEach(req.headers.set);
      final body = jsonEncode({
        'snapshot': snapshot,
        'metadata': metadata,
      });
      req.add(utf8.encode(body));
      final resp = await req.close();
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final text = await resp.transform(utf8.decoder).join();
        throw HttpException('HTTP ${resp.statusCode}: $text', uri: uri);
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
    final client = HttpClient();
    try {
      final uri = _uri('/api/cloud/parties/$partieId');
      final req = await client.getUrl(uri);
      final headers = await _buildHeaders();
      headers.forEach(req.headers.set);
      final resp = await req.close();
      if (resp.statusCode == 404) return null;
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final text = await resp.transform(utf8.decoder).join();
        throw HttpException('HTTP ${resp.statusCode}: $text', uri: uri);
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
    final client = HttpClient();
    try {
      final uri = _uri('/api/cloud/parties/$partieId/status');
      final req = await client.getUrl(uri);
      final headers = await _buildHeaders();
      headers.forEach(req.headers.set);
      final resp = await req.close();
      if (resp.statusCode == 404) {
        return CloudStatus(partieId: partieId, syncState: 'unknown');
      }
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final text = await resp.transform(utf8.decoder).join();
        throw HttpException('HTTP ${resp.statusCode}: $text', uri: uri);
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
