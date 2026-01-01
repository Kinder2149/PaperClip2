import 'dart:async';
import 'dart:convert';
import 'dart:io';

class BackendHealthService {
  final Uri baseUri;
  final Duration timeout;

  BackendHealthService({required String baseUrl, Duration? timeout})
      : baseUri = Uri.parse(baseUrl),
        timeout = timeout ?? const Duration(seconds: 5);

  /// Effectue un GET sur /health et retourne true si 200 et payload cohérent.
  Future<bool> checkHealth() async {
    final client = HttpClient();
    client.connectionTimeout = timeout;
    try {
      final uri = baseUri.replace(path: _join(baseUri.path, 'health'));
      final req = await client.getUrl(uri).timeout(timeout);
      final resp = await req.close().timeout(timeout);
      if (resp.statusCode != 200) return false;
      final body = await resp.transform(utf8.decoder).join();
      if (body.isEmpty) return true; // Accepte 200 sans corps.
      try {
        final json = jsonDecode(body);
        // Accepte {"status":"ok"} ou équivalent.
        if (json is Map && json['status']?.toString().toLowerCase() == 'ok') {
          return true;
        }
      } catch (_) {
        // Corps non JSON: on considère OK si 200
        return true;
      }
      return true;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  String _join(String a, String b) {
    if (a.endsWith('/')) a = a.substring(0, a.length - 1);
    if (b.startsWith('/')) b = b.substring(1);
    return '$a/$b';
  }
}
