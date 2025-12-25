// lib/services/analytics/http_analytics_port.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'analytics_port.dart';

class HttpAnalyticsPort implements AnalyticsPort {
  final String baseUrl;
  final Future<Map<String, String>?> Function()? authHeaderProvider;

  HttpAnalyticsPort({
    required this.baseUrl,
    this.authHeaderProvider,
  });

  @override
  Future<void> recordEvent(String name, Map<String, Object?> properties) async {
    final uri = Uri.parse('$baseUrl/api/analytics/events');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final extra = await authHeaderProvider?.call();
    if (extra != null) {
      headers.addAll(extra);
    }

    final body = jsonEncode({
      'name': name,
      'properties': properties,
      'timestamp': DateTime.now().toIso8601String(),
    });

    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      headers.forEach(request.headers.add);
      request.add(utf8.encode(body));
      final response = await request.close();
      // Best-effort: ignore non-200 without throwing
      await response.drain();
    } catch (_) {
      // No-op on failure
    } finally {
      client.close(force: true);
    }
  }
}
